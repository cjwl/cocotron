#import <UIKit/UIResponder.h>
#import <UIKit/UIDevice.h>
#import <UIKit/UIKitExport.h>
#import <CoreGraphics/CoreGraphics.h>

@class UILocalNotification;

typedef enum {
   UIInterfaceOrientationPortrait          =UIDeviceOrientationPortrait,
   UIInterfaceOrientationPortraitUpsideDown=UIDeviceOrientationPortraitUpsideDown,
   UIInterfaceOrientationLandscapeLeft     =UIDeviceOrientationLandscapeRight,
   UIInterfaceOrientationLandscapeRight    =UIDeviceOrientationLandscapeLeft,
} UIInterfaceOrientation;

typedef enum {
   UIStatusBarStyleDefault=0,
   UIStatusBarStyleBlackTranslucent=1,
   UIStatusBarStyleBlackOpaque=2,
} UIStatusBarStyle;

typedef enum {
   UIStatusBarAnimationNone=0,
   UIStatusBarAnimationFade=1,
   UIStatusBarAnimationSlide=2,
} UIStatusBarAnimation;

typedef enum {
   UIRemoteNotificationTypeNone =0x00,
   UIRemoteNotificationTypeBadge=0x01,
   UIRemoteNotificationTypeSound=0x02,
   UIRemoteNotificationTypeAlert=0x04,
} UIRemoteNotificationType;

typedef enum {
   UIApplicationStateActive=0,
   UIApplicationStateInactive=1,
   UIApplicationStateBackground=2,
} UIApplicationState;

typedef NSUInteger UIBackgroundTaskIdentifier;

UIKIT_EXPORT const UIBackgroundTaskIdentifier UIBackgroundTaskInvalid;
UIKIT_EXPORT const NSTimeInterval UIMinimumKeepAliveTimeout;

UIKIT_EXPORT NSString *const UITrackingRunLoopMode;

UIKIT_EXPORT NSString *const UIApplicationLaunchOptionsURLKey;
UIKIT_EXPORT NSString *const UIApplicationLaunchOptionsSourceApplicationKey;
UIKIT_EXPORT NSString *const UIApplicationLaunchOptionsRemoteNotificationKey;
UIKIT_EXPORT NSString *const UIApplicationLaunchOptionsAnnotationKey;
UIKIT_EXPORT NSString *const UIApplicationLaunchOptionsLocalNotificationKey;
UIKIT_EXPORT NSString *const UIApplicationLaunchOptionsLocationKey;

UIKIT_EXPORT NSString *const UIApplicationStatusBarOrientationUserInfoKey;
UIKIT_EXPORT NSString *const UIApplicationStatusBarFrameUserInfoKey;

UIKIT_EXPORT NSString *const UIApplicationDidBecomeActiveNotification;
UIKIT_EXPORT NSString *const UIApplicationDidChangeStatusBarFrameNotification;
UIKIT_EXPORT NSString *const UIApplicationDidChangeStatusBarOrientationNotification;
UIKIT_EXPORT NSString *const UIApplicationDidEnterBackgroundNotification;
UIKIT_EXPORT NSString *const UIApplicationDidFinishLaunchingNotification;
UIKIT_EXPORT NSString *const UIApplicationDidReceiveMemoryWarningNotification;
UIKIT_EXPORT NSString *const UIApplicationProtectedDataDidBecomeAvailable;
UIKIT_EXPORT NSString *const UIApplicationProtectedDataWillBecomeUnavailable;
UIKIT_EXPORT NSString *const UIApplicationSignificantTimeChangeNotification;
UIKIT_EXPORT NSString *const UIApplicationWillChangeStatusBarOrientationNotification;
UIKIT_EXPORT NSString *const UIApplicationWillChangeStatusBarFrameNotification;
UIKIT_EXPORT NSString *const UIApplicationWillEnterForegroundNotification;
UIKIT_EXPORT NSString *const UIApplicationWillResignActiveNotification;
UIKIT_EXPORT NSString *const UIApplicationWillTerminateNotification;

UIKIT_EXPORT int UIApplicationMain (int argc,char *argv[],NSString *applicationClassName,NSString *appDelegateClassName);


@protocol UIApplicationDelegate
@end


@interface UIApplication : UIResponder {
   id              _delegate;
   NSMutableArray *_windows;
   UIWindow       *_keyWindow;
}

@property(nonatomic,assign) id<UIApplicationDelegate> delegate;
@property(nonatomic,readonly) NSArray *windows;
@property(nonatomic,readonly) UIWindow *keyWindow;

@property(nonatomic) NSInteger applicationIconBadgeNumber;
@property(nonatomic,readonly) UIApplicationState applicationState;
@property(nonatomic) BOOL applicationSupportsShakeToEdit;
@property(nonatomic,readonly) NSTimeInterval backgroundTimeRemaining;
@property(nonatomic,getter=isIdleTimerDisabled) BOOL idleTimerDisabled;
@property(nonatomic,getter=isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;
@property(nonatomic,readonly,getter=isProtectedDataAvailable) BOOL protectedDataAvailable;
@property(nonatomic,readonly) CGRect statusBarFrame;
@property(nonatomic,getter=isStatusBarHidden) BOOL statusBarHidden;
@property(nonatomic) UIInterfaceOrientation statusBarOrientation;
@property(nonatomic,readonly) NSTimeInterval statusBarOrientationAnimationDuration;
@property(nonatomic) UIStatusBarStyle statusBarStyle;

+ (UIApplication *)sharedApplication;

//-(UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void(^)(void))handler;
-(void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

-(BOOL)isIgnoringInteractionEvents;
-(void)beginIgnoringInteractionEvents;
-(void)endIgnoringInteractionEvents;

-(void)beginReceivingRemoteControlEvents;
-(void)endReceivingRemoteControlEvents;

-(void)cancelAllLocalNotifications;
-(void)cancelLocalNotification:(UILocalNotification *)note;

-(BOOL)canOpenURL:(NSURL *)url;

-(void)clearKeepAliveTimeout;

-(UIRemoteNotificationType)enabledRemoteNotificationTypes;
-(void)unregisterForRemoteNotifications;                

-(BOOL)openURL:(NSURL *)url;

-(void)presentLocalNotificationNow:(UILocalNotification *)note;
-(void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;
-(NSArray *)scheduledLocalNotifications;
-(void)scheduleLocalNotification:(UILocalNotification *)note;

-(BOOL)sendAction:(SEL)action to:target from:sender forEvent:(UIEvent *)event;

-(void)sendEvent:(UIEvent *)event;

//-(BOOL)setKeepAliveTimeout:(NSTimeInterval)value handler:(void(^)(void))handler;

-(void)setStatusBarHidden:(BOOL)value withAnimation:(UIStatusBarAnimation)animation;
-(void)setStatusBarOrientation:(UIInterfaceOrientation)value animated:(BOOL)animated;
-(void)setStatusBarStyle:(UIStatusBarStyle)value animated:(BOOL)animated;


@end
