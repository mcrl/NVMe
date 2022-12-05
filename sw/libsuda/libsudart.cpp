#include <suda_runtime.h>

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

extern __host__ __sudart_builtin__ const char* SUDARTAPI sudaGetErrorName(sudaError_t error) {
  switch (error) {
    case sudaSuccess: return "sudaSuccess";
    case sudaErrorInvalidValue: return "sudaErrorInvalidValue";
    case sudaErrorMemoryAllocation: return "sudaErrorMemoryAllocation";
    case sudaErrorInitializationError: return "sudaErrorInitializationError";
    case sudaErrorCudartUnloading: return "sudaErrorCudartUnloading";
    case sudaErrorProfilerDisabled: return "sudaErrorProfilerDisabled";
    case sudaErrorProfilerNotInitialized: return "sudaErrorProfilerNotInitialized";
    case sudaErrorProfilerAlreadyStarted: return "sudaErrorProfilerAlreadyStarted";
    case sudaErrorProfilerAlreadyStopped: return "sudaErrorProfilerAlreadyStopped";
    case sudaErrorInvalidConfiguration: return "sudaErrorInvalidConfiguration";
    case sudaErrorInvalidPitchValue: return "sudaErrorInvalidPitchValue";
    case sudaErrorInvalidSymbol: return "sudaErrorInvalidSymbol";
    case sudaErrorInvalidHostPointer: return "sudaErrorInvalidHostPointer";
    case sudaErrorInvalidDevicePointer: return "sudaErrorInvalidDevicePointer";
    case sudaErrorInvalidTexture: return "sudaErrorInvalidTexture";
    case sudaErrorInvalidTextureBinding: return "sudaErrorInvalidTextureBinding";
    case sudaErrorInvalidChannelDescriptor: return "sudaErrorInvalidChannelDescriptor";
    case sudaErrorInvalidMemcpyDirection: return "sudaErrorInvalidMemcpyDirection";
    case sudaErrorAddressOfConstant: return "sudaErrorAddressOfConstant";
    case sudaErrorTextureFetchFailed: return "sudaErrorTextureFetchFailed";
    case sudaErrorTextureNotBound: return "sudaErrorTextureNotBound";
    case sudaErrorSynchronizationError: return "sudaErrorSynchronizationError";
    case sudaErrorInvalidFilterSetting: return "sudaErrorInvalidFilterSetting";
    case sudaErrorInvalidNormSetting: return "sudaErrorInvalidNormSetting";
    case sudaErrorMixedDeviceExecution: return "sudaErrorMixedDeviceExecution";
    case sudaErrorNotYetImplemented: return "sudaErrorNotYetImplemented";
    case sudaErrorMemoryValueTooLarge: return "sudaErrorMemoryValueTooLarge";
    case sudaErrorStubLibrary: return "sudaErrorStubLibrary";
    case sudaErrorInsufficientDriver: return "sudaErrorInsufficientDriver";
    case sudaErrorCallRequiresNewerDriver: return "sudaErrorCallRequiresNewerDriver";
    case sudaErrorInvalidSurface: return "sudaErrorInvalidSurface";
    case sudaErrorDuplicateVariableName: return "sudaErrorDuplicateVariableName";
    case sudaErrorDuplicateTextureName: return "sudaErrorDuplicateTextureName";
    case sudaErrorDuplicateSurfaceName: return "sudaErrorDuplicateSurfaceName";
    case sudaErrorDevicesUnavailable: return "sudaErrorDevicesUnavailable";
    case sudaErrorIncompatibleDriverContext: return "sudaErrorIncompatibleDriverContext";
    case sudaErrorMissingConfiguration: return "sudaErrorMissingConfiguration";
    case sudaErrorPriorLaunchFailure: return "sudaErrorPriorLaunchFailure";
    case sudaErrorLaunchMaxDepthExceeded: return "sudaErrorLaunchMaxDepthExceeded";
    case sudaErrorLaunchFileScopedTex: return "sudaErrorLaunchFileScopedTex";
    case sudaErrorLaunchFileScopedSurf: return "sudaErrorLaunchFileScopedSurf";
    case sudaErrorSyncDepthExceeded: return "sudaErrorSyncDepthExceeded";
    case sudaErrorLaunchPendingCountExceeded: return "sudaErrorLaunchPendingCountExceeded";
    case sudaErrorInvalidDeviceFunction: return "sudaErrorInvalidDeviceFunction";
    case sudaErrorNoDevice: return "sudaErrorNoDevice";
    case sudaErrorInvalidDevice: return "sudaErrorInvalidDevice";
    case sudaErrorDeviceNotLicensed: return "sudaErrorDeviceNotLicensed";
    case sudaErrorSoftwareValidityNotEstablished: return "sudaErrorSoftwareValidityNotEstablished";
    case sudaErrorStartupFailure: return "sudaErrorStartupFailure";
    case sudaErrorInvalidKernelImage: return "sudaErrorInvalidKernelImage";
    case sudaErrorDeviceUninitialized: return "sudaErrorDeviceUninitialized";
    case sudaErrorMapBufferObjectFailed: return "sudaErrorMapBufferObjectFailed";
    case sudaErrorUnmapBufferObjectFailed: return "sudaErrorUnmapBufferObjectFailed";
    case sudaErrorArrayIsMapped: return "sudaErrorArrayIsMapped";
    case sudaErrorAlreadyMapped: return "sudaErrorAlreadyMapped";
    case sudaErrorNoKernelImageForDevice: return "sudaErrorNoKernelImageForDevice";
    case sudaErrorAlreadyAcquired: return "sudaErrorAlreadyAcquired";
    case sudaErrorNotMapped: return "sudaErrorNotMapped";
    case sudaErrorNotMappedAsArray: return "sudaErrorNotMappedAsArray";
    case sudaErrorNotMappedAsPointer: return "sudaErrorNotMappedAsPointer";
    case sudaErrorECCUncorrectable: return "sudaErrorECCUncorrectable";
    case sudaErrorUnsupportedLimit: return "sudaErrorUnsupportedLimit";
    case sudaErrorDeviceAlreadyInUse: return "sudaErrorDeviceAlreadyInUse";
    case sudaErrorPeerAccessUnsupported: return "sudaErrorPeerAccessUnsupported";
    case sudaErrorInvalidPtx: return "sudaErrorInvalidPtx";
    case sudaErrorInvalidGraphicsContext: return "sudaErrorInvalidGraphicsContext";
    case sudaErrorNvlinkUncorrectable: return "sudaErrorNvlinkUncorrectable";
    case sudaErrorJitCompilerNotFound: return "sudaErrorJitCompilerNotFound";
    case sudaErrorUnsupportedPtxVersion: return "sudaErrorUnsupportedPtxVersion";
    case sudaErrorJitCompilationDisabled: return "sudaErrorJitCompilationDisabled";
    case sudaErrorUnsupportedExecAffinity: return "sudaErrorUnsupportedExecAffinity";
    case sudaErrorInvalidSource: return "sudaErrorInvalidSource";
    case sudaErrorFileNotFound: return "sudaErrorFileNotFound";
    case sudaErrorSharedObjectSymbolNotFound: return "sudaErrorSharedObjectSymbolNotFound";
    case sudaErrorSharedObjectInitFailed: return "sudaErrorSharedObjectInitFailed";
    case sudaErrorOperatingSystem: return "sudaErrorOperatingSystem";
    case sudaErrorInvalidResourceHandle: return "sudaErrorInvalidResourceHandle";
    case sudaErrorIllegalState: return "sudaErrorIllegalState";
    case sudaErrorSymbolNotFound: return "sudaErrorSymbolNotFound";
    case sudaErrorNotReady: return "sudaErrorNotReady";
    case sudaErrorIllegalAddress: return "sudaErrorIllegalAddress";
    case sudaErrorLaunchOutOfResources: return "sudaErrorLaunchOutOfResources";
    case sudaErrorLaunchTimeout: return "sudaErrorLaunchTimeout";
    case sudaErrorLaunchIncompatibleTexturing: return "sudaErrorLaunchIncompatibleTexturing";
    case sudaErrorPeerAccessAlreadyEnabled: return "sudaErrorPeerAccessAlreadyEnabled";
    case sudaErrorPeerAccessNotEnabled: return "sudaErrorPeerAccessNotEnabled";
    case sudaErrorSetOnActiveProcess: return "sudaErrorSetOnActiveProcess";
    case sudaErrorContextIsDestroyed: return "sudaErrorContextIsDestroyed";
    case sudaErrorAssert: return "sudaErrorAssert";
    case sudaErrorTooManyPeers: return "sudaErrorTooManyPeers";
    case sudaErrorHostMemoryAlreadyRegistered: return "sudaErrorHostMemoryAlreadyRegistered";
    case sudaErrorHostMemoryNotRegistered: return "sudaErrorHostMemoryNotRegistered";
    case sudaErrorHardwareStackError: return "sudaErrorHardwareStackError";
    case sudaErrorIllegalInstruction: return "sudaErrorIllegalInstruction";
    case sudaErrorMisalignedAddress: return "sudaErrorMisalignedAddress";
    case sudaErrorInvalidAddressSpace: return "sudaErrorInvalidAddressSpace";
    case sudaErrorInvalidPc: return "sudaErrorInvalidPc";
    case sudaErrorLaunchFailure: return "sudaErrorLaunchFailure";
    case sudaErrorCooperativeLaunchTooLarge: return "sudaErrorCooperativeLaunchTooLarge";
    case sudaErrorNotPermitted: return "sudaErrorNotPermitted";
    case sudaErrorNotSupported: return "sudaErrorNotSupported";
    case sudaErrorSystemNotReady: return "sudaErrorSystemNotReady";
    case sudaErrorSystemDriverMismatch: return "sudaErrorSystemDriverMismatch";
    case sudaErrorCompatNotSupportedOnDevice: return "sudaErrorCompatNotSupportedOnDevice";
    case sudaErrorMpsConnectionFailed: return "sudaErrorMpsConnectionFailed";
    case sudaErrorMpsRpcFailure: return "sudaErrorMpsRpcFailure";
    case sudaErrorMpsServerNotReady: return "sudaErrorMpsServerNotReady";
    case sudaErrorMpsMaxClientsReached: return "sudaErrorMpsMaxClientsReached";
    case sudaErrorMpsMaxConnectionsReached: return "sudaErrorMpsMaxConnectionsReached";
    case sudaErrorMpsClientTerminated: return "sudaErrorMpsClientTerminated";
    case sudaErrorStreamCaptureUnsupported: return "sudaErrorStreamCaptureUnsupported";
    case sudaErrorStreamCaptureInvalidated: return "sudaErrorStreamCaptureInvalidated";
    case sudaErrorStreamCaptureMerge: return "sudaErrorStreamCaptureMerge";
    case sudaErrorStreamCaptureUnmatched: return "sudaErrorStreamCaptureUnmatched";
    case sudaErrorStreamCaptureUnjoined: return "sudaErrorStreamCaptureUnjoined";
    case sudaErrorStreamCaptureIsolation: return "sudaErrorStreamCaptureIsolation";
    case sudaErrorStreamCaptureImplicit: return "sudaErrorStreamCaptureImplicit";
    case sudaErrorCapturedEvent: return "sudaErrorCapturedEvent";
    case sudaErrorStreamCaptureWrongThread: return "sudaErrorStreamCaptureWrongThread";
    case sudaErrorTimeout: return "sudaErrorTimeout";
    case sudaErrorGraphExecUpdateFailure: return "sudaErrorGraphExecUpdateFailure";
    case sudaErrorExternalDevice: return "sudaErrorExternalDevice";
    case sudaErrorInvalidClusterSize: return "sudaErrorInvalidClusterSize";
    case sudaErrorUnknown: return "sudaErrorUnknown";
    case sudaErrorApiFailureBase: return "sudaErrorApiFailureBase";
    default: return "<invalid error>";
  }
}

extern __host__ __sudart_builtin__ const char* SUDARTAPI sudaGetErrorString(sudaError_t error) {
  switch (error) {
    case sudaSuccess: return "no error";
    case sudaErrorInvalidValue: return "invalid argument";
    case sudaErrorMemoryAllocation: return "out of memory";
    case sudaErrorInitializationError: return "initialization error";
    case sudaErrorCudartUnloading: return "driver shutting down";
    case sudaErrorProfilerDisabled: return "profiler disabled while using external profiling tool";
    case sudaErrorProfilerNotInitialized: return "profiler not initialized: call cudaProfilerInitialize()";
    case sudaErrorProfilerAlreadyStarted: return "profiler already started";
    case sudaErrorProfilerAlreadyStopped: return "profiler already stopped";
    case sudaErrorInvalidConfiguration: return "invalid configuration argument";
    case sudaErrorInvalidPitchValue: return "invalid pitch argument";
    case sudaErrorInvalidSymbol: return "invalid device symbol";
    case sudaErrorInvalidHostPointer: return "invalid host pointer";
    case sudaErrorInvalidDevicePointer: return "invalid device pointer";
    case sudaErrorInvalidTexture: return "invalid texture reference";
    case sudaErrorInvalidTextureBinding: return "texture is not bound to a pointer";
    case sudaErrorInvalidChannelDescriptor: return "invalid channel descriptor";
    case sudaErrorInvalidMemcpyDirection: return "invalid copy direction for memcpy";
    case sudaErrorAddressOfConstant: return "invalid address of constant";
    case sudaErrorTextureFetchFailed: return "fetch from texture failed";
    case sudaErrorTextureNotBound: return "cannot fetch from a texture that is not bound";
    case sudaErrorSynchronizationError: return "incorrect use of __syncthreads()";
    case sudaErrorInvalidFilterSetting: return "linear filtering not supported for non-float type";
    case sudaErrorInvalidNormSetting: return "read as normalized float not supported for 32-bit non float type";
    case sudaErrorMixedDeviceExecution: return "device emulation mode and device execution mode cannot be mixed";
    case sudaErrorNotYetImplemented: return "feature not yet implemented";
    case sudaErrorMemoryValueTooLarge: return "memory size or pointer value too large to fit in 32 bit";
    case sudaErrorStubLibrary: return "CUDA driver is a stub library";
    case sudaErrorInsufficientDriver: return "CUDA driver version is insufficient for CUDA runtime version";
    case sudaErrorCallRequiresNewerDriver: return "API call is not supported in the installed CUDA driver";
    case sudaErrorInvalidSurface: return "invalid surface reference";
    case sudaErrorDuplicateVariableName: return "duplicate global variable looked up by string name";
    case sudaErrorDuplicateTextureName: return "duplicate texture looked up by string name";
    case sudaErrorDuplicateSurfaceName: return "duplicate surface looked up by string name";
    case sudaErrorDevicesUnavailable: return "CUDA-capable device(s) is/are busy or unavailable";
    case sudaErrorIncompatibleDriverContext: return "incompatible driver context";
    case sudaErrorMissingConfiguration: return "__global__ function call is not configured";
    case sudaErrorPriorLaunchFailure: return "unspecified launch failure in prior launch";
    case sudaErrorLaunchMaxDepthExceeded: return "launch would exceed maximum depth of nested launches";
    case sudaErrorLaunchFileScopedTex: return "launch failed because kernel uses unsupported, file-scoped textures (texture objects are supported)";
    case sudaErrorLaunchFileScopedSurf: return "launch failed because kernel uses unsupported, file-scoped surfaces (surface objects are supported)";
    case sudaErrorSyncDepthExceeded: return "cudaDeviceSynchronize failed because caller's grid depth exceeds cudaLimitDevRuntimeSyncDepth";
    case sudaErrorLaunchPendingCountExceeded: return "launch failed because launch would exceed cudaLimitDevRuntimePendingLaunchCount";
    case sudaErrorInvalidDeviceFunction: return "invalid device function";
    case sudaErrorNoDevice: return "no CUDA-capable device is detected";
    case sudaErrorInvalidDevice: return "invalid device ordinal";
    case sudaErrorDeviceNotLicensed: return "device doesn't have valid Grid license";
    case sudaErrorSoftwareValidityNotEstablished: return "integrity checks failed";
    case sudaErrorStartupFailure: return "startup failure in cuda runtime";
    case sudaErrorInvalidKernelImage: return "device kernel image is invalid";
    case sudaErrorDeviceUninitialized: return "invalid device context";
    case sudaErrorMapBufferObjectFailed: return "mapping of buffer object failed";
    case sudaErrorUnmapBufferObjectFailed: return "unmapping of buffer object failed";
    case sudaErrorArrayIsMapped: return "array is mapped";
    case sudaErrorAlreadyMapped: return "resource already mapped";
    case sudaErrorNoKernelImageForDevice: return "no kernel image is available for execution on the device";
    case sudaErrorAlreadyAcquired: return "resource already acquired";
    case sudaErrorNotMapped: return "resource not mapped";
    case sudaErrorNotMappedAsArray: return "resource not mapped as array";
    case sudaErrorNotMappedAsPointer: return "resource not mapped as pointer";
    case sudaErrorECCUncorrectable: return "uncorrectable ECC error encountered";
    case sudaErrorUnsupportedLimit: return "limit is not supported on this architecture";
    case sudaErrorDeviceAlreadyInUse: return "exclusive-thread device already in use by a different thread";
    case sudaErrorPeerAccessUnsupported: return "peer access is not supported between these two devices";
    case sudaErrorInvalidPtx: return "a PTX JIT compilation failed";
    case sudaErrorInvalidGraphicsContext: return "invalid OpenGL or DirectX context";
    case sudaErrorNvlinkUncorrectable: return "uncorrectable NVLink error detected during the execution";
    case sudaErrorJitCompilerNotFound: return "PTX JIT compiler library not found";
    case sudaErrorUnsupportedPtxVersion: return "the provided PTX was compiled with an unsupported toolchain.";
    case sudaErrorJitCompilationDisabled: return "PTX JIT compilation was disabled";
    case sudaErrorUnsupportedExecAffinity: return "the provided execution affinity is not supported";
    case sudaErrorInvalidSource: return "device kernel image is invalid";
    case sudaErrorFileNotFound: return "file not found";
    case sudaErrorSharedObjectSymbolNotFound: return "shared object symbol not found";
    case sudaErrorSharedObjectInitFailed: return "shared object initialization failed";
    case sudaErrorOperatingSystem: return "OS call failed or operation not supported on this OS";
    case sudaErrorInvalidResourceHandle: return "invalid resource handle";
    case sudaErrorIllegalState: return "the operation cannot be performed in the present state";
    case sudaErrorSymbolNotFound: return "named symbol not found";
    case sudaErrorNotReady: return "device not ready";
    case sudaErrorIllegalAddress: return "an illegal memory access was encountered";
    case sudaErrorLaunchOutOfResources: return "too many resources requested for launch";
    case sudaErrorLaunchTimeout: return "the launch timed out and was terminated";
    case sudaErrorLaunchIncompatibleTexturing: return "launch uses incompatible texturing mode";
    case sudaErrorPeerAccessAlreadyEnabled: return "peer access is already enabled";
    case sudaErrorPeerAccessNotEnabled: return "peer access has not been enabled";
    case sudaErrorSetOnActiveProcess: return "cannot set while device is active in this process";
    case sudaErrorContextIsDestroyed: return "context is destroyed";
    case sudaErrorAssert: return "device-side assert triggered";
    case sudaErrorTooManyPeers: return "peer mapping resources exhausted";
    case sudaErrorHostMemoryAlreadyRegistered: return "part or all of the requested memory range is already mapped";
    case sudaErrorHostMemoryNotRegistered: return "pointer does not correspond to a registered memory region";
    case sudaErrorHardwareStackError: return "hardware stack error";
    case sudaErrorIllegalInstruction: return "an illegal instruction was encountered";
    case sudaErrorMisalignedAddress: return "misaligned address";
    case sudaErrorInvalidAddressSpace: return "operation not supported on global/shared address space";
    case sudaErrorInvalidPc: return "invalid program counter";
    case sudaErrorLaunchFailure: return "unspecified launch failure";
    case sudaErrorCooperativeLaunchTooLarge: return "too many blocks in cooperative launch";
    case sudaErrorNotPermitted: return "operation not permitted";
    case sudaErrorNotSupported: return "operation not supported";
    case sudaErrorSystemNotReady: return "system not yet initialized";
    case sudaErrorSystemDriverMismatch: return "system has unsupported display driver / cuda driver combination";
    case sudaErrorCompatNotSupportedOnDevice: return "forward compatibility was attempted on non supported HW";
    case sudaErrorMpsConnectionFailed: return "MPS client failed to connect to the MPS control daemon or the MPS server";
    case sudaErrorMpsRpcFailure: return "the remote procedural call between the MPS server and the MPS client failed";
    case sudaErrorMpsServerNotReady: return "MPS server is not ready to accept new MPS client requests";
    case sudaErrorMpsMaxClientsReached: return "the hardware resources required to create MPS client have been exhausted";
    case sudaErrorMpsMaxConnectionsReached: return "the hardware resources required to support device connections have been exhausted";
    case sudaErrorMpsClientTerminated: return "the MPS client has been terminated by the server";
    case sudaErrorStreamCaptureUnsupported: return "operation not permitted when stream is capturing";
    case sudaErrorStreamCaptureInvalidated: return "operation failed due to a previous error during capture";
    case sudaErrorStreamCaptureMerge: return "operation would result in a merge of separate capture sequences";
    case sudaErrorStreamCaptureUnmatched: return "capture was not ended in the same stream as it began";
    case sudaErrorStreamCaptureUnjoined: return "capturing stream has unjoined work";
    case sudaErrorStreamCaptureIsolation: return "dependency created on uncaptured work in another stream";
    case sudaErrorStreamCaptureImplicit: return "operation would make the legacy stream depend on a capturing blocking stream";
    case sudaErrorCapturedEvent: return "operation not permitted on an event last recorded in a capturing stream";
    case sudaErrorStreamCaptureWrongThread: return "attempt to terminate a thread-local capture sequence from another thread";
    case sudaErrorTimeout: return "wait operation timed out";
    case sudaErrorGraphExecUpdateFailure: return "the graph update was not performed because it included changes which violated constraints specific to instantiated graph update";
    case sudaErrorExternalDevice: return "an async error has occured in external entity outside of CUDA";
    case sudaErrorInvalidClusterSize: return "a kernel launch error has occurred due to cluster misconfiguration";
    case sudaErrorUnknown: return "unknown error";
    case sudaErrorApiFailureBase: return "api failure base";
    default: return "<invalid error>";
  }
}

extern __host__ sudaError_t SUDARTAPI sudaMemset(void *devPtr, int value, size_t count) {
  spdlog::warn("sudaMemset not implemented");
  return sudaErrorUnknown;
}