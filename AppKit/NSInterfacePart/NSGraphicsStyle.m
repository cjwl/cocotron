/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSInterfacePartAttributedString.h>
#import <AppKit/NSInterfacePartDisabledAttributedString.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import "NSInterfaceGraphics.h"

@implementation NSGraphicsStyle

-initWithView:(NSView *)view {
   _view=[view retain];
   return self;
}

-(void)dealloc {
   [_view release];
   [super dealloc];
}

-(NSSize)sizeOfMenuBranchArrow {
   return [[[[NSInterfacePartAttributedString alloc] initWithCharacter:0x34 fontName:@"Marlett" pointSize:10 color:[NSColor menuItemTextColor]] autorelease] size];
}

-(void)drawMenuSeparatorInRect:(NSRect)rect {
   NSPoint point=rect.origin;
   float   width=rect.size.width;
     
   [[NSColor darkGrayColor] setFill];
   NSRectFill(NSMakeRect(point.x,point.y,width,1));
   [[NSColor whiteColor] setFill];
   NSRectFill(NSMakeRect(point.x,point.y+1,width,1));
}

-(void)drawMenuCheckmarkAtPoint:(NSPoint)point selected:(BOOL)selected {
	NSColor         *color=selected?[NSColor selectedControlTextColor]:[NSColor 
menuItemTextColor];
	NSInterfacePart *arrow;
	
	arrow=[[[NSInterfacePartAttributedString alloc] initWithCharacter:0x61 fontName:@"Marlett" 
pointSize:10 color:color] autorelease];
	
	[arrow drawAtPoint:point];
}

-(NSRect)drawUnborderedButtonInRect:(NSRect)rect defaulted:(BOOL)defaulted {
   if(defaulted){
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    rect = NSInsetRect(rect,1,1);
   }
   return rect;
}

-(void)drawPushButtonNormalInRect:(NSRect)rect defaulted:(BOOL)defaulted {
   if(defaulted){
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    rect = NSInsetRect(rect,1,1);
   }

   NSDrawButton(rect,rect);
}

-(void)drawPushButtonPressedInRect:(NSRect)rect {
   NSInterfaceDrawDepressedButton(rect,rect);
}

-(void)drawPushButtonHighlightedInRect:(NSRect)rect {
   NSInterfaceDrawHighlightedButton(rect,rect);
}

-(NSSize)sizeOfButtonImage:(NSImage *)image enabled:(BOOL)enabled mixed:(BOOL)mixed {
   return [image size];
}

-(void)drawButtonImage:(NSImage *)image inRect:(NSRect)rect enabled:(BOOL)enabled mixed:(BOOL)mixed {
   float fraction=enabled?1.0:0.5;
   
   [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];
}

-(void)drawBrowserTitleBackgroundInRect:(NSRect)rect {
   NSInterfaceDrawBrowserHeader(rect,rect);
}

-(void)drawBrowserHorizontalScrollerWellInRect:(NSRect)rect clipRect:(NSRect)clipRect {
   NSDrawGrayBezel(rect,clipRect);
}

-(NSRect)drawColorWellBorderInRect:(NSRect)rect enabled:(BOOL)enabled bordered:(BOOL)bordered active:(BOOL)active {
   if(bordered){
    if(active)
     NSInterfaceDrawHighlightedButton(rect,rect);
    else
     NSInterfaceDrawButton(rect,rect);
    
    rect=NSInsetRect(rect,6,6);
     
    if(enabled)
     NSDrawGrayBezel(rect,rect);
   }
   else {
    if(enabled){
     NSDrawGrayBezel(rect,rect);
    }
   }
   
   return NSInsetRect(rect,2,2);
}

-(void)drawMenuBranchArrowAtPoint:(NSPoint)point selected:(BOOL)selected {
   NSColor         *color=selected?[NSColor selectedControlTextColor]:[NSColor menuItemTextColor];
   NSInterfacePart *arrow;
         
   arrow=[[[NSInterfacePartAttributedString alloc] initWithCharacter:0x34 fontName:@"Marlett" pointSize:10 color:color] autorelease];

   [arrow drawAtPoint:point];
}

-(void)drawMenuWindowBackgroundInRect:(NSRect)rect {
   NSRect   rects[7];
   NSColor *colors[7];

   rects[0]=rect;
   colors[0]=[NSColor menuBackgroundColor];

   rects[1]=rect;
   rects[1].origin.y=NSMaxY(rect)-1;
   rects[1].size.height=1;
   colors[1]=[NSColor blackColor];

   rects[2]=rect;
   rects[2].origin.x=NSMaxX(rect)-1;
   rects[2].size.width=1;
   colors[2]=[NSColor blackColor];  

   rects[3]=rect;
   rects[3].origin.x+=1;
   rects[3].size.width=1;
   rects[3].origin.y+=1;
   rects[3].size.height-=2;
   colors[3]=[NSColor whiteColor];

   rects[4]=rect;
   rects[4].origin.x+=2;
   rects[4].size.width-=4;
   rects[4].origin.y+=1;
   rects[4].size.height=1;
   colors[4]=[NSColor whiteColor];

   rects[5]=rect;
   rects[5].origin.x+=1;
   rects[5].size.width-=2;
   rects[5].origin.y=NSMaxY(rect)-2;
   rects[5].size.height=1;
   colors[5]=[NSColor darkGrayColor];

   rects[6]=rect;
   rects[6].origin.x=NSMaxX(rect)-2;
   rects[6].size.width=1;
   rects[6].origin.y=1;
   rects[6].size.height-=2;
   colors[6]=[NSColor darkGrayColor];

   NSRectFillListWithColors(rects,colors,7);
}

-(void)drawPopUpButtonWindowBackgroundInRect:(NSRect)rect {
   NSDrawButton(rect,rect);
}

-(void)drawOutlineViewBranchInRect:(NSRect)rect expanded:(BOOL)expanded {
   NSInterfaceDrawOutlineMarker(rect,rect,expanded);
}

-(void)drawOutlineViewGridInRect:(NSRect)rect {
   NSInterfaceDrawOutlineGrid(rect,NSCurrentGraphicsPort());
}

-(NSRect)drawProgressIndicatorBackground:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled {
   if(bezeled){
    NSInterfaceDrawProgressIndicatorBezel(rect,clipRect);
    return NSInsetRect(rect,2,2);
   }
   else {
    [[[_view window] backgroundColor] setFill];
    NSRectFill(rect);
    return rect;
   }
}

-(void)drawProgressIndicatorChunk:(NSRect)rect {
   [[NSColor selectedControlColor] setFill];
   NSRectFill(rect);
}

// rough estimates
#define BLOCK_WIDTH	8.0
#define BLOCK_SPACING	2.0

-(void)drawProgressIndicatorIndeterminate:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled animation:(double)animation {
   if(bezeled)
    rect=[self drawProgressIndicatorBackground:rect clipRect:clipRect bezeled:bezeled];

    NSRect progressRect = rect;
    NSRect blockRect = progressRect;
    int numBlocks;

    numBlocks = (animation * progressRect.size.width)/(BLOCK_WIDTH + BLOCK_SPACING);

    if (numBlocks > 0)
        numBlocks++;

    while (numBlocks-->=0) {
        blockRect.size.width = BLOCK_WIDTH;

        if (NSMaxX(blockRect) > NSMaxX(progressRect))
            blockRect.size.width -= (NSMaxX(blockRect) - NSMaxX(progressRect));

        if (blockRect.size.width > 0) {
            if (numBlocks < 2) {
               [self drawProgressIndicatorChunk:blockRect];
            }
            blockRect.origin.x += BLOCK_WIDTH + BLOCK_SPACING;
        }
    }
}

-(void)drawProgressIndicatorDeterminate:(NSRect)rect clipRect:(NSRect)clipRect bezeled:(BOOL)bezeled value:(double)value {
   if(bezeled)
    rect=[self drawProgressIndicatorBackground:rect clipRect:clipRect bezeled:bezeled];

    NSRect progressRect = rect;
    NSRect blockRect = progressRect;
    int numBlocks;
                
    numBlocks = (value * progressRect.size.width)/(BLOCK_WIDTH + BLOCK_SPACING);
    
    if (numBlocks > 0)
        numBlocks++;

    while (numBlocks-->=0) {
        blockRect.size.width = BLOCK_WIDTH;

        if (NSMaxX(blockRect) > NSMaxX(progressRect))
            blockRect.size.width -= (NSMaxX(blockRect) - NSMaxX(progressRect));

        if (blockRect.size.width > 0) {
            [self drawProgressIndicatorChunk:blockRect];
            blockRect.origin.x += BLOCK_WIDTH + BLOCK_SPACING;
        }
    }
}

-(void)drawScrollerButtonInRect:(NSRect)rect enabled:(BOOL)enabled pressed:(BOOL)pressed vertical:(BOOL)vertical upOrLeft:(BOOL)upOrLeft {
   unichar code=vertical?(upOrLeft?0x74:0x75):(upOrLeft?0x33:0x34);
   Class   class;
   NSInterfacePart *arrow;
   
   if(enabled)
    class=[NSInterfacePartAttributedString class];
   else
    class=[NSInterfacePartDisabledAttributedString class];

   arrow=[[[class alloc] initWithMarlettCharacter:code] autorelease];
   
   if(!NSIsEmptyRect(rect)){
    NSSize arrowSize=[arrow size];

    if(pressed)
     NSInterfaceDrawDepressedScrollerButton(rect,rect);
    else
     NSInterfaceDrawScrollerButton(rect,rect);

    if(rect.size.height>8 && rect.size.width>8){
     NSPoint point=rect.origin;

     point.x+=floor((rect.size.width-arrowSize.width)/2);
     point.y+=floor((rect.size.height-arrowSize.height)/2);
     [arrow drawAtPoint:point];
    }
   }
}

-(void)drawScrollerKnobInRect:(NSRect)rect vertical:(BOOL)vertical highlight:(BOOL)highlight {
   NSDrawButton(rect,rect);
}

-(void)drawScrollerTrackInRect:(NSRect)rect vertical:(BOOL)vertical upOrLeft:(BOOL)upOrLeft {
   [[NSColor colorWithCalibratedWhite:0.9 alpha:1] setFill];
   NSRectFill(rect);
}

-(void)drawScrollerTrackInRect:(NSRect)rect vertical:(BOOL)vertical {
   [self drawScrollerTrackInRect:rect vertical:vertical upOrLeft:NO];
}

-(CGFloat)sliderKnobThickness {
   return 8;
}

-(void)drawSliderKnobInRect:(NSRect)rect vertical:(BOOL)vertical highlighted:(BOOL)highlighted {
   NSDrawButton(rect,rect);

   if(highlighted) {
    [[NSColor whiteColor] setFill];
    NSRectFill(NSInsetRect(rect,1,1));
   }
}

-(void)drawSliderTrackInRect:(NSRect)rect vertical:(BOOL)vertical {
   NSRect groove=rect;

   if(vertical){
    groove.size.width=4;
    groove.origin.x=floor(rect.origin.x+(rect.size.width-4)/2);
   }
   else {
    groove.size.height=4;
    groove.origin.y=floor(rect.origin.y+(rect.size.height-4)/2);
   }

   NSDrawGrayBezel(groove, rect);
}

-(void)drawSliderTickInRect:(NSRect)rect {
   [[NSColor blackColor] setFill];
   NSRectFill(rect);
}

-(void)drawStepperButtonInRect:(NSRect)rect clipRect:(NSRect)clipRect enabled:(BOOL)enabled highlighted:(BOOL)highlighted upNotDown:(BOOL)upNotDown {
   unichar         code=upNotDown?0x74:0x75;
   NSInterfacePart *arrow;
     
   if(enabled)
    arrow=[[[NSInterfacePartAttributedString alloc] initWithMarlettCharacter:code] autorelease];
   else
    arrow=[[[NSInterfacePartDisabledAttributedString alloc] initWithMarlettCharacter:code] autorelease];
      
   if(highlighted)
    NSDrawWhiteBezel(rect,clipRect);
   else
    NSDrawButton(rect,clipRect);
      
   rect.origin.x += rect.size.width/2;
   rect.origin.x -= [arrow size].width/2;
   rect.origin.y += rect.size.height/2;
   rect.origin.y -= [arrow size].height/2;
   [arrow drawAtPoint:rect.origin];
}

-(void)drawTableViewHeaderInRect:(NSRect)rect highlighted:(BOOL)highlighted {
   NSDrawButton(rect, rect);
    
   if(highlighted){
    [[NSColor darkGrayColor] setFill];
    NSRectFill(NSInsetRect(rect,2,2));
   }
}

-(void)drawTableViewCornerInRect:(NSRect)rect {
   NSDrawButton(rect,rect);
}

-(void)drawBoxWithLineInRect:(NSRect)rect {
   [[NSColor blackColor] setStroke];
   NSFrameRect(rect);
}

-(void)drawBoxWithBezelInRect:(NSRect)rect clipRect:(NSRect)clipRect {
   NSDrawGrayBezel(rect,clipRect);
}

-(void)drawBoxWithGrooveInRect:(NSRect)rect clipRect:(NSRect)clipRect {
   NSDrawGroove(rect,clipRect);
}

-(void)drawComboBoxButtonInRect:(NSRect)rect enabled:(BOOL)enabled bordered:(BOOL)bordered pressed:(BOOL)pressed {
   NSImage *image=[NSImage imageNamed:@"NSComboBoxCellDown"];
   NSSize   imageSize=[image size];
   NSRect   imageRect;
   
   if(pressed)
    NSInterfaceDrawDepressedButton(rect,rect);
   else
    NSDrawButton(rect,rect);
    
   imageRect.origin.x=rect.origin.x+(rect.size.width-imageSize.width)/2+(pressed?1:0);
   imageRect.origin.y=rect.origin.y+(rect.size.height-imageSize.height)/2+(pressed?-1:0);
   imageRect.size=imageSize;
   
   [self drawButtonImage:image inRect:imageRect enabled:enabled mixed:NO];
}

-(void)drawTabInRect:(NSRect)rect clipRect:(NSRect)clipRect color:(NSColor *)color selected:(BOOL)selected {
    NSRect originalRect=rect;
    NSRect rects[8];
    NSColor *colors[8];
    int i;

    if(selected){
       rect.origin.x-=2;
       rect.size.width+=3;
    }
    else {
     rect.size.height-=2;
    }

    for(i=0; i<8; i++)
        rects[i]=rect;

    colors[0]=[NSColor controlColor];
    if(selected){
     rects[0].origin.y-=1;
     rects[0].size.height+=1;
    }
    colors[1]=color;
    rects[1]=NSInsetRect(rect,1,1);
    colors[2]=[NSColor whiteColor];
    rects[2].size.width=1;
    rects[2].size.height-=2;
    if(selected){
     rects[2].origin.y-=1;
     rects[2].size.height+=1;
    }
    colors[3]=[NSColor whiteColor];
    rects[3].origin.x+=1;
    rects[3].origin.y+=rect.size.height-2;
    rects[3].size.width=1;
    rects[3].size.height=1;
    colors[4]=[NSColor whiteColor];
    rects[4].origin.x+=2;
    rects[4].origin.y+=rect.size.height-1;
    rects[4].size.width=rect.size.width-4;
    rects[4].size.height=1;
    colors[5]=[NSColor blackColor];
    rects[5].origin.x+=rect.size.width-2;
    rects[5].origin.y+=rect.size.height-2;
    rects[5].size.width=1;
    rects[5].size.height=1;
    colors[6]=[NSColor controlShadowColor];
    rects[6].origin.x+=rect.size.width-2;
    rects[6].size.width=1;
    rects[6].size.height-=2;
    colors[7]=[NSColor blackColor];
    rects[7].origin.x+=rect.size.width-1;
    rects[7].size.width=1;
    rects[7].size.height-=2;
    if(selected){
     rects[7].origin.y-=1;
     rects[7].size.height+=1;
    }

    for(i=0; i<8; i++) {
        [colors[i] setFill];
        NSRectFill(rects[i]);
    }
    
    if(selected){ // cleanup
     NSRect erase=originalRect;
     
     [[NSColor controlColor] setFill];
     erase.size.height=2;
     erase=NSInsetRect(erase,1,0);
     NSRectFill(erase);
    }
}

-(void)drawTabPaneInRect:(NSRect)rect {
   NSDrawButton(rect,rect);
}

-(void)drawTabViewBackgroundInRect:(NSRect)rect {
   // do nothing
}

-(void)drawTextFieldBorderInRect:(NSRect)rect bezeledNotLine:(BOOL)bezeledNotLine {
   if(bezeledNotLine)
    NSDrawWhiteBezel(rect,rect);
   else {
    [[NSColor blackColor] setStroke];
    NSFrameRect(rect);
   }
}

-(void)drawTextViewInsertionPointInRect:(NSRect)rect color:(NSColor *)color {
   [color setFill];
   NSRectFill(rect);
}

@end

@implementation NSView(NSGraphicsStyle)

-(NSGraphicsStyle *)graphicsStyle {
   return [[[NSGraphicsStyle alloc] initWithView:self] autorelease];
}

@end
