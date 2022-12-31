# FPGA NVMe Hardware Driver + suFile Library

# Environment

Below are environments that authors used.

- OS: Ubuntu 20.04.3 LTS
- CPU: Intel(R) Xeon(R) Gold 6130F CPU @ 2.10GHz


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
