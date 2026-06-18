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

int g_mps=256, g_mrrs=256;   // bytes to program into SSD PCIe Device Control (0 = leave as-is)
int g_distinct=0;            // 1 = distinct PRP1 per outstanding command
static int encb(int b){switch(b){case 128:return 0;case 256:return 1;case 512:return 2;case 1024:return 3;case 2048:return 4;case 4096:return 5;default:return -1;}}
static void bringup(){
  wr(0x04,1); usleep(1000000); wr(0x04,0);
  wr(0x30,0); wcfg(0x18,0x100); rcfg(0x18);
  printf("  NVMe id=%08X\n", rcfg((1u<<20)|0x00));
  wcfg((1u<<20)|0x04,0x6); wcfg((1u<<20)|0x10,0x4000); wcfg((1u<<20)|0x14,0x0);
  // tune PCIe Device Control MPS/MRRS on BOTH the root port (no 1<<20) and the SSD (1<<20).
  // MPS must match on both ends; set root first, then SSD, before any IO (no traffic in flight).
  if(g_mps||g_mrrs){
    uint32_t rdc=rcfg(0x78);                                   // root-port DevControl @ PCIe cap 0x70+8
    if(g_mps>0)  rdc=(rdc&~(0x7u<<5)) |((uint32_t)encb(g_mps)<<5);
    if(g_mrrs>0) rdc=(rdc&~(0x7u<<12))|((uint32_t)encb(g_mrrs)<<12);
    wcfg(0x78,rdc);
    uint32_t dc=rcfg((1u<<20)|0x78);                           // SSD DevControl
    if(g_mps>0)  dc=(dc&~(0x7u<<5)) |((uint32_t)encb(g_mps)<<5);
    if(g_mrrs>0) dc=(dc&~(0x7u<<12))|((uint32_t)encb(g_mrrs)<<12);
    wcfg((1u<<20)|0x78,dc);
    uint32_t rv=rcfg(0x78), sv=rcfg((1u<<20)|0x78);
    printf("  MPS/MRRS root=(%s/%s) ssd=(%s/%s)\n",
      ((const char*[]){"128","256","512","1024","2048","4096"})[(rv>>5)&7],
      ((const char*[]){"128","256","512","1024","2048","4096"})[(rv>>12)&7],
      ((const char*[]){"128","256","512","1024","2048","4096"})[(sv>>5)&7],
      ((const char*[]){"128","256","512","1024","2048","4096"})[(sv>>12)&7]);
  }
  wcfg(0x148,0x1); rcfg(0x148); wr(0x30,1);
  wr(0x30,0); wctrl(0x14,0x0); while(rctrl(0x1C)!=0);
  wctrl(0x24,(64<<16)|64); wctrl(0x28,0x8000); wctrl(0x2C,0); wctrl(0x30,0x9000); wctrl(0x34,0);
  wctrl(0x14,0x1); while(rctrl(0x1C)!=1); wr(0x30,1);
  { uint32_t c=rd(0x64); wr(0x40,1); while(rd(0x64)==c); }
  { uint32_t c=rd(0x64); wr(0x44,1); while(rd(0x64)==c); }
  printf("  controller READY, IO queues created (depth 64)\n");
}

// trig 0x4C=write, 0x48=read. Sweep blocks/command (nlb+1) at queue depth QD.
// REALMB/s = FPGA data-beat counter (0x68 write-payload R / 0x6C read-payload W, x32 B) = actual bytes
// moved over OcuLink. cmplMB/s = completions x size (overcounts if the SSD fast-acks ahead of real transfer).
static void sweep(uint32_t trig,const char*name,int QD){
  uint32_t beatreg = (trig==0x4C) ? 0x68 : 0x6C;
  printf("\n== %s : bandwidth vs transfer size (QD=%d)  [Gen3 x4 ceiling ~3940 MB/s] ==\n",name,QD);
  printf("  %-7s %-8s %-10s %-12s %-12s %s\n","blocks","KB/cmd","cmds/s","cmplMB/s","REALMB/s","status");
  int nlbs[]={255,1023,2047};
  for(unsigned n=0;n<sizeof(nlbs)/sizeof(int);n++){
    int nlb=nlbs[n]; int blocks=nlb+1; long bytes_cmd=(long)blocks*512;
    int cmds = (int)(128L*1024*1024 / bytes_cmd); if(cmds>1500) cmds=1500; if(cmds<QD*4) cmds=QD*4;
    int batches = cmds/QD; if(batches<1) batches=1;
    wr(0x58,nlb);
    // For READ, pre-write the same LBAs (QD-batched) so reads return real data instead of being
    // short-circuited as never-written -> gives the true read transfer rate (from SSD cache/NAND).
    // g_distinct: give each of the QD outstanding commands its own PRP1 buffer (base 0x10000, stride 0x10000)
    // so QD>1 commands don't overlap on the same host buffer (this design uses a single nvme_addr otherwise).
    #define PRP1(k) (g_distinct ? (0x10000u + ((unsigned)((k)%QD))*0x10000u) : 0xC000u)
    if(trig==0x48){
      uint32_t pc=rd(0x64); unsigned ps=0;
      for(int b=0;b<batches;b++){ for(int k=0;k<QD;k++){ wr(0x50,PRP1(k)); wr(0x54,(b*QD+k)*blocks%0x100000); wr(0x4C,0); ps++; }
        long it=0; for(; it<8000000L && (uint32_t)(rd(0x64)-pc)<ps; it++); }
    }
    uint32_t cbase=rd(0x64), bbase=rd(beatreg), submitted=0; int stalled=0;
    double t0=now();
    for(int b=0;b<batches && !stalled;b++){
      for(int k=0;k<QD;k++){ wr(0x50,PRP1(k)); wr(0x54,(b*QD+k)*blocks % 0x100000); wr(trig,0); submitted++; }
      long it=0; for(; it<8000000L && (uint32_t)(rd(0x64)-cbase)<submitted; it++);
      if((uint32_t)(rd(0x64)-cbase)<submitted) stalled=1;
    }
    double s=now()-t0; uint32_t done=rd(0x64)-cbase; uint32_t beats=rd(beatreg)-bbase;
    double cmpl=(done/s)*bytes_cmd/1e6, real=(double)beats*32.0/1e6/s;
    if(stalled) printf("  %-7d %-8.1f %-10s %-12s %-12.1f STALL %u/%u\n",blocks,bytes_cmd/1024.0,"-","-",real,done,submitted);
    else        printf("  %-7d %-8.1f %-10.0f %-12.1f %-12.1f ok\n",blocks,bytes_cmd/1024.0,done/s,cmpl,real);
  }
}

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int QD=argc>3?atoi(argv[3]):8;
  if(argc>4) g_mps=atoi(argv[4]);
  if(argc>5) g_mrrs=atoi(argv[5]);
  if(argc>6) g_distinct=atoi(argv[6]);
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
