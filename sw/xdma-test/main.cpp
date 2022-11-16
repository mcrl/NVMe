#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>

void* bar0base;

void SetData(size_t addr, uint32_t data) {
  if (addr % 4 != 0) {
    spdlog::warn("SetData skipped due to unaligned access (addr={}, data={})", addr, data);
  }
  volatile uint32_t* p = (uint32_t*)(bar0base + addr);
  *p = data;
}

uint32_t GetData(size_t addr) {
  if (addr % 4 != 0) {
    spdlog::warn("GetData skipped due to unaligned access (addr={})", addr);
  }
  volatile uint32_t* p = (uint32_t*)(bar0base + addr);
  return *p;
}

void AssertOcuReset() {
  SetData(0xc4, 0);
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

void DeassertOcuReset() {
  SetData(0xc0, 0);
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

uint32_t ReadOcu(size_t addr) {
  // Setup addr
  SetData(0x00, addr);
  SetData(0x04, addr >> 32);
  // Push to k2o_ar
  SetData(0x40, 0);
  // Wait for response in k2o_r
  while (true) {
    uint32_t valid = GetData(0x60);
    if (valid) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
  }
  // Pop from k2o_r
  SetData(0x64, 0);
  uint32_t rdata = GetData(0x00);
  uint32_t rresp = GetData(0x04) & 0b11;
  uint32_t rid = (GetData(0x04) >> 2) & 0b1111;
  spdlog::info("ReadOcu rdata={}, rresp={}, rid={}", rdata, rresp, rid);
  return rdata;
}

uint32_t ReadOcuECAM(int bus, int dev, int func, int offset) {
  size_t addr = (bus << 20) | (dev << 15) | (func << 12) | offset;
  return ReadOcu(addr);
}

void PrintPCIConfigSpaceHeader(int bus, int dev, int func) {
  spdlog::info("PCI Config Space Header of {:02X}:{:02X}.{:01X} (through ECAM)", bus, dev, func);
  for (int i = 0; i < 0x40; i += 4) {
    spdlog::info("{:02X} {:08X}", i, ReadOcuECAM(bus, dev, func, i));
  }
}

int main(int argc, char** argv) {
  const char* devname = "/dev/xdma0_user";
  int fd;
	if ((fd = open(argv[1], O_RDWR | O_SYNC)) == -1) {
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

  PrintPCIConfigSpaceHeader(0, 0, 0);

  return 0;
}
