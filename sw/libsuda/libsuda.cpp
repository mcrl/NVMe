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

SUresult SUDAAPI suGetErrorName(SUresult error, const char **pStr) {
  switch (error) {
    case SUDA_SUCCESS: *pStr = "SUDA_SUCCESS"; break;
    case SUDA_ERROR_INVALID_VALUE: *pStr = "SUDA_ERROR_INVALID_VALUE"; break;
    case SUDA_ERROR_OUT_OF_MEMORY: *pStr = "SUDA_ERROR_OUT_OF_MEMORY"; break;
    case SUDA_ERROR_NOT_INITIALIZED: *pStr = "SUDA_ERROR_NOT_INITIALIZED"; break;
    case SUDA_ERROR_DEINITIALIZED: *pStr = "SUDA_ERROR_DEINITIALIZED"; break;
    case SUDA_ERROR_PROFILER_DISABLED: *pStr = "SUDA_ERROR_PROFILER_DISABLED"; break;
    case SUDA_ERROR_PROFILER_NOT_INITIALIZED: *pStr = "SUDA_ERROR_PROFILER_NOT_INITIALIZED"; break;
    case SUDA_ERROR_PROFILER_ALREADY_STARTED: *pStr = "SUDA_ERROR_PROFILER_ALREADY_STARTED"; break;
    case SUDA_ERROR_PROFILER_ALREADY_STOPPED: *pStr = "SUDA_ERROR_PROFILER_ALREADY_STOPPED"; break;
    case SUDA_ERROR_STUB_LIBRARY: *pStr = "SUDA_ERROR_STUB_LIBRARY"; break;
    case SUDA_ERROR_DEVICE_UNAVAILABLE: *pStr = "SUDA_ERROR_DEVICE_UNAVAILABLE"; break;
    case SUDA_ERROR_NO_DEVICE: *pStr = "SUDA_ERROR_NO_DEVICE"; break;
    case SUDA_ERROR_INVALID_DEVICE: *pStr = "SUDA_ERROR_INVALID_DEVICE"; break;
    case SUDA_ERROR_DEVICE_NOT_LICENSED: *pStr = "SUDA_ERROR_DEVICE_NOT_LICENSED"; break;
    case SUDA_ERROR_INVALID_IMAGE: *pStr = "SUDA_ERROR_INVALID_IMAGE"; break;
    case SUDA_ERROR_INVALID_CONTEXT: *pStr = "SUDA_ERROR_INVALID_CONTEXT"; break;
    case SUDA_ERROR_CONTEXT_ALREADY_CURRENT: *pStr = "SUDA_ERROR_CONTEXT_ALREADY_CURRENT"; break;
    case SUDA_ERROR_MAP_FAILED: *pStr = "SUDA_ERROR_MAP_FAILED"; break;
    case SUDA_ERROR_UNMAP_FAILED: *pStr = "SUDA_ERROR_UNMAP_FAILED"; break;
    case SUDA_ERROR_ARRAY_IS_MAPPED: *pStr = "SUDA_ERROR_ARRAY_IS_MAPPED"; break;
    case SUDA_ERROR_ALREADY_MAPPED: *pStr = "SUDA_ERROR_ALREADY_MAPPED"; break;
    case SUDA_ERROR_NO_BINARY_FOR_GPU: *pStr = "SUDA_ERROR_NO_BINARY_FOR_GPU"; break;
    case SUDA_ERROR_ALREADY_ACQUIRED: *pStr = "SUDA_ERROR_ALREADY_ACQUIRED"; break;
    case SUDA_ERROR_NOT_MAPPED: *pStr = "SUDA_ERROR_NOT_MAPPED"; break;
    case SUDA_ERROR_NOT_MAPPED_AS_ARRAY: *pStr = "SUDA_ERROR_NOT_MAPPED_AS_ARRAY"; break;
    case SUDA_ERROR_NOT_MAPPED_AS_POINTER: *pStr = "SUDA_ERROR_NOT_MAPPED_AS_POINTER"; break;
    case SUDA_ERROR_ECC_UNCORRECTABLE: *pStr = "SUDA_ERROR_ECC_UNCORRECTABLE"; break;
    case SUDA_ERROR_UNSUPPORTED_LIMIT: *pStr = "SUDA_ERROR_UNSUPPORTED_LIMIT"; break;
    case SUDA_ERROR_CONTEXT_ALREADY_IN_USE: *pStr = "SUDA_ERROR_CONTEXT_ALREADY_IN_USE"; break;
    case SUDA_ERROR_PEER_ACCESS_UNSUPPORTED: *pStr = "SUDA_ERROR_PEER_ACCESS_UNSUPPORTED"; break;
    case SUDA_ERROR_INVALID_PTX: *pStr = "SUDA_ERROR_INVALID_PTX"; break;
    case SUDA_ERROR_INVALID_GRAPHICS_CONTEXT: *pStr = "SUDA_ERROR_INVALID_GRAPHICS_CONTEXT"; break;
    case SUDA_ERROR_NVLINK_UNCORRECTABLE: *pStr = "SUDA_ERROR_NVLINK_UNCORRECTABLE"; break;
    case SUDA_ERROR_JIT_COMPILER_NOT_FOUND: *pStr = "SUDA_ERROR_JIT_COMPILER_NOT_FOUND"; break;
    case SUDA_ERROR_UNSUPPORTED_PTX_VERSION: *pStr = "SUDA_ERROR_UNSUPPORTED_PTX_VERSION"; break;
    case SUDA_ERROR_JIT_COMPILATION_DISABLED: *pStr = "SUDA_ERROR_JIT_COMPILATION_DISABLED"; break;
    case SUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY: *pStr = "SUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY"; break;
    case SUDA_ERROR_INVALID_SOURCE: *pStr = "SUDA_ERROR_INVALID_SOURCE"; break;
    case SUDA_ERROR_FILE_NOT_FOUND: *pStr = "SUDA_ERROR_FILE_NOT_FOUND"; break;
    case SUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND: *pStr = "SUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND"; break;
    case SUDA_ERROR_SHARED_OBJECT_INIT_FAILED: *pStr = "SUDA_ERROR_SHARED_OBJECT_INIT_FAILED"; break;
    case SUDA_ERROR_OPERATING_SYSTEM: *pStr = "SUDA_ERROR_OPERATING_SYSTEM"; break;
    case SUDA_ERROR_INVALID_HANDLE: *pStr = "SUDA_ERROR_INVALID_HANDLE"; break;
    case SUDA_ERROR_ILLEGAL_STATE: *pStr = "SUDA_ERROR_ILLEGAL_STATE"; break;
    case SUDA_ERROR_NOT_FOUND: *pStr = "SUDA_ERROR_NOT_FOUND"; break;
    case SUDA_ERROR_NOT_READY: *pStr = "SUDA_ERROR_NOT_READY"; break;
    case SUDA_ERROR_ILLEGAL_ADDRESS: *pStr = "SUDA_ERROR_ILLEGAL_ADDRESS"; break;
    case SUDA_ERROR_LAUNCH_OUT_OF_RESOURCES: *pStr = "SUDA_ERROR_LAUNCH_OUT_OF_RESOURCES"; break;
    case SUDA_ERROR_LAUNCH_TIMEOUT: *pStr = "SUDA_ERROR_LAUNCH_TIMEOUT"; break;
    case SUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING: *pStr = "SUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING"; break;
    case SUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED: *pStr = "SUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED"; break;
    case SUDA_ERROR_PEER_ACCESS_NOT_ENABLED: *pStr = "SUDA_ERROR_PEER_ACCESS_NOT_ENABLED"; break;
    case SUDA_ERROR_PRIMARY_CONTEXT_ACTIVE: *pStr = "SUDA_ERROR_PRIMARY_CONTEXT_ACTIVE"; break;
    case SUDA_ERROR_CONTEXT_IS_DESTROYED: *pStr = "SUDA_ERROR_CONTEXT_IS_DESTROYED"; break;
    case SUDA_ERROR_ASSERT: *pStr = "SUDA_ERROR_ASSERT"; break;
    case SUDA_ERROR_TOO_MANY_PEERS: *pStr = "SUDA_ERROR_TOO_MANY_PEERS"; break;
    case SUDA_ERROR_HOST_MEMORY_ALREADY_REGISTERED: *pStr = "SUDA_ERROR_HOST_MEMORY_ALREADY_REGISTERED"; break;
    case SUDA_ERROR_HOST_MEMORY_NOT_REGISTERED: *pStr = "SUDA_ERROR_HOST_MEMORY_NOT_REGISTERED"; break;
    case SUDA_ERROR_HARDWARE_STACK_ERROR: *pStr = "SUDA_ERROR_HARDWARE_STACK_ERROR"; break;
    case SUDA_ERROR_ILLEGAL_INSTRUCTION: *pStr = "SUDA_ERROR_ILLEGAL_INSTRUCTION"; break;
    case SUDA_ERROR_MISALIGNED_ADDRESS: *pStr = "SUDA_ERROR_MISALIGNED_ADDRESS"; break;
    case SUDA_ERROR_INVALID_ADDRESS_SPACE: *pStr = "SUDA_ERROR_INVALID_ADDRESS_SPACE"; break;
    case SUDA_ERROR_INVALID_PC: *pStr = "SUDA_ERROR_INVALID_PC"; break;
    case SUDA_ERROR_LAUNCH_FAILED: *pStr = "SUDA_ERROR_LAUNCH_FAILED"; break;
    case SUDA_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE: *pStr = "SUDA_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE"; break;
    case SUDA_ERROR_NOT_PERMITTED: *pStr = "SUDA_ERROR_NOT_PERMITTED"; break;
    case SUDA_ERROR_NOT_SUPPORTED: *pStr = "SUDA_ERROR_NOT_SUPPORTED"; break;
    case SUDA_ERROR_SYSTEM_NOT_READY: *pStr = "SUDA_ERROR_SYSTEM_NOT_READY"; break;
    case SUDA_ERROR_SYSTEM_DRIVER_MISMATCH: *pStr = "SUDA_ERROR_SYSTEM_DRIVER_MISMATCH"; break;
    case SUDA_ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE: *pStr = "SUDA_ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE"; break;
    case SUDA_ERROR_MPS_CONNECTION_FAILED: *pStr = "SUDA_ERROR_MPS_CONNECTION_FAILED"; break;
    case SUDA_ERROR_MPS_RPC_FAILURE: *pStr = "SUDA_ERROR_MPS_RPC_FAILURE"; break;
    case SUDA_ERROR_MPS_SERVER_NOT_READY: *pStr = "SUDA_ERROR_MPS_SERVER_NOT_READY"; break;
    case SUDA_ERROR_MPS_MAX_CLIENTS_REACHED: *pStr = "SUDA_ERROR_MPS_MAX_CLIENTS_REACHED"; break;
    case SUDA_ERROR_MPS_MAX_CONNECTIONS_REACHED: *pStr = "SUDA_ERROR_MPS_MAX_CONNECTIONS_REACHED"; break;
    case SUDA_ERROR_MPS_CLIENT_TERMINATED: *pStr = "SUDA_ERROR_MPS_CLIENT_TERMINATED"; break;
    case SUDA_ERROR_STREAM_CAPTURE_UNSUPPORTED: *pStr = "SUDA_ERROR_STREAM_CAPTURE_UNSUPPORTED"; break;
    case SUDA_ERROR_STREAM_CAPTURE_INVALIDATED: *pStr = "SUDA_ERROR_STREAM_CAPTURE_INVALIDATED"; break;
    case SUDA_ERROR_STREAM_CAPTURE_MERGE: *pStr = "SUDA_ERROR_STREAM_CAPTURE_MERGE"; break;
    case SUDA_ERROR_STREAM_CAPTURE_UNMATCHED: *pStr = "SUDA_ERROR_STREAM_CAPTURE_UNMATCHED"; break;
    case SUDA_ERROR_STREAM_CAPTURE_UNJOINED: *pStr = "SUDA_ERROR_STREAM_CAPTURE_UNJOINED"; break;
    case SUDA_ERROR_STREAM_CAPTURE_ISOLATION: *pStr = "SUDA_ERROR_STREAM_CAPTURE_ISOLATION"; break;
    case SUDA_ERROR_STREAM_CAPTURE_IMPLICIT: *pStr = "SUDA_ERROR_STREAM_CAPTURE_IMPLICIT"; break;
    case SUDA_ERROR_CAPTURED_EVENT: *pStr = "SUDA_ERROR_CAPTURED_EVENT"; break;
    case SUDA_ERROR_STREAM_CAPTURE_WRONG_THREAD: *pStr = "SUDA_ERROR_STREAM_CAPTURE_WRONG_THREAD"; break;
    case SUDA_ERROR_TIMEOUT: *pStr = "SUDA_ERROR_TIMEOUT"; break;
    case SUDA_ERROR_GRAPH_EXEC_UPDATE_FAILURE: *pStr = "SUDA_ERROR_GRAPH_EXEC_UPDATE_FAILURE"; break;
    case SUDA_ERROR_EXTERNAL_DEVICE: *pStr = "SUDA_ERROR_EXTERNAL_DEVICE"; break;
    case SUDA_ERROR_INVALID_CLUSTER_SIZE: *pStr = "SUDA_ERROR_INVALID_CLUSTER_SIZE"; break;
    case SUDA_ERROR_UNKNOWN: *pStr = "SUDA_ERROR_UNKNOWN"; break;
    default: *pStr = "<invalid error>";
  }
  return SUDA_SUCCESS;
}

SUresult SUDAAPI suGetErrorString(SUresult error, const char **pStr) {
  switch (error) {
    case SUDA_SUCCESS: *pStr = "no error"; break;
    case SUDA_ERROR_INVALID_VALUE: *pStr = "invalid argument"; break;
    case SUDA_ERROR_OUT_OF_MEMORY: *pStr = "out of memory"; break;
    case SUDA_ERROR_NOT_INITIALIZED: *pStr = "initialization error"; break;
    case SUDA_ERROR_DEINITIALIZED: *pStr = "driver shutting down"; break;
    case SUDA_ERROR_PROFILER_DISABLED: *pStr = "profiler disabled while using external profiling tool"; break;
    case SUDA_ERROR_PROFILER_NOT_INITIALIZED: *pStr = "profiler not initialized: call cudaProfilerInitialize()"; break;
    case SUDA_ERROR_PROFILER_ALREADY_STARTED: *pStr = "profiler already started"; break;
    case SUDA_ERROR_PROFILER_ALREADY_STOPPED: *pStr = "profiler already stopped"; break;
    case SUDA_ERROR_STUB_LIBRARY: *pStr = "CUDA driver is a stub library"; break;
    case SUDA_ERROR_DEVICE_UNAVAILABLE: *pStr = "CUDA-capable device(s) is/are busy or unavailable"; break;
    case SUDA_ERROR_NO_DEVICE: *pStr = "no CUDA-capable device is detected"; break;
    case SUDA_ERROR_INVALID_DEVICE: *pStr = "invalid device ordinal"; break;
    case SUDA_ERROR_DEVICE_NOT_LICENSED: *pStr = "device doesn't have valid Grid license"; break;
    case SUDA_ERROR_INVALID_IMAGE: *pStr = "device kernel image is invalid"; break;
    case SUDA_ERROR_INVALID_CONTEXT: *pStr = "invalid device context"; break;
    case SUDA_ERROR_CONTEXT_ALREADY_CURRENT: *pStr = "context already current"; break;
    case SUDA_ERROR_MAP_FAILED: *pStr = "mapping of buffer object failed"; break;
    case SUDA_ERROR_UNMAP_FAILED: *pStr = "unmapping of buffer object failed"; break;
    case SUDA_ERROR_ARRAY_IS_MAPPED: *pStr = "array is mapped"; break;
    case SUDA_ERROR_ALREADY_MAPPED: *pStr = "resource already mapped"; break;
    case SUDA_ERROR_NO_BINARY_FOR_GPU: *pStr = "no kernel image is available for execution on the device"; break;
    case SUDA_ERROR_ALREADY_ACQUIRED: *pStr = "resource already acquired"; break;
    case SUDA_ERROR_NOT_MAPPED: *pStr = "resource not mapped"; break;
    case SUDA_ERROR_NOT_MAPPED_AS_ARRAY: *pStr = "resource not mapped as array"; break;
    case SUDA_ERROR_NOT_MAPPED_AS_POINTER: *pStr = "resource not mapped as pointer"; break;
    case SUDA_ERROR_ECC_UNCORRECTABLE: *pStr = "uncorrectable ECC error encountered"; break;
    case SUDA_ERROR_UNSUPPORTED_LIMIT: *pStr = "limit is not supported on this architecture"; break;
    case SUDA_ERROR_CONTEXT_ALREADY_IN_USE: *pStr = "exclusive-thread device already in use by a different thread"; break;
    case SUDA_ERROR_PEER_ACCESS_UNSUPPORTED: *pStr = "peer access is not supported between these two devices"; break;
    case SUDA_ERROR_INVALID_PTX: *pStr = "a PTX JIT compilation failed"; break;
    case SUDA_ERROR_INVALID_GRAPHICS_CONTEXT: *pStr = "invalid OpenGL or DirectX context"; break;
    case SUDA_ERROR_NVLINK_UNCORRECTABLE: *pStr = "uncorrectable NVLink error detected during the execution"; break;
    case SUDA_ERROR_JIT_COMPILER_NOT_FOUND: *pStr = "PTX JIT compiler library not found"; break;
    case SUDA_ERROR_UNSUPPORTED_PTX_VERSION: *pStr = "the provided PTX was compiled with an unsupported toolchain."; break;
    case SUDA_ERROR_JIT_COMPILATION_DISABLED: *pStr = "PTX JIT compilation was disabled"; break;
    case SUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY: *pStr = "the provided execution affinity is not supported"; break;
    case SUDA_ERROR_INVALID_SOURCE: *pStr = "device kernel image is invalid"; break;
    case SUDA_ERROR_FILE_NOT_FOUND: *pStr = "file not found"; break;
    case SUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND: *pStr = "shared object symbol not found"; break;
    case SUDA_ERROR_SHARED_OBJECT_INIT_FAILED: *pStr = "shared object initialization failed"; break;
    case SUDA_ERROR_OPERATING_SYSTEM: *pStr = "OS call failed or operation not supported on this OS"; break;
    case SUDA_ERROR_INVALID_HANDLE: *pStr = "invalid resource handle"; break;
    case SUDA_ERROR_ILLEGAL_STATE: *pStr = "the operation cannot be performed in the present state"; break;
    case SUDA_ERROR_NOT_FOUND: *pStr = "named symbol not found"; break;
    case SUDA_ERROR_NOT_READY: *pStr = "device not ready"; break;
    case SUDA_ERROR_ILLEGAL_ADDRESS: *pStr = "an illegal memory access was encountered"; break;
    case SUDA_ERROR_LAUNCH_OUT_OF_RESOURCES: *pStr = "too many resources requested for launch"; break;
    case SUDA_ERROR_LAUNCH_TIMEOUT: *pStr = "the launch timed out and was terminated"; break;
    case SUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING: *pStr = "launch uses incompatible texturing mode"; break;
    case SUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED: *pStr = "peer access is already enabled"; break;
    case SUDA_ERROR_PEER_ACCESS_NOT_ENABLED: *pStr = "peer access has not been enabled"; break;
    case SUDA_ERROR_PRIMARY_CONTEXT_ACTIVE: *pStr = "cannot set while device is active in this process"; break;
    case SUDA_ERROR_CONTEXT_IS_DESTROYED: *pStr = "context is destroyed"; break;
    case SUDA_ERROR_ASSERT: *pStr = "device-side assert triggered"; break;
    case SUDA_ERROR_TOO_MANY_PEERS: *pStr = "peer mapping resources exhausted"; break;
    case SUDA_ERROR_HOST_MEMORY_ALREADY_REGISTERED: *pStr = "part or all of the requested memory range is already mapped"; break;
    case SUDA_ERROR_HOST_MEMORY_NOT_REGISTERED: *pStr = "pointer does not correspond to a registered memory region"; break;
    case SUDA_ERROR_HARDWARE_STACK_ERROR: *pStr = "hardware stack error"; break;
    case SUDA_ERROR_ILLEGAL_INSTRUCTION: *pStr = "an illegal instruction was encountered"; break;
    case SUDA_ERROR_MISALIGNED_ADDRESS: *pStr = "misaligned address"; break;
    case SUDA_ERROR_INVALID_ADDRESS_SPACE: *pStr = "operation not supported on global/shared address space"; break;
    case SUDA_ERROR_INVALID_PC: *pStr = "invalid program counter"; break;
    case SUDA_ERROR_LAUNCH_FAILED: *pStr = "unspecified launch failure"; break;
    case SUDA_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE: *pStr = "too many blocks in cooperative launch"; break;
    case SUDA_ERROR_NOT_PERMITTED: *pStr = "operation not permitted"; break;
    case SUDA_ERROR_NOT_SUPPORTED: *pStr = "operation not supported"; break;
    case SUDA_ERROR_SYSTEM_NOT_READY: *pStr = "system not yet initialized"; break;
    case SUDA_ERROR_SYSTEM_DRIVER_MISMATCH: *pStr = "system has unsupported display driver / cuda driver combination"; break;
    case SUDA_ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE: *pStr = "forward compatibility was attempted on non supported HW"; break;
    case SUDA_ERROR_MPS_CONNECTION_FAILED: *pStr = "MPS client failed to connect to the MPS control daemon or the MPS server"; break;
    case SUDA_ERROR_MPS_RPC_FAILURE: *pStr = "the remote procedural call between the MPS server and the MPS client failed"; break;
    case SUDA_ERROR_MPS_SERVER_NOT_READY: *pStr = "MPS server is not ready to accept new MPS client requests"; break;
    case SUDA_ERROR_MPS_MAX_CLIENTS_REACHED: *pStr = "the hardware resources required to create MPS client have been exhausted"; break;
    case SUDA_ERROR_MPS_MAX_CONNECTIONS_REACHED: *pStr = "the hardware resources required to support device connections have been exhausted"; break;
    case SUDA_ERROR_MPS_CLIENT_TERMINATED: *pStr = "the MPS client has been terminated by the server"; break;
    case SUDA_ERROR_STREAM_CAPTURE_UNSUPPORTED: *pStr = "operation not permitted when stream is capturing"; break;
    case SUDA_ERROR_STREAM_CAPTURE_INVALIDATED: *pStr = "operation failed due to a previous error during capture"; break;
    case SUDA_ERROR_STREAM_CAPTURE_MERGE: *pStr = "operation would result in a merge of separate capture sequences"; break;
    case SUDA_ERROR_STREAM_CAPTURE_UNMATCHED: *pStr = "capture was not ended in the same stream as it began"; break;
    case SUDA_ERROR_STREAM_CAPTURE_UNJOINED: *pStr = "capturing stream has unjoined work"; break;
    case SUDA_ERROR_STREAM_CAPTURE_ISOLATION: *pStr = "dependency created on uncaptured work in another stream"; break;
    case SUDA_ERROR_STREAM_CAPTURE_IMPLICIT: *pStr = "operation would make the legacy stream depend on a capturing blocking stream"; break;
    case SUDA_ERROR_CAPTURED_EVENT: *pStr = "operation not permitted on an event last recorded in a capturing stream"; break;
    case SUDA_ERROR_STREAM_CAPTURE_WRONG_THREAD: *pStr = "attempt to terminate a thread-local capture sequence from another thread"; break;
    case SUDA_ERROR_TIMEOUT: *pStr = "wait operation timed out"; break;
    case SUDA_ERROR_GRAPH_EXEC_UPDATE_FAILURE: *pStr = "the graph update was not performed because it included changes which violated constraints specific to instantiated graph update"; break;
    case SUDA_ERROR_EXTERNAL_DEVICE: *pStr = "an async error has occured in external entity outside of CUDA"; break;
    case SUDA_ERROR_INVALID_CLUSTER_SIZE: *pStr = "a kernel launch error has occurred due to cluster misconfiguration"; break;
    case SUDA_ERROR_UNKNOWN: *pStr = "unknown error"; break;
    default: *pStr = "<invalid error>";
  }
  return SUDA_SUCCESS;
}
