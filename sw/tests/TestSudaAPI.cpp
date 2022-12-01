#include <cstdlib>

#include <suda_runtime.h>

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

  return 0;
}