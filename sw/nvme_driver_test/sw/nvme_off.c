// Isolate the page-11 boundary from the PRP-list logic: do a SINGLE-page (4 KB) round-trip whose PRP1 points
// directly at the data-window page <pg> (oculink 0xC000 + pg*0x1000), so NO PRP list is involved. The host
// fills/reads that page's slice of wbuf/rbuf (word pg*128 ..). If this passes for pg=11+, the word-1408 host
// + offset path is fine and the multi-page failure is purely the PRP-list walker.  Run: nvme_off <res0> <pg>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
static volatile uint32_t *B;
static uint32_t rd(uint32_t o){return B[o/4];}
static void wr(uint32_t o,uint32_t v){B[o/4]=v;}
#define WBUF 0x40000u
#define RBUF 0x60000u
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t pg = argc>2 ? (uint32_t)atoi(argv[2]) : 11;
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  uint32_t prp1 = 0xC000u + pg*0x1000u;        // oculink data-window page <pg>
  uint32_t hbyte = pg*4096u;                   // host buffer byte offset for that page
  for (int k=0;k<1024;k++) wr(WBUF + hbyte + k*4, 0xC0DE0000u + k);   // fill that page's wbuf slice
  wr(0x58,7);                                  // 1 page = 8 LBA
  { uint32_t c=rd(0x64); wr(0x50,prp1); wr(0x54,0); wr(0x4C,0);
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("WRITE TIMEOUT\n");return 3;} }
  { uint32_t c=rd(0x64); wr(0x50,prp1); wr(0x54,0); wr(0x48,0);
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("READ TIMEOUT\n");return 3;} }
  int bad=0; uint32_t fg=0; int fk=-1;
  for (int k=0;k<1024;k++){ uint32_t g=rd(RBUF + hbyte + k*4); if(g!=(0xC0DE0000u+k)){ if(fk<0){fk=k;fg=g;} bad++; } }
  printf("single-page @pg=%u (PRP1=0x%X, host byte 0x%X): %d/1024 mismatch => %s",
         pg, prp1, hbyte, bad, bad==0?"PASS":"FAIL");
  if(bad) printf("  (first @word %d got %08X)", fk, fg);
  printf("\n");
  return bad?4:0;
}
