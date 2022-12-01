#include <cstdio>
#include <cstdlib>
#include <cassert>

#include <suda_runtime.h>
#include <suda.h>

#define CHECK_SUDA(call)                                              \
  do {                                                                \
    sudaError_t status_ = call;                                       \
    if (status_ != sudaSuccess) {                                     \
      fprintf(stderr, "SUDA error (%s:%d): %s\n", __FILE__, __LINE__, \
              sudaGetErrorString(status_));                           \
      assert(false);                                                  \
    }                                                                 \
  } while (0)

#define CHECK_SU(call)                                                  \
  do {                                                                  \
    SUresult status_ = call;                                            \
    if (status_ != SUDA_SUCCESS) {                                      \
      const char *name, *string;                                        \
      suGetErrorName(status_, &name);                                   \
      suGetErrorString(status_, &string);                               \
      fprintf(stderr, "SU error (%s:%d): %s(%s)\n", __FILE__, __LINE__, \
              name, string);                                            \
      assert(false);                                                    \
    }                                                                   \
  } while (0)

int main() {
  sudaDeviceReset();

  sudaDeviceSynchronize();

  size_t nbytes = 1024;
  void *h_a, *h_b, *d_a, *d_b;
  h_a = malloc(nbytes);
  h_b = malloc(nbytes);
  sudaMalloc(&d_a, nbytes);
  sudaMalloc(&d_b, nbytes);

  sudaMemcpy(d_a, h_a, nbytes, sudaMemcpyHostToDevice);
  sudaMemcpy(d_b, d_a, nbytes, sudaMemcpyDeviceToDevice);
  sudaMemcpy(h_b, d_b, nbytes, sudaMemcpyDeviceToHost);

  sudaMemcpyAsync(d_a, h_a, nbytes, sudaMemcpyHostToDevice);
  sudaMemcpyAsync(d_b, d_a, nbytes, sudaMemcpyDeviceToDevice);
  sudaMemcpyAsync(h_b, d_b, nbytes, sudaMemcpyDeviceToHost);

  sudaDeviceSynchronize();

  free(h_a);
  free(h_b);
  sudaFree(d_a);
  sudaFree(d_b);

  SUmodule mod;
  SUfunction func;
  suModuleLoad(&mod, "");
  suModuleGetFunction(&func, mod, "");
  suLaunchKernel(func, 1, 1, 1, 1, 1, 1, 0, 0, nullptr, nullptr);

  CHECK_SU(suModuleLoad(&mod, ""));
  CHECK_SUDA(sudaDeviceReset());

  return 0;
}