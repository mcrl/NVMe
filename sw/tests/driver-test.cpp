#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>
#include <vector>
#include "nvme_spec.h"

const size_t NVME_BAR0 = 0x80000000;

const size_t ADBUF_ADDR = 0x00c00000;
const size_t ADMIN_SQ_ADDR = ADBUF_ADDR;
static_assert(ADMIN_SQ_ADDR % 4096 == 0, "Incorrect alignment");
const size_t ADMIN_SQ_DEPTH = 64;
static_assert(ADMIN_SQ_DEPTH * 64 <= 4096, "Incorrect size");
const size_t ADMIN_CQ_ADDR = ADMIN_SQ_ADDR + 4096;
static_assert(ADMIN_CQ_ADDR % 4096 == 0, "Incorrect alignment");
const size_t ADMIN_CQ_DEPTH = 64;
static_assert(ADMIN_CQ_DEPTH * 16 <= 4096, "Incorrect size");
const size_t ADBUF_DPTR = ADMIN_CQ_ADDR + 4096;
static_assert(ADBUF_DPTR % 4096 == 0, "Incorrect alignment");
const size_t IO_SQ_ADDR = ADBUF_DPTR + 4096;
static_assert(IO_SQ_ADDR % 4096 == 0, "Incorrect alignment");
const size_t IO_SQ_DEPTH = 64;
static_assert(IO_SQ_DEPTH * 64 <= 4096, "Incorrect size");
const size_t IO_CQ_ADDR = IO_SQ_ADDR + 4096;
static_assert(IO_CQ_ADDR % 4096 == 0, "Incorrect alignment");
const size_t IO_CQ_DEPTH = 64;
static_assert(IO_CQ_DEPTH * 16 <= 4096, "Incorrect size");

const size_t WRSQ_ADDR = 0x00000000;
const size_t WRBUF_ADDR = 0x00200000;
const size_t WRCQ_ADDR = 0x00400000;
const size_t RDSQ_ADDR = 0x00600000;
const size_t RDCQ_ADDR = 0x00a00000;
const size_t OUTSTANDING = 16;


class SnuFPGA {
public:
  SnuFPGA(int devnum, int bus);
  ~SnuFPGA();
  void Reset();
  void WritePCIeConfig(int bus, int dev, int func, size_t offset, uint32_t data);
  uint32_t ReadPCIeConfig(int bus, int dev, int func, size_t offset);
  void WriteNVMe(size_t offset, uint32_t data);
  uint32_t ReadNVMe(size_t offset);
  void WriteMemory(size_t offset, uint32_t data);
  uint32_t ReadMemory(size_t offset);
  void WriteUser(size_t offset, uint32_t data);
  uint32_t ReadUser(size_t offset);
  void Memset(size_t offset, uint32_t data, size_t n);
  void MemcpyH2D(size_t dst, const void* src, size_t n);
  void MemcpyD2H(void* dst, size_t src, size_t n);
  void InitNVMe();
  void CheckError();
  void PrintPCIeConfigSpaceHeader(int bus, int dev, int func);
  void BuildAdminCommandIdentify(NVMeSQEntry &sqe, int cns);
  void BuildAdminCommandSetFeaturesNumberOfQueues(NVMeSQEntry &sqe, int nsid, int nsqr, int ncqr);
  void BuildAdminCommandCreateCQ(NVMeSQEntry &sqe, size_t addr, int qid, int qsize);
  void BuildAdminCommandCreateSQ(NVMeSQEntry &sqe, size_t addr, int qid, int qsize, int cqid);
  void BuildAdminCommandGetLogPage(NVMeSQEntry &sqe);
  void BuildIOCommandWrite(NVMeSQEntry &sqe, size_t addr, size_t slba, uint16_t nlb);
  void EnqueueAdminSQ(NVMeSQEntry &sqe);
  void DequeueAdminCQ(NVMeCQEntry &cqe);
  void EnqueueIOSQ(NVMeSQEntry &sqe);
  void DoorbellIOSQ();
  void DequeueIOCQ(NVMeCQEntry &cqe);
  void DoorbellIOCQ();
  void SetKernelArgument(size_t start_addr, size_t end_addr, uint32_t benchmode);
  void LaunchKernel();
  void TestWrite();
private:
  int devnum_;
  int bus_;

  int fd_bypass_;
  void* vaddr_bypass_;
  size_t mmio_sz_bypass_;

  int fd_user_;
  void* vaddr_user_;
  size_t mmio_sz_user_;

  // Admin
  int sq0t;
  int cq0h;
  int cq0phase;

  // IO
  int sq1t;
  int cq1h;
  int cq1phase;
};

SnuFPGA::SnuFPGA(int devnum, int bus) : devnum_(devnum), bus_(bus) {
  char devname[64];

  snprintf(devname, sizeof(devname), "/dev/xdma%d_bypass", devnum);
	if ((fd_bypass_ = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} open failed: {}.", devname, strerror(errno));
    exit(0);
	}
	spdlog::info("character device {} opened. fd={}", devname, fd_bypass_);

  mmio_sz_bypass_ = 64UL * 1024 * 1024 * 1024; // 64GB
	vaddr_bypass_ = mmap(NULL, mmio_sz_bypass_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_bypass_, 0);
	if (vaddr_bypass_ == (void *)-1) {
    spdlog::info("mmap failed: {}", strerror(errno));
    close(fd_bypass_);
    exit(0);
	}
  spdlog::info("mmap done. vaddr={}, sz={}", vaddr_bypass_, mmio_sz_bypass_);

  snprintf(devname, sizeof(devname), "/dev/xdma%d_user", devnum);
	if ((fd_user_ = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} open failed: {}.", devname, strerror(errno));
    exit(0);
	}
	spdlog::info("character device {} opened. fd={}", devname, fd_user_);

  mmio_sz_user_ = 2UL * 1024 * 1024; // 2MB
	vaddr_user_ = mmap(NULL, mmio_sz_user_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_user_, 0);
	if (vaddr_user_ == (void *)-1) {
    spdlog::info("mmap failed: {}", strerror(errno));
    close(fd_user_);
    exit(0);
	}
  spdlog::info("mmap done. vaddr={}, sz={}", vaddr_user_, mmio_sz_user_);

  sq0t = cq0h = cq0phase = 0;
}

SnuFPGA::~SnuFPGA() {
  munmap(vaddr_bypass_, mmio_sz_bypass_);
  close(fd_bypass_);
}

void SnuFPGA::Reset() {
  char pcie_rst_name[64];
  snprintf(pcie_rst_name, sizeof(pcie_rst_name), "/sys/bus/pci/devices/0000:%02x:00.0/reset", bus_);
  FILE* f = fopen(pcie_rst_name, "w");
  if (f == NULL) {
    spdlog::info("sysfs pcie reset node {} opened failed: {}.", pcie_rst_name, strerror(errno));
    exit(0);
  }
  fprintf(f, "1\n");
  fclose(f);
  spdlog::info("reset done. ({})", pcie_rst_name);
}

static size_t ECAMAddress(int bus, int dev, int func) {
  return (bus << 20) | (dev << 15) | (func << 12);
}

void SnuFPGA::WritePCIeConfig(int bus, int dev, int func, size_t offset, uint32_t data) {
  *(volatile uint32_t*)((size_t)vaddr_bypass_ + 0x200000000 + ECAMAddress(bus, dev, func) + offset) = data;
}

uint32_t SnuFPGA::ReadPCIeConfig(int bus, int dev, int func, size_t offset) {
  return *(volatile uint32_t*)((size_t)vaddr_bypass_ + 0x200000000 + ECAMAddress(bus, dev, func) + offset);
}

void SnuFPGA::WriteNVMe(size_t offset, uint32_t data) {
  *(volatile uint32_t*)((size_t)vaddr_bypass_ + 0x300000000 + NVME_BAR0 + offset) = data;
}

uint32_t SnuFPGA::ReadNVMe(size_t offset) {
  return *(volatile uint32_t*)((size_t)vaddr_bypass_ + 0x300000000 + NVME_BAR0 + offset);
}

void SnuFPGA::WriteMemory(size_t offset, uint32_t data) {
  *(volatile uint32_t*)((size_t)vaddr_bypass_ + offset) = data;
}

uint32_t SnuFPGA::ReadMemory(size_t offset) {
  return *(volatile uint32_t*)((size_t)vaddr_bypass_ + offset);
}

void SnuFPGA::WriteUser(size_t offset, uint32_t data) {
  *(volatile uint32_t*)((size_t)vaddr_user_ + offset) = data;
}

uint32_t SnuFPGA::ReadUser(size_t offset) {
  return *(volatile uint32_t*)((size_t)vaddr_user_ + offset);
}

void SnuFPGA::Memset(size_t offset, uint32_t data, size_t n) {
  for (size_t i = 0; i < n; i += 4) {
    *(volatile uint32_t*)((size_t)vaddr_bypass_ + offset + i) = data;
  }
}

void SnuFPGA::MemcpyH2D(size_t dst, const void* src, size_t n) {
  for (size_t i = 0; i < n; i += 4) {
    *(volatile uint32_t*)((size_t)vaddr_bypass_ + dst + i) = *(uint32_t*)((size_t)src + i);
  }
}

void SnuFPGA::MemcpyD2H(void* dst, size_t src, size_t n) {
  for (size_t i = 0; i < n; i += 4) {
    *(uint32_t*)((size_t)dst + i) = *(volatile uint32_t*)((size_t)vaddr_bypass_ + src + i);
  }
}

void SnuFPGA::PrintPCIeConfigSpaceHeader(int bus, int dev, int func) {
  spdlog::info("PCI Config Space Header of {:02X}:{:02X}.{:01X}", bus, dev, func);
  for (int i = 0; i < 0x40; i += 4) {
    spdlog::info("{:02X} {:08X}", i, ReadPCIeConfig(bus, dev, func, i));
  }
}

void SnuFPGA::BuildAdminCommandIdentify(NVMeSQEntry &sqe, int cns) {
  sqe.opc = 0x06;
  sqe.fuse = 0;
  sqe.psdt = 0;
  sqe.nsid = 0;
  sqe.mptr = 0;
  sqe.dptr.prp.prp1 = ADBUF_DPTR;
  sqe.dptr.prp.prp2 = 0;
  sqe.cdw10_bits.identify.cns = cns;
  sqe.cdw10_bits.identify.cntid = 0;
  sqe.cdw11 = 0;
  sqe.cdw12 = 0;
  sqe.cdw13 = 0;
  sqe.cdw14 = 0;
  sqe.cdw15 = 0;
}

void SnuFPGA::BuildAdminCommandSetFeaturesNumberOfQueues(NVMeSQEntry &sqe, int nsid, int nsqr, int ncqr) {
  sqe.opc = 0x09;
  sqe.fuse = 0;
  sqe.psdt = 0;
  sqe.nsid = 0;
  sqe.mptr = 0;
  sqe.dptr.prp.prp1 = 0;
  sqe.dptr.prp.prp2 = 0;
  sqe.cdw10_bits.set_features.fid = 0x07;
  sqe.cdw10_bits.set_features.sv = 0;
  sqe.cdw11_bits.feat_num_of_queues.bits.nsqr = nsqr - 1; // 0-base
  sqe.cdw11_bits.feat_num_of_queues.bits.ncqr = ncqr - 1; // 0-base
  sqe.cdw12 = 0;
  sqe.cdw13 = 0;
  sqe.cdw14 = 0;
  sqe.cdw15 = 0;
}

void SnuFPGA::BuildAdminCommandCreateCQ(NVMeSQEntry &sqe, size_t addr, int qid, int qsize) {
  sqe.opc = 0x05;
  sqe.fuse = 0;
  sqe.psdt = 0;
  sqe.nsid = 0;
  sqe.mptr = 0;
  sqe.dptr.prp.prp1 = addr;
  sqe.dptr.prp.prp2 = 0;
  sqe.cdw10_bits.create_io_q.qid = qid;
  sqe.cdw10_bits.create_io_q.qsize = qsize - 1; // 0-base
  sqe.cdw11_bits.create_io_cq.pc = 1;
  sqe.cdw11_bits.create_io_cq.ien = 0;
  sqe.cdw11_bits.create_io_cq.iv = 0;
  sqe.cdw12 = 0;
  sqe.cdw13 = 0;
  sqe.cdw14 = 0;
  sqe.cdw15 = 0;
}

void SnuFPGA::BuildAdminCommandCreateSQ(NVMeSQEntry &sqe, size_t addr, int qid, int qsize, int cqid) {
  sqe.opc = 0x01;
  sqe.fuse = 0;
  sqe.psdt = 0;
  sqe.nsid = 0;
  sqe.mptr = 0;
  sqe.dptr.prp.prp1 = addr;
  sqe.dptr.prp.prp2 = 0;
  sqe.cdw10_bits.create_io_q.qid = qid;
  sqe.cdw10_bits.create_io_q.qsize = qsize - 1; // 0-base
  sqe.cdw11_bits.create_io_sq.pc = 1;
  sqe.cdw11_bits.create_io_sq.qprio = 0;
  sqe.cdw11_bits.create_io_sq.cqid = cqid;
  sqe.cdw12 = 0;
  sqe.cdw13 = 0;
  sqe.cdw14 = 0;
  sqe.cdw15 = 0;
}

void SnuFPGA::BuildAdminCommandGetLogPage(NVMeSQEntry &sqe) {
  sqe.opc = 0x02;
  sqe.fuse = 0;
  sqe.psdt = 0;
  sqe.nsid = 0;
  sqe.mptr = 0;
  sqe.dptr.prp.prp1 = ADBUF_DPTR;
  sqe.dptr.prp.prp2 = 0;
  sqe.cdw10_bits.get_log_page.lid = 0x01; // Error information
  sqe.cdw10_bits.get_log_page.lsp = 0;
  sqe.cdw10_bits.get_log_page.rae = 0;
  sqe.cdw10_bits.get_log_page.numdl = 15; // 0-based, request 16 dwords = one 64-byte entry
  sqe.cdw11_bits.get_log_page.numdu = 0;
  sqe.cdw11_bits.get_log_page.lsid = 0;
  sqe.cdw12 = 0;
  sqe.cdw13 = 0;
  sqe.cdw14 = 0;
  sqe.cdw15 = 0;
}

void SnuFPGA::BuildIOCommandWrite(NVMeSQEntry &sqe, size_t addr, size_t slba, uint16_t nlb) {
  sqe.opc = 0x01;
  sqe.fuse = 0;
  sqe.psdt = 0;
  sqe.nsid = 1;
  sqe.mptr = 0;
  sqe.dptr.prp.prp1 = addr;
  sqe.dptr.prp.prp2 = 0;
  sqe.cdw10 = slba; // starting lba
  sqe.cdw11 = slba >> 32;
  sqe.cdw12 = nlb - 1; // 0-base
  sqe.cdw13 = 0;
  sqe.cdw14 = 0;
  sqe.cdw15 = 0;
}

void SnuFPGA::EnqueueAdminSQ(NVMeSQEntry &sqe) {
  sqe.cid = sq0t; // queue slot number as cid
  MemcpyH2D(ADMIN_SQ_ADDR + sq0t * 64, &sqe, 64);
  sq0t = (sq0t + 1) % ADMIN_SQ_DEPTH;
  WriteNVMe(0x1000, sq0t);
}

void SnuFPGA::DequeueAdminCQ(NVMeCQEntry &cqe) {
  while (true) {
    MemcpyD2H(&cqe, ADMIN_CQ_ADDR + cq0h * 16, 16);
    if (cqe.status.p != cq0phase) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  // 32-bit access from host and 128-bit access from NVMe might have interleaved
  // So copy full 128-bit again
  MemcpyD2H(&cqe, ADMIN_CQ_ADDR + cq0h * 16, 16);

  spdlog::info("sqhd={:X} sqid={:X} cid={} phase={} sc={} sct={} crd={} m={} dnr={} cdw0={:#X} cdw1={:#X}",
    cqe.sqhd, cqe.sqid, cqe.cid, (int)cqe.status.p, (int)cqe.status.sc, (int)cqe.status.sct,
    (int)cqe.status.crd, (int)cqe.status.m, (int)cqe.status.dnr, cqe.cdw0, cqe.cdw1);
  cq0h = (cq0h + 1) % ADMIN_CQ_DEPTH;
  if (cq0h == 0) cq0phase ^= 1;
  WriteNVMe(0x1004, cq0h);
}

void SnuFPGA::EnqueueIOSQ(NVMeSQEntry &sqe) {
  sqe.cid = sq1t; // queue slot number as cid
  MemcpyH2D(IO_SQ_ADDR + sq1t * 64, &sqe, 64);
  sq1t = (sq1t + 1) % IO_SQ_DEPTH;
}

void SnuFPGA::DoorbellIOSQ() {
  WriteNVMe(0x1008, sq1t);
}

void SnuFPGA::DequeueIOCQ(NVMeCQEntry &cqe) {
  while (true) {
    MemcpyD2H(&cqe, IO_CQ_ADDR + cq1h * 16, 16);
    if (cqe.status.p != cq1phase) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  // 32-bit access from host and 128-bit access from NVMe might have interleaved
  // So copy full 128-bit again
  MemcpyD2H(&cqe, IO_CQ_ADDR + cq1h * 16, 16);

  spdlog::info("sqhd={:X} sqid={:X} cid={} phase={} sc={} sct={} crd={} m={} dnr={}",
    cqe.sqhd, cqe.sqid, cqe.cid, (int)cqe.status.p, (int)cqe.status.sc, (int)cqe.status.sct,
    (int)cqe.status.crd, (int)cqe.status.m, (int)cqe.status.dnr);
  cq1h = (cq1h + 1) % IO_CQ_DEPTH;
  if (cq1h == 0) cq1phase ^= 1;
}

void SnuFPGA::DoorbellIOCQ() {
  WriteNVMe(0x100c, cq1h);
}

void SnuFPGA::CheckError() {
  NVMeSQEntry sqe;
  NVMeCQEntry cqe;
  BuildAdminCommandGetLogPage(sqe);
  EnqueueAdminSQ(sqe);
  DequeueAdminCQ(cqe);
  // Check spec 5.16.1.2
  spdlog::info("Error Information Log Entry");
  for (int i = 0; i < 64; i += 4) {
    uint32_t val = ReadMemory(ADBUF_DPTR + i);
    spdlog::info("{:#04X} {:#010X}", i, val);
  }
}

void SnuFPGA::InitNVMe() {
  /*
   * PCIe Transport-specific controller initialization START
   */

  // Set secondary bus number to 1 (at 0x18 on config space of PCIe IP)
  // TODO limit write to secondary bus number (not 4byte)
  WritePCIeConfig(0, 0, 0, 0x18, 0x00000100);

  // Poll until the NVMe device is detected on bus 1.
  // If the device is found, we will read device ID and vendor ID.
  // (at 0x00 on config space of NVMe)
  // Otherwise, we get 0xFFFFFFFF.
  while (ReadPCIeConfig(1, 0, 0, 0x00) == 0xFFFFFFFF) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  spdlog::info("NVMe found on 01:00.0");

  /*
   * Enable memory space of NVMe. (offset 0x04 bit 1)
   * Without it, all requests will result in "Unsupported Requests" in PCIe or "DECERR" in AXI.
   * Enable bus master of NVMe. (offset 0x04 bit 2)
   */
  // TODO limit write to memory space (not 4byte)
  WritePCIeConfig(1, 0, 0, 0x04, 0x00000006);

  /*
   * BAR size detection
   */

  // 1. try to set all bits in BAR
  WritePCIeConfig(1, 0, 0, 0x10, 0xffffffff);

  // 2. Read BAR and find the lowest set bit in address bits.
  // (4 lsb are not address bits, so ignore them.)
  uint32_t bar = ReadPCIeConfig(1, 0, 0, 0x10) & 0xfffffff0;
  if (bar == 0) {
    spdlog::info("bar_size==0 something wrong");
    exit(0);
  }

  // 3. Infer BAR size from unchanged bits
  size_t nvme_bar0_size = 1 << __builtin_ctz(bar);
  spdlog::info("Detected bar_size = {}", nvme_bar0_size);

  // 4. Assign NVMe's BAR0 (64-bit) at given address
  WritePCIeConfig(1, 0, 0, 0x10, NVME_BAR0);
  WritePCIeConfig(1, 0, 0, 0x14, NVME_BAR0 >> 32);

  // Bridge Enable after enumeration is done.
  // This is described in Xilinx PG194.
  // TODO limit write to bridge enable (not 4byte)
  WritePCIeConfig(0, 0, 0, 0x148, 0x00000001);

  /*
   * PCIe Transport-specific controller initialization DONE
   */
  
  // Just checking headers
  spdlog::info("RP CAP = {:32b}", ReadPCIeConfig(0, 0, 0, 0x04));
  spdlog::info("RP CTL = {:32b}", ReadPCIeConfig(0, 0, 0, 0x08));
  spdlog::info("EP CAP = {:32b}", ReadPCIeConfig(1, 0, 0, 0x04));
  spdlog::info("EP CTL = {:32b}", ReadPCIeConfig(1, 0, 0, 0x08));

  PrintPCIeConfigSpaceHeader(0, 0, 0);
  PrintPCIeConfigSpaceHeader(1, 0, 0);

  /*
   * Memory-based transport controller initialization START
   * We follow "3.5.1 Memory-based Transport Controller Initialization" in spec.
   */

  // 1. The host waits for the controller to indicate that any previous reset
  //    is complete by waiting for CSTS.RDY to become ‘0’;
  // CSTS.RDY at [0] at 0x1c
  while (ReadNVMe(0x1c) & 0b1 != 0) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  /*
   * 2. The host configures the Admin Queue by setting the Admin Queue Attributes (AQA), Admin
   * Submission Queue Base Address (ASQ), and Admin Completion Queue Base Address (ACQ) to
   * appropriate values;
   */
  // We put ASQ right after NVMe BAR0, and ACQ right after ASQ.
  WriteNVMe(0x24, (ADMIN_CQ_DEPTH << 16) | ADMIN_SQ_DEPTH); // AQA set (CQ size, SQ size)
  WriteNVMe(0x28, ADMIN_SQ_ADDR); // ASQ low adddr
  WriteNVMe(0x2c, ADMIN_SQ_ADDR >> 32); // ASQ high addr
  WriteNVMe(0x30, ADMIN_CQ_ADDR); // ACQ low adddr
  WriteNVMe(0x34, ADMIN_CQ_ADDR >> 32); // ASQ high addr
  // Clean ACQ to check phase
  Memset(ADMIN_CQ_ADDR, 0, ADMIN_CQ_DEPTH * 16);

  /*
    3. The host determines the supported I/O Command Sets by checking the state of CAP.CSS and
       appropriately initializing CC.CSS as follows:
       a. If the CAP.CSS bit 7 is set to ‘1’, then the CC.CSS field should be set to 111b;
       b. If the CAP.CSS bit 6 is set to ‘1’, then the CC.CSS field should be set to 110b; and
       c. If the CAP.CSS bit 6 is cleared to ‘0’ and bit 0 is set to ‘1’, then the CC.CSS field should be set
       to 000b;
   */
  // CAP.CSS is bits 44:37 at 0x00. (thus, 12:5 at 0x04)
  // CC.CSS is bits 6:4 at 0x14
  {
    uint32_t CAP0 = ReadNVMe(0x00);
    uint32_t CAP4 = ReadNVMe(0x04);
    uint32_t CAP_CSS = (CAP4 >> 5) & 0xff;
    uint32_t CC = ReadNVMe(0x14);
    // Clear CC.CSS
    CC &= ~(0b111 << 4);
    spdlog::info("CAP.CSS={:#b}", CAP_CSS);
    if (CAP_CSS & 0b10000000) {
      spdlog::info("CSS Case a");
      WriteNVMe(0x14, CC | (0b111 << 4));
    } else if (CAP_CSS & 0b1000000) { 
      spdlog::info("CSS Case b");
      WriteNVMe(0x14, CC | (0b110 << 4));
    } else if (!(CAP_CSS & 0b1000000) && (CAP_CSS & 0b1)) {
      spdlog::info("CSS Case c");
      WriteNVMe(0x14, CC | (0b000 << 4));
    } else {
      spdlog::info("CSS Case Invalid");
      exit(0);
    }
  }

  /*
  4. The controller settings should be configured. Specifically:
    a. The arbitration mechanism should be selected in CC.AMS; and
    b. The memory page size should be initialized in CC.MPS;
  */
  // CAP.AMS @ 18:17, CAP.MPSMAX @ 55:52, CAP.MPSMIN @ 51:48 at 0x00
  // CC.AMS @ 13:11, CC.MPS @ 10:7 at 0x14
  {
    uint32_t CAP0 = ReadNVMe(0x00);
    uint32_t CAP4 = ReadNVMe(0x04);
    uint32_t CAP_AMS = (CAP0 >> 17) & 0b11;
    uint32_t CAP_MPSMAX = (CAP4 >> (52 - 32)) & 0b1111;
    uint32_t CAP_MPSMIN = (CAP4 >> (48 - 32)) & 0b1111;
    spdlog::info("CAP.AMS={:#b} CAP.MPSMAX={:#b} CAP.MPSMIN={:#b}", CAP_AMS, CAP_MPSMAX, CAP_MPSMIN);
    uint32_t CC = ReadNVMe(0x14);
    // Clear CC.AMS
    CC &= ~(0b111 << 11);
    // Clear CC.MPS
    CC &= ~(0b1111 << 7);
    // Set CC.AMS to 000 (round robin)
    CC |= 0b000 << 11;
    // Set CC.MPS to CAP.MPSMIN
    CC |= CAP_MPSMIN << 7;
    WriteNVMe(0x14, CC);
  }

  /*
  5. The host enables the controller by setting CC.EN to ‘1’;
  */
  // CC.EN @ 0 at 0x14
  {
    uint32_t CC = ReadNVMe(0x14);
    // Set CC.EN
    CC |= 0b1;
    WriteNVMe(0x14, CC);
  }

  /*
  6. The host waits for the controller to indicate that the controller is ready to process commands. The
controller is ready to process commands when CSTS.RDY is set to ‘1’;
  */
  // CSTS.RDY at [0] at 0x1c
  while ((ReadNVMe(0x1c) & 0b1) != 1) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  spdlog::info("NVMe ready.");

  /*
  7. The host determines the configuration of the controller by issuing the Identify command specifying
the Identify Controller data structure (i.e., CNS 01h);
  */
  {
    // skip identify command
    /*
    NVMeSQEntry sqe;
    NVMeCQEntry cqe;
    BuildAdminCommandIdentify(sqe, 0x01);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
    uint32_t cds512 = ReadMemory(ADBUF_DPTR + 512);
    int min_sqes = cds512 & 0b1111;
    int max_sqes = (cds512 >> 4) & 0b1111;
    int min_cqes = (cds512 >> 8) & 0b1111;
    int max_cqes = (cds512 >> 12) & 0b1111;
    spdlog::info("min_sqes={} max_sqes={} min_cqes={} max_cqes={}", min_sqes, max_sqes, min_cqes, max_cqes);
    */
    // CC.IOCQES @ 23:20, CC.IOSQES @ 19:16
    uint32_t CC = ReadNVMe(0x14);
    // Clear CC.IOCQES
    CC &= ~(0b1111 << 20);
    // Clear CC.IOSQES
    CC &= ~(0b1111 << 16);
    // Set CC.IOCQES to 4 (16B)
    CC |= 4 << 20;
    // Set CC.IOSQES to 6 (64B)
    CC |= 6 << 16;
    WriteNVMe(0x14, CC);
  }
  spdlog::info("SQ/CQ entry size written.");

  /*
  8. The host determines any I/O Command Set specific configuration information as follows:
    a. If the CAP.CSS bit 6 is set to ‘1’, then the host does the following:
    (We do not belong to this case.)
    b. For each I/O Command Set that is enabled (Note: the NVM Command Set is enabled if the
    CC.CSS field is set to 000b):
       i. Issue the Identify command specifying the I/O Command Set specific Active Namespace
       ID list (CNS 07h) with the appropriate Command Set Identifier (CSI) value of that I/O
       Command Set; and
       ii. For each NSID that is returned:
         1. If the enabled I/O Command Set is the NVM Command Set or an I/O Command Set
         based on the NVM Command Set (e.g., the Zoned Namespace Command Set) issue
         the Identify command specifying the Identify Namespace data structure (CNS 00h);
         and
         2. Issue the Identify command specifying each of the following data structures (refer to
         Figure 274): the I/O Command Set specific Identify Namespace data structure, the I/O
         Command Set specific Identify Controller data structure, and the I/O Command Set
         independent Identify Namespace data structure;
  */
  {
    // There will be single nsid 1.
    NVMeSQEntry sqe;
    NVMeCQEntry cqe;
    BuildAdminCommandIdentify(sqe, 0x02);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
    for (int i = 0; i < 4096; i += 4) {
      uint32_t nsid = ReadMemory(ADBUF_DPTR + i);
      if (nsid == 0) break;
      spdlog::info("Found namespace with id {}", nsid);
    }
  }
  spdlog::info("namespace identified.");

  /*
  9. If the controller implements I/O queues, then the host should determine the number of I/O
  Submission Queues and I/O Completion Queues supported using the Set Features command with
  the Number of Queues feature identifier. After determining the number of I/O Queues, the NVMe
  Transport specific interrupt registers (e.g. MSI and/or MSI-X registers) should be configured;
  */
  {
    NVMeSQEntry sqe;
    NVMeCQEntry cqe;
    // Make 3 SQs and 3 CQs on NSID 1 (IO + driver write/read)
    BuildAdminCommandSetFeaturesNumberOfQueues(sqe, 1, 3, 3);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
  }

  /*
  10. If the controller implements I/O queues, then the host should allocate the appropriate number of
  I/O Completion Queues based on the number required for the system configuration and the number
  supported by the controller. The I/O Completion Queues are allocated using the Create I/O
  Completion Queue command;
  */
  {
    NVMeSQEntry sqe;
    NVMeCQEntry cqe;
    // Build IOCQ
    BuildAdminCommandCreateCQ(sqe, IO_CQ_ADDR, 1, IO_CQ_DEPTH);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
    // Build WRCQ
    BuildAdminCommandCreateCQ(sqe, WRCQ_ADDR, 2, OUTSTANDING);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
    // Build RDCQ
    BuildAdminCommandCreateCQ(sqe, RDCQ_ADDR, 3, OUTSTANDING);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
  }

  /*
  11. If the controller implements I/O queues, then the host should allocate the appropriate number of
  I/O Submission Queues based on the number required for the system configuration and the number
  supported by the controller. The I/O Submission Queues are allocated using the Create I/O
  Submission Queue command; and
  */
  {
    NVMeSQEntry sqe;
    NVMeCQEntry cqe;
    // Build IOSQ
    BuildAdminCommandCreateSQ(sqe, IO_SQ_ADDR, 1, IO_SQ_DEPTH, 1);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
    // Build WRSQ
    BuildAdminCommandCreateSQ(sqe, WRSQ_ADDR, 2, OUTSTANDING, 2);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
    // Build RDSQ
    BuildAdminCommandCreateSQ(sqe, RDSQ_ADDR, 3, OUTSTANDING, 3);
    EnqueueAdminSQ(sqe);
    DequeueAdminCQ(cqe);
  }

  /*
  12. To enable asynchronous notification of optional events, the host should issue a Set Features
  command specifying the events to enable. To enable asynchronous notification of events, the host
  should submit an appropriate number of Asynchronous Event Request commands. This step may
  be done at any point after the controller signals that the controller is ready (i.e., CSTS.RDY is set
  to ‘1’)
  */
  // Skip

  // Clean CQs
  Memset(IO_CQ_ADDR, 0, IO_CQ_DEPTH * 16);
  Memset(WRCQ_ADDR, 0, OUTSTANDING * 16);
  Memset(RDCQ_ADDR, 0, OUTSTANDING * 16);

  spdlog::info("Done.");
}

void SnuFPGA::SetKernelArgument(size_t start_addr, size_t end_addr, uint32_t benchmode) {
  uint32_t start_val[4] = {0, 0, 0, 0};
  uint32_t stride[4] = {1, 1, 1, 1};

  const uint32_t kernel_lba_size = 512;
  const uint32_t kernel_burst_len = kernel_lba_size / 16 - 1;
  const uint32_t driver_lba_size = 512;
  const uint32_t driver_log2_lba = __builtin_ctz(kernel_lba_size);
  const uint32_t driver_burst_len = kernel_burst_len;
  const uint32_t driver_nlb = kernel_lba_size / driver_lba_size;
  static_assert((1 << driver_log2_lba) == kernel_lba_size, "Incorrect size");
  static_assert(kernel_lba_size == driver_nlb * driver_lba_size, "Incorrect size");

  // Kernel write
  WriteUser(0x10, start_addr);
  WriteUser(0x14, start_addr >> 32);
  WriteUser(0x18, end_addr);
  WriteUser(0x1c, end_addr >> 32);
  WriteUser(0x20, start_val[0]);
  WriteUser(0x24, start_val[1]);
  WriteUser(0x28, start_val[2]);
  WriteUser(0x2c, start_val[3]);
  WriteUser(0x30, stride[0]);
  WriteUser(0x34, stride[1]);
  WriteUser(0x38, stride[2]);
  WriteUser(0x3c, stride[3]);
  WriteUser(0x40, benchmode);
  WriteUser(0x48, kernel_burst_len);
  WriteUser(0x4c, kernel_lba_size);
  // Driver write
  WriteUser(0x00200000, driver_log2_lba);
  WriteUser(0x00200004, driver_burst_len);
  WriteUser(0x00200008, driver_nlb);

  size_t check_start_addr;
  size_t check_end_addr;
  uint32_t check_start_val[4];
  uint32_t check_stride[4];
  uint32_t check_benchmode;
  check_start_addr = ((size_t)ReadUser(0x14) << 32) | ReadUser(0x10);
  check_end_addr = ((size_t)ReadUser(0x1c) << 32) | ReadUser(0x18);
  check_start_val[0] = ReadUser(0x20);
  check_start_val[1] = ReadUser(0x24);
  check_start_val[2] = ReadUser(0x28);
  check_start_val[3] = ReadUser(0x2c);
  check_stride[0] = ReadUser(0x30);
  check_stride[1] = ReadUser(0x34);
  check_stride[2] = ReadUser(0x38);
  check_stride[3] = ReadUser(0x3c);
  check_benchmode = ReadUser(0x40);
  uint32_t check_kernel_burst_len = ReadUser(0x48);
  uint32_t check_kernel_lba_size = ReadUser(0x4c);
  uint32_t check_driver_log2_lba = ReadUser(0x00200000);
  uint32_t check_driver_burst_len = ReadUser(0x00200004);
  uint32_t check_driver_nlb = ReadUser(0x00200008);

  spdlog::info("Kernel argument validation: saddr={} eaddr={} "
    "start_val={},{},{},{} stride={},{},{},{} benchmode={} burst_len={} lba_size={}",
    check_start_addr, check_end_addr, check_start_val[0], check_start_val[1],
    check_start_val[2], check_start_val[3], check_stride[0], check_stride[1],
    check_stride[2], check_stride[3], check_benchmode, check_kernel_burst_len, check_kernel_lba_size);
  spdlog::info("Driver argument validation: log2_lba={} burst_len={} nlb={}",
    check_driver_log2_lba, check_driver_burst_len, check_driver_nlb);

  // Expected checksum
  uint32_t val[4] = {start_val[0], start_val[1], start_val[2], start_val[3]};
  uint32_t expected = 0;
  for (size_t i = start_addr; i < end_addr; i += 16) {
    expected += val[0];
    expected += val[1];
    expected += val[2];
    expected += val[3];
    val[0] += stride[0];
    val[1] += stride[1];
    val[2] += stride[2];
    val[3] += stride[3];
  }
  spdlog::info("expected checksum={}", expected);
}

void SnuFPGA::LaunchKernel() {
  uint32_t state;
  state = ReadUser(0x04);
  if (state != 0) {
    spdlog::info("Kernel should be IDLE, but unexpected kernel state = {}", state);
    exit(0);
  }

  // kernel start trigger
  WriteUser(0x00, 0);

  while (true) {
    state = ReadUser(0x04);
    if (state == 0) {
      spdlog::info("Unexpected kernel state IDLE after kernel start");
      exit(0);
    }
    if (state == 2) {
      spdlog::info("Kernel DONE");
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  // Reset to idle
  WriteUser(0x08, 0);

  state = ReadUser(0x04);
  if (state != 0) {
    spdlog::info("Kernel should be IDLE, but unexpected kernel state = {}", state);
    exit(0);
  }

  if (ReadUser(0x40) == 1) { // read benchmode
    uint32_t checksum = ReadUser(0x44);
    spdlog::info("checksum={}", checksum);
  }
}

void SnuFPGA::TestWrite() {
  {
    NVMeSQEntry sqe;
    NVMeCQEntry cqe;
    const int iter = 4;
    const int lba_per_iter = 8;
    for (int i = 0; i < iter; ++i) {
      BuildIOCommandWrite(sqe, WRBUF_ADDR + i * 512 * lba_per_iter, i * lba_per_iter, lba_per_iter);
      EnqueueIOSQ(sqe);
    }
    DoorbellIOSQ();
    for (int i = 0; i < iter; ++i) {
      DequeueIOCQ(cqe);
    }
    DoorbellIOCQ();
  }
}

int main(int argc, char **argv) {
  if (argc < 2) {
    spdlog::info("Usage: {} [chunk]", argv[0]);
    exit(0);
  }
  SnuFPGA *fpga = new SnuFPGA(0, 0x86);
  fpga->Reset();
  fpga->InitNVMe();

  //fpga->TestWrite();

  std::chrono::steady_clock cpu_clock;

  // Write bench
  //{
  //  spdlog::info("4KB Seq write test");
  //  size_t n = atoi(argv[1]) * 512;
  //  fpga->SetKernelArgument(0, n, 0);
  //  auto st = cpu_clock.now();
  //  fpga->LaunchKernel();
  //  auto et = cpu_clock.now();
  //  double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(et - st).count() / 1e9;
  //  double mbps = n / elapsed / 1e6;
  //  spdlog::info("{} bytes, {} sec, {} MB/s", n, elapsed, mbps);
  //}

  // Read bench
  //{
  //  spdlog::info("4KB Seq read test");
  //  size_t n = atoi(argv[1]) * 512;
  //  fpga->SetKernelArgument(0, n, 1);
  //  auto st = cpu_clock.now();
  //  fpga->LaunchKernel();
  //  auto et = cpu_clock.now();
  //  double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(et - st).count() / 1e9;
  //  double mbps = n / elapsed / 1e6;
  //  spdlog::info("{} bytes, {} sec, {} MB/s", n, elapsed, mbps);
  //}

  delete fpga;
  return 0;
}