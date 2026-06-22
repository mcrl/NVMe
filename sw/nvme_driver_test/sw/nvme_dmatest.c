// Real host-data round-trip at scale: host buffer -> FPGA wbuf (on-chip SRAM) -> SSD -> NAND -> SSD ->
// FPGA rbuf -> host.  The data buffers are now 128 KB block-RAM each, reachable through a 1 MB host BAR
// window (wbuf @ 0x40000, rbuf @ 0x60000), and the PRP layout is dense so the host fills ONE flat buffer.
// For each size we write a known pattern into wbuf, issue a WRITE then a READ of the same LBA, read rbuf
// back and check the round-trip.  Run: nvme_dmatest [resource0]
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
#define WBUF 0x40000u      // host writes write-payload here (128 KB window)
#define RBUF 0x60000u      // host reads captured read-payload here (128 KB window)
#define MAPSZ (1024*1024)  // full 1 MB BAR
static uint32_t patt(uint32_t base,int k){ return base + (uint32_t)k*0x01010101u; }

// run one size: bytes total, nlb = (bytes/512)-1, unique pattern base so a stale rbuf cannot mask an error
static int run_size(const char*tag, uint32_t bytes, uint32_t base){
  uint32_t words = bytes/4, nlb = bytes/512 - 1;
  long i;
  for (uint32_t k=0;k<words;k++) wr(WBUF + k*4, patt(base,k));   // 1) fill wbuf (flat, dense)
  wr(0x58,nlb);
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0); // 2) WRITE (SSD reads wbuf -> NAND)
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("  %s WRITE TIMEOUT\n",tag);return 3;} }
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0); // 3) READ (SSD reads NAND -> rbuf)
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("  %s READ TIMEOUT\n",tag);return 3;} }
  int bad=0; uint32_t fg=0,fe=0; uint32_t fk=0;                  // 4) verify rbuf == pattern
  for (uint32_t k=0;k<words;k++){ uint32_t g=rd(RBUF + k*4); if(g!=patt(base,k)){ if(!bad){fg=g;fe=patt(base,k);fk=k;} bad++; } }
  printf("  %-6s %6u KB (nlb=%u): %d/%u words mismatch => %s\n", tag, bytes/1024, nlb, bad, words,
         bad==0?"PASS":"FAIL");
  if(bad) printf("    first mismatch @word %u: got %08X exp %08X\n", fk, fg, fe);
  return bad?4:0;
}

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,MAPSZ,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}

  // autonomous bring-up (host only triggers; FPGA does enum/queues/cfg)
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  printf("bring-up ready\n");

  int rc=0;
  rc |= run_size("4KB",   4*1024,  0xD00D0000u);   // regression (1 page, no PRP-list)
  rc |= run_size("32KB",  32*1024, 0xA5A50000u);   // 8 pages  (PRP-list)
  rc |= run_size("128KB", 128*1024,0x5EED0000u);   // 32 pages (full buffer)
  printf("=> %s\n", rc==0 ? "ALL PASS (real host data round-tripped host->wbuf->SSD->NAND->SSD->rbuf->host)"
                          : "FAIL");
  return rc;
}
