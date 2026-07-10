// DIAG: dump the SSD's data-page ACCESS ORDER captured in HW during a 256 KB streamed WRITE then READ.
// cap_val(0x94) at index i (set via 0x90) = {ar_cnt[6:0]<<19, aw_cnt[6:0]<<12, ar_page[i][5:0]<<6, aw_page[i][5:0]}.
//   ar_page[] = order the SSD READ  write-payload pages (WRITE cmd, SSD reads wbuf2)
//   aw_page[] = order the SSD WROTE read-payload  pages (READ  cmd, SSD writes rbuf)
// If a sequence is NOT 0,1,2,...,63 the SSD DMAs pages out of order -> the count-based streaming FC is broken.
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
#define WINW (128*1024/4)
#define DWW  (128*1024/32)
static int wait_busy(){ for(int t=0;t<8000 && (rd(0x80)&1);t++) usleep(100); return (rd(0x80)&1)?-1:0; }
static void cp(int op,uint32_t words,uint32_t base){ wr(0x88,words); wr(0x8C,base); wr(0x84,op); }
static uint32_t patt(uint32_t k){ return 0x5EED0000u + k*0x01010101u; }

int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  uint32_t bytes=256*1024, totdw=bytes/32, nlb=bytes/512-1, nch=bytes/(128*1024);
  int fd=open(p,O_RDWR|O_SYNC); B=(volatile uint32_t*)mmap(0,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);
  wr(0x08,1); long i; for(i=0;i<200000000L && !(rd(0x0C)&1);i++);
  for(i=0;i<400 && !(rd(0x80)&2);i++) usleep(10000);
  if(!(rd(0x80)&2)){ printf("DDR4 not calibrated\n"); return 6; }

  // WRITE 256KB (generates the SSD's write-payload AR reads), then READ 256KB (read-payload AW writes)
  for (uint32_t c=0;c<nch;c++){ for(uint32_t k=0;k<WINW;k++) wr(WBUF+k*4, patt(c*WINW+k)); cp(0,DWW,c*DWW); wait_busy(); }
  cp(2,totdw,0); usleep(2000); wr(0x58,nlb);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0); for(i=0;i<800000000L&&rd(0x64)==cc;i++);} wait_busy();
  cp(3,totdw,0); usleep(200);
  { uint32_t cc=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0); for(i=0;i<800000000L&&rd(0x64)==cc;i++);} wait_busy();

  uint32_t v0=(wr(0x90,0),rd(0x94)); uint32_t arc=(v0>>19)&0x7F, awc=(v0>>12)&0x7F;
  printf("captured: ar_events=%u (WRITE: SSD reads wbuf2)  aw_events=%u (READ: SSD writes rbuf)\n", arc, awc);
  int ar[64], aw[64];
  for (uint32_t k=0;k<64;k++){ wr(0x90,k); uint32_t v=rd(0x94); ar[k]=(v>>6)&0x3F; aw[k]=v&0x3F; }
  printf("WRITE-side page read order (ar):");
  for(uint32_t k=0;k<arc && k<64;k++) printf(" %d", ar[k]); printf("\n");
  printf("READ-side  page write order (aw):");
  for(uint32_t k=0;k<awc && k<64;k++) printf(" %d", aw[k]); printf("\n");
  int ar_ooo=0, aw_ooo=0;
  for(uint32_t k=1;k<arc && k<64;k++) if(ar[k] < ar[k-1]) ar_ooo++;
  for(uint32_t k=1;k<awc && k<64;k++) if(aw[k] < aw[k-1]) aw_ooo++;
  printf("=> WRITE-side regressions=%d, READ-side regressions=%d  (%s)\n",
         ar_ooo, aw_ooo, (ar_ooo||aw_ooo)?"OUT-OF-ORDER SSD DMA":"in-order");
  return 0;
}
