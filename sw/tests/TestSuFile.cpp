#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <suda_runtime.h>
#include "sufile.h"

using namespace std;

int main() {
  ssize_t ret;
  void *devPtr_base;
  off_t file_offset = 0x2000;
  off_t devPtr_offset = 0x1000;
  ssize_t IO_size = 1UL << 24;
  size_t buff_size = IO_size + 0x1000;
  SUfileError_t status;
  int suda_result;
  SUfileDescr_t cf_descr;
  SUfileHandle_t cf_handle;

  cout << "Opening suFileDriver." << std::endl;
  status = suFileDriverOpen();
  if (status.err != SU_FILE_SUCCESS) {
    std::cerr << " suFile driver failed to open " << std::endl;
    return -1;
  }

  cout << "Registering cuFile handle." << std::endl;

  memset((void *)&cf_descr, 0, sizeof(SUfileDescr_t));
  cf_descr.handle.fd = 0;
  cf_descr.type = SU_FILE_HANDLE_TYPE_OPAQUE_FD;
  status = suFileHandleRegister(&cf_handle, &cf_descr);
  if (status.err != SU_FILE_SUCCESS) {
    std::cerr << "suFileHandleRegister status " << status.err << std::endl;
    return -1;
  }

  cout << "Allocating SUDA buffer of " << buff_size << " bytes." << std::endl;

  suda_result = sudaMalloc(&devPtr_base, buff_size);
  if (suda_result != SUDA_SUCCESS) {
    std::cerr << "buffer allocation failed " << suda_result << std::endl;
    suFileHandleDeregister(cf_handle);
    return -1;
  }

  cout << "Registering Buffer of " << buff_size << " bytes." << std::endl;
  status = suFileBufRegister(devPtr_base, buff_size, 0);
  if (status.err != SU_FILE_SUCCESS) {
    std::cerr << "buffer registration failed " << status.err << std::endl;
    suFileHandleDeregister(cf_handle);
    sudaFree(devPtr_base);
    return -1;
  }

  // fill a pattern
  cout << "Filling memory." << std::endl;

  sudaMemset((void *)devPtr_base, 0xab, buff_size);

  // perform write operation directly from GPU mem to file
  cout << "Writing buffer to file." << std::endl;
  ret = suFileWrite(cf_handle, devPtr_base, IO_size, file_offset, devPtr_offset);

  if (ret < 0 || ret != IO_size) {
    std::cerr << "suFileWrite failed " << ret << std::endl;
  }

  // release the GPU memory pinning
  cout << "Releasing suFile buffer." << std::endl;
  status = suFileBufDeregister(devPtr_base);
  if (status.err != SU_FILE_SUCCESS) {
    std::cerr << "buffer deregister failed" << std::endl;
    sudaFree(devPtr_base);
    suFileHandleDeregister(cf_handle);
    return -1;
  }

  cout << "Freeing SUDA buffer." << std::endl;
  sudaFree(devPtr_base);
  // deregister the handle from suFile
  cout << "Releasing file handle. " << std::endl;
  (void)suFileHandleDeregister(cf_handle);

  // release all suFile resources
  cout << "Closing File Driver." << std::endl;
  (void)suFileDriverClose();

  cout << std::endl;

  return 0;
}