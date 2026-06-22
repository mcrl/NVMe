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
0x8000 ASQ   0x9000 ACQ   0xA000 IOCQ   0xB000 IOSQ   0xC000 IORW(data)   0xD000 PRP-list   0xE000 page2
NVMe ctrl regs @ 0x8000_4000 ; doorbells: SQ-tail +0x1008, CQ-head +0x100C
```

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
| 0x100–0x11C | wrdata[0..7] | same |

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

Open / future: an ILA trace to confirm the QD>1 coalesce is SSD-inherent vs command-pattern-triggered; and a
real host-DMA datapath (today only a 32 B pattern is replayed to fill blocks, not real host payload).
