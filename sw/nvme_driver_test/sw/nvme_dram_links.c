// Per-link bandwidth of the full path:  host main memory <-> FPGA DDR4 <-> NVMe SSD.
//   host<->DDR4 splits into  host<->on-chip-SRAM (PCIe BAR MMIO)  and  SRAM<->DDR4 (on-chip copy engine).
//   DDR4<->SSD is the OcuLink/NVMe link (256 KB transfer; WRITE streamed, READ chunked+drain-all).
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
static volatile uint32_t *B;
static uint32_t rd(uint32_t o){return B[o/4];}
static void wr(uint32_t o,uint32_t v){B[o/4]=v;}
#define WBUF 0x40000u
#define RBUF 0x60000u
#define WINW (128*1024/4)
#define DWW  (128*1024/32)
static double now(){ struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t); return t.tv_sec+t.tv_nsec*1e-9; }
static int busy_spin(){ for(long t=0;t<200000000L && (rd(0x80)&1);t++); return rd(0x80)&1; }
static void cp(int op,uint32_t words,uint32_t base){ wr(0x88,words); wr(0x8C,base); wr(0x84,op); }
static uint32_t patt(uint32_t k){ return 0x5EED0000u + k*0x01010101u; }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }
  const int N=200; double t; volatile uint32_t sink=0;

  // ---- host -> on-chip SRAM (PCIe BAR MMIO write) ----
  t=now(); for(int r=0;r<N;r++) for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(k));
  double bw_bar_wr = (double)N*WINW*4/(now()-t)/1e9;
  // ---- on-chip SRAM -> host (PCIe BAR MMIO read) ----  (fewer reps; MMIO reads are round-trips)
  t=now(); for(int r=0;r<8;r++) for(uint32_t k=0;k<WINW;k++) sink+=rd(RBUF+k*4);
  double bw_bar_rd = (double)8*WINW*4/(now()-t)/1e9;

  // ---- on-chip SRAM -> DDR4 (copy push) ----
  for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(k));
  t=now(); for(int r=0;r<N;r++){ cp(0,DWW,0); if(busy_spin()){printf("push stuck\n");return 5;} }
  double bw_push = (double)N*DWW*32/(now()-t)/1e9;
  // ---- DDR4 -> on-chip SRAM (copy pull) ----
  t=now(); for(int r=0;r<N;r++){ cp(1,DWW,0); if(busy_spin()){printf("pull stuck\n");return 5;} }
  double bw_pull = (double)N*DWW*32/(now()-t)/1e9;

  // ---- DDR4 <-> SSD (OcuLink/NVMe), 256 KB ----
  uint32_t bytes=256*1024, totdw=bytes/32, nlb=bytes/512-1, nch=2;
  for(uint32_t c=0;c<nch;c++){ for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(c*WINW+k)); cp(0,DWW,c*DWW); busy_spin(); }
  cp(2,totdw,0); usleep(2000); wr(0x58,nlb); wr(0x54,0);
  double tw=now(); uint32_t rb0=rd(0x68);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x4C,0); for(i=0;i<800000000L&&rd(0x64)==cc;i++);} tw=now()-tw;
  double bw_ssd_wr = (double)(rd(0x68)-rb0)*32/tw/1e9; busy_spin();
  double tr=0; uint32_t rbeats=0;
  for(uint32_t h=0;h<nch;h++){ wr(0x54,h*256); wr(0x58,255);
    double t0=now(); uint32_t wb0=rd(0x6C); { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x48,0); for(i=0;i<800000000L&&rd(0x64)==cc;i++);} tr+=now()-t0; rbeats+=rd(0x6C)-wb0;
    cp(3,DWW,1); busy_spin(); }
  double bw_ssd_rd = (double)rbeats*32/tr/1e9;

  printf("\n==== per-link bandwidth (256-bit DDR4 @~300MHz, OcuLink Gen3x4) ====\n");
  printf("host main mem <-> FPGA DDR4 :\n");
  printf("   host -> SRAM  (BAR MMIO wr) : %7.2f GB/s\n", bw_bar_wr);
  printf("   SRAM -> host  (BAR MMIO rd) : %7.3f GB/s   <- MMIO read round-trips (no host-DMA path)\n", bw_bar_rd);
  printf("   SRAM -> DDR4  (copy push)   : %7.2f GB/s\n", bw_push);
  printf("   DDR4 -> SRAM  (copy pull)   : %7.2f GB/s\n", bw_pull);
  printf("FPGA DDR4 <-> NVMe SSD (OcuLink) :\n");
  printf("   DDR4 -> SSD   (write,stream): %7.2f GB/s\n", bw_ssd_wr);
  printf("   SSD  -> DDR4  (read, chunk) : %7.2f GB/s   <- same-LBA 128KB, NAND-read-bound\n", bw_ssd_rd);
  (void)sink; return 0;
}
