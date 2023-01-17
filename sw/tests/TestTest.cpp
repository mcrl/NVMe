#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>
#include <vector>

int main() {
  int devnum = 0;
  char devname[64];
  snprintf(devname, sizeof(devname), "/dev/xdma%d_bypass", devnum);
  int fd;
	if ((fd = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} open failed: {}.", devname, strerror(errno));
    exit(0);
	}
	spdlog::info("character device {} opened. fd={}", devname, fd);

  size_t mmio_sz = 64UL * 1024 * 1024 * 1024; // 64GB
	void* vaddr = mmap(NULL, mmio_sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (vaddr == (void *)-1) {
    spdlog::info("mmap failed: {}", strerror(errno));
    close(fd);
    exit(0);
	}
  spdlog::info("mmap done. vaddr={}, sz={}", vaddr, mmio_sz);

  //size_t offset = 0x00c00000;
  size_t offset = 0x00000000;
  vaddr = (void*)((size_t)vaddr + offset);

  //for (size_t i = 0; i < 128; i += 16) {
  //  //*(volatile uint64_t*)((size_t)vaddr + (i + 8)) = ((i + 12) << 32) + (i + 8);
  //  //*(volatile uint64_t*)((size_t)vaddr + i) = ((i + 4) << 32) + i;

  //  *(volatile uint32_t*)((size_t)vaddr + i) = i; // erase rest 3
  //  *(volatile uint32_t*)((size_t)vaddr + (i + 4)) = i + 4;
  //  *(volatile uint32_t*)((size_t)vaddr + (i + 8)) = i + 8;
  //  *(volatile uint32_t*)((size_t)vaddr + (i + 12)) = i + 12;
  //}

  //for (int i = 0; i < 128; i += 4) {
  //  uint32_t val = *(volatile uint32_t*)((size_t)vaddr + i);
  //  spdlog::info("i={:X} val={:X}", i, val);
  //}

  // Leak test
  size_t o = 0x00400000;
  srand(time(NULL));
  uint32_t v = rand();
  spdlog::info("v={}", v);
  *(volatile uint32_t*)((size_t)vaddr + o + 0) = v; // erase rest 3
  uint32_t r;
  r = *(volatile uint32_t*)((size_t)vaddr + o);
  spdlog::info("r={}", r);
  r = *(volatile uint32_t*)((size_t)vaddr + o);
  spdlog::info("r={}", r);

  return 0;
}