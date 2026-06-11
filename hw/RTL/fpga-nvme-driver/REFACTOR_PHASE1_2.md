# RTL Refactor — Phase 1 (correctness) + Phase 2 (read return)

Status: **implemented, synthesized (timing met, WNS +0.163ns), JTAG-programmed, verified on real hardware (Samsung NVMe SSD).** 2026-06-10.

See `ARCHITECTURE_ANALYSIS.md` for the full architecture analysis and the multi-phase roadmap this is the first step of.

## What changed (RTL)

| Change | File | Detail |
|---|---|---|
| **Real SLBA** (was hardcoded LBA 0) | `nvme_driver.sv` | The dead `fpga_addr` (CSR **0x54**) is now routed into the IO command **SQE DW10 (SLBA)**. Previously every read/write hit LBA 0. |
| **SQ tail doorbell wrap** + depth 64 | `nvme_driver.sv` | `iosqtdbl`/`asqtdbl` now wrap modulo queue depth (64); IO queue-create `QSIZE` set to 63 (depth 64). Previously the tail free-ran and the device stalled after ~16 commands. |
| **CQE status exposed** | `nvme_driver.sv`, `kernel.sv`, `csr.sv` | Completion CQE DW3 (status/phase/cid) is captured and readable at CSR **0x60**. Previously any CQ write looked like success. |
| **Read-data return path** | `nvme_driver.sv`, `kernel.sv`, `csr.sv` | `rd_data` (last 32 B of the read payload) is exposed at CSR **0x200–0x21C** (8×32-bit). Previously read data went only to an ILA probe — the host never saw it. |
| Cleanup | `nvme_driver.sv` | Moved `cmd_done` declaration before first use (was a forward reference; now passes `xvlog`). |

## New / changed CSR offsets (software contract)
| Offset | Dir | Meaning |
|---|---|---|
| 0x50 | W | PRP / FPGA data-buffer address (= IORW_BAR region, e.g. 0xC000) |
| **0x54** | W | **SLBA — start LBA** (repurposed; was the dead "fpga_addr") |
| 0x58 | W | NLB (number of logical blocks − 1) |
| 0x100–0x11C | W | write data (8×32-bit = 32 B, replayed for every beat) |
| **0x60** | R | **last completion CQE DW3** (success if bits [31:17] == 0) |
| **0x200–0x21C** | R | **read-back data** (valid after cpl_done @0x5C) |

## Hardware verification (`sw/nvme_driver_test/sw/nvme_hw_verify.c`)
```
TEST 1: SLBA + read-back + integrity
  WRITE PA -> LBA 100 ; WRITE PB -> LBA 200
  READ  LBA 100 -> AA000001..AA000008  == PA OK
  READ  LBA 200 -> BB0000F1..BB0000F8  == PB OK
  RE-READ LBA100 still PA (distinct from LBA200): YES
  >> PASS  (distinct LBAs + correct data round-trip — impossible before this refactor)
TEST 2: completion status (0x60) == 0 => success
TEST 3: sustained back-to-back writes: 58 completed (was ~16)
```
`driver_test.c` also now prints the read-back (writes A1..A8, reads back A1111111..A8888888) and the completion status.

## Known limitation / next step
Sustained operation now reaches ~58–64 commands (up from ~16) but still stalls there, because the FPGA
never rings the **CQ-head doorbell** to free completion-queue slots. Adding the CQ-head ring (in the
`db_state`/`cpl_state` FSMs) gives unlimited sustained operation — this is the next, more invasive batch,
deliberately separated to keep this correctness batch low-risk. After that: ease-of-use API + interrupts
(Phase 3), then the big throughput work — multiple outstanding commands and the real host-DMA datapath
(Phase 4–5). Current effective throughput is still ~MB/s vs the ~3.9 GB/s hardware ceiling; see ARCHITECTURE_ANALYSIS.md §4–6.
