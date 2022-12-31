# FPGA NVMe Hardware Driver + suFile Library


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
* 
