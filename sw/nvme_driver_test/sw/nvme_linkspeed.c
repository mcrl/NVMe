// Read the OcuLink (FPGA root <-> SSD endpoint) negotiated PCIe link speed/width from the SSD's
// PCIe Express capability (Link Status register), via the FPGA's config-access path. No synth needed.
#include <stdio.h>
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
static uint32_t cfg(uint32_t off){return rcfg((1u<<20)|off);}   // SSD config dword at byte 'off'
int main(int argc,char**argv){
  setvbuf(stdout,NULL,_IONBF,0);
  const char*p=argc>1?argv[1]:"/sys/bus/pci/devices/0000:18:00.0/resource0";
  int fd=open(p,O_RDWR|O_SYNC); if(fd<0){printf("open:%s\n",strerror(errno));return 1;}
  B=(volatile uint32_t*)mmap(0,64*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
  if(B==MAP_FAILED){printf("mmap:%s\n",strerror(errno));return 1;}
  // minimal cfg-access enable (mirror nvme bringup prologue)
  wr(0x04,1); usleep(500000); wr(0x04,0);
  wr(0x30,0); wcfg(0x18,0x100); rcfg(0x18);
  uint32_t id = cfg(0x00);
  printf("SSD id = %08X  (status/cmd=%08X)\n", id, cfg(0x04));
  // walk the capability list for the PCIe Express capability (ID 0x10)
  uint32_t capptr = cfg(0x34) & 0xFF;
  int found=0;
  for(int i=0;i<48 && capptr>=0x40;i++){
    uint32_t cap = cfg(capptr & 0xFC);
    uint8_t  id8 = cap & 0xFF, nxt = (cap>>8)&0xFF;
    if(id8==0x10){ // PCIe Express capability
      uint32_t linkcap = cfg((capptr&0xFC)+0x0C);          // Link Capabilities
      uint32_t linksts = cfg((capptr&0xFC)+0x10);          // [31:16]=Link Status
      uint32_t ls = (linksts>>16)&0xFFFF;
      int spd = ls & 0xF, wid = (ls>>4)&0x3F;
      int cspd = linkcap & 0xF, cwid = (linkcap>>4)&0x3F;
      const char* g[]={"?","2.5GT/Gen1","5GT/Gen2","8GT/Gen3","16GT/Gen4","32GT/Gen5"};
      printf("PCIe Express cap @0x%02X\n", capptr);
      printf("  negotiated: speed=%s  width=x%d\n", (spd<6?g[spd]:"?"), wid);
      printf("  capable:    speed=%s  width=x%d\n", (cspd<6?g[cspd]:"?"), cwid);
      double perlane[]={0,0.25,0.5,0.985,1.969,3.938}; // GB/s per lane (approx, w/ encoding)
      if(spd<6) printf("  => theoretical link BW ~ %.2f GB/s (per dir)\n", perlane[spd]*wid);
      found=1; break;
    }
    capptr = nxt;
  }
  if(!found) printf("PCIe Express capability not found\n");
  return 0;
}
