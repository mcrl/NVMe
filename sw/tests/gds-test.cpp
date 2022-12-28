#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <ctime>
#include <cufile.h>
#include <cuda_runtime.h>
#include "util.h"

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("Usage: %s [path_to_dev]\n", argv[0]);
    printf(" e.g., %s /dev/nvme0n1\n", argv[0]);
    exit(0);
  }

  cudaError_t cerr;
  CUfileError_t cferr;
  double st, et;

  // Open driver
  cferr = cuFileDriverOpen();
  CheckCuFile(cferr, "cuFileDriverOpen error");

  // Setup descriptor with linux file descriptor and get handle
  CUfileDescr_t descr;
  memset(&descr, 0, sizeof(descr));
  int fd = open(argv[1], O_DIRECT | O_RDWR);
  if (fd < 0) perror("file open error");
  CheckCond(fd < 0, "file open error");
  descr.handle.fd = fd;
  descr.type = CU_FILE_HANDLE_TYPE_OPAQUE_FD;
  CUfileHandle_t fh;
  cferr = cuFileHandleRegister(&fh, &descr);
  CheckCuFile(cferr, "cuFileHandleRegister error");

  // Alloc and register device memory
  void* devmem;
  size_t devmemsz = 1LL * 1024 * 1024 * 1024;
  //size_t devmemsz = 1LL * 10;
  cerr = cudaMalloc(&devmem, devmemsz);
  CheckCuda(cerr, "cudaMalloc error");
  cferr = cuFileBufRegister(devmem, devmemsz, 0);
  CheckCuFile(cferr, "cuFileBufRegister error");

  // Fill devmem
  void* hostmem;
  hostmem = malloc(devmemsz);
  CheckCond(hostmem == nullptr, "malloc error");
  for (size_t i = 0; i < devmemsz; ++i) {
    *((unsigned char*)hostmem + i) = i % 256;
  }
  st = GetTime();
  cudaMemcpy(devmem, hostmem, devmemsz, cudaMemcpyHostToDevice);
  et = GetTime();
  printf("cudaMemcpy H2D %f MB/s\n", devmemsz / 1e6 / (et - st));

  return 0;
}
