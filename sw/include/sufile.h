#pragma once

#include "suda.h"
#include <sys/types.h>
#include <sys/socket.h>

#define SUFILEOP_BASE_ERR 5000

#define SUFILEOP_STATUS_ENTRIES \
  SUFILE_OP(0,                      SU_FILE_SUCCESS, cufile success) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 1,  SU_FILE_DRIVER_NOT_INITIALIZED, nvidia-fs driver is not loaded) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 2,  SU_FILE_DRIVER_INVALID_PROPS, invalid property) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 3,  SU_FILE_DRIVER_UNSUPPORTED_LIMIT, property range error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 4,  SU_FILE_DRIVER_VERSION_MISMATCH, nvidia-fs driver version mismatch) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 5,  SU_FILE_DRIVER_VERSION_READ_ERROR, nvidia-fs driver version read error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 6,  SU_FILE_DRIVER_CLOSING, driver shutdown in progress) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 7,  SU_FILE_PLATFORM_NOT_SUPPORTED, GPUDirect Storage not supported on current platform) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 8,  SU_FILE_IO_NOT_SUPPORTED, GPUDirect Storage not supported on current file) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 9,  SU_FILE_DEVICE_NOT_SUPPORTED, GPUDirect Storage not supported on current GPU) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 10, SU_FILE_NVFS_DRIVER_ERROR, nvidia-fs driver ioctl error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 11, SU_FILE_CUDA_DRIVER_ERROR, CUDA Driver API error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 12, SU_FILE_CUDA_POINTER_INVALID, invalid device pointer) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 13, SU_FILE_CUDA_MEMORY_TYPE_INVALID, invalid pointer memory type) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 14, SU_FILE_CUDA_POINTER_RANGE_ERROR, pointer range exceeds allocated address range) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 15, SU_FILE_CUDA_CONTEXT_MISMATCH, cuda context mismatch) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 16, SU_FILE_INVALID_MAPPING_SIZE, access beyond maximum pinned size) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 17, SU_FILE_INVALID_MAPPING_RANGE, access beyond mapped size) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 18, SU_FILE_INVALID_FILE_TYPE, unsupported file type) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 19, SU_FILE_INVALID_FILE_OPEN_FLAG, unsupported file open flags) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 20, SU_FILE_DIO_NOT_SET, fd direct IO not set) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 22, SU_FILE_INVALID_VALUE, invalid arguments) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 23, SU_FILE_MEMORY_ALREADY_REGISTERED, device pointer already registered) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 24, SU_FILE_MEMORY_NOT_REGISTERED, device pointer lookup failure) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 25, SU_FILE_PERMISSION_DENIED, driver or file access error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 26, SU_FILE_DRIVER_ALREADY_OPEN, driver is already open) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 27, SU_FILE_HANDLE_NOT_REGISTERED, file descriptor is not registered) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 28, SU_FILE_HANDLE_ALREADY_REGISTERED, file descriptor is already registered) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 29, SU_FILE_DEVICE_NOT_FOUND, GPU device not found) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 30, SU_FILE_INTERNAL_ERROR, internal error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 31, SU_FILE_GETNEWFD_FAILED, failed to obtain new file descriptor) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 33, SU_FILE_NVFS_SETUP_ERROR, NVFS driver initialization error) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 34, SU_FILE_IO_DISABLED, GPUDirect Storage disabled by config on current file)\
  SUFILE_OP(SUFILEOP_BASE_ERR + 35, SU_FILE_BATCH_SUBMIT_FAILED, failes to submit batch operation)\
  SUFILE_OP(SUFILEOP_BASE_ERR + 36, SU_FILE_GPU_MEMORY_PINNING_FAILED, Failed to allocate pinned GPU Memory) \
  SUFILE_OP(SUFILEOP_BASE_ERR + 37, SU_FILE_IO_MAX_ERROR, GPUDirect Storage Max Error)

typedef enum SUfileOpError {
  #define SUFILE_OP(code, name, string) name = code,
  SUFILEOP_STATUS_ENTRIES
  #undef SUFILE_OP 
} SUfileOpError;

typedef struct SUfileError {
  SUfileOpError err;
  SUresult su_err;
} SUfileError_t;

typedef void* SUfileHandle_t;

enum SUfileFileHandleType {
  SU_FILE_HANDLE_TYPE_OPAQUE_FD = 1,
  SU_FILE_HANDLE_TYPE_OPAQUE_WIN32 = 2,
  SU_FILE_HANDLE_TYPE_USERSPACE_FS = 3,
};

typedef struct sockaddr sockaddr_t;

typedef struct sufileRDMAInfo {
  int version;
  int desc_len;
  const char *desc_str;
} sufileRDMAInfo_t;

typedef struct SUfileFSOps {
  const char* (*fs_type) (void *handle);
  int (*getRDMADeviceList)(void *handle, sockaddr_t **hostaddrs);
  int (*getRDMADevicePriority)(void *handle, char*, size_t, loff_t, sockaddr_t* hostaddr);
  ssize_t (*read) (void *handle, char*, size_t, loff_t, sufileRDMAInfo_t*);
  ssize_t (*write) (void *handle, const char *, size_t, loff_t , sufileRDMAInfo_t*);
} SUfileFSOps_t;

typedef struct SUfileDescr_t {
  enum SUfileFileHandleType type; /* type of file being registered */
  union {
    int fd; /* Linux   */
    void *handle; /* Windows */
  } handle;
  const SUfileFSOps_t *fs_ops;     /* file system operation table */
} SUfileDescr_t;

#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */

SUfileError_t suFileDriverOpen(void);
SUfileError_t suFileDriverClose(void);

SUfileError_t suFileHandleRegister(SUfileHandle_t *fh, SUfileDescr_t *descr);
void suFileHandleDeregister(SUfileHandle_t fh);

SUfileError_t suFileBufRegister(const void *devPtr_base, size_t length, int flags);
SUfileError_t suFileBufDeregister(const void *devPtr_base);

ssize_t suFileRead(SUfileHandle_t fh, void *devPtr_base, size_t size, off_t file_offset, off_t devPtr_offset);
ssize_t suFileWrite(SUfileHandle_t fh, const void *devPtr_base, size_t size, off_t file_offset, off_t devPtr_offset);

#if defined(__cplusplus)
}
#endif /* __cplusplus */