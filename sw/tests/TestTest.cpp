#include <cstdio>
#include <chrono>
#include <sys/mman.h>
#include <unistd.h>
#include <spdlog/spdlog.h>
#include <vector>

void* vaddr;

uint32_t Read32(size_t offset) {
  return *(volatile uint32_t*)((size_t)vaddr + offset);
}

void Write32(size_t offset, uint32_t val) {
  *(volatile uint32_t*)((size_t)vaddr + offset) = val;
}

void BringUpEth(size_t eth) {
  spdlog::info("Bring up eth @ 0x{:X}", eth);
  Write32(eth + 0x014, 0x1); // ctl_rx_enable
  Write32(eth + 0x00C, 0x10); // ctl_tx_send_rfi

  while (true) {
    uint32_t tx_status = Read32(eth + 0x200);
    uint32_t rx_status = Read32(eth + 0x204);
    spdlog::info("tx_status = 0b{:032b}", tx_status);
    spdlog::info("rx_status = 0b{:032b}", rx_status);
    if (rx_status & 0b10) break;
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
  }
  
  Write32(eth + 0x00C, 0x1); // ctl_tx_enable to 1, ctl_tx_send_rfi to 0

  Write32(eth + 0x084, 0x00003DFF);
  Write32(eth + 0x088, 0x0001C631);
  Write32(eth + 0x048, 0xFFFFFFFF);
  Write32(eth + 0x04C, 0xFFFFFFFF);
  Write32(eth + 0x050, 0xFFFFFFFF);
  Write32(eth + 0x054, 0xFFFFFFFF);
  Write32(eth + 0x058, 0x0000FFFF);
  Write32(eth + 0x034, 0xFFFFFFFF);
  Write32(eth + 0x038, 0xFFFFFFFF);
  Write32(eth + 0x03C, 0xFFFFFFFF);
  Write32(eth + 0x040, 0xFFFFFFFF);
  Write32(eth + 0x044, 0x0000FFFF);
  Write32(eth + 0x030, 0x000001FF);
}

void PrintEthStatus(size_t eth) {
  spdlog::info("Eth status @ 0x{:X}", eth);
  uint32_t tx_status = Read32(eth + 0x200);
  uint32_t rx_status = Read32(eth + 0x204);
  spdlog::info("tx_status = 0b{:032b}", tx_status);
  spdlog::info("rx_status = 0b{:032b}", rx_status);
}

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
	vaddr = mmap(NULL, mmio_sz, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (vaddr == (void *)-1) {
    spdlog::info("mmap failed: {}", strerror(errno));
    close(fd);
    exit(0);
	}
  spdlog::info("mmap done. vaddr={}, sz={}", vaddr, mmio_sz);

  size_t eth0 = 0x200000;
  size_t eth1 = 0x400000;
  BringUpEth(eth0);
  BringUpEth(eth1);

  PrintEthStatus(eth0);
  PrintEthStatus(eth1);
  std::this_thread::sleep_for(std::chrono::milliseconds(1000));

  Write32(0, 0xDEADBEEF);

  PrintEthStatus(eth0);
  PrintEthStatus(eth1);
  std::this_thread::sleep_for(std::chrono::milliseconds(1000));

  //size_t offset = 0x00c00000;
  //size_t offset = 0x00000000;
  //vaddr = (void*)((size_t)vaddr + offset);

  ////for (size_t i = 0; i < 128; i += 16) {
  ////  //*(volatile uint64_t*)((size_t)vaddr + (i + 8)) = ((i + 12) << 32) + (i + 8);
  ////  //*(volatile uint64_t*)((size_t)vaddr + i) = ((i + 4) << 32) + i;

  ////  *(volatile uint32_t*)((size_t)vaddr + i) = i; // erase rest 3
  ////  *(volatile uint32_t*)((size_t)vaddr + (i + 4)) = i + 4;
  ////  *(volatile uint32_t*)((size_t)vaddr + (i + 8)) = i + 8;
  ////  *(volatile uint32_t*)((size_t)vaddr + (i + 12)) = i + 12;
  ////}

  ////for (int i = 0; i < 128; i += 4) {
  ////  uint32_t val = *(volatile uint32_t*)((size_t)vaddr + i);
  ////  spdlog::info("i={:X} val={:X}", i, val);
  ////}

  //// Leak test
  //size_t o = 0x00400000;
  //srand(time(NULL));
  //uint32_t v = rand();
  //spdlog::info("v={}", v);
  //*(volatile uint32_t*)((size_t)vaddr + o + 0) = v; // erase rest 3
  //uint32_t r;
  //r = *(volatile uint32_t*)((size_t)vaddr + o);
  //spdlog::info("r={}", r);
  //r = *(volatile uint32_t*)((size_t)vaddr + o);
  //spdlog::info("r={}", r);

  return 0;
}