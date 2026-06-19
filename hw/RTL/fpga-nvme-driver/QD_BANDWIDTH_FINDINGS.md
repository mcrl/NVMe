# OcuLink NVMe bandwidth: how far the FPGA host can push, and where the wall is

Goal was ">=80% of the 3.94 GB/s Gen3 x4 link" (3.15 GB/s). This documents the FPGA-side work done to get
there, and the hardware-counter proof of what actually limits it. Bottom line up front: **the FPGA datapath is
at line rate and is not the bottleneck; sustained bandwidth is gated by the SSD** (its 256 B MaxPayload HW cap
and its serial streaming / concurrent-read behaviour). Measured sustained (QD=1, beat-counter validated):
READ ~2.37-2.84 GB/s (60-72%), WRITE ~2.38-2.43 GB/s (60-62%).

## FPGA optimisations implemented (all HW-built, timing MET)

- **MO-8 — write-data R-serve back-to-back (no inter-burst bubble).** The write-payload R server (`wrdata_state`
  FSM in `nvme_driver.sv`) went IDLE between bursts, costing ~2 idle cycles per 8-beat (256 B = MPS) MRd burst
  = ~20% of line rate when the SSD pipelines MRds. Added a 2-deep peek to `tagfifo.sv` (`head2`/`cnt`) and a
  stall-robust chaining FSM: it crosses a burst boundary only once the `rlast` beat is actually accepted
  (`rready`), so it chains at 0% bubble AND holds correctly across `rready` stalls. Sim (tb_cpl_stress
  RDBURST/RDSTALL): 642->516 cycles for 64x8-beat, bubble 20%->0%, every beat served across throttled `rready`.
  **HW result: write 128 KB unchanged (~2.43 GB/s).** => the FPGA bubble was *masked* by the SSD's slower MRd
  cadence; removing it is correct and robust but the SSD, not the FPGA, paces writes.

- **MO-9 — decouple SQE submission from the doorbell-B rendezvous.** `CMD_DONE` waited `db_done` and `DB_DONE`
  waited `cmd_done` (a two-way rendezvous), pinning effective QD~1: the cmd FSM could not pop the next SQE until
  a full SQ-tail doorbell AW+W+B round-trip finished. Removed both waits (CMD_DONE->CMD_IDLE, DB_DONE->DB_IDLE
  unconditionally); `io_serve_cnt`/`io_sq_rung` coalescing already rings the SQ-tail to the latest value, which
  is valid NVMe. Single-command regression (tb_nvme_driver 70w/8r) and a new pipelined QD test (tb_nvme_qd +
  ssd_model_pipe, QD=8/32) pass: the FPGA correctly serves many in-flight SQEs and captures every read-payload
  beat with exactly one CQE per command. **HW result: QD=1 unchanged; QD>1 still does not raise BW (see below).**

- **Diagnostic counters (CSR 0x70 `raw_w_beats`, 0x74 `raw_w_bursts`).** `raw_w_beats` counts EVERY accepted W
  beat regardless of class -> distinguishes "FPGA dropped data" from "SSD sent less". These settled the QD>1
  question definitively.

## Datapath audit (multi-agent) — the FPGA is already optimal

A parallel audit + adversarial verification of the whole `oculink_m_axi` slave datapath confirmed, with line
references, that the user's two levers are **already satisfied**:
- **Continuous AR/AW accept + many in flight:** `arready/awready/wready` are tied 1; rtag/wtag are 256 deep; the
  W-acceptor captures interleaved read-data + CQE from many outstanding AWs correctly (tb_cpl_stress RDCQE).
- **Fast B:** `oculink_m_axi_bvalid = wb_avail` is a register compare; B is 1 cycle after `wlast`, 1 B/cycle,
  independent of `bready`; W is never back-pressured.
The only FPGA-side throughput lever the audit found was effective QD (MO-9), now removed. No datapath edit can
close the remaining gap.

## The QD>1 read "anomaly" — measured to the SSD with raw counters

At QD>1 the completion-based bandwidth (`cmpl`) reads as `QD x REAL` and `REAL` (real bytes moved) does not
rise. Pinned it with the raw counter, single batch, distinct per-command buffers AND distinct per-LBA data:

| case (QD=2, distinct) | cpl_count | w_data_beats | raw_w_beats | meaning |
|---|---|---|---|---|
| nlb=7 (1 page, no PRP2) | 2 (correct) | 128 (half) | **130** = 128 data + 2 cqe | SSD sent ONE command's data |
| nlb=63 (8 pages, list) | 2 (correct) | 1024 (half) | **1026** | same |
| QD=4 nlb=7 | 4 (correct) | 128 | **132** = 128 + 4 cqe | SSD sent ONE command's data, 4 CQEs |

Key facts established:
- **`cpl_count` is correct** (= QD). There is no completion inflation in the FPGA; `cmpl` over-reports only
  because it assumes each completion moved a full command's data, which is false when the SSD coalesces.
- **`raw_w_beats` = one command's payload + QD CQE beats.** The FPGA received exactly what the SSD sent and
  counted it correctly; **the SSD physically transferred only one command's read-data while completing all QD.**
- Independent of distinct buffers, distinct data content (rules out dedup), page count, and PRP-list.
- **Spacing the submissions fixes it**: any *overlap* of two read commands -> half; fully *serialised*
  (submission gap > one command's transfer time) -> full (raw_w_beats = 8194/8194 at 128 KB QD=2, 80 us gap).
  Sub-write flushing (read-back to force each MMIO write to land) does NOT fix it -> the CSR/SQE values are
  correct; it is genuinely a *concurrent-read* effect, not a submission corruption.

Conclusion: **QD>1 reads provide no bandwidth on this SSD** — any concurrency makes the SSD coalesce to one
command's transfer. The FPGA is proven (raw counters + pipelined sim) to handle QD>1 correctly. Writes behave
similarly (QD>1 doesn't raise `REAL`; the SSD's MRd cadence paces it). QD=4+ sustained load wedges the card.

## Where the 80% goes

- Link = Gen3 x4 = 3.94 GB/s. SSD MaxPayloadSupported = **256 B (HW cap)** -> PCIe TLP efficiency ceiling
  ~256/(256+~24) = ~91% -> ~3.58 GB/s absolute max. 80% of *link* (3.15) = 88% of that ceiling.
- Achieved (QD=1, the only regime where data isn't coalesced): READ 2.37-2.84 (66-79% of the 3.58 ceiling),
  WRITE 2.38-2.43 (66-68% of ceiling). The remainder is the SSD's own streaming engine efficiency at 256 B
  TLPs + its per-command turnaround, none of which the FPGA can accelerate (reads never back-pressure W;
  writes are served bubble-free after MO-8).
- **80% of link is not reachable on this SSD/OcuLink pairing.** It would require either a larger SSD MPS (HW
  capped at 256 B) or the SSD to stream faster / not coalesce concurrent reads — both SSD-side.

## Repro / tools
- `sw/nvme_driver_test/sw/nvme_qd_diag.c` — single-batch QD raw-counter probe. Env: `SPACEDUS=<us>` inter-command
  gap. Args: `<resource0> <QD> <nlb> <distinct>`. Prints cpl/w_data_beats/raw_w_beats deltas + verdict.
- `sw/nvme_driver_test/sw/nvme_bw_bench.c` — size sweep; REALMB/s (beat counter) is the honest number, cmplMB/s
  over-reports at QD>1 (SSD coalesce). Args: `<resource0> r|w|wr <QD> <mps> <mrrs> <distinct>`.
- `sim/ssd_model_pipe.sv` + `sim/tb_nvme_qd.sv` — pipelined (two-thread) SSD model proving the FPGA handles
  true QD>1 read concurrency (all payload captured, one CQE/command) — i.e. the HW shortfall is SSD-side.
- `sim/tb_cpl_stress.sv` — RDBURST/RDSTALL (write-serve bubble + stall robustness), RDCQE (W-acceptor under
  many outstanding interleaved AWs).
