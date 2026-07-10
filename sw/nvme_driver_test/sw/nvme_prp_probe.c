// Diagnose the max single-command transfer size at QD=1 (no high-rate race), to tell whether the
// >2 KB stall is a PRP/transfer-size limit or a high-throughput completion race.
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>
#include <time.h>
static volatile uint32_t *B;
static uint32_t rd(uint32_t o){return B[o/4];}
static void wr(uint32_t o,uint32_t v){B[o/4]=v;}
static int waitN(uint32_t o,uint32_t val,long lim){for(long i=0;i<lim;i++)if(rd(o)==val)return 1;return 0;}
static int wcfg(uint32_t a,uint32_t d){wr(0x14,a);wr(0x18,d);wr(0x10,1);return waitN(0x1C,1,8000000);}
static uint32_t rcfg(uint32_t a){wr(0x24,a);wr(0x20,1);waitN(0x2C,1,8000000);return rd(0x28);}
static uint32_t rctrl(uint32_t o){return rcfg(0x80000000u|(0x4000+o));}
static void wctrl(uint32_t o,uint32_t d){wcfg(0x80000000u|(0x4000+o),d);}
static void bringup(){
  wr(0x04,1); usleep(1000000); wr(0x04,0);
  wr(0x30,0); wcfg(0x18,0x100); rcfg(0x18);
  printf("  NVMe id=%08X\n", rcfg((1u<<20)|0x00));
  wcfg((1u<<20)|0x04,0x6); wcfg((1u<<20)|0x10,0x4000); wcfg((1u<<20)|0x14,0x0);
  wcfg(0x148,0x1); rcfg(0x148); wr(0x30,1);
  wr(0x30,0); wctrl(0x14,0x0); while(rctrl(0x1C)!=0);
  wctrl(0x24,(64<<16)|64); wctrl(0x28,0x8000); wctrl(0x2C,0); wctrl(0x30,0x9000); wctrl(0x34,0);
  wctrl(0x14,0x1); while(rctrl(0x1C)!=1); wr(0x30,1);
  { uint32_t c=rd(0x64); wr(0x40,1); while(rd(0x64)==c); }
  { uint32_t c=rd(0x64); wr(0x44,1); while(rd(0x64)==c); }
  printf("  controller READY\n");
}
// issue ONE command (trig) of (nlb+1) blocks, wait up to ~1s for its completion. return 1 if completed.
static int one(uint32_t trig,int nlb,int slba){
  uint32_t c=rd(0x64);
  wr(0x58,nlb); wr(0x54,slba); wr(trig,0);
  for(long i=0;i<2000000L;i++){ if(rd(0x64)!=c) return 1; }
  return 0;
}
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t trig = (argc>2 && argv[2][0]=='w') ? 0x4C : 0x48;  // default read
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  printf("== bring up ==\n"); bringup();
  for(int i=0;i<8;i++) wr(0x100+4*i,0xC0DE0000+i);
  wr(0x50,0xC000);
  printf("== single-command (QD=1) max transfer probe, %s ==\n", trig==0x4C?"WRITE":"READ");
  int nlbs[]={0,1,3,7,15,31,63,127,255};
  for(unsigned n=0;n<sizeof(nlbs)/sizeof(int);n++){
    int nlb=nlbs[n], ok=0;
    for(int rep=0;rep<5;rep++) ok += one(trig,nlb, 100 + rep*512);  // 5 reps, distinct SLBAs
    printf("  nlb=%-3d (%4d B): %d/5 completed %s\n", nlb,(nlb+1)*512, ok, ok==5?"OK":(ok==0?"<-- HARD STALL":"<-- partial"));
    if(ok==0) break;  // stop once it hard-stalls
  }
  return 0;
}
