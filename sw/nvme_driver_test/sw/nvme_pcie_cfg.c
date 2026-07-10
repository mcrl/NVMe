// Read (and optionally set) the SSD's PCIe Express Device Control MPS / MRRS, which gate TLP sizes and
// therefore OcuLink utilization. Usage: nvme_pcie_cfg <resource0> [set <mps_bytes> <mrrs_bytes>]
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
static uint32_t cfg(uint32_t off){return rcfg((1u<<20)|off);}
static void wcfgs(uint32_t off,uint32_t d){wcfg((1u<<20)|off,d);}
static int enc(int bytes){ // bytes -> MPS/MRRS field code
  switch(bytes){case 128:return 0;case 256:return 1;case 512:return 2;case 1024:return 3;
                case 2048:return 4;case 4096:return 5;default:return -1;} }
static const char* dec(int code){static const char*s[]={"128","256","512","1024","2048","4096"};return code<6?s[code]:"?";}
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  wr(0x04,1); usleep(500000); wr(0x04,0);
  wr(0x30,0); wcfg(0x18,0x100); rcfg(0x18);
  printf("SSD id=%08X\n", cfg(0x00));
  uint32_t capptr=cfg(0x34)&0xFF, cap=0;
  for(int i=0;i<48 && capptr>=0x40;i++){ uint32_t c=cfg(capptr&0xFC); if((c&0xFF)==0x10){cap=capptr&0xFC;break;} capptr=(c>>8)&0xFF; }
  if(!cap){printf("no PCIe cap\n");return 1;}
  uint32_t devcap = cfg(cap+0x04);
  uint32_t dc_dw  = cfg(cap+0x08);            // [15:0]=DevControl [31:16]=DevStatus
  int mps_sup = devcap & 0x7;
  int mps = (dc_dw>>5)&0x7, mrrs=(dc_dw>>12)&0x7;
  printf("PCIe cap@0x%02X  MaxPayloadSupported=%s B\n", cap, dec(mps_sup));
  printf("  current: MPS=%s B   MRRS=%s B  (DevControl=%04X)\n", dec(mps), dec(mrrs), dc_dw&0xFFFF);

  if(argc>=5 && !strcmp(argv[2],"set")){
    int nmps=enc(atoi(argv[3])), nmrrs=enc(atoi(argv[4]));
    if(nmps<0||nmrrs<0){printf("bad mps/mrrs (use 128/256/512/1024/2048/4096)\n");return 1;}
    uint32_t ctl = dc_dw & 0xFFFF;
    ctl = (ctl & ~(0x7<<5)  ) | (nmps<<5);
    ctl = (ctl & ~(0x7<<12) ) | (nmrrs<<12);
    wcfgs(cap+0x08, ctl);                       // write back DevControl (DevStatus high bits = 0, harmless)
    uint32_t v=cfg(cap+0x08);
    printf("  SET -> MPS=%s B  MRRS=%s B  (DevControl=%04X)\n",
           dec((v>>5)&0x7), dec((v>>12)&0x7), v&0xFFFF);
  }
  return 0;
}
