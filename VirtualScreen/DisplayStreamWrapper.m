#import "DisplayStreamWrapper.h"
#import <dlfcn.h>

// Define function pointers
typedef CGDisplayStreamRef (*CGDisplayStreamCreateWithDispatchQueueType)(
    CGDirectDisplayID, size_t, size_t, OSType, CFDictionaryRef,
    dispatch_queue_t, CGDisplayStreamFrameAvailableHandler);
typedef CGError (*CGDisplayStreamStartType)(CGDisplayStreamRef);
typedef CGError (*CGDisplayStreamStopType)(CGDisplayStreamRef);

// Hardcode keys to bypass availability checks
// These string values are stable in macOS.
#define kCGDisplayStreamShowCursor_Compat @"ShowCursor"
#define kCGDisplayStreamYCbCrMatrix_Compat @"YCbCrMatrix"
#define kCGDisplayStreamYCbCrMatrix_ITU_R_709_2_Compat                         \
  @"YCbCrMatrix_ITU_R_709_2"

@implementation DisplayStreamWrapper {
  void *coreGraphicsHandle;
}

- (instancetype)initWithDisplayID:(CGDirectDisplayID)displayID
                            width:(size_t)width
                           height:(size_t)height
                          handler:(void (^)(CGDisplayStreamFrameStatus,
                                            uint64_t, IOSurfaceRef _Nullable,
                                            CGDisplayStreamUpdateRef _Nullable))
                                      handler {
  self = [super init];
  if (self) {
    // Dynamically load symbols
    coreGraphicsHandle =
        dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
               RTLD_LAZY);
    if (!coreGraphicsHandle)
      return nil;

    CGDisplayStreamCreateWithDispatchQueueType createFunc =
        (CGDisplayStreamCreateWithDispatchQueueType)dlsym(
            coreGraphicsHandle, "CGDisplayStreamCreateWithDispatchQueue");

    if (!createFunc)
      return nil;

    NSDictionary *properties = @{
      kCGDisplayStreamShowCursor_Compat : @YES
      // Removing YCbCrMatrix for now as it might cause issues on some displays
      // kCGDisplayStreamYCbCrMatrix_Compat :
      // kCGDisplayStreamYCbCrMatrix_ITU_R_709_2_Compat
    };

    _stream = createFunc(
        displayID, width, height, kCVPixelFormatType_32BGRA,
        (__bridge CFDictionaryRef)properties, dispatch_get_main_queue(),
        ^(CGDisplayStreamFrameStatus status, uint64_t displayTime,
          IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
          if (status == kCGDisplayStreamFrameStatusFrameComplete) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
              printf("DisplayStreamWrapper: Received first frame!\n");
            });
          }
          if (handler) {
            handler(status, displayTime, frameSurface, updateRef);
          }
        });

    if (!_stream) {
      printf("DisplayStreamWrapper: failed to create stream (createFunc "
             "returned NULL)\n");
    }
  }
  return self;
}

- (void)start {
  if (_stream && coreGraphicsHandle) {
    CGDisplayStreamStartType startFunc = (CGDisplayStreamStartType)dlsym(
        coreGraphicsHandle, "CGDisplayStreamStart");
    if (startFunc) {
      startFunc(_stream);
    }
  }
}

- (void)stop {
  if (_stream && coreGraphicsHandle) {
    CGDisplayStreamStopType stopFunc = (CGDisplayStreamStopType)dlsym(
        coreGraphicsHandle, "CGDisplayStreamStop");
    if (stopFunc) {
      stopFunc(_stream);
    }
  }
}

- (void)dealloc {
  if (_stream) {
    CFRelease(_stream);
  }
  if (coreGraphicsHandle) {
    dlclose(coreGraphicsHandle);
  }
  [super dealloc];
}

@end
