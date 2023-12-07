#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <ctime>
#include <cufile.h>
#include <cuda_runtime.h>

double GetTime() {
  timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec + t.tv_nsec / 1e9;
}

void CheckError(bool cond, const char* msg, const char* file = __builtin_FILE(), int line = __builtin_LINE()) {
  if (cond) {
    printf("[%s:%d] %s\n", file, line, msg);
    exit(0);
  }
}

void CheckCuFile(CUfileError_t err, const char* msg, const char* file = __builtin_FILE(), int line = __builtin_LINE()) {
  if (err.err != CU_FILE_SUCCESS) {
    printf("[%s:%d] %s (CufileOpError %d, CUresult %d)\n", file, line, msg, err.err, err.cu_err);
    exit(0);
  }
}

void CheckCuda(cudaError_t err, const char* msg, const char* file = __builtin_FILE(), int line = __builtin_LINE()) {
  if (err != cudaSuccess) {
    printf("[%s:%d] %s\n", file, line, msg);
    exit(0);
  }
}

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("Usage: %s [device path]\n", argv[0]);
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
  CheckError(fd < 0, "file open error");
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
  CheckError(hostmem == nullptr, "malloc error");
  for (size_t i = 0; i < devmemsz; ++i) {
    *((unsigned char*)hostmem + i) = i % 256;
  }
  st = GetTime();
  cudaMemcpy(devmem, hostmem, devmemsz, cudaMemcpyHostToDevice);
  et = GetTime();
  printf("cudaMemcpy H2D %f MB/s\n", devmemsz / 1e6 / (et - st));

  // Write test
  st = GetTime();
  ssize_t wsz = cuFileWrite(fh, devmem, devmemsz, 0, 0);
  CheckError(wsz < 0 || wsz < devmemsz, "cuFileWrite error");
  et = GetTime();
  printf("cuFileWrite %ld B written, %f MB/s\n", wsz, devmemsz / 1e6 / (et - st));

  // Read test
  st = GetTime();
  ssize_t rsz = cuFileRead(fh, devmem, devmemsz, 0, 0);
  CheckError(rsz < 0 || rsz < devmemsz, "cuFileRead error");
  et = GetTime();
  printf("cuFileRead %ld B read, %f MB/s\n", rsz, devmemsz / 1e6 / (et - st));

  // Read devmem
  st = GetTime();
  cudaMemcpy(hostmem, devmem, devmemsz, cudaMemcpyDeviceToHost);
  et = GetTime();
  printf("cudaMemcpy D2H %f MB/s\n", devmemsz / 1e6 / (et - st));
  for (size_t i = 0; i < devmemsz; ++i) {
    if (*((unsigned char*)hostmem + i) != i % 256) {
      printf("mem[%lu] expected %02lX, got %02X ", i, i % 256, *((unsigned char*)hostmem + i));
      break;
    }
    //printf("%02X ", *((char*)hostmem + i));
  }
  //printf("\n");

  // Cleanup
  CheckCuFile(cuFileBufDeregister(devmem), "cuFileBufDeregister error");
  cuFileHandleDeregister(fh);
  CheckCuFile(cuFileDriverClose(), "cuFileDriverClose error");

  return 0;
}
