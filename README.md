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
