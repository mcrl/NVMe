# FPGA NVMe Hardware Driver + suFile Library
![대표도면](https://user-images.githubusercontent.com/49220047/210135164-1e84a88d-7648-48c1-bc83-7155dc0b07fa.PNG)

# Environment

Below are environments that authors used.

- OS: Ubuntu 20.04.3 LTS
- CPU: Intel(R) Xeon(R) Gold 6130F CPU @ 2.10GHz

# Code Structure
```plaintext
NVMe/     
├── hw/                       (RTL codes)
│   ├── COMSTRAINTS/          (Constraints : Board connections)         
│   ├── IP/                   (IPs : ILA, XDMA IP, Board design)
│   ├── RTL/                  (NVMe Hardware Driver RTL codes)
│   ├── scripts/             
│   ├── SIM/                 
│   └── SYNTH/                (NVMe Hardware Driver Project directories)
├── sw/                       (NVMe suFile Library)
├── SIM/
├── README.md
├── LICENSE
└── CMakeLists.txt
```


## How to build

```
mkdir build
cd build
cmake ..
make
```


## How to install driver 

```
cd sw
cd driver
sudo ./install_n_compile_driver.sh
```

## suFile API
* suFileDriverOpen(void) : suFile infrastructure initialize
* suFileDriverClose(void) : suFile system finalize
* suFileHandleRegister(SUfileHandle_t *fh, SUfileDescr_t *descr) : suFilehandle register 
* suFileHandleDeregister(SUfileHandle_t fh) : suFileHandle and sufile descriptor deregister
* suFileBufRegister(void *devPtr, size_t length, int flags) : set suFile pinned buffer
* suFileBufDeregister(void *devPtr) : cleanup pinned buffer
* suFileRead(SUfileHandle_t fh, void *devPtr, size_t size, off_t file_offset, off_t devPtr_offset) : Read at pinned buffer
* suFileWrite(SUfileHandle_t fh, void *devPtr, size_t size, off_t file_offset, off_t devPtr_offset) : Write into pinned buffer
