# FPGA NVMe Hardware Driver

An **FPGA-resident NVMe host controller**: the FPGA (Bittware/Nallatech 250-SoC, Xilinx `xczu19eg`
Zynq UltraScale+) is the NVMe **host/root**, driving a real NVMe SSD over **OcuLink (PCIe Gen3 x4)**.
A host PC only pokes control registers over its own PCIe BAR; all NVMe queue logic lives in the PL.

- **Target HW**: 250-SoC card; SSD = Samsung 980 PRO / PM9A1 (`144D:A808`, Gen4 x4 drive, link negotiates Gen3 x4).
- **Tooling**: Vivado 2024.2 (project opens from 2021.2 with auto-upgrade).
- **Sustained bandwidth** (QD=1, beat-counter validated): **READ 2.4–2.84 GB/s, WRITE 2.4–2.43 GB/s** — SSD-bound (see §5).

```
NVMe/
├── hw/
│   ├── RTL/fpga-nvme-driver/   core RTL (nvme_driver.sv, csr.sv, kernel.sv, top.sv, tagfifo.sv, …) + sim/
│   ├── BD/                     block designs: host_xdma_bd (host PCIe) + oculink_0a_bd (SSD PCIe root + GTH)
│   ├── CONSTRAINTS/            fpga-nvme-driver.xdc
│   ├── SYNTH/fpga-nvme-driver/ Vivado project (.xpr + .srcs)  [.runs/.cache/.gen are build output, gitignored]
│   └── scripts/gen_project.tcl
└── sw/nvme_driver_test/        host control tools (driver_test.c, nvme_bw_bench.c, nvme_qd_diag.c, …)
```

---

## 1. Architecture — "inverted queue" NVMe host

Normal NVMe: the host keeps SQ/CQ in DRAM and the SSD reads/writes them. Here the FPGA has **no DRAM
queues** — it **reacts** to the SSD's OcuLink memory accesses in real time:

| SSD action on OcuLink `m_axi` | FPGA (`nvme_driver`) response | block |
|---|---|---|
| reads the SQ (fetch a command) `AR` | **synthesises** the SQE on the fly from CSR values, returns it on `R` | `cmd` FSM |
| reads write-payload `AR` | serves the `wrdata` pattern on `R` | `wrdata` FSM |
| reads the PRP-list `AR` (>2-page xfer) | generates page addresses on `R` | `listgen` FSM |
| writes read-payload `AW+W` | captures + counts every beat | W-acceptor |
| writes a CQE `AW+W` | captures, `cpl_count++`, advances CQ-head | W-acceptor |
| — FPGA → SSD on `s_axi` | rings doorbells (SQ-tail, CQ-head) | `db` FSM |

Two AXI interfaces on OcuLink: **`m_axi`** (SSD = master, FPGA = slave) and **`s_axi`** (FPGA = master,
SSD = slave, for doorbells). Two clock domains: **`host_bram_clk` 250 MHz** (host/CSR side) and
**`oculink_axi_clk` 125 MHz** (SSD side); the `iosq`/`asq` FIFOs cross between them.

### Module hierarchy
```
top.sv
├── host_xdma_bd          host PCIe/XDMA → CSR BAR (resource0)
├── oculink_0a_bd         SSD-side PCIe root + GTH x4 (m_axi / s_axi)
└── kernel.sv
    ├── csr.sv            register file (host BAR ↔ registers)
    ├── nvme_configurator.sv   config-access executor (one PCIe config/mem TLP per request)
    ├── nvme_bringup.sv   autonomous bring-up sequencer (drives the configurator + admin path)
    └── nvme_driver.sv    ← the controller (cmd / wrdata / listgen / W-acceptor / db FSMs + tag FIFOs)
```

### Data flows
```
WRITE (host→SSD): CSR(nvme_addr,SLBA,nlb,trig 0x4C)→iosq → db rings SQ-tail
  → SSD AR(SQ): cmd FSM synthesises write SQE → SSD AR(data): wrdata FSM serves (r_data_beats++)
  → SSD AW+W(CQE): W-acceptor (cpl_count++) → db rings CQ-head
READ  (SSD→host): same SQE synth (incl. PRP1/PRP2) → SSD AW+W(read data): W-acceptor (w_data_beats++)
  → (if >2 pages: SSD AR(PRP-list): listgen serves page addrs) → SSD AW+W(CQE) → CQ-head
```

### Address map (what the SSD sees in the FPGA BAR window)
```
0x8000 ASQ   0x9000 ACQ   0xA000 IOCQ   0xB000 IOSQ   0xC000 IORW(data, DENSE: page k = 0xC000+(k-1)*0x1000)
page2 = 0xD000 direct (2-page) ; >2 pages: PRP2 = PRP-list @ 0x4C000 (held high, above the 128 KB data window)
NVMe ctrl regs @ 0x8000_4000 ; doorbells: SQ-tail +0x1008, CQ-head +0x100C
```
Data pages are **contiguous** from 0xC000 so the host fills one flat buffer; the PRP-list page sits above the
data window so it consumes no data-offset slot.

### CSR map (host BAR, `csr.sv`)
| off | write | read |
|---|---|---|
| 0x04 | sw_reset | — |
| 0x08 / 0x0C | bring-up start (kick HW sequencer) | bring-up status: bit0=ready, bit1=busy |
| 0x10/0x14/0x18 · 0x1C | cfg-write trig / wraddr / wrdata · wr_done | SSD/root PCIe config access |
| 0x20/0x24 · 0x28/0x2C | cfg-read trig / rdaddr · rddata / rd_done | (use `(1<<20)\|off` = SSD endpoint) |
| 0x30 | cfg_done / bridge enable | cfg_done |
| 0x40 / 0x44 | IOCQ create / IOSQ create | — |
| 0x48 / 0x4C | read trig / write trig | — |
| 0x50 / 0x54 / 0x58 | nvme_addr(PRP1) / fpga_addr(SLBA) / nlb | same |
| 0x5C / 0x60 / 0x64 | — | cpl_done / cpl_status / cpl_count |
| 0x68 / 0x6C | — | r_data_beats / w_data_beats (×32 B, real bytes moved) |
| 0x70 / 0x74 | — | raw_w_beats / raw_w_bursts (DIAG: SSD-sent vs FPGA-dropped) |
| 0x100–0x11C | wrdata[0..7] (legacy 32 B pattern) | same |
| 0x40000–0x5FFFF | wbuf: host writes the real write-payload (**128 KB**) | — |
| 0x60000–0x7FFFF | — | rbuf: host reads the captured read-payload (**128 KB**) |

Host BAR window is **1 MB** (`host_bram_addr[19:0]`): `[19:17]`=000 CSR, 010 wbuf (0x40000), 011 rbuf (0x60000).

---

## 2. Refactor history (MO-4 … MO-9)

The original driver was single-outstanding, 32 B/command, hardcoded LBA 0. The current design:

- **Phase 1/2** — real SLBA via CSR 0x54, CQE status read-back (0x60), SQ-tail wrap.
- **MO-4 — R/W in-order demux.** Replaced the `is_sending_cmd`/`is_receving_cpl` producer-state muxes with
  `tagfifo.sv` (FWFT) tag FIFOs: each accepted `AR`/`AW` pushes a 1-class tag; the mux serves the oldest
  outstanding (the only legal single-ID schedule). Fixed the QD≥4 hang.
- **MO-5 — unified W-channel acceptor.** One W-stream-driven capture (`wtagmem` + `w_awp`/`w_capp`/`w_bp`
  pointers) for read-payload **and** CQEs → never drops back-to-back CQEs.
- **MO-7 — PRP2 + PRP-list walker.** `DW8` set per size (0 / 0xE000 direct / 0xD000 list); `listgen` serves
  list pages → transfers >2 pages (large blocks → multi-GB/s).
- **MO-8 — write-payload R-serve back-to-back.** `tagfifo` 2-deep peek (`head2`/`cnt`) lets the `wrdata` FSM
  chain bursts with 0 inter-burst bubble, and it crosses a burst boundary only after the `rlast` beat is
  accepted (`rready`) → robust to stalls. (Bubble 20%→0% in sim; HW write unchanged ⇒ SSD-paced, not FPGA.)
- **MO-9 — decouple SQE submission from the doorbell-B rendezvous.** Removed the `cmd_done↔db_done` mutual
  wait so the cmd FSM keeps many SQEs in flight (SQ-tail coalesces to the latest `io_serve_cnt`).
- **DIAG counters** (CSR 0x70/0x74) — count *every* accepted W beat, to separate "FPGA dropped" from
  "SSD sent less" (used to root-cause the QD>1 behaviour in §5).
- **Autonomous bring-up (`nvme_bringup.sv`).** Originally the host ran the whole ~20-step bring-up by hand
  (PCIe enumerate → MPS/MRRS=256 → CC.EN/CSTS → AQA/ASQ/ACQ → IOCQ/IOSQ create). Now a HW microcode sequencer
  replays that exact sequence on a single CSR 0x08 trigger; the host just waits for 0x0C bit0 (ready) and then
  issues reads/writes. `nvme_configurator` stays the per-TLP executor; the sequencer drives it and the admin
  path (muxed against the host CSR while it runs) and forces cfg_done=1 once ready. Verified on HW from a
  freshly-programmed card (`nvme_autobringup`): host issues only the trigger + R/W, FPGA builds the queues.
- **Real host data path (`wbuf`/`rbuf`), Stage A → B.** Replaced the 32 B `wrdata` replay with real host-data
  buffers in `nvme_driver`. **Stage B (HW-verified, `nvme_dmatest` 4/32/128 KB all 0-mismatch):** each buffer is
  **256 b × 4096 = 128 KB on-chip SRAM** (`dpram_be.sv`, block-RAM with a `"ultra"` URAM drop-in), reached through
  the **1 MB host BAR window** (wbuf 0x40000, rbuf 0x60000). Because the RAM has read latency, the write-payload
  server **prefetches** behind a small output FIFO (credit-throttled) instead of a 0-latency combinational read —
  the same shape the DRAM stage will need. **Dense PRP** makes the data pages contiguous so the host fills one flat
  buffer. Two bugs the scale-up exposed and fixed: (1) the host BAR decode now gates CSR off the data regions (a
  0x40008 write used to alias to `bringup_start`); (2) the **PRP-list generator** re-served entry 0 on every list
  read chunk (a per-burst beat counter) → real data truncated at ~page 11; it now captures each list AR's address
  offset in a FIFO and serves from there, robust to however the SSD chunks its list reads. Sim `tb_datapath.sv`
  T1–T6 (latency FSM, 8 KB burst, dense page-2 offset, PRP-list at offsets 0/8) all pass.
- **DRAM data path (Stage final, HW-verified).** Real host data now genuinely transits the board's **4 GB PL
  DDR4** both ways: WRITE `host -> wbuf SRAM -> (copy engine) -> DDR4 -> wbuf2 SRAM -> SSD -> NAND`, READ the
  reverse into `rbuf2`. `nvme_dmatest` 4/32/128 KB all 0-mismatch. The `ddr4_0` MIG IP (4 GB DDR4-2400, 72-bit
  ECC, J19 300 MHz ref) is driven by `ddr4_engine.sv` (a ui_clk DDR4 AXI master, AW+W presented concurrently
  because the DDR4 AXI gates `wready` on a pending `awvalid`) via `copy_engine.sv` (SRAM↔DDR4↔SRAM, ≤256-beat
  bursts). The four staging SRAMs are dual-clock, so **all DDR4 access is one clock (ui_clk) and the SRAMs absorb
  the host/oculink crossing — no explicit AXI CDC**. CSR 0x84 triggers a copy (bit0 0=write 1=read), 0x88=words,
  0x80 read bit1=cal_done bit0=busy. (Per-command transfer is SRAM-window-limited to 128 KB; streaming a larger
  window over the 4 GB is the next step.)

Sim (`hw/RTL/fpga-nvme-driver/sim/`): `tb_cpl_stress.sv` (RDBURST/RDSTALL/RDCQE — write-serve bubble + stall +
W-acceptor), `tb_nvme_driver.sv` + `ssd_model.sv` (70 writes / 8 reads + BEATCOUNT), `tb_nvme_qd.sv` +
`ssd_model_pipe.sv` (pipelined QD>1). Run: `xvlog -sv tagfifo.sv sim/sim_fifo.sv sim/ila_0_stub.sv
nvme_driver.sv sim/<tb>.sv && xelab <tb> -s s && xsim s -R`.

---

## 3. Build · program · verify

```bash
# build (Vivado 2024.2; opens 2021.2 project with auto-upgrade)
setsid <vivado>/bin/vivado -mode batch -source build.tcl &     # synth + impl + write_bitstream
# program over JTAG (FT232H): unload ftdi_sio, run hw_server as root
sudo modprobe -r ftdi_sio usbserial ; sudo setsid <vivado>/bin/hw_server -d
sudo <vivado>/bin/vivado -mode batch -source prog.tcl          # -> impl_1/top.bit
# after JTAG load the PCIe BAR reads 0xFFFFFFFF -> re-enumerate:
echo 1 | sudo tee /sys/bus/pci/devices/0000:18:00.0/remove ; echo 1 | sudo tee /sys/bus/pci/rescan
# run host tools (mmap resource0 directly; no xdma driver needed)
cd sw/nvme_driver_test/sw && gcc -O2 -o nvme_bw_bench nvme_bw_bench.c
sudo ./nvme_bw_bench /sys/bus/pci/devices/0000:18:00.0/resource0 wr 1 256 256 0
```
Note: `read_csr` in `driver_test.c` must be `volatile` (else `-O2` polling loops hang). The design needs
BAR0=1 MB(user)+BAR1=64 KB(config); boot-time bridge window is 1 MB so `xdma` probe fails — the tools bypass
it by mmap'ing `…/resource0`. For `xdma` to bind, boot with `pci=realloc`.

---

## 4. Host tools (`sw/nvme_driver_test/sw/`, build with `gcc -O2`)
- `nvme_dmatest.c` — real host-data round-trip at scale: fills wbuf (0x40000) with a pattern, WRITE then READ
  the same LBA, reads rbuf (0x60000), checks the data round-tripped. Verified 4 KB / 32 KB / **128 KB** (0 mismatch).
  `nvme_dma128diag.c` (per-page status + beat counters) / `nvme_off.c` (single-page round-trip at any page offset)
  are the localizers used to root-cause the PRP-list truncation.
- `nvme_autobringup.c` — exercises the autonomous HW bring-up: pulses sw_reset, writes CSR 0x08, polls 0x0C
  ready, then does a R/W — no manual config sequence at all.
- `driver_test.c` — end-to-end (manual) bringup + single R/W + data-pattern check.
- `nvme_bw_bench.c` — bandwidth vs transfer size / QD. **REALMB/s (beat counter) is the honest number**;
  cmplMB/s over-reports at QD>1 (SSD coalesce). Args: `<resource0> r|w|wr <QD> <mps> <mrrs> <distinct>`.
- `nvme_qd_diag.c` — single-batch QD raw-counter probe (cpl/w_data_beats/raw_w_beats). `SPACEDUS=<us>` env.
- `nvme_pcie_cfg.c` / `nvme_rootmps.c` — SSD / root-port PCIe MPS·MRRS. `nvme_linkspeed.c` — link gen/width.

---

## 5. Bandwidth: how far it goes, and why (the wall is the SSD)

The FPGA datapath is **already at line rate** — a multi-agent audit + the raw W-beat counters confirm:
`arready/awready/wready` tied 1, rtag/wtag 256-deep, B is 1 cycle after `wlast` (1 B/cycle), write-payload
served bubble-free (MO-8). No datapath edit can push further.

**Ceilings**: physical link Gen3 x4 = **3.94 GB/s**; with the SSD's **256 B MaxPayload HW cap** the PCIe TLP
efficiency ceiling is **~3.58 GB/s**. Achieved QD=1: read 2.4–2.84 (66–79% of ceiling), write 2.4–2.43.

**QD>1 gives no bandwidth here.** Raw counters prove it is **SSD-side**: at QD>1 the SSD posts all QD CQEs
(`cpl_count` correct) but physically transfers only **one command's** read-payload (`raw_w_beats` = one
command + QD CQE beats), independent of distinct buffers / data / size / PRP-list. Any *overlap* of two reads
→ the SSD coalesces to half; fully *serialised* submission → full data. (`nvme_qd_diag SPACEDUS=…` shows this.)

**80% of link (3.15 GB/s) is not reachable on this SSD/board.** It is gated by (a) the FPGA PCIe being Gen3
(US+ integrated block max; the SSD itself is Gen4-capable) and (b) the 256 B MPS + the SSD's serial-streaming /
concurrent-read-coalesce behaviour. A Gen4-capable PCIe path (Versal-class) would roughly double the ceiling.

Real host data moves end to end — **HW-verified up to 128 KB** (4/32/128 KB, 0 mismatch) — first through 128 KB
on-chip SRAM (Stage B) and now **through the board's 4 GB PL DDR4** (Stage final, §2): the full A → B → DRAM
roadmap is complete. Open / future: stream a >128 KB SRAM window over the 4 GB DDR4 for a single large transfer;
and an ILA trace to confirm the QD>1 coalesce is SSD-inherent vs command-pattern-triggered.
