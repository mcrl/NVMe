// Discriminate WHERE the streaming path corrupts: stage host->DDR4 (copy push) then pull DDR4->host (copy pull),
// NO SSD, NO refill/drain. If this round-trip is clean, the copy/DDR4 staging is good and the corruption is in
// the refill/drain/SSD streaming; if it fails, the copy_engine / DDR4 / owner-mux is the culprit.
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
#define WINW (128*1024/4)
#define DWW  (128*1024/32)
static int wait_busy(){ for(int t=0;t<8000 && (rd(0x80)&1);t++) usleep(100); return (rd(0x80)&1)?-1:0; }
static void cp(int op,uint32_t words,uint32_t base){ wr(0x88,words); wr(0x8C,base); wr(0x84,op); }
static uint32_t patt(uint32_t k){ return 0xC0DE0000u + k*0x01010101u; }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t kb = argc>2?(uint32_t)atoi(argv[2]):256, reps=argc>3?(uint32_t)atoi(argv[3]):8;
  int fd=open(p,O_RDWR|O_SYNC); B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }
  uint32_t nch=kb*1024/(128*1024);
  printf("=== copy round-trip (host->DDR4->host, NO SSD) %u KB x%u reps ===\n", kb, reps);
  for (uint32_t r=0;r<reps;r++){
    for (uint32_t c=0;c<nch;c++){                                  // stage each 128KB chunk into DDR4
      for (uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(r*1000003u + c*WINW+k));
      cp(0,DWW,c*DWW); if(wait_busy()){printf("rep%u push%u STUCK\n",r,c);return 5;}
    }
    int bad=0; uint32_t fk=0,fg=0,fe=0;
    for (uint32_t c=0;c<nch;c++){                                  // pull each chunk back and check
      cp(1,DWW,c*DWW); if(wait_busy()){printf("rep%u pull%u STUCK\n",r,c);return 5;}
      for (uint32_t k=0;k<WINW;k++){ uint32_t g=rd(RBUF+k*4), e=patt(r*1000003u + c*WINW+k);
        if(g!=e){ if(!bad){fk=c*WINW+k;fg=g;fe=e;} bad++; } }
    }
    printf("rep%u: %d/%u mismatch %s%s\n", r, bad, kb*1024/4, bad?"FAIL":"PASS",
           bad?({static char s[64]; snprintf(s,64,"  @%u got %08X exp %08X",fk,fg,fe); s;}):"");
  }
  return 0;
}
