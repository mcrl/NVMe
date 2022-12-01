#include <suda.h>

#include <spdlog/spdlog.h>

SUresult SUDAAPI suModuleLoad(SUmodule *module, const char *fname) {
  spdlog::warn("suModuleLoad not implemented");
  return SUDA_ERROR_UNKNOWN;
}

SUresult SUDAAPI suModuleGetFunction(SUfunction *hfunc, SUmodule hmod, const char *name) {
  spdlog::warn("suModuleGetFunction not implemented");
  return SUDA_ERROR_UNKNOWN;
}

SUresult SUDAAPI suLaunchKernel(SUfunction f, unsigned int gridDimX, unsigned int gridDimY, unsigned int gridDimZ, unsigned int blockDimX, unsigned int blockDimY, unsigned int blockDimZ, unsigned int sharedMemBytes, SUstream hStream, void **kernelParams, void **extra) {
  spdlog::warn("suLaunchKernel not implemented");
  return SUDA_ERROR_UNKNOWN;
}