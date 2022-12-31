#include <sufile.h>

#include <spdlog/spdlog.h>
#include <errno.h>

SUfileError_t suFileDriverOpen(void) {
  //spdlog::warn("suFileDriverOpen not implemented");
  
  spdlog::info("[SYS] Start bus enumeration");
  // open device
  const char* devname = "/dev/xdma0_user";
  int fd;
	if ((fd = open(devname, O_RDWR | O_SYNC)) == -1) {
		spdlog::info("character device {} opened failed: {}.", devname, strerror(errno));
    return {SU_FILE_DRIVER_NOT_INITIALIZED, SUDA_ERROR_UNKNOWN};
	}
	spdlog::info("[SYS] Device {} opened. fd={}", devname, fd);

  return {SU_FILE_SUCCESS, SUDA_ERROR_UNKNOWN};
}

SUfileError_t suFileDriverClose(void) {
  spdlog::warn("suFileDriverClose not implemented");
  return {SU_FILE_DRIVER_NOT_INITIALIZED, SUDA_ERROR_UNKNOWN};
}

SUfileError_t suFileHandleRegister(SUfileHandle_t *fh, SUfileDescr_t *descr) {
  spdlog::warn("suFileHandleRegister not implemented");
  return {SU_FILE_DRIVER_NOT_INITIALIZED, SUDA_ERROR_UNKNOWN};
}

void suFileHandleDeregister(SUfileHandle_t fh) {
  spdlog::warn("suFileHandleDeregister not implemented");
}

SUfileError_t suFileBufRegister(const void *devPtr_base, size_t length, int flags) {
  spdlog::warn("suFileBufRegister not implemented");
  return {SU_FILE_DRIVER_NOT_INITIALIZED, SUDA_ERROR_UNKNOWN};
}

SUfileError_t suFileBufDeregister(const void *devPtr_base) {
  spdlog::warn("suFileBufDeregister not implemented");
  return {SU_FILE_DRIVER_NOT_INITIALIZED, SUDA_ERROR_UNKNOWN};
}

ssize_t suFileRead(SUfileHandle_t fh, void *devPtr_base, size_t size, off_t file_offset, off_t devPtr_offset) {
  spdlog::warn("suFileRead not implemented");
  errno = ENOTSUP;
  return -1;
}

ssize_t suFileWrite(SUfileHandle_t fh, const void *devPtr_base, size_t size, off_t file_offset, off_t devPtr_offset) {
  spdlog::warn("suFileWrite not implemented");
  errno = ENOTSUP;
  return -1;
}
