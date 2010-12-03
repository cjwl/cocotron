#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIView,UIWindow;

typedef enum {
   UITouchPhaseBegan=0,
   UITouchPhaseMoved=1,
   UITouchPhaseStationary=2,
   UITouchPhaseEnded=3,
   UITouchPhaseCancelled=4,
} UITouchPhase;

@interface UITouch : NSObject {
}

@property(nonatomic,readonly) UITouchPhase phase;
@property(nonatomic,readonly) NSUInteger tapCount;
@property(nonatomic,readonly) NSTimeInterval timestamp;
@property(nonatomic,readonly,retain) UIView *view;
@property(nonatomic,readonly,retain) UIWindow *window;
@property(nonatomic,readonly,copy) NSArray *gestureRecognizers;

-(CGPoint)locationInView:(UIView *)view;
-(CGPoint)previousLocationInView:(UIView *)view;

@end
