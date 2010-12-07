#import <UIKit/UIView.h>
#import <UIKit/UIKitExport.h>

@class CARenderer,UIViewController,UIScreen;

typedef CGFloat UIWindowLevel;

UIKIT_EXPORT const UIWindowLevel UIWindowLevelNormal;
UIKIT_EXPORT const UIWindowLevel UIWindowLevelAlert;
UIKIT_EXPORT const UIWindowLevel UIWindowLevelStatusBar;

UIKIT_EXPORT NSString *const UIKeyboardFrameBeginUserInfoKey;
UIKIT_EXPORT NSString *const UIKeyboardFrameEndUserInfoKey;
UIKIT_EXPORT NSString *const UIKeyboardAnimationDurationUserInfoKey;
UIKIT_EXPORT NSString *const UIKeyboardAnimationCurveUserInfoKey;

UIKIT_EXPORT NSString *const UIKeyboardCenterBeginUserInfoKey;
UIKIT_EXPORT NSString *const UIKeyboardCenterEndUserInfoKey;
UIKIT_EXPORT NSString *const UIKeyboardBoundsUserInfoKey;

UIKIT_EXPORT NSString *const UIWindowDidBecomeVisibleNotification;
UIKIT_EXPORT NSString *const UIWindowDidBecomeHiddenNotification;
UIKIT_EXPORT NSString *const UIWindowDidBecomeKeyNotification;
UIKIT_EXPORT NSString *const UIWindowDidResignKeyNotification;
UIKIT_EXPORT NSString *const UIKeyboardWillShowNotification;
UIKIT_EXPORT NSString *const UIKeyboardDidShowNotification;
UIKIT_EXPORT NSString *const UIKeyboardWillHideNotification;
UIKIT_EXPORT NSString *const UIKeyboardDidHideNotification;

@interface UIWindow : UIView {
   UIWindowLevel     _windowLevel;
   UIViewController *_rootViewController;
   void             *_cglContext;
   CARenderer       *_renderer;
}


@property(nonatomic) UIWindowLevel windowLevel;
@property(nonatomic,retain) UIViewController *rootViewController;

@property(nonatomic,retain) UIScreen *screen;

@property(nonatomic,readonly,getter=isKeyWindow) BOOL keyWindow;


-(CGPoint)convertPoint:(CGPoint)point toWindow:(UIWindow *)window;
-(CGPoint)convertPoint:(CGPoint)point fromWindow:(UIWindow *)window;
-(CGRect)convertRect:(CGRect)rect toWindow:(UIWindow *)window;
-(CGRect)convertRect:(CGRect)rect fromWindow:(UIWindow *)window;

-(void)makeKeyAndVisible;
-(void)makeKeyWindow;

-(void)becomeKeyWindow;
-(void)resignKeyWindow;

-(void)sendEvent:(UIEvent *)event;

@end
