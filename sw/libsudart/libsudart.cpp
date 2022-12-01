#include <suda_runtime_api.h>

#include <spdlog/spdlog.h>

extern __host__ sudaError_t SUDARTAPI sudaDeviceReset(void) {
  spdlog::warn("sudaDeviceReset not implemented");
  return sudaErrorUnknown;
}

extern __host__ __sudart_builtin__ sudaError_t SUDARTAPI sudaDeviceSynchronize(void) {
  spdlog::warn("sudaDeviceSynchronize not implemented");
  return sudaErrorUnknown;
}

extern __host__ sudaError_t SUDARTAPI sudaMemcpy(void *dst, const void *src, size_t count, enum sudaMemcpyKind kind) {
  spdlog::warn("sudaMemcpy not implemented");
  return sudaErrorUnknown;
}

extern __host__ __sudart_builtin__ sudaError_t SUDARTAPI sudaMemcpyAsync(void *dst, const void *src, size_t count, enum sudaMemcpyKind kind, sudaStream_t stream) {
  spdlog::warn("sudaMemcpyAsync not implemented");
  return sudaErrorUnknown;
}

extern __host__ __sudart_builtin__ sudaError_t SUDARTAPI sudaMalloc(void **devPtr, size_t size) {
  spdlog::warn("sudaMalloc not implemented");
  return sudaErrorUnknown;
}

extern __host__ __sudart_builtin__ sudaError_t SUDARTAPI sudaFree(void *devPtr) {
  spdlog::warn("sudaFree not implemented");
  return sudaErrorUnknown;
}