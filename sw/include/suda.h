#pragma once

#define SUDAAPI

typedef enum sudaError_enum {
    SUDA_SUCCESS                              = 0,
    SUDA_ERROR_INVALID_VALUE                  = 1,
    SUDA_ERROR_OUT_OF_MEMORY                  = 2,
    SUDA_ERROR_NOT_INITIALIZED                = 3,
    SUDA_ERROR_DEINITIALIZED                  = 4,
    SUDA_ERROR_PROFILER_DISABLED              = 5,
    SUDA_ERROR_PROFILER_NOT_INITIALIZED       = 6,
    SUDA_ERROR_PROFILER_ALREADY_STARTED       = 7,
    SUDA_ERROR_PROFILER_ALREADY_STOPPED       = 8,
    SUDA_ERROR_STUB_LIBRARY                   = 34,
    SUDA_ERROR_DEVICE_UNAVAILABLE            = 46,
    SUDA_ERROR_NO_DEVICE                      = 100,
    SUDA_ERROR_INVALID_DEVICE                 = 101,
    SUDA_ERROR_DEVICE_NOT_LICENSED            = 102,
    SUDA_ERROR_INVALID_IMAGE                  = 200,
    SUDA_ERROR_INVALID_CONTEXT                = 201,
    SUDA_ERROR_CONTEXT_ALREADY_CURRENT        = 202,
    SUDA_ERROR_MAP_FAILED                     = 205,
    SUDA_ERROR_UNMAP_FAILED                   = 206,
    SUDA_ERROR_ARRAY_IS_MAPPED                = 207,
    SUDA_ERROR_ALREADY_MAPPED                 = 208,
    SUDA_ERROR_NO_BINARY_FOR_GPU              = 209,
    SUDA_ERROR_ALREADY_ACQUIRED               = 210,
    SUDA_ERROR_NOT_MAPPED                     = 211,
    SUDA_ERROR_NOT_MAPPED_AS_ARRAY            = 212,
    SUDA_ERROR_NOT_MAPPED_AS_POINTER          = 213,
    SUDA_ERROR_ECC_UNCORRECTABLE              = 214,
    SUDA_ERROR_UNSUPPORTED_LIMIT              = 215,
    SUDA_ERROR_CONTEXT_ALREADY_IN_USE         = 216,
    SUDA_ERROR_PEER_ACCESS_UNSUPPORTED        = 217,
    SUDA_ERROR_INVALID_PTX                    = 218,
    SUDA_ERROR_INVALID_GRAPHICS_CONTEXT       = 219,
    SUDA_ERROR_NVLINK_UNCORRECTABLE           = 220,
    SUDA_ERROR_JIT_COMPILER_NOT_FOUND         = 221,
    SUDA_ERROR_UNSUPPORTED_PTX_VERSION        = 222,
    SUDA_ERROR_JIT_COMPILATION_DISABLED       = 223,
    SUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY      = 224,
    SUDA_ERROR_INVALID_SOURCE                 = 300,
    SUDA_ERROR_FILE_NOT_FOUND                 = 301,
    SUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND = 302,
    SUDA_ERROR_SHARED_OBJECT_INIT_FAILED      = 303,
    SUDA_ERROR_OPERATING_SYSTEM               = 304,
    SUDA_ERROR_INVALID_HANDLE                 = 400,
    SUDA_ERROR_ILLEGAL_STATE                  = 401,
    SUDA_ERROR_NOT_FOUND                      = 500,
    SUDA_ERROR_NOT_READY                      = 600,
    SUDA_ERROR_ILLEGAL_ADDRESS                = 700,
    SUDA_ERROR_LAUNCH_OUT_OF_RESOURCES        = 701,
    SUDA_ERROR_LAUNCH_TIMEOUT                 = 702,
    SUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  = 703,
    SUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED    = 704,
    SUDA_ERROR_PEER_ACCESS_NOT_ENABLED        = 705,
    SUDA_ERROR_PRIMARY_CONTEXT_ACTIVE         = 708,
    SUDA_ERROR_CONTEXT_IS_DESTROYED           = 709,
    SUDA_ERROR_ASSERT                         = 710,
    SUDA_ERROR_TOO_MANY_PEERS                 = 711,
    SUDA_ERROR_HOST_MEMORY_ALREADY_REGISTERED = 712,
    SUDA_ERROR_HOST_MEMORY_NOT_REGISTERED     = 713,
    SUDA_ERROR_HARDWARE_STACK_ERROR           = 714,
    SUDA_ERROR_ILLEGAL_INSTRUCTION            = 715,
    SUDA_ERROR_MISALIGNED_ADDRESS             = 716,
    SUDA_ERROR_INVALID_ADDRESS_SPACE          = 717,
    SUDA_ERROR_INVALID_PC                     = 718,
    SUDA_ERROR_LAUNCH_FAILED                  = 719,
    SUDA_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE   = 720,
    SUDA_ERROR_NOT_PERMITTED                  = 800,
    SUDA_ERROR_NOT_SUPPORTED                  = 801,
    SUDA_ERROR_SYSTEM_NOT_READY               = 802,
    SUDA_ERROR_SYSTEM_DRIVER_MISMATCH         = 803,
    SUDA_ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE = 804,
    SUDA_ERROR_MPS_CONNECTION_FAILED          = 805,
    SUDA_ERROR_MPS_RPC_FAILURE                = 806,
    SUDA_ERROR_MPS_SERVER_NOT_READY           = 807,
    SUDA_ERROR_MPS_MAX_CLIENTS_REACHED        = 808,
    SUDA_ERROR_MPS_MAX_CONNECTIONS_REACHED    = 809,
    SUDA_ERROR_MPS_CLIENT_TERMINATED          = 810,
    SUDA_ERROR_STREAM_CAPTURE_UNSUPPORTED     = 900,
    SUDA_ERROR_STREAM_CAPTURE_INVALIDATED     = 901,
    SUDA_ERROR_STREAM_CAPTURE_MERGE           = 902,
    SUDA_ERROR_STREAM_CAPTURE_UNMATCHED       = 903,
    SUDA_ERROR_STREAM_CAPTURE_UNJOINED        = 904,
    SUDA_ERROR_STREAM_CAPTURE_ISOLATION       = 905,
    SUDA_ERROR_STREAM_CAPTURE_IMPLICIT        = 906,
    SUDA_ERROR_CAPTURED_EVENT                 = 907,
    SUDA_ERROR_STREAM_CAPTURE_WRONG_THREAD    = 908,
    SUDA_ERROR_TIMEOUT                        = 909,
    SUDA_ERROR_GRAPH_EXEC_UPDATE_FAILURE      = 910,
    SUDA_ERROR_EXTERNAL_DEVICE               = 911,
    SUDA_ERROR_INVALID_CLUSTER_SIZE           = 912,
    SUDA_ERROR_UNKNOWN                        = 999
} SUresult;

typedef struct SUmod_st *SUmodule;                           /**< suda module */
typedef struct SUfunc_st *SUfunction;                        /**< suda function */
typedef struct SUstream_st *SUstream;                        /**< suda stream */

#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */

SUresult SUDAAPI suModuleLoad(SUmodule *module, const char *fname);
SUresult SUDAAPI suModuleGetFunction(SUfunction *hfunc, SUmodule hmod, const char *name);
SUresult SUDAAPI suLaunchKernel(SUfunction f, unsigned int gridDimX, unsigned int gridDimY, unsigned int gridDimZ, unsigned int blockDimX, unsigned int blockDimY, unsigned int blockDimZ, unsigned int sharedMemBytes, SUstream hStream, void **kernelParams, void **extra);

#if defined(__cplusplus)
}
#endif /* __cplusplus */