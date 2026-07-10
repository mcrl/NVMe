// Verify the AUTONOMOUS hardware bring-up: the host does NOT run the ~20-step bringup() sequence anymore.
// It only: pulses sw_reset, writes CSR 0x08 (kick the HW bring-up sequencer), polls 0x0C bit0 (ready), then
// issues a write + a read and checks they complete. If the FPGA built the PCIe/NVMe queues itself, the I/O
// completes; if not, it times out.  Run: nvme_autobringup <resource0>
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
static uint32_t rcfg(uint32_t a){wr(0x24,a);wr(0x20,1);waitN(0x2C,1,8000000);return rd(0x28);}
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}

  printf("== autonomous bring-up (host does NO config sequence) ==\n");
  wr(0x04,1); usleep(200000); wr(0x04,0); usleep(50000);   // sw_reset pulse -> sequencer at idle
  uint32_t c0=rd(0x64);
  wr(0x08,1);                                              // <-- the ONLY config the host does: kick bring-up
  long i; for(i=0;i<200000000L;i++){ uint32_t s=rd(0x0C); if(s&1) break; }
  uint32_t st=rd(0x0C);
  if(!(st&1)){ printf("  FAIL: bring-up never asserted ready (0x0C=%08X, busy=%d)\n", st, (st>>1)&1); return 2; }
  uint32_t cst=rd(0x60);
  printf("  HW bring-up READY (0x0C=%08X). cpl_count rose by %u (admin IOCQ+IOSQ). cpl_status=%08X (SC=%u)\n",
         st, rd(0x64)-c0, cst, (cst>>17)&0x3FF);
  // cfg_done is forced to normal mode by HW once ready -- the host issues NO 0x30 / config writes.

  // ---- now just do I/O: a write then a read, no manual queue setup ----
  for(int k=0;k<8;k++) wr(0x100+4*k,0xC0DE0000u+k);        // wrdata pattern
  wr(0x58,7);                                              // nlb=7 (4 KB)
  uint32_t cb;
  cb=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x4C,0);    // WRITE LBA 0
  for(i=0;i<8000000L && rd(0x64)==cb;i++);
  int wok = (rd(0x64)!=cb);
  cb=rd(0x64); wr(0x50,0xC000); wr(0x54,0); wr(0x48,0);    // READ  LBA 0
  for(i=0;i<8000000L && rd(0x64)==cb;i++);
  int rok = (rd(0x64)!=cb);
  uint32_t rbeats=rd(0x6C);
  printf("  WRITE %s, READ %s ; read-payload beats=%u\n", wok?"completed":"TIMEOUT", rok?"completed":"TIMEOUT", rbeats);
  printf("  => %s\n", (wok&&rok) ? "PASS (autonomous bring-up + I/O works; host issued only trigger+R/W)"
                                 : "FAIL (queues not functional)");
  return (wok&&rok)?0:3;
}
