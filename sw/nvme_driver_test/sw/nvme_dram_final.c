// Final DRAM-routed data path, reliable against the SSD's out-of-order read DMA:
//   WRITE: one 256 KB NVMe command, STREAMED through the 128 KB on-chip window over DDR4 (host -> DDR4 ->
//          wbuf2 window -> SSD). The SSD reads write-payload IN ORDER, so a single >window write streams fine.
//   READ : the SSD DMAs read-payload pages OUT OF ORDER, so a single >window read cannot stream through a
//          smaller window. Read instead in <=128 KB chunks (one NVMe command each, SLBA stepped): each chunk's
//          out-of-order pages all land in distinct window slots, and a post-completion DRAIN-ALL (cp_base[0])
//          moves the fully-populated window -> DDR4 -> host. Order-independent => reliable.
// Reports bandwidth (beat counters) and verifies the full 256 KB round trip.
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
static int wait_busy(){ for(int t=0;t<8000 && (rd(0x80)&1);t++) usleep(100); return (rd(0x80)&1)?-1:0; }
static void cp(int op,uint32_t words,uint32_t base){ wr(0x88,words); wr(0x8C,base); wr(0x84,op); }
static uint32_t patt(uint32_t k){ return 0x5EED0000u + k*0x01010101u; }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t reps = argc>2?(uint32_t)atoi(argv[2]):1;
  uint32_t bytes=256*1024, totdw=bytes/32, nlb=bytes/512-1, nch=bytes/(128*1024);
  int fd=open(p,O_RDWR|O_SYNC); B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }

  int fails=0;
  for (uint32_t r=0;r<reps;r++){
    // ---- WRITE 256 KB as ONE streamed command ----
    for (uint32_t c=0;c<nch;c++){ for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(r*7u + c*WINW+k)); cp(0,DWW,c*DWW); if(wait_busy()){printf("push STUCK\n");return 5;} }
    cp(2,totdw,0); usleep(2000); wr(0x58,nlb); wr(0x54,0);
    double tw=now(); uint32_t rb0=rd(0x68);
    { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x4C,0); for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("WRITE TIMEOUT\n");return 3;} }
    tw=now()-tw; uint32_t wbeats=rd(0x68)-rb0; wait_busy();

    // ---- READ back in 128 KB chunks (reliable: drain-all after each chunk completes) ----
    int bad=0; uint32_t fk=0,fg=0,fe=0; double tr=0; uint32_t rbeats=0;
    for (uint32_t h=0; h<nch; h++){
      wr(0x54,h*256); wr(0x58,255);
      double t0=now(); uint32_t wb0=rd(0x6C);
      { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x48,0); for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("READ TIMEOUT\n");return 3;} }
      tr+=now()-t0; rbeats+=rd(0x6C)-wb0;
      cp(3,DWW,1); if(wait_busy()){printf("drain STUCK\n");return 5;}   // drain-all (post-completion)
      cp(1,DWW,0); if(wait_busy()){printf("pull STUCK\n");return 5;}    // DDR4 -> rbuf2
      for(uint32_t k=0;k<WINW;k++){ uint32_t g=rd(RBUF+k*4), e=patt(r*7u + h*WINW+k); if(g!=e){ if(!bad){fk=h*WINW+k;fg=g;fe=e;} bad++; } }
    }
    if (reps==1 || bad)
      printf("rep%u: round-trip %d/%u bad %s%s | WRITE %.2f GB/s (%uB,%.0fus) READ %.2f GB/s (%uB,%.0fus)\n",
        r, bad, bytes/4, bad?"FAIL":"PASS", bad?"":"          ",
        (double)wbeats*32/tw/1e9, wbeats*32, tw*1e6, (double)rbeats*32/tr/1e9, rbeats*32, tr*1e6);
    if (bad){ printf("   first @%u got %08X exp %08X\n", fk,fg,fe); fails++; }
  }
  if (reps>1) printf("=> %u/%u reps clean\n", reps-fails, reps);
  return fails?4:0;
}
