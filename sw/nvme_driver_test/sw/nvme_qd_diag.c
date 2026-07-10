// QD>1 read anomaly pinpoint: submit exactly QD read commands in ONE batch (distinct per-command buffers and
// distinct LBAs), then print the RAW hardware-counter deltas:
//   cpl_count (0x64)     delta -> should be QD            (if > QD: CQE inflation in the FPGA cpl logic)
//   w_data_beats (0x6C)  delta -> should be QD*beats/cmd  (if < that: read-payload never captured/written)
// beats/cmd = (nlb+1)*512/32 = (nlb+1)*16. Run: nvme_qd_diag <resource0> <QD> <nlb> <distinct0|1>
#include <stdio.h>
#include <stdlib.h>
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
static int encb(int b){switch(b){case 128:return 0;case 256:return 1;case 512:return 2;case 1024:return 3;default:return -1;}}
static void bringup(){
  wr(0x04,1); usleep(1000000); wr(0x04,0);
  wr(0x30,0); wcfg(0x18,0x100); rcfg(0x18);
  wcfg((1u<<20)|0x04,0x6); wcfg((1u<<20)|0x10,0x4000); wcfg((1u<<20)|0x14,0x0);
  uint32_t rdc=rcfg(0x78); rdc=(rdc&~(0x7u<<5))|((uint32_t)encb(256)<<5); rdc=(rdc&~(0x7u<<12))|((uint32_t)encb(256)<<12); wcfg(0x78,rdc);
  uint32_t dc=rcfg((1u<<20)|0x78); dc=(dc&~(0x7u<<5))|((uint32_t)encb(256)<<5); dc=(dc&~(0x7u<<12))|((uint32_t)encb(256)<<12); wcfg((1u<<20)|0x78,dc);
  wcfg(0x148,0x1); rcfg(0x148); wr(0x30,1);
  wr(0x30,0); wctrl(0x14,0x0); while(rctrl(0x1C)!=0);
  wctrl(0x24,(64<<16)|64); wctrl(0x28,0x8000); wctrl(0x2C,0); wctrl(0x30,0x9000); wctrl(0x34,0);
  wctrl(0x14,0x1); while(rctrl(0x1C)!=1); wr(0x30,1);
  { uint32_t c=rd(0x64); wr(0x40,1); while(rd(0x64)==c); }
  { uint32_t c=rd(0x64); wr(0x44,1); while(rd(0x64)==c); }
  printf("  controller READY\n");
}
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int QD=argc>2?atoi(argv[2]):2; int nlb=argc>3?atoi(argv[3]):255; int distinct=argc>4?atoi(argv[4]):1;
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  printf("== bringup ==\n"); bringup();
  for(int i=0;i<8;i++) wr(0x100+4*i,0xC0DE0000+i);
  int blocks=nlb+1; long beats_cmd=(long)blocks*512/32;
  wr(0x58,nlb);
  #define PRP1(k) (distinct ? (0x10000u+((unsigned)(k))*0x10000u) : 0xC000u)
  // pre-write the QD LBAs so the reads return real data (not short-circuited never-written)
  printf("== pre-write %d LBAs (nlb=%d, %ld beats/cmd) ==\n", QD, nlb, beats_cmd);
  for(int k=0;k<QD;k++){ uint32_t c=rd(0x64);
    for(int j=0;j<8;j++) wr(0x100+4*j, 0xC0DE0000u + ((unsigned)k<<24) + j);  // DISTINCT data per LBA (defeat SSD dedup)
    wr(0x50,PRP1(k)); wr(0x54,k*blocks); wr(0x4C,0);
    long it=0; for(; it<8000000L && rd(0x64)==c; it++); if(rd(0x64)==c){printf("  pre-write %d STALL\n",k);} }
  // one batch of QD reads; WAIT ON raw_w_beats (actual data) reaching the full expected count -- NOT on
  // cpl_count, which is the suspected-inflated counter. This way we measure the true data delivered.
  uint32_t cpl0=rd(0x64), beat0=rd(0x6C), raw0=rd(0x70), brst0=rd(0x74);
  long expraw = QD*beats_cmd;   // full read payload beats (CQE beats are tiny, ignore in the threshold)
  int spacedus = getenv("SPACEDUS")?atoi(getenv("SPACEDUS")):0;   // us between command submissions
  printf("== submit %d reads (distinct=%d spacing=%dus) ==\n", QD, distinct, spacedus);
  for(int k=0;k<QD;k++){
    wr(0x50,PRP1(k)); wr(0x54,k*blocks); wr(0x48,0);
    if(spacedus) usleep(spacedus);
  }
  // wait until data settles: stop when raw reaches full, OR when it stalls (no growth for a while), OR cap
  long it=0; uint32_t prev=0, stall=0;
  for(; it<3000000L && (long)(rd(0x70)-raw0)<expraw; it++){
    uint32_t cur=rd(0x70); if(cur==prev){ if(++stall>200000) break; } else { stall=0; prev=cur; }
  }
  usleep(5000);  // let any trailing CQE land
  uint32_t dcpl=rd(0x64)-cpl0, dbeat=rd(0x6C)-beat0, draw=rd(0x70)-raw0, dbrst=rd(0x74)-brst0;
  printf("\n  RESULT QD=%d nlb=%d:\n", QD, nlb);
  printf("    cpl_count delta    = %u   (expect %d)   %s\n", dcpl, QD, dcpl==(uint32_t)QD?"ok":(dcpl>(uint32_t)QD?"** CQE INFLATION **":"(incomplete)"));
  printf("    w_data_beats delta = %u   (expect %ld)  %s\n", dbeat, QD*beats_cmd,
         dbeat==(uint32_t)(QD*beats_cmd)?"ok (all payload captured)":"** READ-DATA SHORT **");
  printf("    raw_w_beats delta  = %u   (expect ~%ld data + %d cqe = %ld)\n", draw, QD*beats_cmd, QD, QD*beats_cmd+QD);
  printf("    raw_w_bursts delta = %u   (data bursts; expect %ld @ 8 beats/burst)\n", dbrst, QD*beats_cmd/8);
  printf("    => VERDICT: %s\n",
         (draw >= (uint32_t)(QD*beats_cmd)) ? "FPGA received full data but w_data_beats undercounts -> FPGA COUNTER/CAPTURE BUG"
                                            : "FPGA received only ~half raw W beats -> SSD SENT LESS (SSD-side short-circuit)");
  printf("    beats per completion = %.1f   (full-cmd beats = %ld)\n", dcpl?(double)dbeat/dcpl:0, beats_cmd);
  return 0;
}
