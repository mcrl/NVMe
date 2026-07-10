// Verify the 256 KB STREAMED WRITE is correct, by reading it back in 128 KB halves with DRAIN-AFTER-COMPLETION:
// for a <=128 KB read the SSD's out-of-order pages all land in distinct window slots (no wrap), so once the READ
// command completes the whole window is populated and a non-concurrent drain reads it cleanly. SLBA via CSR 0x54.
//   WRITE: 256 KB streamed (host->DDR4->wbuf2 window->SSD, SSD reads in-order -> reliable).
//   READ-back: 2 x 128 KB, each [READ cmd; wait cpl; drain; pull] -> check vs the written pattern.
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
static volatile uint32_t *B;
static uint32_t rd(uint32_t o){return B[o/4];}
static void wr(uint32_t o,uint32_t v){B[o/4]=v;}
#define WBUF 0x40000u
#define RBUF 0x60000u
#define WINW (128*1024/4)
#define DWW  (128*1024/32)
static int wait_busy(){ for(int t=0;t<8000 && (rd(0x80)&1);t++) usleep(100); return (rd(0x80)&1)?-1:0; }
static void cp(int op,uint32_t words,uint32_t base){ wr(0x88,words); wr(0x8C,base); wr(0x84,op); }
static uint32_t patt(uint32_t k){ return 0x5EED0000u + k*0x01010101u; }
static int rdcmd(uint32_t slba){ uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,slba); wr(0x58,255); wr(0x48,0);
  for(long i=0;i<800000000L && rd(0x64)==cc;i++); return rd(0x64)==cc; }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t bytes=256*1024, totdw=bytes/32, nlb=bytes/512-1, nch=2;
  int fd=open(p,O_RDWR|O_SYNC); B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }

  // ---- WRITE 256 KB streamed (SLBA 0) ----
  for (uint32_t c=0;c<nch;c++){ for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(c*WINW+k)); cp(0,DWW,c*DWW); if(wait_busy()){printf("push STUCK\n");return 5;} }
  cp(2,totdw,0); usleep(2000); wr(0x58,nlb); wr(0x54,0);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x4C,0); for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("WRITE TIMEOUT\n");return 3;} } wait_busy();

  // ---- read back each 128 KB half with DRAIN-AFTER (reliable for <=window even with out-of-order DMA) ----
  int total_bad=0;
  for (uint32_t h=0; h<2; h++){
    uint32_t cc0=rd(0x64),wb0=rd(0x6C); if (rdcmd(h*256)){ printf("READ half%u TIMEOUT: cpl %u->%u w_beats %u->%u\n",h,cc0,rd(0x64),wb0,rd(0x6C)); return 3; }
    cp(3, DWW, 1); if(wait_busy()){printf("drain%u STUCK\n",h);return 5;}  // drain AFTER completion (no concurrency)
    cp(1, DWW, 0); if(wait_busy()){printf("pull%u STUCK\n",h);return 5;}   // DDR4 -> rbuf2
    int bad=0; uint32_t fk=0,fg=0,fe=0;
    for(uint32_t k=0;k<WINW;k++){ uint32_t g=rd(RBUF+k*4), e=patt(h*WINW+k); if(g!=e){ if(!bad){fk=k;fg=g;fe=e;} bad++; } }
    printf("half%u (LBA %u): %d/%u bad %s%s\n", h, h*256, bad, WINW, bad?"FAIL":"PASS",
           bad?({static char s[80]; snprintf(s,80,"  @%u got %08X exp %08X (delta %d pages)",fk,fg,fe,(int)((fg-fe)/0x10101000)); s;}):"");
    total_bad += bad;
  }
  printf("=> WRITE 256KB streamed: %s (read back in 128KB halves, drain-after)\n", total_bad?"DATA MISMATCH":"CLEAN");
  return total_bad?4:0;
}
