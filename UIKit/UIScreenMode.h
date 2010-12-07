#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIScreenMode : NSObject {
}

@property(readonly,nonatomic) CGFloat pixelAspectRatio;
@property(readonly,nonatomic) CGSize size;

@end
