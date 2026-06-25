// Discriminate WRITE-side vs READ-side streaming corruption: WRITE a 256 KB pattern once, then READ it back
// TWICE into separate host buffers. If readA==readB but both != pattern -> the WRITE path put bad data in NAND
// (both reads see the same wrong bytes). If readA != readB -> the READ path (drain/pull) corrupts per-read.
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

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t kb=256, bytes=kb*1024, totw=bytes/4, totdw=bytes/32, nlb=bytes/512-1, nch=bytes/(128*1024);
  int fd=open(p,O_RDWR|O_SYNC); B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }
  static uint32_t A[256*1024/4], C[256*1024/4];

  // ---- WRITE once ----
  for (uint32_t c=0;c<nch;c++){ for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(c*WINW+k));
    cp(0,DWW,c*DWW); if(wait_busy()){printf("push STUCK\n");return 5;} }
  cp(2,totdw,0); usleep(2000); wr(0x58,nlb);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);
    for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("WRITE TIMEOUT\n");return 3;} } wait_busy();

  // ---- READ pass: returns mismatches vs pattern, fills out[] ----
  #define READ_PASS(out) do{ \
    cp(3,totdw,0); usleep(200); \
    { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0); \
      for(i=0;i<800000000L && rd(0x64)==cc;i++); if(rd(0x64)==cc){printf("READ TIMEOUT\n");return 3;} } wait_busy(); \
    for(uint32_t c=0;c<nch;c++){ cp(1,DWW,c*DWW); if(wait_busy()){printf("pull STUCK\n");return 5;} \
      for(uint32_t k=0;k<WINW;k++) out[c*WINW+k]=rd(RBUF+k*4); } }while(0)

  READ_PASS(A);
  READ_PASS(C);

  int badA=0,badC=0,diffAC=0; uint32_t f1=0,fa=0,fe=0;
  for(uint32_t k=0;k<totw;k++){
    uint32_t e=patt(k);
    if(A[k]!=e){ if(!badA){f1=k;fa=A[k];fe=e;} badA++; }
    if(C[k]!=e) badC++;
    if(A[k]!=C[k]) diffAC++;
  }
  printf("readA vs pattern: %d/%u bad\n", badA, totw);
  printf("readB vs pattern: %d/%u bad\n", badC, totw);
  printf("readA vs readB  : %d/%u differ\n", diffAC, totw);
  if(badA) printf("  first A-bad @%u got %08X exp %08X\n", f1, fa, fe);
  printf("=> %s\n", diffAC? "READ-SIDE (reads disagree => drain/pull intermittent)"
                          : (badA? "WRITE-SIDE (both reads agree but != pattern => bad data in NAND)" : "CLEAN"));
  return 0;
}
