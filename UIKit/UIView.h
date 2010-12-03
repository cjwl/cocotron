#import <UIKit/UIResponder.h>
#import <CoreGraphics/CoreGraphics.h>

@class CALayer,UIColor;

typedef enum {
   UIViewAnimationCurveEaseInOut=0,
   UIViewAnimationCurveEaseIn=1,
   UIViewAnimationCurveEaseOut=2,
   UIViewAnimationCurveLinear=3,
} UIViewAnimationCurve;

typedef enum {
   UIViewContentModeScaleToFill=0,
   UIViewContentModeScaleAspectFit=1,
   UIViewContentModeScaleAspectFill=2,
   UIViewContentModeRedraw=3,
   UIViewContentModeCenter=4,
   UIViewContentModeTop=5,
   UIViewContentModeBottom=6,
   UIViewContentModeLeft=7,
   UIViewContentModeRight=8,
   UIViewContentModeTopLeft=9,
   UIViewContentModeTopRight=10,
   UIViewContentModeBottomLeft=11,
   UIViewContentModeBottomRight=12,
} UIViewContentMode;

enum {
   UIViewAutoresizingNone                =0x00,
   UIViewAutoresizingFlexibleLeftMargin  =0x01,
   UIViewAutoresizingFlexibleWidth       =0x02,
   UIViewAutoresizingFlexibleRightMargin =0x04,
   UIViewAutoresizingFlexibleTopMargin   =0x08,
   UIViewAutoresizingFlexibleHeight      =0x10,
   UIViewAutoresizingFlexibleBottomMargin=0x20,
};
typedef NSUInteger UIViewAutoresizing;

typedef enum {
   UIViewAnimationTransitionNone=0,
   UIViewAnimationTransitionFlipFromLeft=1,
   UIViewAnimationTransitionFlipFromRight=2,
   UIViewAnimationTransitionCurlUp=3,
   UIViewAnimationTransitionCurlDown=4,
} UIViewAnimationTransition;

@interface UIView : UIResponder <NSCoding> {
}

@property(nonatomic) CGRect frame;
@property(nonatomic) CGRect bounds;
@property(nonatomic) CGPoint center;
@property(nonatomic) BOOL autoresizesSubviews;
@property(nonatomic) UIViewAutoresizing autoresizingMask;
@property(nonatomic,getter=isHidden) BOOL hidden;
@property(nonatomic,readonly,retain) CALayer *layer;
@property(nonatomic,readonly,copy) NSArray *subviews;
@property(nonatomic,readonly) UIView *superview;
@property(nonatomic) NSInteger tag;
@property(nonatomic,readonly) UIWindow *window;
@property(nonatomic,getter=isOpaque) BOOL opaque;
@property(nonatomic) CGAffineTransform transform;

@property(nonatomic) CGFloat alpha;
@property(nonatomic,copy) UIColor *backgroundColor;
@property(nonatomic) BOOL clearsContextBeforeDrawing;
@property(nonatomic) BOOL clipsToBounds;
@property(nonatomic) UIViewContentMode contentMode;
@property(nonatomic) CGFloat contentScaleFactor;
@property(nonatomic) CGRect contentStretch;
@property(nonatomic,getter=isExclusiveTouch) BOOL exclusiveTouch;
@property(nonatomic,copy) NSArray *gestureRecognizers;
@property(nonatomic,getter=isMultipleTouchEnabled) BOOL multipleTouchEnabled;
@property(nonatomic,getter=isUserInteractionEnabled) BOOL userInteractionEnabled;

//+(void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;
//+(void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
//+(void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+(BOOL)areAnimationsEnabled;
+(void)beginAnimations:(NSString *)animationID context:(void *)context;
+(void)commitAnimations;
+(Class)layerClass;
+(void)setAnimationBeginsFromCurrentState:(BOOL)value;
+(void)setAnimationCurve:(UIViewAnimationCurve)value;
+(void)setAnimationDelay:(NSTimeInterval)value;
+(void)setAnimationDelegate:delegate;
+(void)setAnimationDidStopSelector:(SEL)selector;
+(void)setAnimationDuration:(NSTimeInterval)value;
+(void)setAnimationRepeatAutoreverses:(BOOL)value;
+(void)setAnimationRepeatCount:(float)value;
+(void)setAnimationsEnabled:(BOOL)value;
+(void)setAnimationStartDate:(NSDate *)value;
+(void)setAnimationTransition:(UIViewAnimationTransition)transition forView:(UIView *)view cache:(BOOL)cache;
+(void)setAnimationWillStartSelector:(SEL)selector;
//+(void)transitionFromView:(UIView *)fromView toView:(UIView *)toView duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completion;
//+(void)transitionWithView:(UIView *)view duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
-(void)addSubview:(UIView *)view;
-(void)bringSubviewToFront:(UIView *)view;
-(CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view;
-(CGPoint)convertPoint:(CGPoint)point toView:(UIView *)view;
-(CGRect)convertRect:(CGRect)rect fromView:(UIView *)view;
-(CGRect)convertRect:(CGRect)rect toView:(UIView *)view;
-(void)didAddSubview:(UIView *)subview;
-(void)didMoveToSuperview;
-(void)didMoveToWindow;
-(void)drawRect:(CGRect)rect;
-(BOOL)endEditing:(BOOL)force;
-(void)exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2;
-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event;
-initWithFrame:(CGRect)rect;
-(void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview;
-(void)insertSubview:(UIView *)view atIndex:(NSInteger)index;
-(void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview;
-(BOOL)isDescendantOfView:(UIView *)view;
-(void)layoutIfNeeded;
-(void)layoutSubviews;
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
-(void)removeFromSuperview;
-(void)removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;
-(void)sendSubviewToBack:(UIView *)view;
-(void)setNeedsDisplay;
-(void)setNeedsDisplayInRect:(CGRect)invalidRect;
-(void)setNeedsLayout;
-(CGSize)sizeThatFits:(CGSize)size;
-(void)sizeToFit;

-(UIView *)viewWithTag:(NSInteger)tag;

-(void)willMoveToSuperview:(UIView *)newSuperview;

-(void)willMoveToWindow:(UIWindow *)newWindow;

-(void)willRemoveSubview:(UIView *)subview;

@end
