<!-- Auto-generated architecture analysis (multi-agent workflow, 2026-06-09).
     Plus live HW measurement: WRITE nlb=0 completes ~16 back-to-back commands then STALLS;
     useful payload = 32 B/command; read data not returned to host. Effective throughput ~2 MB/s
     vs ~3.9 GB/s hardware ceiling. -->

# FPGA NVMe Host Controller — Architecture & Refactor Proposal

**Scope:** RTL under `/home/junsik/workspace/NVMe/hw/RTL/fpga-nvme-driver/` (`top.sv`, `kernel.sv`, `csr.sv`, `nvme_configurator.sv`, `nvme_driver.sv`), the BDs under `/home/junsik/workspace/NVMe/hw/BD/`, and the host test program `/home/junsik/workspace/NVMe/sw/nvme_driver_test/sw/driver_test.c`.

**One-line verdict:** This is a *correct, single-command functional bring-up harness*, not a data mover. It moves at most 32 bytes of real payload per fully-serialized, software-polled command, and the host's high-bandwidth DMA path is physically unconnected. Both of the owner's goals — ease-of-use and R/W performance — are blocked by the same root causes: a raw-MMIO/poll control model and a missing bulk datapath. The good news: the silicon is already balanced for ~3.9 GB/s, so the entire gap is in architecture, recoverable incrementally.

---

## 1. Architecture overview

### Module hierarchy

```
top (top.sv:2)
├── host_xdma_bd_wrapper_i        (top.sv:103)   Host PCIe Gen3 x16 endpoint (to the PC)
│     └─ xdam_host : xdma 4.1, DMA mode, 512-bit, 250 MHz
│          ├─ M_AXI_LITE ─► axi_bram_ctrl (AXI4-LITE, 32-bit) ─► BRAM ─► host_bram_*
│          └─ M_AXI (512-bit, 4×H2C + 4×C2H DMA)  ──►  *** DANGLING — no interface_net ***
├── oculink_0a_bd_wrapper_i       (top.sv:121)   OcuLink PCIe Gen3 x4 Root Complex (to the SSD)
│     └─ xdma 4.1, AXI_Bridge mode, Root Port, 256-bit, 125 MHz
│          ├─ m_axi  (SSD as master into FPGA "host memory")
│          └─ s_axi  (FPGA as host writing SSD BAR / doorbells)
└── kernel  kernel_i              (top.sv:201, kernel.sv:1)
      ├── csr               csr_i                  (kernel.sv:147)  register file (host_bram_clk)
      ├── nvme_configurator nvme_0a_configurator_i (kernel.sv:180)  PCIe cfg-space walk to SSD
      └── nvme_driver       nvme_driver_0a_i       (kernel.sv:227)  doorbells + SQE gen + data + completion
```

The OcuLink **slave** write channel is muxed between configurator and driver by `cfg_0a_cfgdone` (`kernel.sv:135-145`): `0` = configurator owns the bus (enumeration), `1` = driver owns it (NVMe traffic). All OcuLink master/slave ready signals are tied to `1'b1` (`kernel.sv:130-134`, `nvme_driver.sv:92-95`) — **the FPGA never back-pressures the SSD**.

### Clock domains (two)

| Clock | Freq | Width | Drives | Source |
|---|---|---|---|---|
| `host_bram_clk` | **250 MHz** | 32-bit AXI4-Lite | all of `csr.sv`; host-side of CDC FIFOs | host XDMA `axisten_freq=250` |
| `oculink_axi_clk` | **125 MHz** | 256-bit AXI4 | all 7 driver FSMs, configurator FSMs | OcuLink XDMA `axisten_freq=125` |

*Resolved disagreement:* one analysis listed the host CSR domain at 125 MHz; the `.xci` confirms host XDMA `axisten_freq=250`. Net effect on conclusions is nil — the CSR path is MMIO-transaction-bound, not clock-bound.

**CDC crossings (host_bram_clk → oculink_axi_clk):** `iosq` FIFO (`nvme_driver.sv:142-143`), `asq` FIFO (`:170-171`), and the configurator's `csr2cfg_w_i`/`csr2cfg_r_i` pulse FIFOs (`nvme_configurator.sv:62-90`). **Unsynchronized crossings (latent bugs):** `wrdata[7:0]` is written on `host_bram_clk` but consumed combinationally on `oculink_axi_clk` (`nvme_driver.sv:688`) with no synchronizer (safe only because SW writes-then-triggers-then-polls); `cpl_done` is a 1-bit crossing read back by CSR with no synchronizer (`csr.sv:122`).

### System block diagram

```
┌────────────┐   PCIe Gen3 x16   ┌──────────────── FPGA ────────────────────────────────────────┐
│  HOST PC   │  (15.75 GB/s raw) │                                                                │
│ driver_    │ ◄───────────────► │  host XDMA (DMA,512b,250MHz)                                    │
│ test.c     │                   │    ├ M_AXI_LITE►axi_bram_ctrl(32b)►BRAM►host_bram_*►┐          │
│ mmap 64KB  │                   │    └ M_AXI (512b, 4×4 DMA) ✗ DANGLING               │          │
│ raw MMIO   │                   │                                                     ▼          │
│ + busypoll │                   │                                            ┌──────csr.sv──────┐│
└────────────┘                   │                                            │ cfg_* / send_*   ││
                                 │                                            │ nvme_addr/nlb    ││
                                 │   ┌────────────────── kernel.sv ───────────┤ wrdata[7:0]=32B  ││
                                 │   │                                        │ cpl_done @0x5C   ││
                                 │   │  cfg_0a_cfgdone mux (kernel.sv:135-145)└──────┬─────┬─────┘│
                                 │   │        │                                     │     │       │
                                 │   │  ┌──────▼────────┐                  ┌────────▼─────▼─────┐ │
                                 │   │  │nvme_configura-│ csr2cfg FIFOs    │   nvme_driver.sv   │ │
                                 │   │  │tor.sv (cfg WR/│ (CDC)            │ 7 FSMs @125MHz:    │ │
                                 │   │  │RD FSMs, 1-beat│                  │ db/cmd/rd/rdrsp/   │ │
                                 │   │  │AXI)           │                  │ wrdata/cpl + cnt   │ │
                                 │   │  └──────┬────────┘                  │ iosq(97b) asq(1b)  │ │
                                 │   │         │ s_axi (cfg TLPs)          │ wraddr_fifo(8b)    │ │
                                 │   │         │                           └───┬─────────┬──────┘ │
                                 │   │         │   OcuLink XDMA (AXI_Bridge,    │ s_axi   │ m_axi  │
                                 │   │         └──►Root Port, Gen3 x4, 256b,◄───┘doorbell │payload │
                                 │   │            125MHz, 3.94 GB/s)             MMIO      │+SQE+CQE│
                                 │   └──────────────────────┬────────────────────────────┘        │
                                 └──────────────────────────┼─────────────────────────────────────┘
                                              OcuLink Gen3 x4 │ (PCIe TLPs)
                                                       ┌──────▼───────┐
                                                       │ Samsung NVMe │  ~3.0-3.5 GB/s rd
                                                       │     SSD      │  ~2-3 GB/s wr
                                                       └──────────────┘
```

**Inverted queue model (important to understand):** the FPGA is the PCIe Root Complex / NVMe host, but it has **no real queues in DRAM**. It *synthesizes the host-memory image the SSD DMAs against*: submission queues are **generated on demand** by the `cmd_state` FSM when the SSD issues a master-read to `ASQ_BAR`/`IOSQ_BAR`; completion queues are **captured** by `cpl_state` when the SSD master-writes to `ACQ_BAR`/`IOCQ_BAR`; doorbells are real MMIO writes via the s_axi port. The only true "queue storage" is the `iosq`/`asq` CDC FIFOs holding *pending work*, not NVMe queue images.

---

## 2. Data path (write & read)

### WRITE (host → SSD)

```
HOST: 8×32b MMIO stores wrdata[0..7] (driver_test.c:155-162) + nvme_addr/fpga_addr/nlb, pulse 0x4C
  │  PCIe Gen3 x16 → host XDMA → AXI4-LITE 32b → axi_bram_ctrl → host_bram_* (32b, 250MHz)
  ▼
csr.sv  wrdata[7:0] = 8×32b = 256-bit REGISTER  (csr.sv:84-91)   ◄── the ONLY write "buffer" = 32 B
  ▼  push into iosq FIFO  {rw, nvme_addr[32], fpga_addr[32], nlb[32]} = 97b×1024  (nvme_driver.sv:138-153)
  │  ===== CDC 250MHz → 125MHz =====
  ▼
DB FSM rings IO SQ doorbell via s_axi write to IODB_OFFSET (BAR+0x1008)  (nvme_driver.sv:225-271)
CMD FSM: SSD master-reads 64B SQE; FPGA serves 2×256b beats on m_axi R  (nvme_driver.sv:414-455)
  ▼  SSD parses PRP1=nvme_addr, master-READs payload (ar ≥ IORW_BAR=0xC000); arlen→wraddr_fifo
WRDATA FSM: every beat drives m_axi R = {wrdata[7]..wrdata[0]} — SAME 32B replayed  (nvme_driver.sv:685-714)
  ▼  OcuLink Gen3 x4 → SSD media
SSD master-WRITES IO completion to IOCQ_BAR(0xA000); CPL FSM captures, B-responds (nvme_driver.sv:745-803)
  ▼  cpl_done=1 → CSR 0x5C → host busy-poll exits (csr.sv:122, driver_test.c:164)
```

### READ (SSD → host) — reverse, but **no data return to host**

```
HOST: nvme_addr/fpga_addr/nlb, pulse 0x48 (driver_test.c:167-172)
  ▼  iosq(READ) → DB doorbell → CMD FSM sends IO READ SQE (2×256b)
SSD master-WRITES read payload into FPGA (aw ≥ IORW_BAR): RD FSM captures into rd_data (256-bit reg)
  ▼  rd_data overwritten each beat — LAST BEAT WINS  (nvme_driver.sv:544)
RDRSP FSM B-responds; SSD posts CQE → CPL FSM → cpl_done
  ▼  rd_data wired ONLY to ILA probe29 (nvme_driver.sv:839) — host NEVER sees the data
```

### Buffer / width / clock inventory

| Buffer | Width × Depth | Total | Role | Clock | File:line |
|---|---|---|---|---|---|
| Host AXI-BRAM (CSR window) | 32-bit | 64 KiB mmap'd | MMIO CSR | host_bram_clk | `driver_test.c:29` |
| **`wrdata[7:0]`** | 256-bit reg | **32 B** | **only write payload** | both (unsync CDC) | `csr.sv:84-91`, `nvme_driver.sv:688-697` |
| `rd_data` | 256-bit reg | 32 B | read capture (last beat) | oculink_axi_clk | `nvme_driver.sv:522,544` |
| `cpl_data` | 256-bit reg | 32 B | completion capture | oculink_axi_clk | `nvme_driver.sv:774` |
| `iosq` FIFO | 97-bit × 1024 | ~12 KB | IO cmd descriptors | CDC 250→125 | `iosq.xci`, `:140-153` |
| `asq` FIFO | 1-bit × 1024 | 128 B | admin cmd flag | CDC 250→125 | `asq.xci`, `:168-181` |
| `wraddr_fifo` | 8-bit × 1024 | 1 KB | SSD's payload-fetch `arlen` | oculink_axi_clk | `wraddr_fifo.xci`, `:617` |
| `bramila`, `async_fifo_263_bit`, `sq`, `m_axi_*_fifo` | — | — | **dead IP, not instantiated** | — | IP dir only |

### MAX transfer size per command — today

- **Useful write payload: 32 bytes**, *full stop*. The FPGA sources one 256-bit register and replays it for every AXI beat the SSD fetches (`nvme_driver.sv:688-697`), so `nlb>0` writes garbage-repeated content. The SSD will burst as many beats as the SQE implies, but they all carry the same 32 B.
- **Read payload returned to host: 0 bytes** — `rd_data` goes only to the ILA.
- SQE caps it further: single PRP1 pointer (DW6), no PRP2, no PRP list (`nvme_driver.sv:416-447`). SW uses `nlb=0x3` → 4 LBAs × 512 B = 2 KiB *logical* transfer at the SSD, but the host neither supplies nor retrieves that much real data.

---

## 3. Control / command flow

Seven `always_ff` FSMs in `oculink_axi_clk`, coordinated by cross-FSM `*_done` handshakes. **Strictly one command in flight.**

| FSM | States | Role | File:line |
|---|---|---|---|
| **db_state** | IDLE→RING_IODBL/ADBL→SEND_IODATA/ADATA→WAIT_RESP→DONE | rings SSD doorbell (s_axi MMIO); IO prioritized over admin | `:185-313` |
| **cmd_state** | IDLE→POP_IOSQ/ASQ→RECV_ADDR→SEND_IOCMD1/2 / SEND_ACMD1/2→DONE | builds 64B SQE, serves 2×256b on m_axi R when SSD fetches | `:324-513` |
| **rd_state** | IDLE→RECV_DATA | captures SSD's read-payload write into `rd_data` | `:518-555` |
| **rdrsp_state** | →SEND_RESP | B-response for read-data write (gated by `!is_receving_cpl`) | `:560-593` |
| **wrdata_state** + cnt | IDLE→SEND_DATA→CHECK_NEXT | streams replayed `wrdata` to SSD on m_axi R | `:638-729` |
| **cpl_state** | IDLE→RECV_IOCPL/ACPL→RESP→DONE | captures 16B CQE; sets `cpl_done` | `:734-803` |

**End-to-end flow (CSR trigger → completion):**
1. Host writes params + pulses a `send_*_cmd` self-clearing CSR (`csr.sv:42-47, 77-80`).
2. CSR pushes a descriptor into `iosq` (IO) or `asq` (admin); CDC to 125 MHz.
3. `db_state` rings the SSD doorbell (s_axi AW+W+B = PCIe round-trip).
4. SSD master-reads the SQE; `cmd_state` fabricates it live (AR→R, 2 beats = another round-trip).
5. Data phase: SSD master-reads (write cmd) or master-writes (read cmd) payload.
6. SSD master-writes the CQE; `cpl_state` captures it and B-responds.
7. `cpl_done` set; host busy-polls CSR `0x5C` until it sees it (PCIe read round-trip).

**Serialization is by design and total:** `db_state` returns to IDLE only after `cmd_done` (`:305`); `cmd_state` only after `db_done` (`:505`); `cpl_state` re-arms only when the next entry is already queued (`:799`); and the host spins on `0x5C` after *every* command before issuing the next. The completion FSM **does not parse CQE status/phase** — any write landing in the CQ BAR sets `cpl_done`, so a failing command still "succeeds."

**The 4 CSR commands** (`csr.sv:77-80`): `send_iocq_create_cmd`(0x40)→asq→admin opcode 0x05; `send_iosq_create_cmd`(0x44)→asq→opcode 0x01; `send_read_cmd`(0x48)→iosq→0x02; `send_write_cmd`(0x4C)→iosq→0x01. IOCQ-before-IOSQ ordering is enforced only by SW call order, not hardware.

### Correctness landmines (independent of performance — flag to owner now)

1. **SLBA hardcoded to 0** (`nvme_driver.sv:443-444`). The CSR `nvme_addr` (0x50, commented "LBA") is routed to **DW6/PRP1**, not DW10/11. Every R/W hits **LBA 0**. *(Confirmed at lines 443-444.)*
2. **Doorbell tail never wraps** to queue depth — `iosqtdbl`/`asqtdbl` free-run from 1 (`:202-203,268,290`). Correctness breaks after `depth` commands.
3. **Write payload is one static 32 B register** — cannot write real multi-block data.
4. **Read data discarded** — no return path to host.
5. **CQE status never parsed** — no error reporting; failures look like success.
6. **`fpga_addr` is dead** — latched (`:383`), routed only to ILA; never used in any SQE field or AXI address.
7. **Unsynchronized multi-bit CDC** on `wrdata[7:0]`.

---

## 4. Performance analysis

### Theoretical ceilings per stage

| Stage | Raw | Usable (~128b/130b) | Notes |
|---|---|---|---|
| Host PCIe Gen3 x16 | 126 Gb/s | **≈15.75 GB/s** | far above everything; mostly unused (DMA dangling) |
| Host CSR (AXI-Lite 32b) | 1 word/transaction | **~tens of MB/s effective** | MMIO-bound, not a burst path |
| OcuLink AXI (256b @125 MHz) | — | **4.0 GB/s** | per direction |
| OcuLink PCIe Gen3 x4 | 31.5 Gb/s | **≈3.94 GB/s** | ≈ matches AXI; the would-be binding link |
| Samsung NVMe SSD | — | **~3.0-3.5 GB/s rd, ~2-3 GB/s wr** | device spec class |

The hardware is **well-balanced at ~3.9 GB/s** (OcuLink Gen3 x4 ≈ 256b×125 MHz AXI ≈ SSD seq). *Uncertainty:* exact SSD model/spec not confirmed in the analyses; if it is a Gen4 drive, the Gen3 x4 link leaves bandwidth on the table — but that is not today's bottleneck.

### Actual bottlenecks in *this* design (all architectural, they stack)

- **(a) Single outstanding command + fully-blocking FSM chain** (`:305, :505, :799`). NVMe's whole performance model (deep queues, many outstanding) is unused despite a 64-entry SSD queue.
- **(b) Software MMIO + busy-poll per command.** Write = 11 stores + spin-poll (`driver_test.c:152-164`); read = 4 stores + spin-poll. One MMIO round-trip ≈ 0.3-1 µs → **~3-10 µs SW overhead/command**.
- **(c) Per-command doorbell + SSD media round-trip** ≈ **10-50 µs** for tiny IO.
- **(d) 32 B of useful payload per command** (replayed register; read data not returned).
- **(e) No interrupts/MSI-X** — CPU spins on `0x5C`, can't overlap submit with execute.

### Rough current throughput estimate

Optimistic full round-trip ~15 µs/command (could be 30-50 µs):
- At **32 B useful/command → ~2 MB/s** (today's reality).
- Even crediting a full 2 KB block/command → **~130 MB/s**.

Versus the ~3.9 GB/s ceiling, this design runs at **~0.05%-3%** of capability. **100% of the lost throughput is in the control architecture**, not the link/AXI/SSD.

### Recipe to MEASURE real R/W MB/s on live HW (no RTL change required)

The loop already exists in `driver_test.c` — instrument and amplify it:

1. **Time a tight loop.** Wrap `send_write_command()`/`send_read_command()` in an N=10,000 loop with `clock_gettime(CLOCK_MONOTONIC)` around it. Compute `cmds_per_sec = N/elapsed`, `useful_BW = cmds_per_sec × 512×(nlb+1)`, and per-command latency `elapsed/N` (the dominant term).
2. **Sweep `nlb`** (CSR 0x58) from 3 up (0x7F, 0xFF, …). Plot BW vs `nlb`. If BW scales, per-command overhead is amortizable → motivates larger transfers. *(Caveat: today the SSD still does the full media transfer while the FPGA replays one word; this measures command-rate × block-size, the right metric for the refactor target.)*
3. **Separate SW from HW latency.** Re-enable the commented perf counter in `nvme_driver.sv:860-890` (`perf_cnt`, IDLE→completion), expose via a new CSR read. Host-measured time minus this = pure SW/MMIO overhead → tells you whether to attack SW (b) or HW (a/c) first.
4. **Measure raw MMIO cost.** Loop 100k `write_csr(scratch,0x00)` / `read_csr` and time → per-store/per-read cost in isolation, quantifying (b).

**Expected:** ~5-50 µs/command → 20k-200k cmd/s; at 2 KB blocks ~40-400 MB/s; at today's 32 B, single-digit MB/s. Raw MMIO store ≈ 0.2-1 µs.

---

## 5. Refactor plan

Two tracks. Each item: *what / where / impact / effort / risk class.*

### Track A — EASE OF USE

| # | What to change | Files/modules | Impact | Effort | Class |
|---|---|---|---|---|---|
| A1 | **Single source-of-truth register map** with named fields (SystemRDL/YAML → generated SV reg block **and** C header). Group logically; add `STATUS{link_up,ready,busy,err,err_code}`, `IRQ_STATUS` (W1C). Kill duplicated bare-hex offsets across HW/SW. | `csr.sv`, new `regs.rdl`, `driver_test.c` | Eliminates the implicit, undocumented SW↔HW contract; removes the `0x80000000\|0x4000+offset` precedence trap (`driver_test.c:82,86`) | M | **incremental** |
| A2 | **Completion interrupts (MSI-X)** instead of busy-poll. Drive `usr_irq_req` on `cpl_done`/error; host blocks on the XDMA event node. Add **timeouts + error/status** (today `driver_test.c:118,143` can hang forever). Parse the CQE status/phase bit. | `nvme_driver.sv` (cpl FSM `:745-803`), `kernel.sv`, `top.sv`, `driver_test.c` | Removes per-command poll stall; surfaces failures; enables overlap | M | **incremental** |
| A3 | **Thin host library.** Replace raw pokes with generated header + a small class: `nvme.write(chan,slba,nlb,buf)` / `nvme.read(...)` doing descriptor build + DMA + IRQ-wait internally. | `driver_test.c` → `libnvmehost` | Users stop needing SQE/BAR math by hand | S-M | **incremental** |
| A4 | **Descriptor/queue-based submission.** Command-descriptor ring in FPGA `{opcode,slba,nlb,buf_addr,tag}`; host bumps a producer doorbell; FPGA posts `{tag,status}` completions. | `csr.sv`, `nvme_driver.sv`, host lib | Removes strict poke-ordering and the 1-at-a-time host model; generalizes to multi-channel | L | **invasive** |
| A5 | **Parameterize for N channels.** `parameter int NUM_NVME`; wrap `csr/configurator/driver` (ideally the OcuLink BD) in `generate for` with per-channel CSR stride (`CHAN[n]` block). Replace literal `_0a` nets with indexed arrays. | `kernel.sv`, `top.sv`, `csr.sv`, BD | "Copy the kernel" → "bump a parameter" | L | **invasive** |
| A6 | **Module decomposition.** Split `nvme_driver.sv`'s 7 hand-rolled FSMs behind one top-level sequencer + clean submodules (doorbell, sqe-gen with a typed SQE struct, data-mover, completion). Lift magic SQE bodies/opcodes/addresses to named params. Delete dead code: `WR_*`/`WRADDR_*` localparams, redundant `wraddr_fifo` vs `wraddr_wrlen[]` tracker, `bramila`/`async_fifo_263_bit` IP. | `nvme_driver.sv` | Brittle 925-line monolith → maintainable; removes deadlock-prone handshakes | L | **invasive** |
| A7 | **Configurator hardening.** Add timeout + surface `bresp`/`rresp` to a `cfg_error` CSR (`nvme_configurator.sv:178,249` hang forever today). Replace incomplete hand-mux (`kernel.sv:135-145`, only AW/W muxed; AR double-driven, cfg `rready`/`bready` dangling at `:204,221`) with a proper 2-master AXI crossbar or full 5-channel mux + distinct AXI IDs. Byte-rotate read data by `araddr[4:2]` (`:250`). | `nvme_configurator.sv`, `kernel.sv` | Removes hang-forever paths and the cooperative-discipline-only arbitration hazard | M | **incremental** (timeout) / **invasive** (crossbar) |

### Track B — PERFORMANCE (ranked by impact)

| Rank | What to change | Files/modules | Expected impact | Effort | Class |
|---|---|---|---|---|---|
| **B1** | **Multiple outstanding commands + deep queue pipelining.** Remove `db_done/cmd_done/cpl_done` serialization (`:305,:505,:799`); track SQ tail / CQ head with credits; allow 32-64 in flight. Fix doorbell wrap (`:202-203`). | `nvme_driver.sv` | **10-50×** (NVMe scales ~linearly with QD at small IO) | M-L | **invasive** |
| **B2** | **Real host-DMA payload buffer.** Wire the dangling XDMA `M_AXI` (512b, 4×4 DMA) into a URAM/HBM-backed `axi_bram_ctrl`; NVMe write engine sources PRP from there; build the missing **read-return path** (`rd_data`→buffer→host C2H). Delete `wrdata[7:0]`. | `host_xdma_bd.bd`, `kernel.sv`, `nvme_driver.sv`, host lib | Removes 32 B cap + makes reads retrievable; up to host-link 15.7 GB/s feed | L | **invasive** |
| **B3** | **Completion interrupts (MSI-X)** = same as A2; enables B1 by stopping the CPU spin so submit overlaps execute. | (see A2) | Removes poll latency/CPU stall | M | **incremental** |
| **B4** | **Larger transfers / PRP lists.** Plumb a real `slba` into DW10/11 (fix `:443-444`); support PRP list / multi-page DPTR so one command moves 128 KB+, amortizing the ~10-50 µs fixed overhead. | `nvme_driver.sv` | Big BW gain when paired with B2 | M | **invasive** |
| **B5** | **Widen/clock-up OcuLink AXI** (512b or higher `oculink_axi_clk`, or Gen4 x4). | OcuLink BD, `nvme_driver.sv` | **Zero today** (4.0 GB/s AXI already matches Gen3 x4); only helps *after* B1-B4. **Do last.** | M-L | **invasive** |

**Ranking rationale (all four analyses agree):** the link/AXI/SSD are balanced at ~3.9 GB/s and are *not* the constraint. Fix the queueing/DMA/interrupt model first; touch the physical datapath last.

---

## 6. Recommended incremental roadmap

Ordered so each step independently builds + verifies on hardware (synth ~40 min → JTAG program → `make && sudo ./driver_test`). Quick high-value wins first; correctness fixes precede performance so you don't optimize a broken baseline.

**Phase 0 — Measure the baseline (no RTL change; ~1 day).**
Apply the §4 recipe: loop-time write/read, sweep `nlb`, re-enable the `perf_cnt` (`nvme_driver.sv:860-890`) behind a new CSR read, measure raw MMIO cost. *Verify:* you have real MB/s + per-command latency numbers and a SW-vs-HW split. This sets the yardstick for every later step.

**Phase 1 — Correctness fixes (small, low-risk; verify each on HW).**
1. **Plumb real SLBA** into DW10/11; route `nvme_addr` correctly (`:443-444,422`). *Verify:* write distinct data to LBA 100, read it back at LBA 100, confirm non-zero LBA works.
2. **Wrap doorbell tails** to queue depth (`:202-203,268,290`). *Verify:* run >64 commands in a loop without hang/corruption.
3. **Parse CQE status**; set an error CSR; add a configurator timeout (`nvme_configurator.sv:178,249`). *Verify:* inject a bad command, confirm error flag instead of false success / hang.

**Phase 2 — Read-data return path (high user value, moderate risk).**
4. Route `rd_data` back to a CSR-readable region (interim: a small BRAM the host reads via MMIO; later upgraded to DMA). *Verify:* write 32 B, read it back through the host and byte-compare.

**Phase 3 — Ease-of-use cleanup (incremental, user-facing).**
5. **Generated register map + named fields + host library** (A1, A3). *Verify:* existing test passes through the new named-field API; diff register behavior against Phase-0 baseline.
6. **MSI-X completion interrupts + timeouts** (A2/B3). *Verify:* completion latency drops vs busy-poll baseline; a stalled command times out instead of hanging.

**Phase 4 — First real throughput win (invasive, biggest payoff).**
7. **Multiple outstanding commands / queue pipelining** (B1). Build incrementally: first allow QD=2, re-measure; then QD=8, QD=32. *Verify after each:* §4 loop shows cmd/s and MB/s climbing; correctness loop (Phase 1.2) still clean.

**Phase 5 — Real data mover (invasive).**
8. **Connect XDMA M_AXI → fabric buffer; PRP-source from it; delete `wrdata[7:0]`** (B2). *Verify:* host H2C-DMAs a multi-KB pattern, SSD-write, SSD-read back via C2H, byte-compare; re-measure MB/s.
9. **PRP lists / large transfers** (B4). *Verify:* sweep transfer size to 128 KB+, confirm BW approaches the ~3.9 GB/s ceiling.

**Phase 6 — Structural & scaling (invasive, do once the above is stable).**
10. **Decompose `nvme_driver.sv`** behind a sequencer + typed SQE struct; delete dead IP/code; replace the configurator hand-mux with a crossbar (A6/A7).
11. **Parameterize for N channels** (A5) and descriptor-ring submission (A4).
12. **Only now:** widen/clock-up OcuLink AXI (B5) if measurements show the link is the new ceiling.

**Why this order:** Phases 0-2 are days of low-risk work that fix real correctness bugs and immediately make the device usable (readable data, named API), keeping the owner in the loop with HW-verified increments. Phase 4 (B1) is the single biggest performance multiplier and is achievable before the invasive datapath rebuild. Phase 5 (B2) unlocks the link ceiling. Physical-datapath widening (B5) is deliberately last because it buys nothing until the control architecture is fixed.

---

### Notes & uncertainties
- **Resolved:** host AXI-Lite clock is **250 MHz** (per `.xci`), not 125 MHz as one analysis stated. No effect on conclusions (CSR path is MMIO-bound).
- **Consistent across all four analyses:** single-outstanding/serialized FSM model, 32 B replayed write payload, dangling XDMA `M_AXI`, dead `bramila`/`async_fifo_263_bit`/`sq` IP, SLBA=0, no read-return path, single `_0a` channel.
- **Unverified by the analyses:** exact Samsung SSD model and its Gen generation — confirm before deciding whether B5 (Gen4) is worthwhile.
- **Key files:** `/home/junsik/workspace/NVMe/hw/RTL/fpga-nvme-driver/{nvme_driver.sv,csr.sv,kernel.sv,top.sv,nvme_configurator.sv}`, `/home/junsik/workspace/NVMe/hw/BD/{host_xdma_bd,oculink_0a_bd}/`, `/home/junsik/workspace/NVMe/sw/nvme_driver_test/sw/driver_test.c`.