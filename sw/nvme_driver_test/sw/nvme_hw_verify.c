// Verify the Phase1+2 RTL changes on HW:
//  - real SLBA (CSR 0x54 = start LBA): write distinct patterns to distinct LBAs, read back, compare
//  - read-data return (CSR 0x200-0x21C)
//  - completion status (CSR 0x60)
//  - sustained operation past the old 16-command stall (SQ tail wrap + depth 64)
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>
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
  printf("  NVMe id=%08X (expect A808144D)\n", rcfg((1u<<20)|0x00));
  wcfg((1u<<20)|0x04,0x6); wcfg((1u<<20)|0x10,0x4000); wcfg((1u<<20)|0x14,0x0);
  wcfg(0x148,0x1); rcfg(0x148); wr(0x30,1);
  wr(0x30,0); wctrl(0x14,0x0); while(rctrl(0x1C)!=0);
  wctrl(0x24,(64<<16)|64); wctrl(0x28,0x8000); wctrl(0x2C,0); wctrl(0x30,0x9000); wctrl(0x34,0);
  wctrl(0x14,0x1); while(rctrl(0x1C)!=1); wr(0x30,1);
  wr(0x40,1); while(rd(0x5C)!=1);
  wr(0x44,1); while(rd(0x5C)!=1);
  printf("  controller READY, IO queues created\n");
}
// one IO command. trig 0x4C=write 0x48=read. returns cpl status (0x60).
static uint32_t io(uint32_t trig,uint32_t lba,uint32_t nlb,const uint32_t*wdat){
  wr(0x50,0xC000);      // PRP / FPGA buffer
  wr(0x54,lba);         // SLBA  (NEW)
  wr(0x58,nlb);
  if(wdat) for(int i=0;i<8;i++) wr(0x100+4*i,wdat[i]);
  wr(trig,0);
  waitN(0x5C,0,1000000); waitN(0x5C,1,40000000L);
  return rd(0x60);      // completion status (NEW)
}
static void rdback(uint32_t*out){ for(int i=0;i<8;i++) out[i]=rd(0x200+4*i); }  // NEW

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  printf("== bring up ==\n"); bringup();

  uint32_t PA[8]={0xAA000001,0xAA000002,0xAA000003,0xAA000004,0xAA000005,0xAA000006,0xAA000007,0xAA000008};
  uint32_t PB[8]={0xBB0000F1,0xBB0000F2,0xBB0000F3,0xBB0000F4,0xBB0000F5,0xBB0000F6,0xBB0000F7,0xBB0000F8};
  uint32_t got[8];

  printf("\n== TEST 1: SLBA + read-back + integrity ==\n");
  uint32_t s1=io(0x4C,100,0,PA); printf("  WRITE PA -> LBA 100, status=%08X\n",s1);
  uint32_t s2=io(0x4C,200,0,PB); printf("  WRITE PB -> LBA 200, status=%08X\n",s2);
  io(0x48,100,0,NULL); rdback(got);
  int okA=!memcmp(got,PA,32);
  printf("  READ  LBA 100 -> %08X %08X .. %08X  %s\n",got[0],got[1],got[7], okA?"== PA OK":"MISMATCH");
  io(0x48,200,0,NULL); rdback(got);
  int okB=!memcmp(got,PB,32);
  printf("  READ  LBA 200 -> %08X %08X .. %08X  %s\n",got[0],got[1],got[7], okB?"== PB OK":"MISMATCH");
  // cross-check: LBA 100 must NOT equal PB (proves distinct LBAs, not all LBA0)
  io(0x48,100,0,NULL); rdback(got); int distinct = memcmp(got,PB,32)!=0 && !memcmp(got,PA,32);
  printf("  RE-READ LBA100 still PA (distinct from LBA200): %s\n", distinct?"YES OK":"NO");
  printf("  >> SLBA+readback+integrity: %s\n", (okA&&okB&&distinct)?"PASS":"FAIL");

  printf("\n== TEST 2: completion status field (0x60) ==\n");
  printf("  last status DW3 = %08X  (SC/SCT bits [31:17] == 0 => success: %s)\n", s2, ((s2>>17)==0)?"YES":"NO/err");

  printf("\n== TEST 3: sustained operation (was stalling at ~16) ==\n");
  int N=120, done=0;
  for(int k=0;k<N;k++){
    wr(0x50,0xC000); wr(0x54,100); wr(0x58,0);
    for(int i=0;i<8;i++) wr(0x100+4*i,PA[i]);
    wr(0x4C,0);
    waitN(0x5C,0,1000000);
    if(!waitN(0x5C,1,30000000L)) break;
    done++;
  }
  printf("  completed %d / %d back-to-back writes %s\n", done, N, done>=64?"[wrap OK, >=64]":(done>16?"[better than 16]":"[still ~16 -> wrap not effective]"));
  printf("  (note: full unlimited sustain needs CQ-head doorbell ring = next iteration)\n");
  return 0;
}
