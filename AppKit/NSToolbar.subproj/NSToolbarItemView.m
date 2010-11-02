/* Copyright (c) 2009 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSToolbarItemView.h"
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSStringDrawer.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContext.h>

@interface NSToolbarItem(private)
-(void)drawInRect:(NSRect)bounds highlighted:(BOOL)highlighted;
-(NSSize)_labelSize;
@end

@implementation NSToolbarItemView

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _toolbarItem=nil;
   return self;
}

-(void)dealloc {
   _toolbarItem=nil;
   [super dealloc];
}

-(void)setToolbarItem:(NSToolbarItem *)item {
   _toolbarItem=item;
}

-(void)setSubview:(NSView *)view {
   while([[self subviews] count])
    [[[self subviews] lastObject] removeFromSuperview];
   
   if(view!=nil)
    [self addSubview:view];
}

-(void)setFrame:(NSRect)frame {
   [super setFrame:frame];

   NSRect bounds=[self bounds];
   CGFloat labelHeight=[_toolbarItem _labelSize].height;
   NSRect viewRect;
   viewRect.origin.y=bounds.origin.y+labelHeight;
   viewRect.origin.x=bounds.origin.x;
			
   viewRect.size.width = bounds.size.width;
   viewRect.size.height = bounds.size.height - labelHeight;
			
   [[_toolbarItem view] setFrame: viewRect];
}

-(NSView *)view {
   return [[self subviews] lastObject];
}

typedef struct {
 CGFloat _C0[4];
 CGFloat _C1[4];
} gradientColors;

static void evaluate(void *info,const float *in, float *output) {
   float         x=in[0];
   gradientColors *colors=info;
   int           i;
   
    for(i=0;i<4;i++)
     output[i]=colors->_C0[i]+x*(colors->_C1[i]-colors->_C0[i]);
}

-(void)drawRect:(NSRect)rect {
   if([[_toolbarItem itemIdentifier] isEqual:[[_toolbarItem toolbar] selectedItemIdentifier]]){
    CGContextRef  cgContext=[[NSGraphicsContext currentContext] graphicsPort];
    float         domain[2]={0,1};
    float         range[8]={0,1,0,1,0,1,0,1};
    CGFunctionCallbacks callbacks={0,evaluate,NULL};
    gradientColors colors;
    NSColor *startColor=[NSColor blackColor];
    NSColor *endColor=[NSColor lightGrayColor];
    
    colors._C0[0]=0.5;
    colors._C0[1]=0.5;
    colors._C0[2]=0.5;
    colors._C0[3]=0.5;
    colors._C1[0]=0.8;
    colors._C1[1]=0.8;
    colors._C1[2]=0.8;
    colors._C1[3]=0;
    
    CGFunctionRef function=CGFunctionCreate(&colors,1,domain,4,range,&callbacks);
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGShadingRef  shading;
    CGRect bounds=[self bounds];
        
    shading=CGShadingCreateAxial(colorSpace,bounds.origin,CGPointMake(bounds.origin.x,bounds.origin.y+NSHeight(bounds)/2),function,NO,NO);
    CGContextDrawShading(cgContext,shading);
    CGShadingRelease(shading);
    
    CGFunctionRelease(function);
    CGColorSpaceRelease(colorSpace);
   }
   [_toolbarItem drawInRect:[self bounds] highlighted:_isHighlighted];  
}

-(void)mouseDown:(NSEvent *)event {
   BOOL sendAction=NO;

   if(![_toolbarItem isEnabled])
    return;

   do {
    NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];

    _isHighlighted=NSMouseInRect(point,[self bounds],[self isFlipped]);

    [self setNeedsDisplay:YES];
    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask| NSLeftMouseDraggedMask];
   }while([event type]!=NSLeftMouseUp);

   if(_isHighlighted){
    _isHighlighted=NO;
    [NSApp sendAction:[_toolbarItem action] to:[_toolbarItem target] from:_toolbarItem];
    [self setNeedsDisplay:YES];
   }
}

@end

