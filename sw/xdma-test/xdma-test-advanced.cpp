#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>
#include <vector>

/*
 * ATTENTION!
 * Xilinx DMA IP seems to have a bug that only 32-bit is applied to C_AXIBAR. (Check xci file of xdma.)
 * For example, even if you map 4G range starting at 0x1_0000_0000 to AXI of xdma in address editor,
 * C_AXIBAR will become 0x0000_0000. (which is incorrect!) Then, if you send request at 0x1_0000_0000,
 * it does not belong to [C_AXIBAR, C_AXIBAR + 4G) which result in DECERR on AXI.
 * 
 * Solution
 * We mapped AXI of xdma to 4G range starting at 0 so that it resides in 32-bit address space.
 * We mapped AXI-lite of xdma (for ecam) to 4G range starting at 4G.
 */
const size_t ecam_addr_base = 0x100000000UL;

// We can map nvme bar to any 32-bit address; we just choose 0 here.
const size_t nvme_bar0 = 0;

// This will be determined during PCIe enumeration
size_t nvme_bar0_size = 0;

// This is bar0 of host-fpga PCIe (not internal PCIe for NVMe) in virtual address in userspace.
// This should be set by mmap.
void* fpga_bar0;

void KernelWrite(size_t addr, uint32_t data) {
  if (addr % 4 != 0) {
    spdlog::warn("KernelWrite skipped due to unaligned access (addr={}, data={})", addr, data);
    exit(0);
  }
  volatile uint32_t* p = (uint32_t*)((size_t)fpga_bar0 + addr);
  *p = data;
}

uint32_t KernelRead(size_t addr) {
  if (addr % 4 != 0) {
    spdlog::warn("KernelRead skipped due to unaligned access (addr={})", addr);
    exit(0);
  }
  volatile uint32_t* p = (uint32_t*)((size_t)fpga_bar0 + addr);
  return *p;
}

void AssertOcuReset() {
  KernelWrite(0xc0, 0);
  std::this_thread::sleep_for(std::chrono::milliseconds(100));
}

void DeassertOcuReset() {
  KernelWrite(0xc4, 0);
  std::this_thread::sleep_for(std::chrono::milliseconds(100));
}

uint32_t OculinkRead32(size_t addr) {
  // Setup addr
  KernelWrite(0x00, addr);
  KernelWrite(0x04, addr >> 32);
  KernelWrite(0x08, 2); // arsize == 2 == 4B read
  // Push to k2o_ar
  KernelWrite(0x40, 0);
  // Wait for response in k2o_r
  while (true) {
    uint32_t valid = KernelRead(0x60);
    if (valid) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  // Pop from k2o_r
  KernelWrite(0x64, 0);
  uint32_t rdatas[4] = {KernelRead(0x00), KernelRead(0x04), KernelRead(0x08), KernelRead(0x0c)};
  uint32_t rdata = addr >= ecam_addr_base ? rdatas[0] : rdatas[addr % 16 / 4];
  uint32_t rresp = KernelRead(0x10) & 0b11;
  uint32_t rid = (KernelRead(0x10) >> 2) & 0b1111;
  spdlog::info("OculinkRead addr=0x{:08X} -> rdata=0x{:08X}, rresp={}, rid={}", addr, rdata, rresp, rid);
  if (rresp != 0) {
    spdlog::info("Exit now due to error");
    exit(0);
  }
  return rdata;
}

void OculinkWrite32(size_t addr, uint32_t data) {
  // Setup addr
  KernelWrite(0x00, addr);
  KernelWrite(0x04, addr >> 32);
  KernelWrite(0x08, 2); // awsize == 2 == 4B write
  // Push to k2o_aw
  KernelWrite(0x20, 0);
  // Setup Data
  KernelWrite(0x00, data);
  KernelWrite(0x04, data);
  KernelWrite(0x08, data);
  KernelWrite(0x0c, data);
  KernelWrite(0x10, 0xffff);
  // Push to k2o_w
  KernelWrite(0x30, 0);
  // Wait for response in k2o_b
  while (true) {
    uint32_t valid = KernelRead(0x50);
    if (valid) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  // Pop from k2o_b
  KernelWrite(0x54, 0);
  uint32_t bresp = KernelRead(0x00) & 0b11;
  uint32_t bid = (KernelRead(0x00) >> 2) & 0b1111;
  spdlog::info("OculinkWrite addr=0x{:08X}, data=0x{:08X} -> bresp={}, bid={}", addr, data, bresp, bid);
  if (bresp != 0) {
    spdlog::info("Exit now due to error");
    exit(0);
  }
}

void OculinkRespondWrite(std::vector<uint32_t>& data) {
  // o2k_aw
  while (true) {
    uint32_t valid = KernelRead(0x70);
    if (valid) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  KernelWrite(0x74, 0);
  uint32_t awaddr0 = KernelRead(0x00);
  uint32_t awaddr1 = KernelRead(0x04);
  uint32_t awsize = KernelRead(0x08) & 0b111;
  uint32_t awlen = (KernelRead(0x08) >> 3) & 0xff;
  uint32_t awid = (KernelRead(0x08) >> 11) & 0b1111;
  spdlog::info("o2k_aw entry found awaddr={},{} awsize={}, awlen={}, awid={}", awaddr1, awaddr0, awsize, awlen, awid);

  size_t addr = ((size_t)awaddr1 << 32) + awaddr0;

  // 1 << awsize is bytes in transfer (single beat in a burst)
  assert((1 << awsize) % sizeof(uint32_t) == 0);
  assert(addr % (1 << awsize) == 0);
  data.clear();

  // o2k_w
  int addr_idx = addr % 16 / 4;
  for (int i = 0; i <= awlen; ++i) {
    while (true) {
      uint32_t valid = KernelRead(0x80);
      if (valid) break;
      std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    KernelWrite(0x84, 0);
    uint32_t wdatas[4] = {0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef};
    wdatas[0] = KernelRead(0x00);
    wdatas[1] = KernelRead(0x04);
    wdatas[2] = KernelRead(0x08);
    wdatas[3] = KernelRead(0x0c);
    for (int j = 0; j < (1 << awsize) / sizeof(uint32_t); ++j) {
      data.push_back(wdatas[addr_idx]);
      addr_idx = (addr_idx + 1) % 4;
    }
    uint32_t wstrb = KernelRead(0x10) & 0xffff;
    spdlog::info("o2k_w entry found wdata={:#010x},{:#010x},{:#010x},{:#010x}, wstrb={}", wdatas[3], wdatas[2], wdatas[1], wdatas[0], wstrb);
  }

  assert((1 << awsize) * (awlen + 1) / sizeof(uint32_t) == data.size());

  // o2k_b
  uint32_t bid = awid;
  KernelWrite(0x00, bid);
  KernelWrite(0xa0, 0);
  spdlog::info("OculinkRespondWrite bid={}", bid);
}

void OculinkRespondRead(std::vector<uint32_t>& data) {
  // o2k_ar
  while (true) {
    uint32_t valid = KernelRead(0x90);
    if (valid) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  KernelWrite(0x94, 0);
  uint32_t araddr0 = KernelRead(0x00);
  uint32_t araddr1 = KernelRead(0x04);
  uint32_t arsize = KernelRead(0x08) & 0b111;
  uint32_t arlen = (KernelRead(0x08) >> 3) & 0xff;
  uint32_t arid = (KernelRead(0x08) >> 11) & 0b1111;
  spdlog::info("o2k_ar entry found araddr={},{} arsize={}, arlen={}, arid={}", araddr1, araddr0, arsize, arlen, arid);

  size_t addr = ((size_t)araddr1 << 32) + araddr0;

  // 1 << arsize is bytes in transfer (single beat in a burst)
  assert((1 << arsize) % sizeof(uint32_t) == 0);
  assert(addr % (1 << arsize) == 0);
  assert((1 << arsize) * (arlen + 1) / sizeof(uint32_t) == data.size());

  // o2k_r
  int addr_idx = addr % 16 / 4;
  int data_idx = 0;
  for (int i = 0; i <= arlen; ++i) {
    uint32_t rdatas[4] = {0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef};
    for (int j = 0; j < (1 << arsize) / sizeof(uint32_t); ++j) {
      rdatas[addr_idx] = data[data_idx];
      addr_idx = (addr_idx + 1) % 4;
      ++data_idx;
    }
    uint32_t rlast = i == arlen;
    uint32_t rid = arid;
    KernelWrite(0x00, rdatas[0]);
    KernelWrite(0x04, rdatas[1]);
    KernelWrite(0x08, rdatas[2]);
    KernelWrite(0x0c, rdatas[3]);
    KernelWrite(0x10, (rid << 1) | rlast);
    KernelWrite(0xb0, 0);
    spdlog::info("OculinkRespondRead rdata={:#010x},{:#010x},{:#010x},{:#010x}, rlast={}, rid={}", rdatas[3], rdatas[2], rdatas[1], rdatas[0], rlast, rid);
  }
}

bool CheckAllQueueIsEmpty() {
  // k2o_b
  if (KernelRead(0x50)) {
    KernelWrite(0x54, 0);
    uint32_t bresp = KernelRead(0x00) & 0b11;
    uint32_t bid = (KernelRead(0x00) >> 2) & 0b1111;
    spdlog::info("k2o_b is not empty!!! bresp={}, bid={}", bresp, bid);
    return false;
  }
  // k2o_r
  if (KernelRead(0x60)) {
    KernelWrite(0x64, 0);
    uint32_t rdata = KernelRead(0x00);
    uint32_t rresp = KernelRead(0x10) & 0b11;
    uint32_t rid = (KernelRead(0x10) >> 2) & 0b1111;
    spdlog::info("k2o_r is not empty!!! rdata={}, rresp={}, rid={}", rdata, rresp, rid);
    return false;
  }
  // o2k_aw
  if (KernelRead(0x70)) {
    KernelWrite(0x74, 0);
    uint32_t awaddr0 = KernelRead(0x00);
    uint32_t awaddr1 = KernelRead(0x04);
    uint32_t awsize = KernelRead(0x08) & 0b111;
    uint32_t awlen = (KernelRead(0x08) >> 3) & 0xff;
    uint32_t awid = (KernelRead(0x08) >> 11) & 0b1111;
    spdlog::info("o2k_aw is not empty!!! awaddr={},{} awsize={}, awlen={}, awid={}", awaddr1, awaddr0, awsize, awlen, awid);
    return false;
  }
  // o2k_w
  if (KernelRead(0x80)) {
    KernelWrite(0x84, 0);
    uint32_t wdata0 = KernelRead(0x00);
    uint32_t wdata1 = KernelRead(0x04);
    uint32_t wdata2 = KernelRead(0x08);
    uint32_t wdata3 = KernelRead(0x0c);
    uint32_t wstrb = KernelRead(0x10) & 0xffff;
    spdlog::info("o2k_w is not empty!!! wdata={},{},{},{}, wstrb={}", wdata3, wdata2, wdata1, wdata0, wstrb);
    return false;
  }
  // o2k_ar
  if (KernelRead(0x90)) {
    KernelWrite(0x94, 0);
    uint32_t araddr0 = KernelRead(0x00);
    uint32_t araddr1 = KernelRead(0x04);
    uint32_t arsize = KernelRead(0x08) & 0b111;
    uint32_t arlen = (KernelRead(0x08) >> 3) & 0xff;
    uint32_t arid = (KernelRead(0x08) >> 11) & 0b1111;
    spdlog::info("o2k_ar is not empty!!! araddr={},{} arsize={}, arlen={}, arid={}", araddr1, araddr0, arsize, arlen, arid);
    return false;
  }
  spdlog::info("All queue is empty!!!");
  return true;
}


size_t ECAMAddress(int bus, int dev, int func) {
  return (bus << 20) | (dev << 15) | (func << 12);
}

uint32_t OculinkReadECAM(int bus, int dev, int func, int offset) {
  return OculinkRead32(ecam_addr_base + ECAMAddress(bus, dev, func) + offset);
  //return OculinkRead32(ECAMAddress(bus, dev, func) + offset);
}

uint32_t OculinkReadNVMe(int offset) {
  return OculinkRead32(nvme_bar0 + offset);
}

void OculinkWriteECAM(int bus, int dev, int func, int offset, uint32_t data) {
  OculinkWrite32(ecam_addr_base + ECAMAddress(bus, dev, func) + offset, data);
  //OculinkWrite32(ECAMAddress(bus, dev, func) + offset, data);
}

void OculinkWriteNVMe(int offset, uint32_t data) {
  OculinkWrite32(nvme_bar0 + offset, data);
}

void PrintPCIConfigSpaceHeader(int bus, int dev, int func) {
  spdlog::info("PCI Config Space Header of {:02X}:{:02X}.{:01X} (through ECAM)", bus, dev, func);
  for (int i = 0; i < 0x40; i += 4) {
    spdlog::info("{:02X} {:08X}", i, OculinkReadECAM(bus, dev, func, i));
  }
}

int main(int argc, char** argv) {
  {
    const char* pcie_rst_name = "/sys/bus/pci/devices/0000:86:00.0/reset";
    FILE* f = fopen(pcie_rst_name, "w");
    if (f == NULL) {
      spdlog::info("sysfs pcie reset node {} opened failed: {}.", pcie_rst_name, strerror(errno));
      return 0;
    }
    fprintf(f, "1\n");
    fclose(f);
    spdlog::info("reset done. ({})", pcie_rst_name);
  }

  const char* devname = "/dev/xdma0_user";
  int fd;
	if ((fd = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} opened failed: {}.", devname, strerror(errno));
    return 0;
	}
	spdlog::info("character device {} opened. fd={}", devname, fd);

  size_t bar0sz = 1024 * 1024; // 1MB
	fpga_bar0 = mmap(NULL, bar0sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (fpga_bar0 == (void *)-1) {
    spdlog::info("mmap failed: {}", strerror(errno));
    close(fd);
    return 0;
	}
  spdlog::info("mmap done. fpga_bar0={}", fpga_bar0);

  // Unnecessary as we reset the whole board
  //AssertOcuReset();
  //DeassertOcuReset();

  // TODO should be replaced with kernel reset
  while (!CheckAllQueueIsEmpty());

  /*
   * PCIe Transport-specific controller initialization START
   */

  // Set secondary bus number to 1 (at 0x18 on config space of PCIe IP)
  // TODO limit write to secondary bus number (not 4byte)
  OculinkWriteECAM(0, 0, 0, 0x18, 0x00000100);

  // Poll until the NVMe device is detected on bus 1.
  // If the device is found, we will read device ID and vendor ID.
  // (at 0x00 on config space of NVMe)
  // Otherwise, we get 0xFFFFFFFF.
  while (OculinkReadECAM(1, 0, 0, 0x00) == 0xFFFFFFFF) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  spdlog::info("NVMe found on 01:00.0");

  /*
   * Expand Memory Limit of RP
   */
  //OculinkWriteECAM(0, 0, 0, 0x20, 0xFFFF0000);

  /*
   * Enable memory space of NVMe. (at 0x02 on config space of NVMe)
   * Without it, all requests will result in "Unsupported Requests" in PCIe or "DECERR" in AXI.
   */
  // TODO limit write to memory space (not 4byte)
  OculinkWriteECAM(1, 0, 0, 0x04, 0x00000002);

  /*
   * BAR size detection
   */

  // 1. try to set all bits in BAR
  OculinkWriteECAM(1, 0, 0, 0x10, 0xffffffff);

  // 2. Read BAR and find the lowest set bit in address bits.
  // (4 lsb are not address bits, so ignore them.)
  uint32_t bar = OculinkReadECAM(1, 0, 0, 0x10) & 0xfffffff0;
  if (bar == 0) {
    spdlog::info("bar_size==0 something wrong");
    exit(0);
  }

  // 3. Infer BAR size from unchanged bits
  nvme_bar0_size = 1 << __builtin_ctz(bar);
  spdlog::info("Detected bar_size = {}", nvme_bar0_size);

  // 4. Assign NVMe's BAR0 (64-bit) at given address
  OculinkWriteECAM(1, 0, 0, 0x10, nvme_bar0);
  OculinkWriteECAM(1, 0, 0, 0x14, 0x00000000);

  // Bridge Enable after enumeration is done.
  // This is described in Xilinx PG194.
  // TODO limit write to bridge enable (not 4byte)
  OculinkWriteECAM(0, 0, 0, 0x148, 0x00000001);

  /*
   * PCIe Transport-specific controller initialization DONE
   */
  
  // Just checking headers
  spdlog::info("RP CAP = {:32b}", OculinkReadECAM(0, 0, 0, 0x04));
  spdlog::info("RP CTL = {:32b}", OculinkReadECAM(0, 0, 0, 0x08));
  spdlog::info("EP CAP = {:32b}", OculinkReadECAM(1, 0, 0, 0x04));
  spdlog::info("EP CTL = {:32b}", OculinkReadECAM(1, 0, 0, 0x08));

  PrintPCIConfigSpaceHeader(0, 0, 0);
  PrintPCIConfigSpaceHeader(1, 0, 0);

  /*
   * Memory-based transport controller initialization START
   * We follow "3.5.1 Memory-based Transport Controller Initialization" in spec.
   */

  // 1. The host waits for the controller to indicate that any previous reset
  //    is complete by waiting for CSTS.RDY to become ‘0’;
  // CSTS.RDY at [0] at 0x1c
  while (OculinkReadNVMe(0x1c) & 0b1 != 0) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  /*
   * 2. The host configures the Admin Queue by setting the Admin Queue Attributes (AQA), Admin
   * Submission Queue Base Address (ASQ), and Admin Completion Queue Base Address (ACQ) to
   * appropriate values;
   */
  // We put ASQ right after NVMe BAR0, and ACQ right after ASQ.
  // admin submission queue size
  size_t asqs = 64;
  // admin completion queue size
  size_t acqs = 64;
  // admin submission queue base
  size_t asqb = nvme_bar0 + nvme_bar0_size;
  // admin completion queue base
  size_t acqb = asqb + asqs * 64; // each queue entry is 64-byte
  OculinkWriteNVMe(0x24, (acqs << 16) | asqs); // AQA set (CQ size, SQ size)
  OculinkWriteNVMe(0x28, asqb); // ASQ low adddr
  OculinkWriteNVMe(0x2c, 0x00000000); // ASQ high addr
  OculinkWriteNVMe(0x30, acqb); // ACQ low adddr
  OculinkWriteNVMe(0x34, 0x00000000); // ASQ high addr

  // Just print CAP for debugging
  {
    uint32_t CAP0 = OculinkReadNVMe(0x00);
    uint32_t CAP4 = OculinkReadNVMe(0x04);
    spdlog::info("CAP0={:032b}", CAP0);
    spdlog::info("CAP4={:032b}", CAP4);
  }

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
    uint32_t CAP0 = OculinkReadNVMe(0x00);
    uint32_t CAP4 = OculinkReadNVMe(0x04);
    uint32_t CAP_CSS = (CAP4 >> 5) & 0xff;
    uint32_t CC = OculinkReadNVMe(0x14);
    // Clear CC.CSS
    CC &= ~(0b111 << 4);
    spdlog::info("CAP.CSS={:#b}", CAP_CSS);
    if (CAP_CSS & 0b10000000) {
      spdlog::info("CSS Case a");
      OculinkWriteNVMe(0x14, CC | (0b111 << 4));
    } else if (CAP_CSS & 0b1000000) { 
      spdlog::info("CSS Case b");
      OculinkWriteNVMe(0x14, CC | (0b110 << 4));
    } else if (!(CAP_CSS & 0b1000000) && (CAP_CSS & 0b1)) {
      spdlog::info("CSS Case c");
      OculinkWriteNVMe(0x14, CC | (0b000 << 4));
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
    uint32_t CAP0 = OculinkReadNVMe(0x00);
    uint32_t CAP4 = OculinkReadNVMe(0x04);
    uint32_t CAP_AMS = (CAP0 >> 17) & 0b11;
    uint32_t CAP_MPSMAX = (CAP4 >> (52 - 32)) & 0b1111;
    uint32_t CAP_MPSMIN = (CAP4 >> (48 - 32)) & 0b1111;
    spdlog::info("CAP.AMS={:#b} CAP.MPSMAX={:#b} CAP.MPSMIN={:#b}", CAP_AMS, CAP_MPSMAX, CAP_MPSMIN);
    uint32_t CC = OculinkReadNVMe(0x14);
    // Clear CC.AMS
    CC &= ~(0b111 << 11);
    // Clear CC.MPS
    CC &= ~(0b1111 << 7);
    // Set CC.AMS to 000 (round robin)
    CC |= 0b000 << 11;
    // Set CC.MPS to CAP.MPSMIN
    CC |= CAP_MPSMIN << 7;
    OculinkWriteNVMe(0x14, CC);
  }

  /*
  5. The host enables the controller by setting CC.EN to ‘1’;
  */
  // CC.EN @ 0 at 0x14
  {
    uint32_t CC = OculinkReadNVMe(0x14);
    // Set CC.EN
    CC |= 0b1;
    OculinkWriteNVMe(0x14, CC);
  }

  /*
  6. The host waits for the controller to indicate that the controller is ready to process commands. The
controller is ready to process commands when CSTS.RDY is set to ‘1’;
  */
  // CSTS.RDY at [0] at 0x1c
  while (OculinkReadNVMe(0x1c) & 0b1 != 1) {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  /*
  7. The host determines the configuration of the controller by issuing the Identify command specifying
the Identify Controller data structure (i.e., CNS 01h);
  */
  // SQ0TDBL at 0x1000
  int sqtail = 0;
  int cqhead = 0;
  OculinkWriteNVMe(0x1000, ++sqtail);
  {
    // 3.3.3.1 Submission Queue Entry : for generic submission queue entry architecture
    // 5. Admin Command Set : for opcode
    // 5.17.1 Identify Command : for command-specific information
    // 5.17.2.1 Identify Controller Data Structure (CNS 01h)
    std::vector<uint32_t> data;
    uint32_t cid = 42; // unique identifier
    uint32_t psdt = 0; // PRP shall be used for all Admin command for NVMe over PCIe.
    uint32_t fuse = 0; // not fused
    uint32_t opcode = 0x06; // IDENTIFY command
    uint32_t cdw0 = (cid << 16) | (psdt << 14) | (fuse << 8) | opcode;
    uint32_t nsid = 0; // namespace identifier not used
    uint32_t cdw2 = 0; // TODO command specific
    uint32_t cdw3 = 0; // TODO command specific
    uint64_t mptr = 0; // TODO metadata pointer what is this???
    // prp1 and prp2 is dptr
    uint64_t prp1 = 6 * 1024 * 1024; // prp entry 1; we give dptr as 2MB
    uint64_t prp2 = 0; // prp entry 2
    uint32_t cdw10 = 0x01; // cntid == 0 (not used), cns = 01h
    uint32_t cdw11 = 0; // csi == 0 (not used), CNS specific Identifier == 0 (not used)
    uint32_t cdw12 = 0;
    uint32_t cdw13 = 0;
    uint32_t cdw14 = 0; // uuid index == 0 (not used)
    uint32_t cdw15 = 0;

    data.push_back(cdw0);
    data.push_back(nsid);
    data.push_back(cdw2);
    data.push_back(cdw3); // 16B
    data.push_back(mptr);
    data.push_back(mptr >> 32);
    data.push_back(prp1);
    data.push_back(prp1 >> 32);
    data.push_back(prp2);
    data.push_back(prp2 >> 32); // 40B
    data.push_back(cdw10);
    data.push_back(cdw11);
    data.push_back(cdw12);
    data.push_back(cdw13);
    data.push_back(cdw14);
    data.push_back(cdw15); // 64B

    OculinkRespondRead(data);

    std::vector<uint32_t> cds; // controller data structure
    for (int i = 0; i < 32; ++i) { // 4KB expected; NVMe sends 32 txn with burst length 8 (32 * 8 * 16B = 4KB)
      std::vector<uint32_t> ret;
      OculinkRespondWrite(ret);
      assert(ret.size() == 32); // (32 * 32b = 128B per txn)
      cds.insert(cds.end(), ret.begin(), ret.end());
    }
    // sqes at 512, cqes at 513

    uint32_t cds512 = cds[512 / sizeof(uint32_t)];
    int min_sqes = cds512 & 0b1111;
    int max_sqes = (cds512 >> 4) & 0b1111;
    int min_cqes = (cds512 >> 8) & 0b1111;
    int max_cqes = (cds512 >> 12) & 0b1111;
    spdlog::info("min_sqes={} max_sqes={} min_cqes={} max_cqes={}", min_sqes, max_sqes, min_cqes, max_cqes);

    {
      // 3.3.3.2 Common Completion Queue Entry
      std::vector<uint32_t> ret;
      OculinkRespondWrite(ret);
      assert(ret.size() == 4); // CQE expected
      uint32_t cqe0 = ret[0];
      uint32_t cqe1 = ret[1];
      uint32_t sqid = (ret[2] >> 16) & 0xffff;
      uint32_t sqhd = ret[2] & 0xffff;
      uint32_t status = (ret[3] >> 17) & 0x7fff;
      uint32_t phase_tag = (ret[3] >> 16) & 0x1;
      uint32_t cid = ret[3] & 0xffff;
      spdlog::info("cqe0={}", cqe0);
      spdlog::info("cqe1={}", cqe1);
      spdlog::info("sqid={} sqhd={}", sqid, sqhd);
      spdlog::info("status={:015b} phase_tag={} cid={}", status, phase_tag, cid);
    }

    {
      // CC.IOCQES @ 23:20, CC.IOSQES @ 19:16
      uint32_t CC = OculinkReadNVMe(0x14);
      // Clear CC.IOCQES
      CC &= ~(0b1111 << 20);
      // Clear CC.IOSQES
      CC &= ~(0b1111 << 16);
      // Set CC.IOCQES to 4 (16B)
      CC |= max_cqes << 20;
      // Set CC.IOSQES to 6 (64B)
      CC |= max_sqes << 16;
      OculinkWriteNVMe(0x14, CC);
    }
  }
  //OculinkWriteNVMe(0x1004, ++cqhead);

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
  uint32_t CC = OculinkReadNVMe(0x14);
  spdlog::info("CC={:32b}", CC);
  OculinkWriteNVMe(0x1000, ++sqtail);
  {
    // Find active namespaces with CNS 02 -> we expect single namespace with NSID 1
    // Query namespace data structe with CNS 00 -> give NSID 1
    std::vector<uint32_t> data;
    uint32_t cid = 42; // unique identifier
    uint32_t psdt = 0; // PRP shall be used for all Admin command for NVMe over PCIe.
    uint32_t fuse = 0; // not fused
    uint32_t opcode = 0x06; // IDENTIFY command
    uint32_t cdw0 = (cid << 16) | (psdt << 14) | (fuse << 8) | opcode;
    uint32_t nsid = 1; // namespace identifier not used
    uint32_t cdw2 = 0; // TODO command specific
    uint32_t cdw3 = 0; // TODO command specific
    uint64_t mptr = 0; // TODO metadata pointer what is this???
    // prp1 and prp2 is dptr
    uint64_t prp1 = 2 * 1024 * 1024; // prp entry 1; we give dptr as 2MB
    uint64_t prp2 = 0; // prp entry 2
    uint32_t cdw10 = 0x00; // cntid == 0 (not used), cns = 00h
    uint32_t cdw11 = 0; // csi == 0 (NVM command set), CNS specific Identifier == 0 (not used)
    uint32_t cdw12 = 0;
    uint32_t cdw13 = 0;
    uint32_t cdw14 = 0; // uuid index == 0 (not used)
    uint32_t cdw15 = 0;

    data.push_back(cdw0);
    data.push_back(nsid);
    data.push_back(cdw2);
    data.push_back(cdw3); // 16B
    data.push_back(mptr);
    data.push_back(mptr >> 32);
    data.push_back(prp1);
    data.push_back(prp1 >> 32);
    data.push_back(prp2);
    data.push_back(prp2 >> 32); // 40B
    data.push_back(cdw10);
    data.push_back(cdw11);
    data.push_back(cdw12);
    data.push_back(cdw13);
    data.push_back(cdw14);
    data.push_back(cdw15); // 64B

    OculinkRespondRead(data);

    for (int i = 0; i < 32; ++i) { // 4KB expected; NVMe sends 32 txn with burst length 8 (32 * 8 * 16B = 4KB)
      std::vector<uint32_t> ret;
      OculinkRespondWrite(ret);
      assert(ret.size() == 32); // (32 * 32b = 128B per txn)
    }

    {
      // 3.3.3.2 Common Completion Queue Entry
      std::vector<uint32_t> ret;
      OculinkRespondWrite(ret);
      assert(ret.size() == 4); // CQE expected
      uint32_t cqe0 = ret[0];
      uint32_t cqe1 = ret[1];
      uint32_t sqid = (ret[2] >> 16) & 0xffff;
      uint32_t sqhd = ret[2] & 0xffff;
      uint32_t status = (ret[3] >> 17) & 0x7fff;
      uint32_t phase_tag = (ret[3] >> 16) & 0x1;
      uint32_t cid = ret[3] & 0xffff;
      spdlog::info("cqe0={}", cqe0);
      spdlog::info("cqe1={}", cqe1);
      spdlog::info("sqid={} sqhd={}", sqid, sqhd);
      spdlog::info("status={:015b} phase_tag={} cid={}", status, phase_tag, cid);
    }
  }
  return 0;
}
