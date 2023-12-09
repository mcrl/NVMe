#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <spdlog/spdlog.h>
#include <spdlog/stopwatch.h>
#include <stdlib.h>

using namespace spdlog;

#define BITTWARE_SOC_DEV "/dev/xdma1_user"
#define SCRATCH_REG   0x0000

void *soc_addr = NULL;
uint32_t arid = 0;
uint32_t awid = 0;

int open_fpga(const char *dev) {
  int fd = 0;
  fd = open(dev, O_RDWR);
  if (fd < 0) info("failed to open FPGA with errno {}", errno);
  else info("success to open FPGA. fd : {}", fd);
  return fd;
}

void* Mmap(int fd) {
  void *addr = mmap(NULL, 64*1024, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (addr == NULL) info("failed to mmap with errno {}", errno);
  else info("success to mmap FPGA. addr : {}", addr);
  return addr;
}

uint32_t write_csr(void *fpga_addr, uint32_t wrdata, uint32_t offset) {
  volatile uint32_t *w = (uint32_t*)((size_t)fpga_addr + offset);
  *w = wrdata;
	return *w;
}

uint32_t read_csr(void *fpga_addr, uint32_t offset) {
  uint32_t rddata = *(uint32_t*)((size_t)fpga_addr + offset);
  return rddata;
}

void sw_reset(){
	info("SW Reset!");
	write_csr(soc_addr, 1, 0x04);
  sleep(1);
	write_csr(soc_addr, 0, 0x04);
}


uint32_t read_cfg(uint32_t addr){
  write_csr(soc_addr, addr, 0x24);  // araddr
  write_csr(soc_addr, 1, 0x20);     // trigger read cfg
  
  // wait until read cfg done
  while(read_csr(soc_addr, 0x2C) == 0);
  uint32_t rddata = read_csr(soc_addr, 0x28); // rddata
  return rddata;
}

void write_cfg(uint32_t addr, uint32_t wdata) {
  write_csr(soc_addr, addr, 0x14);  // awaddr
  write_csr(soc_addr, wdata, 0x18); // wdata
  write_csr(soc_addr, 1, 0x10);     // trigger write cfg
  // wait until write cfg done
  while(read_csr(soc_addr, 0x1C) == 0);
  //info("write cfg : {:08X}, addr : {:08X}", wdata, addr);
}

uint32_t read_nvme_cfg(uint32_t offset){
	return read_cfg(1<<20|offset);
}

void write_nvme_cfg(uint32_t offset, uint32_t wdata) {
	write_cfg(1<<20|offset, wdata);
}

uint32_t read_nvme_ctrl(uint32_t offset){
	return read_cfg(0x80000000|0x4000 + offset);
}

void write_nvme_ctrl(uint32_t offset, uint32_t wdata) {
	write_cfg(0x80000000|0x4000 + offset, wdata);
}


void setting_nvme_cfg_bar(){
	info("Setting NVMe Configuration BAR");
  write_csr(soc_addr, 0x0, 0x30);
  write_cfg(0x18, 0x00000100); //info("Set secondary bus number");
  read_cfg(0x18);
	read_cfg(1<<20|0x00); //info("find nvme controller bar");
	write_cfg(1<<20|0x04, 0x00000006); //info("enable bus master + memory space");
	read_cfg(1<<20|0x04);
	write_cfg(1<<20|0x10, 0x4000); //info("Write BAR");
	write_cfg(1<<20|0x14, 0x0000);
	write_cfg(0x148, 0x1); //info("Enum done, Bridge Enable");
	read_cfg(0x148);
  write_csr(soc_addr, 0x1, 0x30);
  info("DONE!");
}

// memory layout : | BAR (bar_size) | ASQ (sq_nbytes) | ACQ (cq_nbytes) |
//              0x4000          0x8000              0x9000           0xA000

void setting_nvme_controller(){
	info("Setting NVMe Controller Properties");
	
  write_csr(soc_addr, 0x0, 0x30);
  read_nvme_ctrl(0x00);	// CAP
	read_nvme_ctrl(0x04);	// CAP
	read_nvme_ctrl(0x08);	// Version == 1.3
	
	write_nvme_ctrl(0x14, 0x00); // CC.EN = 0
	while(read_nvme_ctrl(0x1C) != 0);	// wait CSTS.RDY to be 0
	
	size_t sq_len = 64;
  size_t sq_nbytes = sq_len * 64; // one queue entry is 64-byte
  size_t cq_len = 64;
  size_t cq_nbytes = cq_len * 64;

	// AQA set (CQ, SQ size)
	write_nvme_ctrl(0x24, (cq_len << 16) | sq_len);
	write_nvme_ctrl(0x28, 0x8000);	// ASQ low
	write_nvme_ctrl(0x2C, 0x00);		// ASQ  high
	write_nvme_ctrl(0x30, 0x8000 + sq_nbytes);	// ACQ low
	write_nvme_ctrl(0x34, 0x00);		// ACQ  high

	// wait until all settings are done
	write_nvme_ctrl(0x14, 0x1); // CC.EN = 1
  
	// wait until CSTS.RDY to be 1
	while(read_nvme_ctrl(0x1c) != 1);
  write_csr(soc_addr, 0x1, 0x30);
  info("DONE!");
}

void send_admin_command(){
  write_csr(soc_addr, 0x1, 0x40);
  while(read_csr(soc_addr, 0x5C) == 0); // wait until cpl received
}

void send_admin_command2(){
  write_csr(soc_addr, 0x1, 0x44);
  while(read_csr(soc_addr, 0x5C) == 0); // wait until cpl received
}

void send_write_command(){
  write_csr(soc_addr, 0xC000, 0x50); // nvme addr
  write_csr(soc_addr, 0xC000, 0x54); // fpga addr
  write_csr(soc_addr, 0x3, 0x58); // nlb
  write_csr(soc_addr, 0xA1111111, 0x100); // wrdata[0] 
  write_csr(soc_addr, 0xA2222222, 0x104); // wrdata[1] 
  write_csr(soc_addr, 0xA3333333, 0x108); // wrdata[2] 
  write_csr(soc_addr, 0xA4444444, 0x10C); // wrdata[3] 
  write_csr(soc_addr, 0xA5555555, 0x110); // wrdata[4] 
  write_csr(soc_addr, 0xA6666666, 0x114); // wrdata[5] 
  write_csr(soc_addr, 0xA7777777, 0x118); // wrdata[6] 
  write_csr(soc_addr, 0xA8888888, 0x11C); // wrdata[7] 
  write_csr(soc_addr, 0x0, 0x4C); // send write cmd
  while(read_csr(soc_addr, 0x5C) == 0); // write until cpl done
}

void send_read_command(){
  write_csr(soc_addr, 0xC000, 0x50); // nvme addr
  write_csr(soc_addr, 0xC000, 0x54); // fpga addr
  write_csr(soc_addr, 0x3, 0x58); // nlb
  write_csr(soc_addr, 0x0, 0x48); // send write cmd
  while(read_csr(soc_addr, 0x5C) == 0); // write until cpl done
}



int main(int argc, char *argv[]){
	spdlog::set_pattern("%^[%l]%$  %v");
  int soc_fd;

  // Open Bittware 250 SOC + mmap 64KB
  soc_fd = open_fpga(BITTWARE_SOC_DEV);
  soc_addr = Mmap(soc_fd);
 
  // Reset modules on FPGA
	sw_reset();	
  
  // Initialize NVMe Configuration Registers and Controller 
  setting_nvme_cfg_bar();
  setting_nvme_controller();

  // Send admin commands : IOCQ, IOSQ create command
  send_admin_command();    
  send_admin_command2();    

  getchar();

  // Send IO commands : Read, Write
  send_write_command();
  send_read_command();
  
  return 0;
}
