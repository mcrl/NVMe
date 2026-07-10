// Real host-data round-trip THROUGH the 4 GB FPGA DDR4: host buffer -> wbuf SRAM -> (copy engine) -> DDR4 ->
// wbuf2 -> SSD -> NAND -> SSD -> DDR4 -> rbuf2 SRAM -> host. The on-chip SRAMs are host/SSD-facing staging; the
// data genuinely resides in DDR4 between the host and the SSD. CSR: 0x84 write triggers a copy (bit0: 0=write
// wbuf->wbuf2, 1=read rbuf->rbuf2), 0x88=words, 0x80 read bit0=copy busy / bit1=DDR4 cal_done.
//   Run: nvme_dmatest [resource0]
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
#define WBUF 0x40000u
#define RBUF 0x60000u
#define MAPSZ (1024*1024)
static uint32_t patt(uint32_t base,int k){ return base + (uint32_t)k*0x01010101u; }

// trigger a DDR4 copy (chan 0=write wbuf->wbuf2, 1=read rbuf->rbuf2) and wait for it to finish
static int cp_copy(int chan){
  wr(0x84, chan); usleep(3000);              // toggle trigger; copy of 128 KB takes <100 us
  for(int t=0;t<2000 && (rd(0x80)&1);t++) usleep(1000);
  return (rd(0x80)&1) ? -1 : 0;              // -1 if still busy (stuck)
}

static int run_size(const char*tag, uint32_t bytes, uint32_t base){
  uint32_t words = bytes/4, dwords = bytes/32, nlb = bytes/512 - 1;  // dwords = 256-b words to copy
  long i;
  for (uint32_t k=0;k<words;k++) wr(WBUF + k*4, patt(base,k));        // 1) fill wbuf SRAM
  wr(0x88, dwords);
  if (cp_copy(0)) { printf("  %-6s wbuf->DDR4->wbuf2 copy STUCK\n", tag); return 5; }  // 2) host data -> DDR4
  wr(0x58,nlb);
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);     // 3) WRITE (SSD reads wbuf2 from DDR4)
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("  %s WRITE TIMEOUT\n",tag);return 3;} }
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0);     // 4) READ (SSD writes rbuf in DDR4 path)
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("  %s READ TIMEOUT\n",tag);return 3;} }
  if (cp_copy(1)) { printf("  %-6s rbuf->DDR4->rbuf2 copy STUCK\n", tag); return 5; }  // 5) DDR4 -> host buffer
  int bad=0; uint32_t fg=0,fe=0,fk=0;                                 // 6) verify rbuf2 == pattern
  for (uint32_t k=0;k<words;k++){ uint32_t g=rd(RBUF + k*4); if(g!=patt(base,k)){ if(!bad){fg=g;fe=patt(base,k);fk=k;} bad++; } }
  printf("  %-6s %6u KB: %d/%u words mismatch => %s\n", tag, bytes/1024, bad, words, bad==0?"PASS":"FAIL");
  if(bad) printf("    first mismatch @word %u: got %08X exp %08X\n", fk, fg, fe);
  return bad?4:0;
}

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,MAPSZ,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}

  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);                  // wait DDR4 cal_done
  if(!(rd(0x80)&2)){ printf("DDR4 cal_done NOT set (status %08X)\n", rd(0x80)); return 6; }
  printf("bring-up ready, DDR4 calibrated\n");

  int rc=0;
  rc |= run_size("4KB",   4*1024,  0xD00D0000u);
  rc |= run_size("32KB",  32*1024, 0xA5A50000u);
  rc |= run_size("128KB", 128*1024,0x5EED0000u);
  printf("=> %s\n", rc==0 ? "ALL PASS (real host data round-tripped host->wbuf->DDR4->wbuf2->SSD->NAND->SSD->DDR4->rbuf2->host)"
                          : "FAIL");
  return rc;
}
