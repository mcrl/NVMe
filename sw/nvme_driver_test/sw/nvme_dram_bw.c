// Measure the DRAM-routed data-path bandwidth on the current bitstream (host data staged in 4 GB DDR4, SSD
// reads/writes the on-chip window). The SSD-transfer rate is the NVMe command's real byte rate; the copy
// engine (SRAM<->DDR4) and the SSD both run well under the DDR4's ~9 GB/s, so this is the SSD-gated ceiling.
//   r_data_beats(0x68)/w_data_beats(0x6C) x 32 B = real payload moved; time = ring->cpl.
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
#include <time.h>
static volatile uint32_t *B;
static uint32_t rd(uint32_t o){return B[o/4];}
static void wr(uint32_t o,uint32_t v){B[o/4]=v;}
#define WBUF 0x40000u
static double now(){ struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t); return t.tv_sec + t.tv_nsec*1e-9; }
static int cp_copy(int chan){ wr(0x84,chan); usleep(2000); for(int t=0;t<2000&&(rd(0x80)&1);t++) usleep(500); return (rd(0x80)&1)?-1:0; }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }
  printf("ready (DDR4 calibrated)\n");

  const uint32_t BYTES=128*1024, WORDS=BYTES/4, DW=BYTES/32, nlb=BYTES/512-1, N=200;
  for (uint32_t k=0;k<WORDS;k++) wr(WBUF+k*4, 0xC0DE0000u+k);
  wr(0x88,DW);

  // ---- copy (host SRAM <-> DDR4) bandwidth: 128 KB push+pull ----
  double t0=now(); for(uint32_t r=0;r<50;r++) cp_copy(0); double tc=now()-t0;
  printf("copy engine wbuf->DDR4->wbuf2 : %.2f GB/s (%.1f us / 128 KB)\n", 50.0*BYTES/tc/1e9, tc/50*1e6);
  cp_copy(0);  // ensure wbuf2 staged

  wr(0x58,nlb);
  // ---- WRITE: SSD reads wbuf2 (DRAM-staged) -> NAND ----
  double t1=now(); uint32_t r0=rd(0x68);
  for(uint32_t r=0;r<N;r++){ uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);
    for(i=0;i<8000000L&&rd(0x64)==c;i++); }
  double tw=now()-t1; uint32_t rb=rd(0x68)-r0;
  printf("WRITE (host->DDR4->wbuf2->SSD->NAND): %.2f GB/s  (%u cmds, %u beats, %.1f us/cmd)\n",
         (double)rb*32/tw/1e9, N, rb, tw/N*1e6);

  // ---- READ: SSD reads NAND -> writes rbuf (DDR4 path) ----
  double t2=now(); uint32_t w0=rd(0x6C);
  for(uint32_t r=0;r<N;r++){ uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0);
    for(i=0;i<8000000L&&rd(0x64)==c;i++); }
  double tr=now()-t2; uint32_t wb=rd(0x6C)-w0;
  printf("READ  (NAND->SSD->rbuf->DDR4 path): %.2f GB/s  (%u cmds, %u beats, %.1f us/cmd)\n",
         (double)wb*32/tr/1e9, N, wb, tr/N*1e6);
  printf("(DDR4 AXI itself ~7-9 GB/s; the SSD link is the limiter, as on-chip.)\n");
  return 0;
}
