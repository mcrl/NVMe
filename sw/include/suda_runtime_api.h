#pragma once

#include <stddef.h>

#define __host__
#define __device_builtin__
#define __cudart_builtin__
#define SUDARTAPI

#if !defined(__dv)
#if defined(__cplusplus)
#define __dv(v) = v
#else /* __cplusplus */
#define __dv(v)
#endif /* __cplusplus */
#endif /* !__dv */

enum __device_builtin__ sudaError {
  sudaSuccess                           =      0,
  sudaErrorInvalidValue                 =     1,
  sudaErrorMemoryAllocation             =      2,
  sudaErrorInitializationError          =      3,
  sudaErrorCudartUnloading              =     4,
  sudaErrorProfilerDisabled             =     5,
  sudaErrorProfilerNotInitialized       =     6,
  sudaErrorProfilerAlreadyStarted       =     7,
  sudaErrorProfilerAlreadyStopped       =    8,
  sudaErrorInvalidConfiguration         =      9,
  sudaErrorInvalidPitchValue            =     12,
  sudaErrorInvalidSymbol                =     13,
  sudaErrorInvalidHostPointer           =     16,
  sudaErrorInvalidDevicePointer         =     17,
  sudaErrorInvalidTexture               =     18,
  sudaErrorInvalidTextureBinding        =     19,
  sudaErrorInvalidChannelDescriptor     =     20,
  sudaErrorInvalidMemcpyDirection       =     21,
  sudaErrorAddressOfConstant            =     22,
  sudaErrorTextureFetchFailed           =     23,
  sudaErrorTextureNotBound              =     24,
  sudaErrorSynchronizationError         =     25,
  sudaErrorInvalidFilterSetting         =     26,
  sudaErrorInvalidNormSetting           =     27,
  sudaErrorMixedDeviceExecution         =     28,
  sudaErrorNotYetImplemented            =     31,
  sudaErrorMemoryValueTooLarge          =     32,
  sudaErrorStubLibrary                  =     34,
  sudaErrorInsufficientDriver           =     35,
  sudaErrorCallRequiresNewerDriver      =     36,
  sudaErrorInvalidSurface               =     37,
  sudaErrorDuplicateVariableName        =     43,
  sudaErrorDuplicateTextureName         =     44,
  sudaErrorDuplicateSurfaceName         =     45,
  sudaErrorDevicesUnavailable           =     46,
  sudaErrorIncompatibleDriverContext    =     49,
  sudaErrorMissingConfiguration         =      52,
  sudaErrorPriorLaunchFailure           =      53,
  sudaErrorLaunchMaxDepthExceeded       =     65,
  sudaErrorLaunchFileScopedTex          =     66,
  sudaErrorLaunchFileScopedSurf         =     67,
  sudaErrorSyncDepthExceeded            =     68,
  sudaErrorLaunchPendingCountExceeded   =     69,
  sudaErrorInvalidDeviceFunction        =      98,
  sudaErrorNoDevice                     =     100,
  sudaErrorInvalidDevice                =     101,
  sudaErrorDeviceNotLicensed            =     102,
  sudaErrorSoftwareValidityNotEstablished  =     103,
  sudaErrorStartupFailure               =    127,
  sudaErrorInvalidKernelImage           =     200,
  sudaErrorDeviceUninitialized          =     201,
  sudaErrorMapBufferObjectFailed        =     205,
  sudaErrorUnmapBufferObjectFailed      =     206,
  sudaErrorArrayIsMapped                =     207,
  sudaErrorAlreadyMapped                =     208,
  sudaErrorNoKernelImageForDevice       =     209,
  sudaErrorAlreadyAcquired              =     210,
  sudaErrorNotMapped                    =     211,
  sudaErrorNotMappedAsArray             =     212,
  sudaErrorNotMappedAsPointer           =     213,
  sudaErrorECCUncorrectable             =     214,
  sudaErrorUnsupportedLimit             =     215,
  sudaErrorDeviceAlreadyInUse           =     216,
  sudaErrorPeerAccessUnsupported        =     217,
  sudaErrorInvalidPtx                   =     218,
  sudaErrorInvalidGraphicsContext       =     219,
  sudaErrorNvlinkUncorrectable          =     220,
  sudaErrorJitCompilerNotFound          =     221,
  sudaErrorUnsupportedPtxVersion        =     222,
  sudaErrorJitCompilationDisabled       =     223,
  sudaErrorUnsupportedExecAffinity      =     224,
  sudaErrorInvalidSource                =     300,
  sudaErrorFileNotFound                 =     301,
  sudaErrorSharedObjectSymbolNotFound   =     302,
  sudaErrorSharedObjectInitFailed       =     303,
  sudaErrorOperatingSystem              =     304,
  sudaErrorInvalidResourceHandle        =     400,
  sudaErrorIllegalState                 =     401,
  sudaErrorSymbolNotFound               =     500,
  sudaErrorNotReady                     =     600,
  sudaErrorIllegalAddress               =     700,
  sudaErrorLaunchOutOfResources         =      701,
  sudaErrorLaunchTimeout                =      702,
  sudaErrorLaunchIncompatibleTexturing  =     703,
  sudaErrorPeerAccessAlreadyEnabled     =     704,
  sudaErrorPeerAccessNotEnabled         =     705,
  sudaErrorSetOnActiveProcess           =     708,
  sudaErrorContextIsDestroyed           =     709,
  sudaErrorAssert                        =    710,
  sudaErrorTooManyPeers                 =     711,
  sudaErrorHostMemoryAlreadyRegistered  =     712,
  sudaErrorHostMemoryNotRegistered      =     713,
  sudaErrorHardwareStackError           =     714,
  sudaErrorIllegalInstruction           =     715,
  sudaErrorMisalignedAddress            =     716,
  sudaErrorInvalidAddressSpace          =     717,
  sudaErrorInvalidPc                    =     718,
  sudaErrorLaunchFailure                =      719,
  sudaErrorCooperativeLaunchTooLarge    =     720,
  sudaErrorNotPermitted                 =     800,
  sudaErrorNotSupported                 =     801,
  sudaErrorSystemNotReady               =     802,
  sudaErrorSystemDriverMismatch         =     803,
  sudaErrorCompatNotSupportedOnDevice   =     804,
  sudaErrorMpsConnectionFailed          =     805,
  sudaErrorMpsRpcFailure                =     806,
  sudaErrorMpsServerNotReady            =     807,
  sudaErrorMpsMaxClientsReached         =     808,
  sudaErrorMpsMaxConnectionsReached     =     809,
  sudaErrorMpsClientTerminated          =     810,
  sudaErrorStreamCaptureUnsupported     =    900,
  sudaErrorStreamCaptureInvalidated     =    901,
  sudaErrorStreamCaptureMerge           =    902,
  sudaErrorStreamCaptureUnmatched       =    903,
  sudaErrorStreamCaptureUnjoined        =    904,
  sudaErrorStreamCaptureIsolation       =    905,
  sudaErrorStreamCaptureImplicit        =    906,
  sudaErrorCapturedEvent                =    907,
  sudaErrorStreamCaptureWrongThread     =    908,
  sudaErrorTimeout                      =    909,
  sudaErrorGraphExecUpdateFailure       =    910,
  sudaErrorExternalDevice               =    911,
  sudaErrorInvalidClusterSize           =    912,
  sudaErrorUnknown                      =    999,
  sudaErrorApiFailureBase               =  10000
};

enum __device_builtin__ sudaMemcpyKind {
    sudaMemcpyHostToHost          =   0,      /**< Host   -> Host */
    sudaMemcpyHostToDevice        =   1,      /**< Host   -> Device */
    sudaMemcpyDeviceToHost        =   2,      /**< Device -> Host */
    sudaMemcpyDeviceToDevice      =   3,      /**< Device -> Device */
    sudaMemcpyDefault             =   4       /**< Direction of the transfer is inferred from the pointer values. Requires unified virtual addressing */
};

typedef __device_builtin__ enum sudaError sudaError_t;

typedef __device_builtin__ struct SUstream_st *sudaStream_t;

#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */

extern __host__ sudaError_t SUDARTAPI sudaDeviceReset(void);
extern __host__ __cudart_builtin__ sudaError_t SUDARTAPI sudaDeviceSynchronize(void);

extern __host__ sudaError_t SUDARTAPI sudaMemcpy(void *dst, const void *src, size_t count, enum sudaMemcpyKind kind);
extern __host__ __cudart_builtin__ sudaError_t SUDARTAPI sudaMemcpyAsync(void *dst, const void *src, size_t count, enum sudaMemcpyKind kind, sudaStream_t stream __dv(0));

extern __host__ __cudart_builtin__ sudaError_t SUDARTAPI sudaMalloc(void **devPtr, size_t size);
extern __host__ __cudart_builtin__ sudaError_t SUDARTAPI sudaFree(void *devPtr);

#if defined(__cplusplus)
}
#endif /* __cplusplus */