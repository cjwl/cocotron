#import <Foundation/NSObject.h>
#import <UIKit/UIKitExport.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIScreenMode,CADisplayLink;

UIKIT_EXPORT NSString *const UIScreenDidConnectNotification;
UIKIT_EXPORT NSString *const UIScreenDidDisconnectNotification;
UIKIT_EXPORT NSString *const UIScreenModeDidChangeNotification;

@interface UIScreen : NSObject {
}

@property(nonatomic,readonly) CGRect bounds;
@property(nonatomic,readonly) CGFloat scale;
@property(nonatomic,readonly) CGRect applicationFrame;
@property(nonatomic,readonly,copy) NSArray *availableModes;
@property(nonatomic,retain) UIScreenMode *currentMode;

+(UIScreen *)mainScreen;
+(NSArray *)screens;

-(CADisplayLink *)displayLinkWithTarget:target selector:(SEL)selector;

@end
