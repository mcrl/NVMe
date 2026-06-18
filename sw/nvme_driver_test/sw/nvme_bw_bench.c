// Bandwidth vs transfer size: sweep NLB (blocks/command) at a fixed QD and report block-level MB/s.
// The 512 B/command bench is IOPS-bound; larger transfers amortize the per-command overhead and should
// approach the OcuLink Gen3 x4 ceiling (256-bit @ 125 MHz = 4 GB/s). NOTE: PRP2 (DW8) is hardwired 0, so
// only PRP1 is provided -> the SSD can address at most one 4 KB page (nlb<=7); bigger nlb may stall/short.
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
  { uint32_t c=rd(0x64); wr(0x40,1); while(rd(0x64)==c); }
  { uint32_t c=rd(0x64); wr(0x44,1); while(rd(0x64)==c); }
  printf("  controller READY, IO queues created (depth 64)\n");
}

// trig 0x4C=write, 0x48=read. Sweep blocks/command (nlb+1) at queue depth QD.
static void sweep(uint32_t trig,const char*name,int QD){
  printf("\n== %s : bandwidth vs transfer size (QD=%d) ==\n",name,QD);
  printf("  %-8s %-8s %-10s %-12s %-10s\n","blocks","KB/cmd","cmds/s","blkMB/s","status");
  int nlbs[]={0,1,2,3};
  for(unsigned n=0;n<sizeof(nlbs)/sizeof(int);n++){
    int nlb=nlbs[n]; int blocks=nlb+1; long bytes_cmd=(long)blocks*512;
    // aim ~128 MB per point, but cap command count to keep runtime bounded
    int cmds = (int)(128L*1024*1024 / bytes_cmd); if(cmds>1500) cmds=1500; if(cmds<QD*4) cmds=QD*4;
    int batches = cmds/QD; if(batches<1) batches=1;
    wr(0x58,nlb);
    uint32_t cbase=rd(0x64), submitted=0; int stalled=0;
    double t0=now();
    for(int b=0;b<batches && !stalled;b++){
      for(int k=0;k<QD;k++){ wr(0x54,(b*QD+k)*blocks % 0x100000); wr(trig,0); submitted++; }
      long it=0; for(; it<3000000L && (uint32_t)(rd(0x64)-cbase)<submitted; it++);
      if((uint32_t)(rd(0x64)-cbase)<submitted) stalled=1;
    }
    double s=now()-t0; uint32_t done=rd(0x64)-cbase; double ips=done/s;
    double mbps=ips*bytes_cmd/1e6;
    printf("  %-8d %-8.1f %-10.0f %-12.1f %s\n",blocks,bytes_cmd/1024.0,ips,mbps,
           stalled?"STALL/short":"ok");
  }
}

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int QD=argc>3?atoi(argv[3]):8;
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  printf("== bring up ==\n"); bringup();
  for(int i=0;i<8;i++) wr(0x100+4*i,0xC0DE0000+i);
  wr(0x50,0xC000);
  const char*mode=argc>2?argv[2]:"wr";
  if(mode[0]=='r') sweep(0x48,"READ",QD);
  else if(mode[0]=='w') sweep(0x4C,"WRITE",QD);
  else { sweep(0x4C,"WRITE",QD); sweep(0x48,"READ",QD); }
  printf("\nblkMB/s = block-level rate the SSD/link sees. OcuLink Gen3 x4 ceiling ~4 GB/s (256b@125MHz).\n");
  return 0;
}
