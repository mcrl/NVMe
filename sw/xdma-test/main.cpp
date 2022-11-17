#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>
#include <vector>

void* bar0base;

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
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

void DeassertOcuReset() {
  KernelWrite(0xc4, 0);
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
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
  uint32_t rdata = KernelRead(0x00);
  uint32_t rresp = KernelRead(0x10) & 0b11;
  uint32_t rid = (KernelRead(0x10) >> 2) & 0b1111;
  spdlog::info("OculinkRead addr={} -> rdata={}, rresp={}, rid={}", addr, rdata, rresp, rid);
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
  KernelWrite(0x10, 0xffffffff);
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
  spdlog::info("OculinkWrite addr={}, data={} -> bresp={}, bid={}", addr, data, bresp, bid);
}

size_t ECAMAddress(int bus, int dev, int func) {
  return (bus << 20) | (dev << 15) | (func << 12);
}

uint32_t OculinkReadECAM(int bus, int dev, int func, int offset) {
  return OculinkRead32(0x100000000UL + ECAMAddress(bus, dev, func) + offset);
}

uint32_t OculinkReadNVMe(int offset) {
  return OculinkRead32(offset);
}

void OculinkWriteECAM(int bus, int dev, int func, int offset, uint32_t data) {
  OculinkWrite32(0x100000000UL + ECAMAddress(bus, dev, func) + offset, data);
}

void OculinkWriteNVMe(int offset, uint32_t data) {
  OculinkWrite32(offset, data);
}

void PrintPCIConfigSpaceHeader(int bus, int dev, int func) {
  spdlog::info("PCI Config Space Header of {:02X}:{:02X}.{:01X} (through ECAM)", bus, dev, func);
  for (int i = 0; i < 0x240; i += 4) {
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
  // Set secondary bus number
  OculinkWriteECAM(0, 0, 0, 0x18, 0x00010100);
  // Enable interrupt
  OculinkWriteECAM(0, 0, 0, 0x13c, 0xffffffff);
  // Enable Memory Space and BusMaster
  OculinkWriteECAM(0, 0, 0, 0x04, 0x00000006); // rq-rc
  //PrintPCIConfigSpaceHeader(0, 0, 0);
  //PrintPCIConfigSpaceHeader(1, 0, 0);

  //// Enable Memory Space and BusMaster
  OculinkWriteECAM(1, 0, 0, 0x04, 0x00000006); // rq-rc
  //// Assign NVMe's BAR0 (64-bit) to 4GB offset
  OculinkWriteECAM(1, 0, 0, 0x10, 0x00000000); // rq-rc
  OculinkWriteECAM(1, 0, 0, 0x14, 0x00000001); // rq-rc

  //// Enum done, Bridge Enable
  OculinkWriteECAM(0, 0, 0, 0x148, 0x00000001);

  //PrintPCIConfigSpaceHeader(1, 0, 0);

  OculinkReadNVMe(0); // rq-rc
  OculinkReadNVMe(0); // rq-rc
  OculinkReadNVMe(0); // rq-rc
  OculinkReadNVMe(0); // rq-rc
  OculinkReadNVMe(0); // rq-rc
  PrintPCIConfigSpaceHeader(0, 0, 0);

  return 0;
}
