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
  spdlog::info("[RC] OculinkRead  addr=0x{:08X}, rdata=0x{:08X} -> rresp={}, rid={}", addr, rdata, rresp, rid);
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
  spdlog::info("[RQ] OculinkWrite addr=0x{:08X}, wdata=0x{:08X} -> bresp={}, bid={}", addr, data, bresp, bid);
}

void OculinkRespondWrite() {
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
  spdlog::info("[CQ] o2k_aw entry found awaddr={:08X},{:08X} awsize={}, awlen={}, awid={}", awaddr1, awaddr0, awsize, awlen, awid);

  // o2k_w
  for (int i = 0; i <= awlen; ++i) {
    while (true) {
      uint32_t valid = KernelRead(0x80);
      if (valid) break;
      std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    KernelWrite(0x84, 0);
    uint32_t wdata0 = KernelRead(0x00);
    uint32_t wdata1 = KernelRead(0x04);
    uint32_t wdata2 = KernelRead(0x08);
    uint32_t wdata3 = KernelRead(0x0c);
    uint32_t wstrb = KernelRead(0x10) & 0xffff;
    spdlog::info("[CQ] o2k_w entry found wdata={:08X},{:08X},{:08X},{:08X}, wstrb={}", wdata3, wdata2, wdata1, wdata0, wstrb);
  }

  // o2k_b
  uint32_t bid = awid;
  KernelWrite(0x00, bid);
  KernelWrite(0xa0, 0);
  spdlog::info("[CQ] OculinkRespondWrite bid={}", bid);
}

static uint32_t cntt = 0x0;

static uint32_t identify_cmd[16] = {
                      0x00000000, // DW15 (CDW15)
                      0x00000000, // DW14 (CDW14, UUID Index)
                      0x00000000, // DW13 (CDW13)
                      0x00000000, // DW12 (CDW12)
                      0x00000000, // DW11 (CDW11, CSI, CNS Specific ID)
                      0x00000001, // DW10 (CDW10)
                      0x00000000, // DW9  (DPTR3)
                      0x00000000, // DW8  (DPTR2)
                      0x00000000, // DW7  (DPTR1) PRP Entry 2
                      0x0000B000, // DW6  (DPTR0) PRP Entry 1
                      0x00000000, // DW5  (MPTR1)
                      0x00000000, // DW4  (MPTR0) 
                      0x00000000, // DW3  (CDW3)
                      0x00000000, // DW2  (CDW2) 
                      0x00000000, // DW1  (NSID)
                      0x00000006  // DW0  (CDW0)
                    };

static uint32_t set_features_cmd[16] = {
                      0x00000000, // DW15 (CDW15)
                      0x00000000, // DW14 (CDW14, UUID Index)
                      0x00000000, // DW13 (CDW13)
                      0x00000000, // DW12 (CDW12)
                      0x00010001, // DW11 (CDW11, CSI, CNS Specific ID)
                      0x00000007, // DW10 (CDW10)
                      0x00000000, // DW9  (DPTR3)
                      0x00000000, // DW8  (DPTR2)
                      0x00000000, // DW7  (DPTR1) PRP Entry 2
                      0x00000000, // DW6  (DPTR0) PRP Entry 1
                      0x00000000, // DW5  (MPTR1)
                      0x00000000, // DW4  (MPTR0) 
                      0x00000000, // DW3  (CDW3)
                      0x00000000, // DW2  (CDW2) 
                      0x00000000, // DW1  (NSID)
                      0x00000009  // DW0  (CDW0)
                    };


static uint32_t iocq_create_cmd[16] = {
                      0x00000000, // DW15 (CDW15)
                      0x00000000, // DW14 (CDW14, UUID Index)
                      0x00000000, // DW13 (CDW13)
                      0x00000000, // DW12 (CDW12)
                      0x00000001, // DW11 (CDW11)
                      0x00100001, // DW10 (CDW10) QID=1, Qsize 0x10
                      0x00000000, // DW9  (DPTR3)
                      0x00000000, // DW8  (DPTR2)
                      0x00000000, // DW7  (DPTR1) PRP Entry 2
                      0x0000A000, // DW6  (DPTR0) PRP Entry 1
                      0x00000000, // DW5  (MPTR1)
                      0x00000000, // DW4  (MPTR0) 
                      0x00000000, // DW3  (CDW3)
                      0x00000000, // DW2  (CDW2) 
                      0x00000000, // DW1  (NSID)
                      0x00000005  // DW0  (CDW0)
                    };

static uint32_t iosq_create_cmd[16] = {
                      0x00000000, // DW15 (CDW15)
                      0x00000000, // DW14 (CDW14, UUID Index)
                      0x00000000, // DW13 (CDW13)
                      0x00000000, // DW12 (CDW12)
                      0x00010001, // DW11 (CDW11), CQID=1
                      0x00100001, // DW10 (CDW10), QID=1, Qsize 0x10
                      0x00000000, // DW9  (DPTR3)
                      0x00000000, // DW8  (DPTR2)
                      0x00000000, // DW7  (DPTR1) PRP Entry 2
                      0x0000B000, // DW6  (DPTR0) PRP Entry 1
                      0x00000000, // DW5  (MPTR1)
                      0x00000000, // DW4  (MPTR0) 
                      0x00000000, // DW3  (CDW3)
                      0x00000000, // DW2  (CDW2) 
                      0x00000000, // DW1  (NSID)
                      0x00000001  // DW0  (CDW0)
                    };

static uint32_t io_write_cmd[16] = {
                      0x00000000, // DW15 (CDW15)
                      0x00000000, // DW14 (CDW14, UUID Index)
                      0x00000000, // DW13 (CDW13)
                      0x00000000, // DW12 (CDW12)
                      0x00000000, // DW11 (CDW11)
                      0x00001000, // DW10 (CDW10)
                      0x00000000, // DW9  (DPTR3)
                      0x00000000, // DW8  (DPTR2)
                      0x00000000, // DW7  (DPTR1) PRP Entry 2
                      0x0000C000, // DW6  (DPTR0) PRP Entry 1
                      0x0000D000, // DW5  (MPTR1)
                      0x00000000, // DW4  (MPTR0) 
                      0x00000000, // DW3  (CDW3)
                      0x00000000, // DW2  (CDW2) 
                      0x00000001, // DW1  (NSID)
                      0x00000001  // DW0  (CDW0)
                    };

static uint32_t io_read_cmd[16] = {
                      0x00000000, // DW15 (CDW15)
                      0x00000000, // DW14 (CDW14, UUID Index)
                      0x00000000, // DW13 (CDW13)
                      0x00000000, // DW12 (CDW12)
                      0x00000000, // DW11 (CDW11)
                      0x00001000, // DW10 (CDW10)
                      0x00000000, // DW9  (DPTR3)
                      0x00000000, // DW8  (DPTR2)
                      0x00000000, // DW7  (DPTR1) PRP Entry 2
                      0x0000C000, // DW6  (DPTR0) PRP Entry 1
                      0x00000000, // DW5  (MPTR1)
                      0x00000000, // DW4  (MPTR0) 
                      0x00000000, // DW3  (CDW3)
                      0x00000000, // DW2  (CDW2) 
                      0x00000001, // DW1  (NSID)
                      0x00000002  // DW0  (CDW0)
                    };




void OculinkRespondRead(uint32_t *sqe) {
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
  spdlog::info("[CQ] o2k_ar araddr={:08X},{:08X} arsize={}, arlen={}, arid={}", araddr1, araddr0, arsize, arlen, arid);



  // o2k_r
  for (int i = 0; i <= arlen; ++i) {
    uint32_t rdata0 = sqe[15-(i*4+0)];
    uint32_t rdata1 = sqe[15-(i*4+1)]; 
    uint32_t rdata2 = sqe[15-(i*4+2)]; 
    uint32_t rdata3 = sqe[15-(i*4+3)]; 
    uint32_t rlast = i == arlen;
    uint32_t rid = arid;
    KernelWrite(0x00, rdata0);              
    KernelWrite(0x04, rdata1);
    KernelWrite(0x08, rdata2);
    KernelWrite(0x0c, rdata3);
    KernelWrite(0x10, (rid << 1) | rlast);  // rlast
    KernelWrite(0xb0, 0);                   // push 
    spdlog::info("[CC] OculinkRespondRead rdata={:08X},{:08X},{:08X},{:08X}, rlast={}, rid={}", rdata3, rdata2, rdata1, rdata0, rlast, rid);
  }
  
}

uint32_t count=0;
void OculinkRespondIOWrite() {
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
  spdlog::info("[CQ] o2k_ar araddr={:08X},{:08X} arsize={}, arlen={}, arid={}", araddr1, araddr0, arsize, arlen, arid);



  size_t addr = ((size_t)araddr1 << 32) + araddr0;

  // 1 << arsize is bytes in transfer (single beat in a burst)
  assert((1 << arsize) % sizeof(uint32_t) == 0);
  assert(addr % (1 << arsize) == 0);
  assert((1 << arsize) * (arlen + 1) / sizeof(uint32_t) == data.size());

  // o2k_r
  int addr_idx = addr % 16 / 4;
  int data_idx = 0;
  for (int i = 0; i <= arlen; ++i) {
    uint32_t rdata0 = count++;
    uint32_t rdata1 = count++; 
    uint32_t rdata2 = count++; 
    uint32_t rdata3 = count++; 
    uint32_t rlast = i == arlen;
    uint32_t rid = arid;
    KernelWrite(0x00, rdata0);              
    KernelWrite(0x04, rdata1);
    KernelWrite(0x08, rdata2);
    KernelWrite(0x0c, rdata3);
    KernelWrite(0x10, (rid << 1) | rlast);  // rlast
    KernelWrite(0xb0, 0);                   // push 
    spdlog::info("[CC] OculinkRespondRead rdata={:08X},{:08X},{:08X},{:08X}, rlast={}, rid={}", rdata3, rdata2, rdata1, rdata0, rlast, rid);
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
    spdlog::info("o2k_aw is not empty!!! awaddr={:08X},{:08X} awsize={}, awlen={}, awid={}", awaddr1, awaddr0, awsize, awlen, awid);
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
    spdlog::info("o2k_w is not empty!!! wdata={:08X},{:08X},{:08X},{:08X}, wstrb={}", wdata3, wdata2, wdata1, wdata0, wstrb);
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
    spdlog::info("o2k_ar is not empty!!! araddr={:08X},{:08x} arsize={}, arlen={}, arid={}", araddr1, araddr0, arsize, arlen, arid);
    return false;
  }
  spdlog::info("All queue is empty");
  return true;
}


size_t ECAMAddress(int bus, int dev, int func) {
  return (bus << 20) | (dev << 15) | (func << 12);
}

uint32_t OculinkReadECAM(int bus, int dev, int func, int offset) {
  return OculinkRead32(ecam_addr_base + ECAMAddress(bus, dev, func) + offset);
}

uint32_t OculinkReadNVMe(int offset) {
  return OculinkRead32(nvme_bar0 + offset);
}

void OculinkWriteECAM(int bus, int dev, int func, int offset, uint32_t data) {
  OculinkWrite32(ecam_addr_base + ECAMAddress(bus, dev, func) + offset, data);
}

void OculinkWriteNVMe(int offset, uint32_t data) {
  OculinkWrite32(nvme_bar0 + offset, data);
}

void PrintPCIConfigSpaceHeader(int bus, int dev, int func) {
  spdlog::info("PCI Config Space Header of {:02X}:{:02X}.{:01X} (through ECAM)", bus, dev, func);
  for (int i = 0; i < 0x40; i += 4) {
    OculinkReadECAM(bus, dev, func, i);
//    spdlog::info("{:02X} {:08X}", i, OculinkReadECAM(bus, dev, func, i));
  }
}

int main(int argc, char** argv) {
 
  spdlog::info("[SYS] Start bus enumeration");
  // open device
  const char* devname = "/dev/xdma0_user";
  int fd;
	if ((fd = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} opened failed: {}.", devname, strerror(errno));
    return 0;
	}
	spdlog::info("[SYS] Device {} opened. fd={}", devname, fd);

  
  size_t bar0sz = 1024 * 1024; // 1MB
	bar0base = mmap(NULL, bar0sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (bar0base == (void *)-1) {
    spdlog::info("[2] mmap failed: {}", strerror(errno));
    close(fd);
    return 0;
	}
  spdlog::info("[SYS] mmap done. bar0base={}", bar0base);

  AssertOcuReset();
  DeassertOcuReset();
  spdlog::info("[SYS] Reset done.");

  // TODO should be replaced with kernel reset
  while (!CheckAllQueueIsEmpty());
  spdlog::info("[SYS] All queue is empty.");

  // Set secondary bus number
  OculinkWriteECAM(0, 0, 0, 0x18, 0x00010100);

  while (OculinkReadECAM(1, 0, 0, 0x00) == 0xFFFFFFFF);
  spdlog::info("[SYS] NVMe found on 01:00.0");

  // Enable Memory Space and BusMaster
  OculinkWriteECAM(1, 0, 0, 0x04, 0x00000006); // rq-rc

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
  bar_size &= 0xfffffff0;
  size_t cnt0 = 0;
  while ((bar_size & 1) == 0) {
    //spdlog::info("bar_size={} cnt0={}", bar_size, cnt0);
    ++cnt0;
    bar_size >>= 1;
  }
  bar_size = 1 << cnt0;
  spdlog::info("[SYS] Detected bar_size = 0x{:08X}", bar_size);
  
  //// Assign NVMe's BAR0 (64-bit) to 4GB offset
  nvme_bar0 = 0x00004000;
  OculinkWriteECAM(1, 0, 0, 0x10, nvme_bar0); // rq-rc
  OculinkWriteECAM(1, 0, 0, 0x14, 0x00000000); // rq-rc

  //// Enum done, Bridge Enable
  OculinkWriteECAM(0, 0, 0, 0x148, 0x00000001);

  PrintPCIConfigSpaceHeader(0, 0, 0);
  PrintPCIConfigSpaceHeader(1, 0, 0);

/*

  // CAP 0x0
  // CC  0x14
  // AQA 0x24
  // ASQ 0x28
  // ACQ 0x30

  OculinkWriteNVMe(0x14, 0x00000000); // CC.EN = 0
  while (OculinkReadNVMe(0x1c) != 0); // wait CSTS.RDY to be 0

  size_t sq_len = 64;
  size_t sq_nbytes = sq_len * 64; // one queue entry is 64-byte
  size_t cq_len = 64;
  size_t cq_nbytes = cq_len * 64;
 
  spdlog::info("[SYS] set Admission Queue base addr & its size");
  
  // memory layout : | BAR (bar_size) | ASQ (sq_nbytes) | ACQ (cq_nbytes)
  //                0x4000          0x8000           0x9000             0xA000
  //
  //                 | IOCQ 1 | IOSQ 1 | Memory spaces~ 
  //                0xA000  0xB000    0xC000
  //
  //OculinkReadNVMe(0x00);    // CAP
  //OculinkReadNVMe(0x04);    // CAP

  OculinkWriteNVMe(0x24, (cq_len << 16) | sq_len);  // AQA set (CQ size, SQ size)
  OculinkWriteNVMe(0x28, nvme_bar0 + bar_size);    // ASQ low adddr
  OculinkWriteNVMe(0x2c, 0x00000000);               // ASQ high addr
  OculinkWriteNVMe(0x30, nvme_bar0 + bar_size + sq_nbytes);     // ACQ low adddr
  OculinkWriteNVMe(0x34, 0x00000000);               // ASQ high addr

  CheckAllQueueIsEmpty();

  spdlog::info("[SYS] check whether ASQ and ACQ is set correctly");
  OculinkReadNVMe(0x24);
  OculinkReadNVMe(0x28);
  OculinkReadNVMe(0x2c);
  OculinkReadNVMe(0x30);
  OculinkReadNVMe(0x34);

  CheckAllQueueIsEmpty();


  spdlog::info("[SYS] wait until all settings are done");
  OculinkWriteNVMe(0x14, 0x00000001); // CC.EN = 1
  while (OculinkReadNVMe(0x1c) != 1) { // wait CSTS.RDY to be 1
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  /*
   * 7. The host determines the configuration of the controller by issuing the Identify command specifying
   * the Identify Controller data structure (i.e., CNS 01h);
   */
  
  spdlog::info("[RQ] Write ASQTDBL (ASQ Tail Doorbell)");
  OculinkWriteNVMe(0x1000, 0x00000001); // ASQTDBL <- 1
  OculinkRespondRead(identify_cmd);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x80)) OculinkRespondWrite();

  /*
   * 9. If the controller implements I/O queues, then the host should
   * determine the number of I/O Submission Queues and I/O Completion Queues
   * supported using the Set Features command with the Number of Queues
   * feature identifier. After determining the number of I/O Queues, the NVMe
   * Transport specific interrupt registers (e.g. MSI and/or MSI-X registers)
   * should be configured;
   */

  spdlog::info("[RQ] Write ASQTDBL (ASQ Tail Doorbell)");
  OculinkWriteNVMe(0x1000, 0x00000002); // ASQTDBL <- 1
  OculinkRespondRead(set_features_cmd);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x80)) OculinkRespondWrite();

  /*
   * 10. If the controller implements I/O queues, then the host should allocate
   * the appropriate number of I/O Completion Queues based on the number
   * required for the system configuration and the number supported by the
   * controller. The I/O Completion Queues are allocated using the Create I/O
   * Completion Queue command;
   */
  
  spdlog::info("[RQ] Write ASQTDBL (ASQ Tail Doorbell)");
  OculinkWriteNVMe(0x1000, 0x00000003); // ASQTDBL 
  OculinkRespondRead(iocq_create_cmd);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x80)) OculinkRespondWrite();

  /*
   * 11. If the controller implements I/O queues, then the host should allocate
   * the appropriate number of I/O Submission Queues based on the number
   * required for the system configuration and the number supported by the
   * controller. The I/O Submission Queues are allocated using the Create I/O
   * Submission Queue command;
   */

  spdlog::info("[RQ] Write ASQTDBL (ASQ Tail Doorbell)");
  OculinkWriteNVMe(0x1000, 0x00000004); // ASQTDBL 
  OculinkRespondRead(iosq_create_cmd);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x80)) OculinkRespondWrite();

  /*
   * Write Data
   */
  
  spdlog::info("[RQ] Write IOSQTDBL1 (IOSQ Tail Doorbell)");
  OculinkWriteNVMe(0x1008, 0x00000001); // ASQTDBL  
  OculinkRespondRead(io_write_cmd);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x90)) OculinkRespondIOWrite();
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x80)) OculinkRespondWrite();

  /*
   * Read Data
   */
  
  spdlog::info("[RQ] Write IOSQTDBL1 (IOSQ Tail Doorbell)");
  OculinkWriteNVMe(0x1008, 0x00000002); // ASQTDBL  
  OculinkRespondRead(io_read_cmd);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  while(KernelRead(0x80)) OculinkRespondWrite();


  return 0;
  */
}
