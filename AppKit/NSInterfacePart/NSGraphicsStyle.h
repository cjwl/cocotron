#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>

@class NSImage,NSColor;

@interface NSGraphicsStyle : NSObject {
   NSView *_view;
}

-(NSSize)sizeOfMenuBranchArrow;

-(void)drawMenuSeparatorInRect:(NSRect)rect;
-(void)drawPushButtonNormalInRect:(NSRect)rect;
-(void)drawPushButtonPressedInRect:(NSRect)rect;
-(void)drawPushButtonHighlightedInRect:(NSRect)rect;
-(void)drawButtonImage:(NSImage *)image inRect:(NSRect)rect enabled:(BOOL)enabled;
-(void)drawBrowserTitleBackgroundInRect:(NSRect)rect;
-(NSRect)drawColorWellBorderInRect:(NSRect)rect enabled:(BOOL)enabled bordered:(BOOL)bordered active:(BOOL)active;
-(void)drawMenuBranchArrowAtPoint:(NSPoint)point selected:(BOOL)selected;
-(void)drawOutlineViewBranchInRect:(NSRect)rect expanded:(BOOL)expanded;
-(void)drawOutlineViewGridInRect:(NSRect)rect;
-(void)drawProgressIndicatorBezel:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled;
-(void)drawScrollerButtonInRect:(NSRect)rect enabled:(BOOL)enabled pressed:(BOOL)pressed vertical:(BOOL)vertical upOrLeft:(BOOL)upOrLeft;
-(void)drawScrollerKnobInRect:(NSRect)rect vertical:(BOOL)vertical highlight:(BOOL)highlight;
-(void)drawScrollerTrackInRect:(NSRect)rect vertical:(BOOL)vertical upOrLeft:(BOOL)upOrLeft;
-(void)drawScrollerTrackInRect:(NSRect)rect vertical:(BOOL)vertical;
-(void)drawSliderKnobInRect:(NSRect)rect vertical:(BOOL)vertical highlighted:(BOOL)highlighted;
-(void)drawSliderTrackInRect:(NSRect)rect vertical:(BOOL)vertical;
-(void)drawSliderTickInRect:(NSRect)rect;
-(void)drawStepperButtonInRect:(NSRect)rect clipRect:(NSRect)clipRect enabled:(BOOL)enabled highlighted:(BOOL)highlighted upNotDown:(BOOL)upNotDown;
-(void)drawTableViewHeaderInRect:(NSRect)rect highlighted:(BOOL)highlighted;
-(void)drawTableViewCornerInRect:(NSRect)rect;

-(void)drawBoxWithLineInRect:(NSRect)rect;
-(void)drawBoxWithBezelInRect:(NSRect)rect clipRect:(NSRect)clipRect;
-(void)drawBoxWithGrooveInRect:(NSRect)rect clipRect:(NSRect)clipRect;

-(void)drawComboBoxButtonInRect:(NSRect)rect enabled:(BOOL)enabled bordered:(BOOL)bordered pressed:(BOOL)pressed;

-(void)drawTabInRect:(NSRect)rect clipRect:(NSRect)clipRect color:(NSColor *)color selected:(BOOL)selected;
-(void)drawTabPaneInRect:(NSRect)rect;

-(void)drawTextFieldBorderInRect:(NSRect)rect bezeledNotLine:(BOOL)bezeledNotLine;

@end

@interface NSView(NSGraphicsStyle)
-(NSGraphicsStyle *)graphicsStyle;
@end
