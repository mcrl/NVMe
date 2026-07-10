// >128 KB single transfer STREAMED through the 128 KB on-chip window over the 4 GB DDR4, + bandwidth.
//   WRITE: host stages N x 128 KB chunks into DDR4 (copy-push), starts the refill (DDR4->wbuf2, streamed),
//          then one WRITE command of the whole size -> the SSD reads it from the streamed window -> NAND.
//   READ : start the drain (rbuf->DDR4, streamed), one READ command, then pull each 128 KB chunk DDR4->rbuf2
//          -> host. Verifies the round-trip + times the SSD-transfer bandwidth (beat counters).
// CSR: 0x84 op[1:0] (0=copy-push 1=copy-pull 2=refill 3=drain), 0x88 words, 0x8C DDR4 word base, 0x80 b0=busy.
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
#define WIN  (128*1024)         // on-chip window
#define WINW (WIN/4)            // 32-bit words per window
#define DWW  (WIN/32)           // 256-b words per window = 4096
static double now(){ struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t); return t.tv_sec+t.tv_nsec*1e-9; }
static uint32_t patt(uint32_t k){ return 0x5EED0000u + k*0x01010101u; }
static int wait_busy(){ for(int t=0;t<4000 && (rd(0x80)&1);t++) usleep(200); return (rd(0x80)&1)?-1:0; }
static void cp(int op,uint32_t words,uint32_t base){ wr(0x88,words); wr(0x8C,base); wr(0x84,op); }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t kb = argc>2?(uint32_t)atoi(argv[2]):256;        // total transfer size (KB), multiple of 128
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }

  uint32_t bytes=kb*1024, totw=bytes/4, totdw=bytes/32, nlb=bytes/512-1, nch=bytes/WIN;
  printf("=== %u KB single transfer streamed over DDR4 (%u x 128 KB window chunks) ===\n", kb, nch);

  // ---- WRITE: stage chunks -> DDR4, refill, one big WRITE command ----
  for (uint32_t c=0;c<nch;c++){
    for (uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(c*WINW+k));   // fill window with chunk c
    cp(0, DWW, c*DWW); if(wait_busy()){printf("push%u STUCK\n",c);return 5;}
  }
  cp(2, totdw, 0); usleep(2000);                                  // refill: DDR4 -> wbuf2 (primes ahead of SSD)
  wr(0x58,nlb);
  double tw=now(); uint32_t r0=rd(0x68);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);
    for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("WRITE TIMEOUT\n");return 3;} }
  tw=now()-tw; uint32_t wbeats=rd(0x68)-r0;  wait_busy();          // let the refill drain out

  // ---- READ: drain, one big READ command, pull chunks -> host ----
  cp(3, totdw, 0); usleep(200);                                   // drain: rbuf -> DDR4 (behind the SSD)
  double tr=now(); uint32_t w0=rd(0x6C);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0);
    for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("READ TIMEOUT\n");return 3;} }
  tr=now()-tr; uint32_t rbeats=rd(0x6C)-w0;  wait_busy();          // let the drain finish

  int bad=0; uint32_t fk=0,fg=0,fe=0;
  for (uint32_t c=0;c<nch;c++){
    cp(1, DWW, c*DWW); if(wait_busy()){printf("pull%u STUCK\n",c);return 5;}   // DDR4 chunk c -> rbuf2
    for (uint32_t k=0;k<WINW;k++){ uint32_t g=rd(RBUF+k*4), e=patt(c*WINW+k);
      if(g!=e){ if(!bad){fk=c*WINW+k;fg=g;fe=e;} bad++; } }
  }
  printf("data: %d/%u words mismatch => %s\n", bad, totw, bad==0?"PASS":"FAIL");
  if(bad) printf("  first @%u got %08X exp %08X\n", fk, fg, fe);
  printf("WRITE %.2f GB/s  (%u beats, %.1f us)\n", (double)wbeats*32/tw/1e9, wbeats, tw*1e6);
  printf("READ  %.2f GB/s  (%u beats, %.1f us)\n", (double)rbeats*32/tr/1e9, rbeats, tr*1e6);
  return bad?4:0;
}
