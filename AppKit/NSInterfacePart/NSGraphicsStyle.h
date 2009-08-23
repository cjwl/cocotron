/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>
#import <AppKit/NSSliderCell.h>

@class NSImage,NSColor;

@interface NSGraphicsStyle : NSObject {
   NSView *_view;
}

-(NSSize)sizeOfMenuBranchArrow;

-(void)drawMenuSeparatorInRect:(NSRect)rect;
-(void)drawMenuCheckmarkAtPoint:(NSPoint)point selected:(BOOL)selected;

-(NSRect)drawUnborderedButtonInRect:(NSRect)rect defaulted:(BOOL)defaulted;

-(void)drawPushButtonNormalInRect:(NSRect)rect defaulted:(BOOL)defaulted;
-(void)drawPushButtonPressedInRect:(NSRect)rect;
-(void)drawPushButtonHighlightedInRect:(NSRect)rect;
-(NSSize)sizeOfButtonImage:(NSImage *)image enabled:(BOOL)enabled mixed:(BOOL)mixed;
-(void)drawButtonImage:(NSImage *)image inRect:(NSRect)rect enabled:(BOOL)enabled mixed:(BOOL)mixed;
-(void)drawBrowserTitleBackgroundInRect:(NSRect)rect;
-(void)drawBrowserHorizontalScrollerWellInRect:(NSRect)rect clipRect:(NSRect)clipRect;
-(NSRect)drawColorWellBorderInRect:(NSRect)rect enabled:(BOOL)enabled bordered:(BOOL)bordered active:(BOOL)active;
-(void)drawMenuBranchArrowAtPoint:(NSPoint)point selected:(BOOL)selected;
-(void)drawMenuWindowBackgroundInRect:(NSRect)rect;

-(void)drawPopUpButtonWindowBackgroundInRect:(NSRect)rect;

-(void)drawOutlineViewBranchInRect:(NSRect)rect expanded:(BOOL)expanded;
-(void)drawOutlineViewGridInRect:(NSRect)rect;

-(NSRect)drawProgressIndicatorBackground:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled;
-(void)drawProgressIndicatorChunk:(NSRect)rect;
-(void)drawProgressIndicatorIndeterminate:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled animation:(double)animation;
-(void)drawProgressIndicatorDeterminate:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled value:(double)value;

-(void)drawScrollerButtonInRect:(NSRect)rect enabled:(BOOL)enabled pressed:(BOOL)pressed vertical:(BOOL)vertical upOrLeft:(BOOL)upOrLeft;
-(void)drawScrollerKnobInRect:(NSRect)rect vertical:(BOOL)vertical highlight:(BOOL)highlight;
-(void)drawScrollerTrackInRect:(NSRect)rect vertical:(BOOL)vertical upOrLeft:(BOOL)upOrLeft;
-(void)drawScrollerTrackInRect:(NSRect)rect vertical:(BOOL)vertical;
-(NSSize)sliderKnobSize;
-(void)drawSliderKnobInRect:(NSRect)rect vertical:(BOOL)vertical highlighted:(BOOL)highlighted hasTickMarks:(BOOL)hasTickMarks tickMarkPosition:(NSTickMarkPosition)tickMarkPosition;
-(void)drawSliderTrackInRect:(NSRect)rect vertical:(BOOL)vertical hasTickMarks:(BOOL)hasTickMarks;
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
-(void)drawTabViewBackgroundInRect:(NSRect)rect;

-(void)drawTextFieldBorderInRect:(NSRect)rect bezeledNotLine:(BOOL)bezeledNotLine;
-(void)drawTextViewInsertionPointInRect:(NSRect)rect color:(NSColor *)color;

@end

@interface NSView(NSGraphicsStyle)
-(NSGraphicsStyle *)graphicsStyle;
@end
