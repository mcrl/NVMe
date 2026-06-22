// Real host-data round-trip: host buffer -> FPGA wbuf -> SSD -> NAND -> SSD -> FPGA rbuf -> host.
// Writes a known 4 KB pattern into wbuf (BAR 0x8000), issues a WRITE command, then a READ command of the same
// LBA, reads rbuf (BAR 0x9000) and checks it equals the pattern. This proves actual host data (not the old
// 32 B replay) is moved through the SSD.  Run: nvme_dmatest <resource0>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
static volatile uint32_t *B;
static uint32_t rd(uint32_t o){return B[o/4];}
static void wr(uint32_t o,uint32_t v){B[o/4]=v;}
#define WBUF 0x8000u      // host writes write-payload here
#define RBUF 0x9000u      // host reads captured read-payload here
#define WORDS 1024        // 4 KB / 4 B
static uint32_t patt(int k){ return 0xD00D0000u + (uint32_t)k*0x01010101u; }
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}

  // autonomous bring-up
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  printf("bring-up ready\n");

  // 1) host fills wbuf with a known 4 KB pattern (distinct from the old 0xC0DE.. replay)
  for(int k=0;k<WORDS;k++) wr(WBUF + k*4, patt(k));

  // 2) WRITE command (SSD reads wbuf -> NAND), LBA 0, 4 KB
  wr(0x58,7); { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);
    for(i=0;i<8000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("WRITE TIMEOUT\n");return 3;} }
  // 3) READ command (SSD reads NAND -> rbuf), same LBA
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0);
    for(i=0;i<8000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("READ TIMEOUT\n");return 3;} }

  // 4) verify rbuf == pattern (the data made the full host->SSD->host round-trip)
  int bad=0; uint32_t first_got=0,first_exp=0;
  for(int k=0;k<WORDS;k++){ uint32_t g=rd(RBUF + k*4); if(g!=patt(k)){ if(!bad){first_got=g;first_exp=patt(k);} bad++; } }
  printf("rbuf vs pattern: %d/%d words mismatch\n", bad, WORDS);
  if(bad) printf("  first mismatch: got %08X exp %08X\n", first_got, first_exp);
  printf("=> %s\n", bad==0 ? "PASS (real host data round-tripped host->wbuf->SSD->NAND->SSD->rbuf->host)"
                           : "FAIL");
  return bad?4:0;
}
