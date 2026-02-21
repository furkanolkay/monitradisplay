#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CGVirtualDisplayDescriptor : NSObject
@property(nonatomic, assign) uint32_t maxPixelsWide;
@property(nonatomic, assign) uint32_t maxPixelsHigh;
@property(nonatomic, assign) CGSize sizeInMillimeters;
@property(nonatomic, assign) uint32_t serialNum;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) uint32_t productID;
@property(nonatomic, assign) uint32_t vendorID;
@property(nonatomic, copy) dispatch_queue_t dispatchQueue;
@property(nonatomic, copy) void (^terminationHandler)(id, id);
@end

@interface CGVirtualDisplayMode : NSObject
@property(nonatomic, assign) uint32_t width;
@property(nonatomic, assign) uint32_t height;
@property(nonatomic, assign) double refreshRate;
- (instancetype)initWithWidth:(uint32_t)width
                       height:(uint32_t)height
                  refreshRate:(double)refreshRate;
@end

@interface CGVirtualDisplaySettings : NSObject
@property(nonatomic, strong) NSArray<CGVirtualDisplayMode *> *modes;
@property(nonatomic, assign) uint32_t hiDPI;
@end

@interface CGVirtualDisplay : NSObject
@property(nonatomic, readonly) uint32_t displayID;
- (nullable instancetype)initWithDescriptor:
    (CGVirtualDisplayDescriptor *)descriptor;
- (BOOL)applySettings:(CGVirtualDisplaySettings *)settings;
@end

NS_ASSUME_NONNULL_END
