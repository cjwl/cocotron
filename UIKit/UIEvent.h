#import <Foundation/NSDate.h>
#import <UIKit/UIKitExport.h>

@class NSSet,UIGestureRecognizer,UIView,UIWindow;

typedef enum {
   UIEventTypeTouches=0,
   UIEventTypeMotion=1,
   UIEventTypeRemoteControl=2,
} UIEventType;

typedef enum {
   UIEventSubtypeNone                              = 0,
   
   UIEventSubtypeMotionShake                       = 1,
   
   UIEventSubtypeRemoteControlPlay                 = 100,
   UIEventSubtypeRemoteControlPause                = 101,
   UIEventSubtypeRemoteControlStop                 = 102,
   UIEventSubtypeRemoteControlTogglePlayPause      = 103,
   UIEventSubtypeRemoteControlNextTrack            = 104,
   UIEventSubtypeRemoteControlPreviousTrack        = 105,
   UIEventSubtypeRemoteControlBeginSeekingBackward = 106,
   UIEventSubtypeRemoteControlEndSeekingBackward   = 107,
   UIEventSubtypeRemoteControlBeginSeekingForward  = 108,
   UIEventSubtypeRemoteControlEndSeekingForward    = 109,
} UIEventSubtype;

@interface UIEvent : NSObject {
}

@property(readonly) UIEventType type;
@property(readonly) UIEventSubtype subtype;
@property(nonatomic,readonly) NSTimeInterval timestamp;

-(NSSet *)allTouches;

-(NSSet *)touchesForGestureRecognizer:(UIGestureRecognizer *)gesture;
-(NSSet *)touchesForView:(UIView *)view;
-(NSSet *)touchesForWindow:(UIWindow *)window;

@end
