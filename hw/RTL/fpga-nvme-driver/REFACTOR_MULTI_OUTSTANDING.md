# RTL Refactor — Multiple-Outstanding / Queue Pipelining (Phase 4 / B1)

Status: **partially complete + verified on hardware.** QD=1 sustained is now unlimited; QD=2 doubles IOPS
(pipelining proven). QD>=4 is capped by a write-channel demux limitation (next step MO-4). 2026-06-10.

## What changed (RTL, on top of Phase 1+2)
| Change | File | Detail |
|---|---|---|
| **CQ-head doorbell ring** | `nvme_driver.sv` | The `cpl` FSM advances `iocqhdbl`/`acqhdbl` per completion (IO vs admin); the `db` FSM rings the CQ-head doorbell (NVMe BAR `+0x100C` IO, `+0x1004` admin) to that value, coalescing. Frees CQ slots so the completion queue never fills. New `db` states `DB_RING_*CQH`/`DB_SEND_*CQH`/`DB_CQH_WAIT`. |
| **cpl FSM always re-arms** | `nvme_driver.sv` | Captures every completion back-to-back instead of waiting for the next submission. |
| **Completion counter** | `nvme_driver.sv`,`kernel.sv`,`csr.sv` | `cpl_count` increments per CQE, readable at CSR **0x64**. Host submits N then polls `cpl_count >= N` — the robust multi-outstanding completion signal (replaces the racy single-bit `cpl_done` poll). |

## Hardware results (`sw/nvme_driver_test/sw/nvme_qd_bench.c`, write IOPS vs queue depth)
```
  QD   completed   cmds/s     us/cmd
  1    1000        128,347    7.79     <- was STALLING at 16 before; now unlimited (CQ-head ring works)
  2    1000        256,028    3.91     <- exactly 2x IOPS: queue pipelining hides latency
  4    2/4 STALL                       <- back-to-back CQE capture miss (see Known limitation)
```
- **Sustained operation fixed:** ran 1000 back-to-back commands with no stall (previously stalled at ~16, then ~58).
- **Multiple-outstanding proven:** QD 1->2 doubled command rate and halved per-command latency. NVMe's
  queue-depth scaling is now real (at least to QD=2).
- IOPS, not GB/s: useful data is still 32 B/command (the host-DMA datapath rebuild, B2, is separate). At the
  SSD block level (512 B) QD=2 is ~131 MB/s; real host payload moved is ~8 MB/s until B2.

## Simulation testbench (NEW, reusable) + revised diagnosis

Built an `xsim` testbench under `hw/RTL/fpga-nvme-driver/sim/` to de-risk the QD>2 work without 40-min synth cycles:
- `sim_fifo.sv` — behavioural stand-ins for the Xilinx FIFO IPs (iosq/asq/wraddr).
- `ila_0_stub.sv` — empty ila_0 (widths matched).
- `ssd_model.sv` — behavioural OcuLink NVMe SSD: receives doorbells, fetches SQEs, runs the data phase,
  posts CQEs (respects CQ space; can pipeline completions to stress the FPGA).
- `tb_nvme_driver.sv` — drives admin creates + N IO writes, checks `cpl_count`.
Run: `xvlog -sv sim/sim_fifo.sv sim/ila_0_stub.sv nvme_driver.sv sim/ssd_model.sv sim/tb_nvme_driver.sv ; xelab tb_nvme_driver -s tbsim ; xsim tbsim -R`

**The testbench corrected two diagnoses the HW alone could not:**
1. The QD>2 "stall" is **not** a back-to-back CQE-capture miss. It is a **doorbell/FIFO race deadlock**: the `db`
   FSM rang SQ-tail doorbells gated on FIFO-non-empty, but the `cmd` FSM pops the same FIFO; when `db` was busy
   (e.g. ringing a CQ-head), `cmd` emptied the FIFO and `db` then never rang the SQ tail -> the SSD never reads
   the SQE -> deadlock. **Fixed** by making SQ-tail doorbells counter-driven (cmd advances `io_serve_cnt`/
   `a_serve_cnt`; db rings to match, coalescing — same pattern as the CQ-head ring). Sim now completes both
   admin creates. (Implemented in the working tree, not yet on hardware.)
2. The remaining QD>1 blocker is bigger than "write-channel demux": **both** OcuLink `m_axi` channels are
   single-muxed and break when commands pipeline:
   - **R channel** (`is_sending_cmd` mux): carries SQE serves (cmd FSM) **and** write-command payload (wrdata
     FSM). With QD>1 the cmd FSM serves the *next* command's SQE while the SSD is still reading the *previous*
     command's write data -> the mux blocks the data serve (observed in sim: `is_sending_cmd=1`, data read
     times out).
   - **W channel** (`is_receving_cpl` mux): carries CQEs (cpl FSM) **and** read-command payload (rd FSM).

## MO-4 IMPLEMENTED — m_axi R/W in-order demux (2026-06-11)

Designed via a multi-agent map/design/judge workflow; landed Approach 2 (minimal mux-by-tag) + two grafts from
Approach 1 (mandatory SQE-AR buffer, arlen-in-tag). New reusable module `tagfifo.sv` (FWFT single-clock ring;
the existing sim_fifo is standard-read and unfit for a head-of-queue mux).

Insight: the R/B muxes selected on a PRODUCER-STATE flag (`is_sending_cmd` / `is_receving_cpl`), not on which
transaction the SSD is waiting on. Since `oculink_m_axi_{ar,aw}ready` are tied 1 and rid/bid are single-ID 0,
AR-accept order IS the mandatory R-return order and AW-accept order IS the B order. So the only correct schedule is
"serve the oldest outstanding transaction" — tracked by a 1-class tag pushed per accepted AR/AW and consumed at
rlast / B.

| Change | Detail |
|---|---|
| **R-tag FIFO** (`rtag`, 9b={is_sqe,arlen}, FWFT, depth 256) | push on every `arvalid`; `rtag_sel_cmd = head.is_sqe` drives the R mux (replaces is_sending_cmd); pop on `rvalid&rready&rlast`. |
| **SQE-AR buffer** (`sqear`, depth 16) | records each accepted SQE-class AR so the cmd FSM never misses an unbuffered arvalid. `CMD_RECV_ADDR` now waits on `!sqear_empty` (not live araddr) and branches on `cmd_is_admin`. |
| **W-tag FIFO** (`wtag`, 1b=is_cqe, depth 256) | push on every `awvalid`; `wtag_sel_cpl = head` drives the B mux (replaces is_receving_cpl); pop on `bvalid&bready`. |
| **Ownership guards** | cmd serves only when `rready & rtag_sel_cmd`; wrdata only when `rready & !rtag_sel_cmd`; cpl sends B only when `bready & wtag_sel_cpl`; rdrsp only when `bready & !wtag_sel_cpl`. Prevents a source advancing on an rready/bready meant for the other. |
| **Deleted legacy ring** | removed the 16-entry `wraddr_wrlen[]`/`wraddr_recv_cnt`/`wrdata_send_cnt`/`WRDATA_CHECK_NEXT` and the dead `wraddr_fifo` IP; wrdata burst length now comes from `rtag_head_arlen` -> outstanding write-data reads no longer capped at 16. |

Invariant (why correct under arbitrary overlap): the tag FIFO records AR/AW-accept order exactly (push == accept,
since *ready=1); head = oldest outstanding; exactly one source drives R/B (the head's class) and the tag pops only
on that burst's rlast/B, so two bursts can never interleave -> single-ID in-order R and AW-order B. A write
command's data-AR sitting behind (or ahead of) the next command's SQE-AR is simply served in accept order; the old
"mask-and-drop" is structurally impossible.

**Verified in xsim** (`tb_nvme_driver`): 2 admin creates + 16 IO writes => `cpl_count=18 PASS` (was a hang/TIMEOUT
before); + 8 IO reads => `cpl_count=26 PASS`, `rddata[0]=dadacafe` (read-data captured via the W demux to the rd
sink; data integrity holds). No axi_read TIMEOUT.

**Bug caught by the testbench assertions (and fixed):** the first cut of Step 3 had `WRDATA_IDLE` start a burst on
`!rtag_empty && !rtag_head_is_sqe`. Because the rtag pop is registered (fires one cycle after rlast), at the burst's
own rlast cycle the FSM is already back in IDLE while the rtag head still shows the just-served data tag -> it
re-triggered on the SAME tag and served a spurious second burst that then collided with the next command's SQE,
truncating the real transfer to 8 of 16 beats. The basic PASS/FAIL test missed it (the SSD model only drains to
rlast and discards the payload); the added beat-count assertion + the SSD `BEATCOUNT` check flagged "got 8 beats,
expected 16". Fix: gate the IDLE entry with `&& !rtag_pop` so a tag being popped this cycle can't restart a burst.
Lesson: keep the in-order length-accounting assertion (`wbeats == arlen+1`) and the rtag/wtag underflow asserts in
the TB permanently — they catch data-corruption bugs that a completion-count test cannot.

Pacing note (kept for the landing): the `cmd_done/db_done` handshake serializes one SQE-serve per SQ-tail doorbell,
so SQE availability (hence achievable submit-side overlap) is ~1 at a time. Correctness is independent of this;
if HW QD scaling plateaus, decouple the handshake (DB_DONE returns on its own B like DB_CQH_WAIT) as a follow-up.

## HARDWARE RESULTS — MO-4 demux on the Samsung SSD (2026-06-11)

Built (timing MET: WNS +0.196ns / WHS +0.0097ns), JTAG-programmed, re-enumerated (PCIe remove+rescan after the PL
reload), and benchmarked with `sw/nvme_driver_test/sw/nvme_qd_bench.c` (write IOPS vs QD):

```
  QD   cmds/s    vs QD1   status
  1    128,479   1.0x     ok
  2    254,321   2.0x     ok
  4    249,869   1.9x     ok   <- STALLED before MO-4; now completes
  8    337,295   2.6x     ok   <- STALLED before MO-4; now completes
  16   365,629   2.85x    ok   <- STALLED before MO-4; now completes
  32   (stall)   -        only 660/672 completed
  64   (stall)   -        0/64 completed
```

**The demux fixed the QD>=4 hang.** Before MO-4 every QD>=4 run stalled (the doorbell-race deadlock + the
single-mux R/W collision). Now QD 4/8/16 all complete and IOPS scales to **2.85x** (366k cmds/s) at QD=16. IOPS
saturates around QD=8-16 (~360k) — that ceiling is the FPGA's per-command serve rate (cmd_done/db_done pacing +
OcuLink round-trip), not the demux.

**Remaining: QD>=32 stalls on completion capture (MO-5).** At high QD the real SSD posts CQEs back-to-back faster
than the `cpl` FSM's IDLE->RECV->RESP->DONE cycle, and its *unbuffered* AW-catch (CPL_IDLE only catches awvalid
while in IDLE) drops some -> `cpl_count` falls short -> stall. The `wtag` already buffers the AW *class* (so the B
mux is correct), but the *capture+count* path is still a single-in-flight FSM. Fix (MO-5): make CQE capture driven
by the W stream (count every CQE wlast, gated by the W-burst's tag class) instead of the FSM state, with a separate
W-burst read pointer for capture vs the B read pointer — i.e. unify rd+cpl into one W-acceptor with a 2-read-pointer
wtag {is_cqe,is_iocq}. This mainly buys robustness/completion at QD>=32 (IOPS is already saturating), so it's a
follow-up, not part of the demux landing. Verify with a back-to-back-CQE stress in the testbench before synth.

## READ vs WRITE performance (MO-4 bitstream, clean single-mode runs)

`sw/nvme_driver_test/sw/nvme_rw_bench.c` (arg2 = "r"/"w"/"wr"; reads use trigger 0x48, writes 0x4C):

```
WRITE (low latency -> command-rate bound, saturates ~QD8):
  QD1 128k  QD2 258k  QD4 250k  QD8 328k (168 MB/s blk, 10.5 MB/s host)  QD16+ stall
READ  (high NAND latency, QD hides it -> near-LINEAR scaling):
  QD1 22.6k(44us)  QD2 45k  QD4 90k  QD8 181k  QD16 363k(186 MB/s blk,11.6 MB/s host)  QD32 284k  QD64 stall
```
- Read scales ~16x from QD1->QD16 (latency fully hidden); not yet saturated. Write saturates ~QD8.
- "host MB/s" (32 B/cmd) is the real unique host bytes moved — the datapath replays one 256-bit beat to fill
  the 512 B block, so block MB/s >> host MB/s until the host-DMA datapath rebuild.
- IMPORTANT: a stalled sweep corrupts the queue pointers, so a later sweep in the same run all-stalls — measure
  read and write in separate fresh-bringup runs (arg2 "r" / "w").

## MO-5 IMPLEMENTED — unified W-channel acceptor (back-to-back CQE capture)

The QD>=16/32 stalls are the completion-CAPTURE path, not the demux: the old `cpl` FSM caught `awvalid` only in
CPL_IDLE and took ~4-5 cycles/CQE (IDLE->RECV->RESP->DONE), so a CQE-AW arriving while it was busy was dropped.
A focused stress (`sim/tb_cpl_stress.sv`, 64 back-to-back CQEs ~2 cycles apart) reproduced it: **32/64 counted**.

Fix: replace the `rd` + `rdrsp` + `cpl` FSMs with one **W-stream-driven acceptor**. `wtag` now carries
{is_cqe, is_iocq} per accepted AW and is walked by THREE pointers: `w_awp` (AW push), `w_capp` (advances per
completed W burst -> capture+count, never blocked by B), `w_bp` (one OKAY B per captured burst, in AW order).
Completion count is driven by the W stream (one count per CQE `wlast`, routed by the tag class at `w_capp`), so
back-to-back CQEs are never dropped; read-command payload lands in `rd_data` on its burst's `wlast`. Handles the
same-cycle AW+W(wlast) case via a live-class bypass. B/id/resp are constant (0/OKAY) so the B mux is gone.

Verified in xsim: `tb_cpl_stress` **64/64 and 200/200 PASS** (was 32/64); `tb_nvme_driver` no regression
(70 writes wrap + 8 reads, rddata integrity, all assertions clean).

**Hardware (MO-5 bitstream, timing MET WNS +0.104ns):**
```
READ : QD16 363k -> QD32 ~295k -> QD64 ~405k cmds/s (209 MB/s blk, 13 MB/s host)   <- QD64 was a STALL pre-MO-5
WRITE: QD1 128k  QD2 259k  QD8 333k (peak, 170 MB/s)  QD16+ : marginal 2-cmd race (see below)
```
- **READ QD64 now completes** (was a hard stall) at ~405k cmds/s / 209 MB/s block — the MO-5 win. Reads are
  reliable across the whole QD sweep now; the cpl-capture overrun is gone (W-stream capture never drops a CQE).
- Read throughput plateaus ~300-400k beyond QD16 (SSD read-rate / FPGA serve-rate ceiling), so it is no longer
  the clean linear curve of QD1-16; QD64 is still the peak.
- **WRITE still stalls ~2 commands short at QD>=16**, at a *random* batch (542/544, 974/976, ...). This is NOT the
  cpl capture (the stress proves 200/200, and READ QD16 — which loads the W channel MORE, with read-data + CQE —
  passes). It is a separate marginal high-rate race on the write path (most likely the single `db` FSM serializing
  SQ-tail + CQ-head rings can't free CQ slots fast enough at peak write rate, so the SSD stalls posting the last
  CQEs). Low value to chase: writes already saturate at QD8 (~333k), so QD16 would gain little. Tracked as MO-6.

## Known limitation -> next step (superseded once MO-4 lands on HW)
Complete multiple-outstanding (QD up to 64) requires **demuxing both `m_axi` channels** so SQE-serve / write-data
(R) and CQE / read-data (W) can interleave: route each AR/AW by address (IOSQ/ASQ vs IORW; IOCQ/ACQ vs IORW),
using a small in-flight address FIFO and AXI IDs, and split the monolithic cmd/wrdata/rd/cpl coordination.
This is now tractable in the testbench (seconds per iteration) before a single synth.

### Original (pre-testbench) note — superseded by the above
QD>=4 stalls because the OcuLink `m_axi` **write** channel carries BOTH completion CQEs (to the CQ BARs) and
read-command data (to the IORW BAR), and with QD>2 these interleave / arrive back-to-back. The current `rd`,
`cpl`, and `rdrsp` FSMs each watch `awvalid`/`wvalid` independently assuming one write in flight, so they drop
AW events that arrive while busy. **Fix:** a single write-demux — push every AW address into a small FIFO, and
route each W burst (until `wlast`) to the CQE handler or the read-data handler by popping that FIFO. This
unifies `rd`+`cpl`+`rdrsp`. Strongly recommended to build the SystemVerilog testbench (modelling the SSD's
OcuLink AXI) first to verify it in `xsim` before the ~40-min synth cycle.

After MO-4 (QD up to 64): expected order-of-magnitude IOPS gains. Full GB/s throughput additionally needs the
host-DMA datapath (B2) and larger transfers (B4) — see ARCHITECTURE_ANALYSIS.md.
