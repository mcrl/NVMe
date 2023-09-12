#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <spdlog/spdlog.h>
#include <stdlib.h>

using namespace spdlog;

#define ALVEO_U280_DEV "/dev/xdma0_user"
#define BITTWARE_SOC_DEV "/dev/xdma0_user"

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
  //info("[ Write CSR ] wraddr : {:08X}, wrdata : {:08X}", offset, *w);
	return *w;
}

uint32_t read_csr(void *fpga_addr, uint32_t offset) {
  uint32_t rddata = *(uint32_t*)((size_t)fpga_addr + offset);
  //info("[ Read  CSR ] rdaddr : {:04X}, rddata : {:08X}", offset, *(uint32_t*)((size_t)fpga_addr + offset));
  return rddata;
}

void nvme_config_done(uint32_t is_done){
	info("nvme configuration done!");
	write_csr(soc_addr, is_done, 0x08);
}

void sw_reset(){
	info("SW Reset!");
	write_csr(soc_addr, 0b1, 0x04);
	write_csr(soc_addr, 0b0, 0x04);
	nvme_config_done(0);
	sleep(1);
}


uint32_t read_cfg(uint32_t offset){
	uint32_t len = 1;
	// add NVMe configuration space address
	uint32_t idx = offset;
	
	// request cfg offset
	// total transfer bytes = len * 32 Bytes  
	write_csr(soc_addr, offset, 0x100);		// araddr
	write_csr(soc_addr, 0x1, 		0x104);		// arburst : Incremental
	write_csr(soc_addr, arid++, 0x108);		// arid
	write_csr(soc_addr, len-0x1,  	0x10C);		// arlen
	write_csr(soc_addr, 0x2,  	0x114);		// arsize, 32 Bytes
	write_csr(soc_addr, 0x1,  	0x120); 	// arvalid : push s_axi_ar data into queue
	
	// wait until nvme send cfg data into s_axi_r fifo
	while(read_csr(soc_addr, 0x430) == 1);

	// read cfg data from s_axi_r fifo
	uint32_t rresp, rlast, rid, rdata0, rdata1, rdata2, rdata3, rdata4, rdata5, rdata6, rdata7;
	read_csr(soc_addr, 0x434); // pop s_axi_r_fifo
	rresp = read_csr(soc_addr, 0x400);	// s_axi_rresp
	rlast = read_csr(soc_addr, 0x404);	// s_axi_rlast
	rid = read_csr(soc_addr, 0x408);	// s_axi_rid

	uint32_t rdata[8];
	idx = (idx % 32) / 4;
	rdata[0] = read_csr(soc_addr, 0x40C);	// s_axi_rdata[0]
	rdata[1] = read_csr(soc_addr, 0x410);	// s_axi_rdata[1]
	rdata[2] = read_csr(soc_addr, 0x414);	// s_axi_rdata[2]
	rdata[3] = read_csr(soc_addr, 0x418);	// s_axi_rdata[3]
	rdata[4] = read_csr(soc_addr, 0x41C);	// s_axi_rdata[4]
	rdata[5] = read_csr(soc_addr, 0x420);	// s_axi_rdata[5]
	rdata[6] = read_csr(soc_addr, 0x424);	// s_axi_rdata[6]
	rdata[7] = read_csr(soc_addr, 0x428);	// s_axi_rdata[7]
	info("raddr : {:08X}, rdata : {:08X}, rresp : {:08X}, rlast : {:08X}, rid : {:08X}", offset, rdata[idx], rresp, rlast, rid);

	return rdata[idx];
}

// TODO : write cfg
void write_cfg(uint32_t addr, uint32_t wdata) {
	uint32_t len = 1;
	uint32_t idx = addr;
	// send write address
	write_csr(soc_addr, addr, 0x200);		// awaddr
	write_csr(soc_addr, 0x1, 	0x204);		// awburst : Incremental
	write_csr(soc_addr, awid++, 0x208);	// awid
	write_csr(soc_addr, len-1, 0x20C);	// awlen
	write_csr(soc_addr, 0x0, 0x210);		// awregion
	write_csr(soc_addr, 0x2, 0x214);		// awsize	: 4 Bytes
	write_csr(soc_addr, 0x0, 0x220); 		// s_axi_aw fifo push
	// info("send write address {:08X}", addr);

	// send write data
	write_csr(soc_addr, 0x1, 0x300);				// wlast
	write_csr(soc_addr, 0xffffffff, 0x304);	// wstrb

	idx = (idx/4 % 8) * 4 + 0x308;
	write_csr(soc_addr, wdata, idx);
	write_csr(soc_addr, wdata, 0x308);
	write_csr(soc_addr, wdata, 0x30C);
	write_csr(soc_addr, wdata, 0x310);
	write_csr(soc_addr, wdata, 0x314);
	write_csr(soc_addr, wdata, 0x318);
	write_csr(soc_addr, wdata, 0x31C);
	write_csr(soc_addr, wdata, 0x320);
	write_csr(soc_addr, wdata, 0x324);

	write_csr(soc_addr, 0x0, 0x330); // s_axi_w_fifo push
	// info("send write data {:08X}", wdata);

	while(read_csr(soc_addr, 0x50C));	

	// pop axi_b_fifo
	write_csr(soc_addr, 0x0, 0x510);	// s_axi_b_fifo pop
	uint32_t bresp, bid;
	bresp = read_csr(soc_addr, 0x500);
	bid = read_csr(soc_addr, 0x504);
	info("waddr : {:08X}, wdata : {:08X}, bresp : {:08X}, bid : {:08X}", addr, wdata, bresp, bid);
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

uint32_t asqtdbl=1;
uint32_t iosqtdbl=1;

void send_admin_command(){
	info("Send Admin Command!");

	info("1. Write ASQTDBL (ASQ Tail Doorbell)");
	write_nvme_ctrl(0x1000, asqtdbl++);	// ASQTDBL <= 1
	
	info("2. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("3. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	uint32_t maraddr = read_csr(soc_addr, 0x600);
	uint32_t arid = read_csr(soc_addr, 0x604);
	uint32_t arlen = read_csr(soc_addr, 0x60C);
	uint32_t arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	info("4. Send command");
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	// iocq create command
	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x5, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x0, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x0, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x0, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0, 0x920); // rdata[5]	
	write_csr(soc_addr, 0xA000, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x0, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x0, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x00100001, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x1, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x0, 0x924); // rdata[6]	
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	info("Wait completion from NVMe");
	// wait aw
	while(read_csr(soc_addr, 0x714));

	info("pop from aw fifo");
	read_csr(soc_addr, 0x71C);  // m_axi_aw_fifo pop

	uint32_t awaddr = read_csr(soc_addr, 0x700);	
	uint32_t awburst = read_csr(soc_addr, 0x704);	
	uint32_t awid = read_csr(soc_addr, 0x708);	
	uint32_t awlen = read_csr(soc_addr, 0x70C);	
	uint32_t awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);

	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop

	uint32_t wlast = read_csr(soc_addr, 0x800);	
	uint32_t wstrb = read_csr(soc_addr, 0x804);	
	uint32_t wdata[8];
	for (int i=0; i<8; ++i) {
		wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
	}
	info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	

	// send b
	info("send b");
	uint32_t bresp = 0x0;
	uint32_t bid= arid;
	write_csr(soc_addr, bresp, 0xA00);
	write_csr(soc_addr, bid, 0xA04);
	write_csr(soc_addr, 0x0, 0xA10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08X}, bid : {:08X}", bresp, bid);
}

void send_admin_command2(){
	info("Send Admin Command!");

	info("1. Write ASQTDBL (ASQ Tail Doorbell)");
	write_nvme_ctrl(0x1000, asqtdbl++);	// ASQTDBL <= 1
	
	info("2. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("3. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	uint32_t maraddr = read_csr(soc_addr, 0x600);
	uint32_t arid = read_csr(soc_addr, 0x604);
	uint32_t arlen = read_csr(soc_addr, 0x60C);
	uint32_t arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	info("4. Send command");
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	// iocq create command
	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x1, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x0, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x0, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x0, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0, 0x920); // rdata[5]	
	write_csr(soc_addr, 0xB000, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x0, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x0, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x00100001, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x00010001, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x0, 0x924); // rdata[6]	
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	info("Wait completion from NVMe");
	// wait aw
	while(read_csr(soc_addr, 0x714));

	info("pop from aw fifo");
	read_csr(soc_addr, 0x71C);  // m_axi_aw_fifo pop

	uint32_t awaddr = read_csr(soc_addr, 0x700);	
	uint32_t awburst = read_csr(soc_addr, 0x704);	
	uint32_t awid = read_csr(soc_addr, 0x708);	
	uint32_t awlen = read_csr(soc_addr, 0x70C);	
	uint32_t awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);

	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop

	uint32_t wlast = read_csr(soc_addr, 0x800);	
	uint32_t wstrb = read_csr(soc_addr, 0x804);	
	uint32_t wdata[8];
	for (int i=0; i<8; ++i) {
		wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
	}
	info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	

	// send b
	info("send b");
	uint32_t bresp = 0x0;
	uint32_t bid= arid;
	write_csr(soc_addr, bresp, 0xA00);
	write_csr(soc_addr, bid, 0xA04);
	write_csr(soc_addr, 0x0, 0xA10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08X}, bid : {:08X}", bresp, bid);
}

void send_write_command(){
	info("Send Write Command!");

	info("1. Write IOSQTDBL (ASQ Tail Doorbell)");
	write_nvme_ctrl(0x1008, iosqtdbl++);	// ASQTDBL <= 1
	
	info("2. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("3. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	uint32_t maraddr = read_csr(soc_addr, 0x600);
	uint32_t arid = read_csr(soc_addr, 0x604);
	uint32_t arlen = read_csr(soc_addr, 0x60C);
	uint32_t arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	info("4. Send command");
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x1, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x1, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x0, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x0, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0xD000, 0x920); // rdata[5]	
	write_csr(soc_addr, 0xC000, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x0, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x0, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x1000, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x0, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x0, 0x924); // rdata[6]	
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	// wait ar again
	info("5. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("6. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	maraddr = read_csr(soc_addr, 0x600);
	arid = read_csr(soc_addr, 0x604);
	arlen = read_csr(soc_addr, 0x60C);
	arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);
	
	// send write data
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x88888888+0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x88888888+0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x88888888+0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x88888888+0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x88888888+0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x88888888+0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x88888888+0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x88888888+0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push
	
	// wait ar again22
	info("5. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("6. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	maraddr = read_csr(soc_addr, 0x600);
	arid = read_csr(soc_addr, 0x604);
	arlen = read_csr(soc_addr, 0x60C);
	arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	// send write data
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x88888888+0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x88888888+0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x88888888+0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x88888888+0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x88888888+0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x88888888+0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x88888888+0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x88888888+0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	// wait ar again22
	info("5. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("6. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	maraddr = read_csr(soc_addr, 0x600);
	arid = read_csr(soc_addr, 0x604);
	arlen = read_csr(soc_addr, 0x60C);
	arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	// send write data
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x88888888+0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x88888888+0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x88888888+0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x88888888+0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x88888888+0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x88888888+0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x88888888+0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x88888888+0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	// wait ar again22
	info("5. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("6. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	maraddr = read_csr(soc_addr, 0x600);
	arid = read_csr(soc_addr, 0x604);
	arlen = read_csr(soc_addr, 0x60C);
	arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	// send write data
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	write_csr(soc_addr, 0x1, 0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x88888888+0x00000000, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x88888888+0x11111111, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x88888888+0x22222222, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x88888888+0x33333333, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x88888888+0x44444444, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x88888888+0x55555555, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x88888888+0x66666666, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x88888888+0x77777777, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	info("Wait completion from NVMe");
	// wait aw
	while(read_csr(soc_addr, 0x714));

	info("pop from aw fifo");
	read_csr(soc_addr, 0x71C);  // m_axi_aw_fifo pop

	uint32_t awaddr = read_csr(soc_addr, 0x700);	
	uint32_t awburst = read_csr(soc_addr, 0x704);	
	uint32_t awid = read_csr(soc_addr, 0x708);	
	uint32_t awlen = read_csr(soc_addr, 0x70C);	
	uint32_t awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);

	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	
	while(true){
		read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop
		uint32_t wlast = read_csr(soc_addr, 0x800);	
		uint32_t wstrb = read_csr(soc_addr, 0x804);	
		uint32_t wdata[8];
		for (int i=0; i<8; ++i) {
			wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
		}
		info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	
		if (wlast == 1) break;
	}
	
	// send b
	info("send b");
	uint32_t bresp = 0x0;
	uint32_t bid= arid;
	write_csr(soc_addr, bresp, 0xA00);
	write_csr(soc_addr, bid, 0xA04);
	write_csr(soc_addr, 0x0, 0xA10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08X}, bid : {:08X}", bresp, bid);
}

void send_read_command(){
	info("Send Read Command!");

	info("1. Write IOSQTDBL (ASQ Tail Doorbell)");
	write_nvme_ctrl(0x1008, iosqtdbl++);	// ASQTDBL <= 1
	
	info("2. Wait until NVMe sends request");
	while(read_csr(soc_addr, 0x618) != 0);

	info("3. check NVMe request : address, datasize = (len+1) * 2^size");
	read_csr(soc_addr, 0x620);	// m_axi_ar_fifo_pop
	uint32_t maraddr = read_csr(soc_addr, 0x600);
	uint32_t arid = read_csr(soc_addr, 0x604);
	uint32_t arlen = read_csr(soc_addr, 0x60C);
	uint32_t arsize = read_csr(soc_addr, 0x614);
	info("araddr : {:08X}, arid : {:08X},  arlen : {:08X}, arsize : {:08X}", maraddr, arid, arlen, arsize);

	info("4. Send command");
	write_csr(soc_addr, arid, 0x900);	// rid	
	write_csr(soc_addr, 0x0, 0x908);	// rresp

	write_csr(soc_addr, 0, 0x904); // rlast
	write_csr(soc_addr, 0x2, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x1, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x0, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x0, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0000, 0x920); // rdata[5]	
	write_csr(soc_addr, 0xC000, 0x924); // rdata[6]	CQ BAR
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push
	
	write_csr(soc_addr, 1, 0x904); // rlast
	write_csr(soc_addr, 0x0, 0x90C);	// rdata[0]
	write_csr(soc_addr, 0x0, 0x910);	// rdata[1]
	write_csr(soc_addr, 0x1000, 0x914);	// rdata[2]
	write_csr(soc_addr, 0x0, 0x918); // rdata[3]	
	write_csr(soc_addr, 0x0, 0x91C); // rdata[4]	
	write_csr(soc_addr, 0x0, 0x920); // rdata[5]	
	write_csr(soc_addr, 0x0, 0x924); // rdata[6]	
	write_csr(soc_addr, 0x0, 0x928); // rdata[7]	
	write_csr(soc_addr, 0x0,  0x934); // push

	info("Wait read data from NVMe");
	while(read_csr(soc_addr, 0x714));
	uint32_t awaddr = read_csr(soc_addr, 0x700);	
	uint32_t awburst = read_csr(soc_addr, 0x704);	
	uint32_t awid = read_csr(soc_addr, 0x708);	
	uint32_t awlen = read_csr(soc_addr, 0x70C);	
	uint32_t awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);
	
	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	
	while(true){
		read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop
		uint32_t wlast = read_csr(soc_addr, 0x800);	
		uint32_t wstrb = read_csr(soc_addr, 0x804);	
		uint32_t wdata[8];
		for (int i=0; i<8; ++i) {
			wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
		}
		info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	
		if (wlast == 1) break;
	}
	info("send b response from w");
	uint32_t bresp = 0x0;
	uint32_t bid= awid;
	write_csr(soc_addr, bresp, 0xa00);
	write_csr(soc_addr, bid, 0xa04);
	write_csr(soc_addr, 0x0, 0xa10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08x}, bid : {:08x}", bresp, bid);

	info("Wait read data from NVMe");
	while(read_csr(soc_addr, 0x714));
	awaddr = read_csr(soc_addr, 0x700);	
	awburst = read_csr(soc_addr, 0x704);	
	awid = read_csr(soc_addr, 0x708);	
	awlen = read_csr(soc_addr, 0x70C);	
	awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);
	
	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	
	while(true){
		read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop
		uint32_t wlast = read_csr(soc_addr, 0x800);	
		uint32_t wstrb = read_csr(soc_addr, 0x804);	
		uint32_t wdata[8];
		for (int i=0; i<8; ++i) {
			wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
		}
		info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	
		if (wlast == 1) break;
	}
	info("send b response from w");
	bresp = 0x0;
	bid= awid;
	write_csr(soc_addr, bresp, 0xa00);
	write_csr(soc_addr, bid, 0xa04);
	write_csr(soc_addr, 0x0, 0xa10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08x}, bid : {:08x}", bresp, bid);


	info("Wait read data from NVMe");
	while(read_csr(soc_addr, 0x714));
	awaddr = read_csr(soc_addr, 0x700);	
	awburst = read_csr(soc_addr, 0x704);	
	awid = read_csr(soc_addr, 0x708);	
	awlen = read_csr(soc_addr, 0x70C);	
	awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);
	
	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	
	while(true){
		read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop
		uint32_t wlast = read_csr(soc_addr, 0x800);	
		uint32_t wstrb = read_csr(soc_addr, 0x804);	
		uint32_t wdata[8];
		for (int i=0; i<8; ++i) {
			wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
		}
		info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	
		if (wlast == 1) break;
	}
	
	info("send b response from w");
	bresp = 0x0;
	bid= awid;
	write_csr(soc_addr, bresp, 0xa00);
	write_csr(soc_addr, bid, 0xa04);
	write_csr(soc_addr, 0x0, 0xa10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08x}, bid : {:08x}", bresp, bid);


	info("Wait read data from NVMe");
	while(read_csr(soc_addr, 0x714));
	awaddr = read_csr(soc_addr, 0x700);	
	awburst = read_csr(soc_addr, 0x704);	
	awid = read_csr(soc_addr, 0x708);	
	awlen = read_csr(soc_addr, 0x70C);	
	awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);
	
	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	
	while(true){
		read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop
		uint32_t wlast = read_csr(soc_addr, 0x800);	
		uint32_t wstrb = read_csr(soc_addr, 0x804);	
		uint32_t wdata[8];
		for (int i=0; i<8; ++i) {
			wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
		}
		info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	
		if (wlast == 1) break;
	}
	
	info("send b response from w");
	bresp = 0x0;
	bid= awid;
	write_csr(soc_addr, bresp, 0xa00);
	write_csr(soc_addr, bid, 0xa04);
	write_csr(soc_addr, 0x0, 0xa10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08x}, bid : {:08x}", bresp, bid);


	info("Wait completion from NVMe");
	// wait aw
	while(read_csr(soc_addr, 0x714));

	info("pop from aw fifo");
	read_csr(soc_addr, 0x71C);  // m_axi_aw_fifo pop

	awaddr = read_csr(soc_addr, 0x700);	
	awburst = read_csr(soc_addr, 0x704);	
	awid = read_csr(soc_addr, 0x708);	
	awlen = read_csr(soc_addr, 0x70C);	
	awsize = read_csr(soc_addr, 0x710);
	info("awaddr : {:08X}, awburst : {:08X}, awid : {:08X}, awlen : {:08X}, awsize : {:08X}", awaddr, awburst, awid, awlen, awsize);

	// wait w
	info("Wait w");
	while(read_csr(soc_addr, 0x828));
	
	while(true){
		read_csr(soc_addr, 0x830);	// m_axi_w_fifo pop
		uint32_t wlast = read_csr(soc_addr, 0x800);	
		uint32_t wstrb = read_csr(soc_addr, 0x804);	
		uint32_t wdata[8];
		for (int i=0; i<8; ++i) {
			wdata[i] = read_csr(soc_addr, 0x808 + 0x04 * i);
		}
		info("wlast : {:08X}, wstrb : {:08X}, wdata[7~0] : {:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X},{:08X}", wlast, wstrb, wdata[7], wdata[6], wdata[5], wdata[4], wdata[3], wdata[2], wdata[1], wdata[0]);	
		if (wlast == 1) break;
	}
	
	// send b
	info("send b");
	bresp = 0x0;
	bid= arid;
	write_csr(soc_addr, bresp, 0xA00);
	write_csr(soc_addr, bid, 0xA04);
	write_csr(soc_addr, 0x0, 0xA10);	// m_axi_b_fifo push (valid)
	info("bresp : {:08X}, bid : {:08X}", bresp, bid);
}


void csr_rw_test(){
	size_t test_wdata = 0x1234;
  write_csr(soc_addr, test_wdata, 0x00);
  size_t test_rdata = read_csr(soc_addr, 0x00);
	if (test_wdata == test_rdata) info("CSR R/W test passed!");
	else info("CSR R/W test failed! write data : {:08X}, read data : {:08X}", test_wdata, test_rdata);
}


int main(int argc, char *argv[]){
	spdlog::set_pattern("%^[%l]%$  %v");
  int soc_fd;

  // Open Bittware 250 SOC + mmap 64KB
  soc_fd = open_fpga(BITTWARE_SOC_DEV);
  soc_addr = Mmap(soc_fd);
  
	sw_reset();	
	csr_rw_test();

	info("Set secondary bus number");
	write_cfg(0x18, 0x00000100);
	read_cfg(0x18);

	info("find nvme controller bar");
	read_cfg(1<<20|0x00);

	info("enable bus master + memory space");
	write_cfg(1<<20|0x04, 0x00000006);
	read_cfg(1<<20|0x04);

	info("Write BAR");
	write_cfg(1<<20|0x10, 0x4000);
	write_cfg(1<<20|0x14, 0x0000);

	info("Enum done, Bridge Enable");
	write_cfg(0x148, 0x1);
	read_cfg(0x148);
	
	//info("Read XDMA PCIe Configuration Space");
	//for (uint32_t x=0x0; x<0x3F; x+=0x4)
	//	read_cfg(x);
	//
	//info("Read NVMe PCIe Configuration Space");
	//for (uint32_t x=0x0; x<0x3F; x+=0x4)
	//	read_cfg(1<<20|x);

	info("");

	// setting nvme controller
	read_nvme_ctrl(0x00);	// CAP
	read_nvme_ctrl(0x04);	// CAP
	read_nvme_ctrl(0x08);	// Version == 1.3
	
	info("Start setting NVMe Controller Properties");
	write_nvme_ctrl(0x14, 0x00); // CC.EN = 0
	while(read_nvme_ctrl(0x1C) != 0);	// wait CSTS.RDY to be 0
	
	size_t sq_len = 64;
  size_t sq_nbytes = sq_len * 64; // one queue entry is 64-byte
  size_t cq_len = 64;
  size_t cq_nbytes = cq_len * 64;
 
  // memory layout : | BAR (bar_size) | ASQ (sq_nbytes) | ACQ (cq_nbytes)
  //                0x4000          0x8000           0x9000             0xA000

	// AQA set (CQ, SQ size)
	write_nvme_ctrl(0x24, (cq_len << 16) | sq_len);
	write_nvme_ctrl(0x28, 0x8000);	// ASQ low
	write_nvme_ctrl(0x2C, 0x00);		// ASQ  high
	write_nvme_ctrl(0x30, 0x8000 + sq_nbytes);	// ACQ low
	write_nvme_ctrl(0x34, 0x00);		// ACQ  high

	// wait until all settings are done
	// CC.EN = 1
	write_nvme_ctrl(0x14, 0x1);

	// wait until CSTS.RDY to be 1
	while(read_nvme_ctrl(0x1c) != 1);
	info("all settings are done!");

	// Send admin commands
	send_admin_command();	// iocq create command
	send_admin_command2();	// iosq create command
	//send_write_command();
	//send_read_command();

	nvme_config_done(1);
	getchar();
	write_csr(soc_addr, 0x1, 0xC);	// do write
	write_csr(soc_addr, 0x0, 0xC);	// do write
	info("write test done!");
	//getchar();
	//write_csr(soc_addr, 0x1, 0x10);	// do read 
	//write_csr(soc_addr, 0x0, 0x10);	// do read 
	//info("read test done!");

	return 0;
}
