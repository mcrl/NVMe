// Read the PL DDR4 cal/BIST status (CSR 0x80). The DDR4 controller calibrates autonomously after reset; this
// just polls and decodes:  status = { 8'hD4 sig, err[15:0], 5'b0, bist_pass, bist_done, cal_done }.
//   sig != 0xD4  -> CSR/logic not present (wrong bitstream?)
//   cal_done=0   -> DDR4 never calibrated (no J19 clock / DRAM absent / pin or timing issue)
//   cal_done=1, bist_done=1, bist_pass=1, err=0 -> DDR4 calibrated AND real AXI read/write verified
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
static volatile uint32_t *B;
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  uint32_t s=0; int i;
  for(i=0;i<200;i++){ s=B[0x80/4]; if(s&1) break; usleep(20000); }   // poll cal_done up to ~4 s
  uint32_t sig=(s>>24)&0xFF, err=(s>>8)&0xFFFF, pass=(s>>2)&1, done=(s>>1)&1, cal=s&1;
  printf("ddr4_status @0x80 = %08X\n", s);
  printf("  signature = %02X (%s)\n", sig, sig==0xD4?"OK - DDR4 logic present":"BAD - wrong bitstream/CSR");
  printf("  cal_done  = %u (%s)\n", cal, cal?"DDR4 CALIBRATED":"not calibrated");
  if((err>>8)==0xFA){ const char*sn[]={"?","AW","W","B","AR","R"}; int n=err&7;
    printf("  bist_done = %u   AXI HANG at state %s (BIST stalled)\n", done, n<6?sn[n]:"?"); }
  else printf("  bist_done = %u   bist_pass = %u   err_count = %u\n", done, pass, err);
  if(cal && done && pass && err==0) printf("=> PASS: DDR4 calibrated + AXI read/write verified on board\n");
  else if(cal) printf("=> DDR4 calibrated but BIST not clean (done=%u pass=%u err=%u)\n", done, pass, err);
  else printf("=> DDR4 did NOT calibrate (check J19 ref clock / DRAM / pinout)\n");
  return (cal&&done&&pass&&err==0)?0:1;
}
