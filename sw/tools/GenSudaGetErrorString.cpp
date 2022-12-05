#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#define GEN_NAME(X) \
  do { \
    char* name = strdup(cudaGetErrorName(X)); \
    name[0] = 's'; \
    printf("case %s: return \"%s\";\n", name, name); \
    free(name); \
  } while (0)

#define GEN_STRING(X) \
  do { \
    char* name = strdup(cudaGetErrorName(X)); \
    char* str = strdup(cudaGetErrorString(X)); \
    name[0] = 's'; \
    printf("case %s: return \"%s\";\n", name, str); \
    free(name); \
    free(str); \
  } while (0)

int main() {
  GEN_NAME(cudaSuccess);
  GEN_NAME(cudaErrorInvalidValue);
  GEN_NAME(cudaErrorMemoryAllocation);
  GEN_NAME(cudaErrorInitializationError);
  GEN_NAME(cudaErrorCudartUnloading);
  GEN_NAME(cudaErrorProfilerDisabled);
  GEN_NAME(cudaErrorProfilerNotInitialized);
  GEN_NAME(cudaErrorProfilerAlreadyStarted);
  GEN_NAME(cudaErrorProfilerAlreadyStopped);
  GEN_NAME(cudaErrorInvalidConfiguration);
  GEN_NAME(cudaErrorInvalidPitchValue);
  GEN_NAME(cudaErrorInvalidSymbol);
  GEN_NAME(cudaErrorInvalidHostPointer);
  GEN_NAME(cudaErrorInvalidDevicePointer);
  GEN_NAME(cudaErrorInvalidTexture);
  GEN_NAME(cudaErrorInvalidTextureBinding);
  GEN_NAME(cudaErrorInvalidChannelDescriptor);
  GEN_NAME(cudaErrorInvalidMemcpyDirection);
  GEN_NAME(cudaErrorAddressOfConstant);
  GEN_NAME(cudaErrorTextureFetchFailed);
  GEN_NAME(cudaErrorTextureNotBound);
  GEN_NAME(cudaErrorSynchronizationError);
  GEN_NAME(cudaErrorInvalidFilterSetting);
  GEN_NAME(cudaErrorInvalidNormSetting);
  GEN_NAME(cudaErrorMixedDeviceExecution);
  GEN_NAME(cudaErrorNotYetImplemented);
  GEN_NAME(cudaErrorMemoryValueTooLarge);
  GEN_NAME(cudaErrorStubLibrary);
  GEN_NAME(cudaErrorInsufficientDriver);
  GEN_NAME(cudaErrorCallRequiresNewerDriver);
  GEN_NAME(cudaErrorInvalidSurface);
  GEN_NAME(cudaErrorDuplicateVariableName);
  GEN_NAME(cudaErrorDuplicateTextureName);
  GEN_NAME(cudaErrorDuplicateSurfaceName);
  GEN_NAME(cudaErrorDevicesUnavailable);
  GEN_NAME(cudaErrorIncompatibleDriverContext);
  GEN_NAME(cudaErrorMissingConfiguration);
  GEN_NAME(cudaErrorPriorLaunchFailure);
  GEN_NAME(cudaErrorLaunchMaxDepthExceeded);
  GEN_NAME(cudaErrorLaunchFileScopedTex);
  GEN_NAME(cudaErrorLaunchFileScopedSurf);
  GEN_NAME(cudaErrorSyncDepthExceeded);
  GEN_NAME(cudaErrorLaunchPendingCountExceeded);
  GEN_NAME(cudaErrorInvalidDeviceFunction);
  GEN_NAME(cudaErrorNoDevice);
  GEN_NAME(cudaErrorInvalidDevice);
  GEN_NAME(cudaErrorDeviceNotLicensed);
  GEN_NAME(cudaErrorSoftwareValidityNotEstablished);
  GEN_NAME(cudaErrorStartupFailure);
  GEN_NAME(cudaErrorInvalidKernelImage);
  GEN_NAME(cudaErrorDeviceUninitialized);
  GEN_NAME(cudaErrorMapBufferObjectFailed);
  GEN_NAME(cudaErrorUnmapBufferObjectFailed);
  GEN_NAME(cudaErrorArrayIsMapped);
  GEN_NAME(cudaErrorAlreadyMapped);
  GEN_NAME(cudaErrorNoKernelImageForDevice);
  GEN_NAME(cudaErrorAlreadyAcquired);
  GEN_NAME(cudaErrorNotMapped);
  GEN_NAME(cudaErrorNotMappedAsArray);
  GEN_NAME(cudaErrorNotMappedAsPointer);
  GEN_NAME(cudaErrorECCUncorrectable);
  GEN_NAME(cudaErrorUnsupportedLimit);
  GEN_NAME(cudaErrorDeviceAlreadyInUse);
  GEN_NAME(cudaErrorPeerAccessUnsupported);
  GEN_NAME(cudaErrorInvalidPtx);
  GEN_NAME(cudaErrorInvalidGraphicsContext);
  GEN_NAME(cudaErrorNvlinkUncorrectable);
  GEN_NAME(cudaErrorJitCompilerNotFound);
  GEN_NAME(cudaErrorUnsupportedPtxVersion);
  GEN_NAME(cudaErrorJitCompilationDisabled);
  GEN_NAME(cudaErrorUnsupportedExecAffinity);
  GEN_NAME(cudaErrorInvalidSource);
  GEN_NAME(cudaErrorFileNotFound);
  GEN_NAME(cudaErrorSharedObjectSymbolNotFound);
  GEN_NAME(cudaErrorSharedObjectInitFailed);
  GEN_NAME(cudaErrorOperatingSystem);
  GEN_NAME(cudaErrorInvalidResourceHandle);
  GEN_NAME(cudaErrorIllegalState);
  GEN_NAME(cudaErrorSymbolNotFound);
  GEN_NAME(cudaErrorNotReady);
  GEN_NAME(cudaErrorIllegalAddress);
  GEN_NAME(cudaErrorLaunchOutOfResources);
  GEN_NAME(cudaErrorLaunchTimeout);
  GEN_NAME(cudaErrorLaunchIncompatibleTexturing);
  GEN_NAME(cudaErrorPeerAccessAlreadyEnabled);
  GEN_NAME(cudaErrorPeerAccessNotEnabled);
  GEN_NAME(cudaErrorSetOnActiveProcess);
  GEN_NAME(cudaErrorContextIsDestroyed);
  GEN_NAME(cudaErrorAssert);
  GEN_NAME(cudaErrorTooManyPeers);
  GEN_NAME(cudaErrorHostMemoryAlreadyRegistered);
  GEN_NAME(cudaErrorHostMemoryNotRegistered);
  GEN_NAME(cudaErrorHardwareStackError);
  GEN_NAME(cudaErrorIllegalInstruction);
  GEN_NAME(cudaErrorMisalignedAddress);
  GEN_NAME(cudaErrorInvalidAddressSpace);
  GEN_NAME(cudaErrorInvalidPc);
  GEN_NAME(cudaErrorLaunchFailure);
  GEN_NAME(cudaErrorCooperativeLaunchTooLarge);
  GEN_NAME(cudaErrorNotPermitted);
  GEN_NAME(cudaErrorNotSupported);
  GEN_NAME(cudaErrorSystemNotReady);
  GEN_NAME(cudaErrorSystemDriverMismatch);
  GEN_NAME(cudaErrorCompatNotSupportedOnDevice);
  GEN_NAME(cudaErrorMpsConnectionFailed);
  GEN_NAME(cudaErrorMpsRpcFailure);
  GEN_NAME(cudaErrorMpsServerNotReady);
  GEN_NAME(cudaErrorMpsMaxClientsReached);
  GEN_NAME(cudaErrorMpsMaxConnectionsReached);
  GEN_NAME(cudaErrorMpsClientTerminated);
  GEN_NAME(cudaErrorStreamCaptureUnsupported);
  GEN_NAME(cudaErrorStreamCaptureInvalidated);
  GEN_NAME(cudaErrorStreamCaptureMerge);
  GEN_NAME(cudaErrorStreamCaptureUnmatched);
  GEN_NAME(cudaErrorStreamCaptureUnjoined);
  GEN_NAME(cudaErrorStreamCaptureIsolation);
  GEN_NAME(cudaErrorStreamCaptureImplicit);
  GEN_NAME(cudaErrorCapturedEvent);
  GEN_NAME(cudaErrorStreamCaptureWrongThread);
  GEN_NAME(cudaErrorTimeout);
  GEN_NAME(cudaErrorGraphExecUpdateFailure);
  GEN_NAME(cudaErrorExternalDevice);
  GEN_NAME(cudaErrorInvalidClusterSize);
  GEN_NAME(cudaErrorUnknown);
  GEN_NAME(cudaErrorApiFailureBase);

  GEN_STRING(cudaSuccess);
  GEN_STRING(cudaErrorInvalidValue);
  GEN_STRING(cudaErrorMemoryAllocation);
  GEN_STRING(cudaErrorInitializationError);
  GEN_STRING(cudaErrorCudartUnloading);
  GEN_STRING(cudaErrorProfilerDisabled);
  GEN_STRING(cudaErrorProfilerNotInitialized);
  GEN_STRING(cudaErrorProfilerAlreadyStarted);
  GEN_STRING(cudaErrorProfilerAlreadyStopped);
  GEN_STRING(cudaErrorInvalidConfiguration);
  GEN_STRING(cudaErrorInvalidPitchValue);
  GEN_STRING(cudaErrorInvalidSymbol);
  GEN_STRING(cudaErrorInvalidHostPointer);
  GEN_STRING(cudaErrorInvalidDevicePointer);
  GEN_STRING(cudaErrorInvalidTexture);
  GEN_STRING(cudaErrorInvalidTextureBinding);
  GEN_STRING(cudaErrorInvalidChannelDescriptor);
  GEN_STRING(cudaErrorInvalidMemcpyDirection);
  GEN_STRING(cudaErrorAddressOfConstant);
  GEN_STRING(cudaErrorTextureFetchFailed);
  GEN_STRING(cudaErrorTextureNotBound);
  GEN_STRING(cudaErrorSynchronizationError);
  GEN_STRING(cudaErrorInvalidFilterSetting);
  GEN_STRING(cudaErrorInvalidNormSetting);
  GEN_STRING(cudaErrorMixedDeviceExecution);
  GEN_STRING(cudaErrorNotYetImplemented);
  GEN_STRING(cudaErrorMemoryValueTooLarge);
  GEN_STRING(cudaErrorStubLibrary);
  GEN_STRING(cudaErrorInsufficientDriver);
  GEN_STRING(cudaErrorCallRequiresNewerDriver);
  GEN_STRING(cudaErrorInvalidSurface);
  GEN_STRING(cudaErrorDuplicateVariableName);
  GEN_STRING(cudaErrorDuplicateTextureName);
  GEN_STRING(cudaErrorDuplicateSurfaceName);
  GEN_STRING(cudaErrorDevicesUnavailable);
  GEN_STRING(cudaErrorIncompatibleDriverContext);
  GEN_STRING(cudaErrorMissingConfiguration);
  GEN_STRING(cudaErrorPriorLaunchFailure);
  GEN_STRING(cudaErrorLaunchMaxDepthExceeded);
  GEN_STRING(cudaErrorLaunchFileScopedTex);
  GEN_STRING(cudaErrorLaunchFileScopedSurf);
  GEN_STRING(cudaErrorSyncDepthExceeded);
  GEN_STRING(cudaErrorLaunchPendingCountExceeded);
  GEN_STRING(cudaErrorInvalidDeviceFunction);
  GEN_STRING(cudaErrorNoDevice);
  GEN_STRING(cudaErrorInvalidDevice);
  GEN_STRING(cudaErrorDeviceNotLicensed);
  GEN_STRING(cudaErrorSoftwareValidityNotEstablished);
  GEN_STRING(cudaErrorStartupFailure);
  GEN_STRING(cudaErrorInvalidKernelImage);
  GEN_STRING(cudaErrorDeviceUninitialized);
  GEN_STRING(cudaErrorMapBufferObjectFailed);
  GEN_STRING(cudaErrorUnmapBufferObjectFailed);
  GEN_STRING(cudaErrorArrayIsMapped);
  GEN_STRING(cudaErrorAlreadyMapped);
  GEN_STRING(cudaErrorNoKernelImageForDevice);
  GEN_STRING(cudaErrorAlreadyAcquired);
  GEN_STRING(cudaErrorNotMapped);
  GEN_STRING(cudaErrorNotMappedAsArray);
  GEN_STRING(cudaErrorNotMappedAsPointer);
  GEN_STRING(cudaErrorECCUncorrectable);
  GEN_STRING(cudaErrorUnsupportedLimit);
  GEN_STRING(cudaErrorDeviceAlreadyInUse);
  GEN_STRING(cudaErrorPeerAccessUnsupported);
  GEN_STRING(cudaErrorInvalidPtx);
  GEN_STRING(cudaErrorInvalidGraphicsContext);
  GEN_STRING(cudaErrorNvlinkUncorrectable);
  GEN_STRING(cudaErrorJitCompilerNotFound);
  GEN_STRING(cudaErrorUnsupportedPtxVersion);
  GEN_STRING(cudaErrorJitCompilationDisabled);
  GEN_STRING(cudaErrorUnsupportedExecAffinity);
  GEN_STRING(cudaErrorInvalidSource);
  GEN_STRING(cudaErrorFileNotFound);
  GEN_STRING(cudaErrorSharedObjectSymbolNotFound);
  GEN_STRING(cudaErrorSharedObjectInitFailed);
  GEN_STRING(cudaErrorOperatingSystem);
  GEN_STRING(cudaErrorInvalidResourceHandle);
  GEN_STRING(cudaErrorIllegalState);
  GEN_STRING(cudaErrorSymbolNotFound);
  GEN_STRING(cudaErrorNotReady);
  GEN_STRING(cudaErrorIllegalAddress);
  GEN_STRING(cudaErrorLaunchOutOfResources);
  GEN_STRING(cudaErrorLaunchTimeout);
  GEN_STRING(cudaErrorLaunchIncompatibleTexturing);
  GEN_STRING(cudaErrorPeerAccessAlreadyEnabled);
  GEN_STRING(cudaErrorPeerAccessNotEnabled);
  GEN_STRING(cudaErrorSetOnActiveProcess);
  GEN_STRING(cudaErrorContextIsDestroyed);
  GEN_STRING(cudaErrorAssert);
  GEN_STRING(cudaErrorTooManyPeers);
  GEN_STRING(cudaErrorHostMemoryAlreadyRegistered);
  GEN_STRING(cudaErrorHostMemoryNotRegistered);
  GEN_STRING(cudaErrorHardwareStackError);
  GEN_STRING(cudaErrorIllegalInstruction);
  GEN_STRING(cudaErrorMisalignedAddress);
  GEN_STRING(cudaErrorInvalidAddressSpace);
  GEN_STRING(cudaErrorInvalidPc);
  GEN_STRING(cudaErrorLaunchFailure);
  GEN_STRING(cudaErrorCooperativeLaunchTooLarge);
  GEN_STRING(cudaErrorNotPermitted);
  GEN_STRING(cudaErrorNotSupported);
  GEN_STRING(cudaErrorSystemNotReady);
  GEN_STRING(cudaErrorSystemDriverMismatch);
  GEN_STRING(cudaErrorCompatNotSupportedOnDevice);
  GEN_STRING(cudaErrorMpsConnectionFailed);
  GEN_STRING(cudaErrorMpsRpcFailure);
  GEN_STRING(cudaErrorMpsServerNotReady);
  GEN_STRING(cudaErrorMpsMaxClientsReached);
  GEN_STRING(cudaErrorMpsMaxConnectionsReached);
  GEN_STRING(cudaErrorMpsClientTerminated);
  GEN_STRING(cudaErrorStreamCaptureUnsupported);
  GEN_STRING(cudaErrorStreamCaptureInvalidated);
  GEN_STRING(cudaErrorStreamCaptureMerge);
  GEN_STRING(cudaErrorStreamCaptureUnmatched);
  GEN_STRING(cudaErrorStreamCaptureUnjoined);
  GEN_STRING(cudaErrorStreamCaptureIsolation);
  GEN_STRING(cudaErrorStreamCaptureImplicit);
  GEN_STRING(cudaErrorCapturedEvent);
  GEN_STRING(cudaErrorStreamCaptureWrongThread);
  GEN_STRING(cudaErrorTimeout);
  GEN_STRING(cudaErrorGraphExecUpdateFailure);
  GEN_STRING(cudaErrorExternalDevice);
  GEN_STRING(cudaErrorInvalidClusterSize);
  GEN_STRING(cudaErrorUnknown);
  GEN_STRING(cudaErrorApiFailureBase);

  return 0;
}