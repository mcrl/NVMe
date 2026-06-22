// Localize the 128 KB failure: run WRITE then READ of 128 KB at QD=1 and print the HW beat counters
// (write-payload R, read-payload W) deltas + CQE status, so we know which side truncates and where.
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
static uint32_t BYTES, WORDS, NPG;
static uint32_t patt(int k){ return 0x5EED0000u + (uint32_t)k*0x01010101u; }
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t kb = argc>2 ? (uint32_t)atoi(argv[2]) : 128;
  BYTES = kb*1024; WORDS = BYTES/4; NPG = BYTES/4096;
  printf("=== size %u KB (%u pages) ===\n", kb, NPG);
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  if(!(rd(0x0C)&1)){ printf("bring-up FAIL\n"); return 2; }
  printf("bring-up ready\n");
  for (uint32_t k=0;k<WORDS;k++) wr(WBUF + k*4, patt(k));
  uint32_t nlb = BYTES/512 - 1;
  wr(0x58,nlb);
  uint32_t r0=rd(0x68), w0=rd(0x6C), raw0=rd(0x70), rb0=rd(0x74);
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("WRITE TIMEOUT\n");return 3;} }
  uint32_t r1=rd(0x68); uint32_t st_w=rd(0x60);
  { uint32_t c=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0);
    for(i=0;i<200000000L && rd(0x64)==c;i++); if(rd(0x64)==c){printf("READ TIMEOUT\n");return 3;} }
  uint32_t w1=rd(0x6C), raw1=rd(0x70), rb1=rd(0x74); uint32_t st_r=rd(0x60);
  printf("expect 4096 data beats each way (128 KB / 32 B)\n");
  printf("WRITE: r_data_beats delta = %u   CQE status(0x60)=%08X\n", r1-r0, st_w);
  printf("READ : w_data_beats delta = %u   raw_w_beats delta = %u   raw_w_bursts delta = %u   CQE status=%08X\n",
         w1-w0, raw1-raw0, rb1-rb0, st_r);
  int bad=0,fk=-1; for (uint32_t k=0;k<WORDS;k++){ uint32_t g=rd(RBUF+k*4); if(g!=patt(k)){ if(fk<0)fk=k; bad++; } }
  printf("rbuf mismatch=%d/%u  first@word=%d (=%d KB, page %d)\n", bad,WORDS,fk, fk>=0?fk*4/1024:-1, fk>=0?fk/1024:-1);
  // per-page status: '.'=match  '0'=all-zero  'X'=non-zero-but-wrong
  printf("per-page (%u): ", NPG);
  for (uint32_t pg=0; pg<NPG; pg++){
    int m=0,z=0; for (int j=0;j<1024;j++){ uint32_t k=pg*1024+j, g=rd(RBUF+k*4); if(g==patt(k))m++; else if(g==0)z++; }
    printf("%c", m==1024?'.':(z==1024?'0':'X'));
  }
  printf("\n");
  return 0;
}
