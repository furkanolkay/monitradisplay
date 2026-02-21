#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DisplayStreamWrapper : NSObject
@property(nonatomic, assign) CGDisplayStreamRef _Nullable stream;

- (instancetype)
    initWithDisplayID:(CGDirectDisplayID)displayID
                width:(size_t)width
               height:(size_t)height
              handler:(void (^)(CGDisplayStreamFrameStatus status,
                                uint64_t displayTime,
                                IOSurfaceRef _Nullable frameSurface,
                                CGDisplayStreamUpdateRef _Nullable updateRef))
                          handler;

- (void)start;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
