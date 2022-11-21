#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>
#include <vector>

const size_t ecam_addr_base = 0x100000000UL;
void* bar0base;
size_t nvme_bar0;

void KernelWrite(size_t addr, uint32_t data) {
  if (addr % 4 != 0) {
    spdlog::warn("KernelWrite skipped due to unaligned access (addr={}, data={})", addr, data);
    exit(0);
  }
  volatile uint32_t* p = (uint32_t*)((size_t)bar0base + addr);
  *p = data;
}

uint32_t KernelRead(size_t addr) {
  if (addr % 4 != 0) {
    spdlog::warn("KernelRead skipped due to unaligned access (addr={})", addr);
    exit(0);
  }
  volatile uint32_t* p = (uint32_t*)((size_t)bar0base + addr);
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
  spdlog::info("o2k_aw entry found awaddr={},{} awsize={}, awlen={}, awid={}", awaddr1, awaddr0, awsize, awlen, awid);

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
    spdlog::info("o2k_w entry found wdata={},{},{},{}, wstrb={}", wdata3, wdata2, wdata1, wdata0, wstrb);
  }

  // o2k_b
  uint32_t bid = awid;
  KernelWrite(0x00, bid);
  KernelWrite(0xa0, 0);
  spdlog::info("OculinkRespondWrite bid={}", bid);
}

void OculinkRespondRead() {
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

  // o2k_r
  for (int i = 0; i <= arlen; ++i) {
    uint32_t rdata0 = 0xdeadbeef;
    uint32_t rdata1 = 0xdebdbeef;
    uint32_t rdata2 = 0xdecdbeef;
    uint32_t rdata3 = 0xdeddbeef;
    uint32_t rlast = i == arlen;
    uint32_t rid = arid;
    KernelWrite(0x00, rdata0);
    KernelWrite(0x04, rdata1);
    KernelWrite(0x08, rdata2);
    KernelWrite(0x0c, rdata3);
    KernelWrite(0x10, (rid << 1) | rlast);
    KernelWrite(0xb0, 0);
    spdlog::info("OculinkRespondRead rdata={},{},{},{}, rlast={}, rid={}", rdata3, rdata2, rdata1, rdata0, rlast, rid);
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
  const char* devname = "/dev/xdma0_user";
  int fd;
	if ((fd = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} opened failed: {}.", devname, strerror(errno));
    return 0;
	}
	spdlog::info("character device {} opened. fd={}", devname, fd);

  size_t bar0sz = 1024 * 1024; // 1MB
	bar0base = mmap(NULL, bar0sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (bar0base == (void *)-1) {
    spdlog::info("mmap failed: {}", strerror(errno));
    close(fd);
    return 0;
	}
  spdlog::info("mmap done. bar0base={}", bar0base);

  AssertOcuReset();
  DeassertOcuReset();

  while (!CheckAllQueueIsEmpty());

  // Set secondary bus number
  OculinkWriteECAM(0, 0, 0, 0x18, 0x00010100);
  // Enable interrupt
  //OculinkWriteECAM(0, 0, 0, 0x13c, 0xffffffff);
  // Enable Memory Space and BusMaster
  //OculinkWriteECAM(0, 0, 0, 0x04, 0x00000006); // rq-rc
  //PrintPCIConfigSpaceHeader(0, 0, 0);
  //PrintPCIConfigSpaceHeader(1, 0, 0);

  while (OculinkReadECAM(1, 0, 0, 0x00) == 0xFFFFFFFF);
  spdlog::info("NVMe found on 01:00.0");

  //// Enable Memory Space and BusMaster
  OculinkWriteECAM(1, 0, 0, 0x04, 0x00000006); // rq-rc

  CheckAllQueueIsEmpty();

  OculinkWriteECAM(1, 0, 0, 0x10, 0xffffffff); // rq-rc
  size_t bar_size = OculinkReadECAM(1, 0, 0, 0x10); // rq-rc
  if (bar_size == 0) {
    spdlog::info("bar_size==0 something wrong");
    exit(0);
  }
  bar_size &= 0xfffffff0;
  size_t cnt0 = 0;
  while ((bar_size & 1) == 0) {
  spdlog::info("bar_size={} cnt0={}", bar_size, cnt0);
    ++cnt0;
    bar_size >>= 1;
  }
  bar_size = 1 << cnt0;
  spdlog::info("Detected bar_size = {}", bar_size);
  //// Assign NVMe's BAR0 (64-bit) to 4GB offset
  nvme_bar0 = 0x00004000;
  OculinkWriteECAM(1, 0, 0, 0x10, nvme_bar0); // rq-rc
  OculinkWriteECAM(1, 0, 0, 0x14, 0x00000000); // rq-rc

  //// Enum done, Bridge Enable
  OculinkWriteECAM(0, 0, 0, 0x148, 0x00000001);

  PrintPCIConfigSpaceHeader(0, 0, 0);
  //PrintPCIConfigSpaceHeader(1, 0, 0);



  // CAP 0x0
  // CC  0x14
  // AQA 0x24
  // ASQ 0x28
  // ACQ 0x30

  OculinkWriteNVMe(0x14, 0x00000000); // CC.EN = 0
  while (OculinkReadNVMe(0x1c) != 0); // wait CSTS.RDY to be 0

  size_t sq_len = 16;
  size_t sq_nbytes = sq_len * 64; // one queue entry is 64-byte
  size_t cq_len = 16;
  size_t cq_nbytes = cq_len * 64;
  // memory layout : | BAR (bar_size) | ASQ (sq_nbytes) | ACQ (cq_nbytes) |
  OculinkWriteNVMe(0x24, (cq_len << 16) | sq_len); // AQA set (CQ size, SQ size)
  OculinkWriteNVMe(0x28, bar_size); // ASQ low adddr
  OculinkWriteNVMe(0x2c, 0x00000000); // ASQ high addr
  OculinkWriteNVMe(0x30, bar_size + sq_nbytes); // ACQ low adddr
  OculinkWriteNVMe(0x34, 0x00000000); // ASQ high addr

  CheckAllQueueIsEmpty();

  OculinkReadNVMe(0x24);
  OculinkReadNVMe(0x28);
  OculinkReadNVMe(0x2c);
  OculinkReadNVMe(0x30);
  OculinkReadNVMe(0x34);

  CheckAllQueueIsEmpty();

  OculinkWriteNVMe(0x14, 0x00000001); // CC.EN = 1
  while (OculinkReadNVMe(0x1c) != 1) { // wait CSTS.RDY to be 1
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }

  OculinkWriteNVMe(0x1000, 0x00000001); // ASQTDBL <- 1
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
  CheckAllQueueIsEmpty();

  return 0;
}
