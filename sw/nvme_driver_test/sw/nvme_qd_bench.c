// Measure multiple-outstanding (queue-depth) scaling: IOPS vs QD using cpl_count (CSR 0x64).
#include <stdio.h>
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
static double now(){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec*1e-9;}

static void bringup(){
  wr(0x04,1); usleep(1000000); wr(0x04,0);
  wr(0x30,0); wcfg(0x18,0x100); rcfg(0x18);
  printf("  NVMe id=%08X\n", rcfg((1u<<20)|0x00));
  wcfg((1u<<20)|0x04,0x6); wcfg((1u<<20)|0x10,0x4000); wcfg((1u<<20)|0x14,0x0);
  wcfg(0x148,0x1); rcfg(0x148); wr(0x30,1);
  wr(0x30,0); wctrl(0x14,0x0); while(rctrl(0x1C)!=0);
  wctrl(0x24,(64<<16)|64); wctrl(0x28,0x8000); wctrl(0x2C,0); wctrl(0x30,0x9000); wctrl(0x34,0);
  wctrl(0x14,0x1); while(rctrl(0x1C)!=1); wr(0x30,1);
  { uint32_t c=rd(0x64); wr(0x40,1); while(rd(0x64)==c); }   // IOCQ create, wait cpl_count++
  { uint32_t c=rd(0x64); wr(0x44,1); while(rd(0x64)==c); }   // IOSQ create
  printf("  controller READY, IO queues created (depth 64)\n");
}

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  printf("== bring up ==\n"); bringup();

  uint32_t pat[8]={0xC0DE0001,0xC0DE0002,0xC0DE0003,0xC0DE0004,0xC0DE0005,0xC0DE0006,0xC0DE0007,0xC0DE0008};
  for(int i=0;i<8;i++) wr(0x100+4*i,pat[i]);
  wr(0x50,0xC000); wr(0x58,0);                 // PRP buffer, nlb=0 (1 block)

  printf("\n== WRITE: IOPS vs queue depth (QD) ==\n");
  printf("  %-5s %-8s %-12s %-12s %-10s\n","QD","batches","cmds","cmds/s","us/cmd");
  int QDs[]={1,2,4,8,16,32,64};
  for(unsigned q=0;q<sizeof(QDs)/sizeof(int);q++){
    int QD=QDs[q];
    int batches = 1000/QD; if(batches<8) batches=8;
    uint32_t cbase=rd(0x64);
    uint32_t submitted=0; int stalled=0;
    double t0=now();
    for(int b=0;b<batches && !stalled;b++){
      for(int k=0;k<QD;k++){ wr(0x54,100+k); wr(0x4C,0); submitted++; }   // QD outstanding
      // wait (wrap-safe cumulative): completions caught up to submissions
      long it=0; for(; it<30000000L && (uint32_t)(rd(0x64)-cbase) < submitted; it++);
      if((uint32_t)(rd(0x64)-cbase) < submitted) stalled=1;
    }
    double s=now()-t0;
    uint32_t done = rd(0x64)-cbase;
    if(stalled) printf("  %-5d %-8d %-12u %-12s %-10s  <-- STALL: only %u/%u completed (back-to-back CQE miss?)\n",
                       QD,batches,submitted,"-","-",done,submitted);
    else        printf("  %-5d %-8d %-12u %-12.0f %-10.3f\n",QD,batches,done,done/s,1e6*s/done);
  }
  printf("\nIf cmds/s rises with QD => multiple-outstanding pipelining works (latency hidden).\n");
  printf("If a row shows INCOMPLETE => cpl capture missed back-to-back CQEs (needs robust capture / testbench).\n");
  return 0;
}
