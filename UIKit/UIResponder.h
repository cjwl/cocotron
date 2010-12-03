#import <Foundation/NSObject.h>
#import <UIKit/UIEvent.h>

@class UIView,NSUndoManager;

@interface UIResponder : NSObject {
}

@property(readonly,retain) UIView *inputAccessoryView;
@property(readonly,retain) UIView *inputView;
@property(readonly) NSUndoManager *undoManager;

-(UIResponder *)nextResponder;

-(BOOL)becomeFirstResponder;
-(BOOL)resignFirstResponder;
-(BOOL)canBecomeFirstResponder;
-(BOOL)canPerformAction:(SEL)action withSender:sender;
-(BOOL)canResignFirstResponder;
-(BOOL)isFirstResponder;

-(void)reloadInputViews;

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event;
-(void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event;
-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)remoteControlReceivedWithEvent:(UIEvent *)event;

@end
