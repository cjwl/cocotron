/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
                 2009 Markus Hitter <mah@jump-ing.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSplitView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSCursor.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSRaise.h>

NSString * const NSSplitViewDidResizeSubviewsNotification = @"NSSplitViewDidResizeSubviewsNotification";
NSString * const NSSplitViewWillResizeSubviewsNotification = @"NSSplitViewWillResizeSubviewsNotification";

@implementation NSSplitView

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    
    _isVertical=[keyed decodeBoolForKey:@"NSIsVertical"];
// The divider thickness in the nib may not be the same as ours
    [self resizeSubviewsWithOldSize:[self bounds].size];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   }

   return self;
}

-(id)delegate {
   return _delegate;
}

-(BOOL)isVertical {
   return _isVertical;
}

-(void)_postNoteWillResize {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewWillResizeSubviewsNotification object:self];
}

-(void)_postNoteDidResize {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewDidResizeSubviewsNotification object:self];
}

-(void)setDelegate:(id)delegate {
    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate name:NSSplitViewDidResizeSubviewsNotification object:self];
    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate name:NSSplitViewWillResizeSubviewsNotification object:self];
    
   _delegate=delegate;

   if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
       [[NSNotificationCenter defaultCenter] addObserver:_delegate
                                                selector:@selector(splitViewDidResizeSubviews:)
                                                    name:NSSplitViewDidResizeSubviewsNotification
                                                  object:self];
   if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
       [[NSNotificationCenter defaultCenter] addObserver:_delegate
                                                selector:@selector(splitViewWillResizeSubviews:)
                                                    name:NSSplitViewWillResizeSubviewsNotification
                                                  object:self];
}

-(void)setVertical:(BOOL)flag {
   _isVertical=flag;
   [self adjustSubviews];
}

-(BOOL)isFlipped {
   return YES;
}

-(BOOL)isSubviewCollapsed:(NSView *)subview {
    if (_isVertical) {
        return [subview frame].size.width == 0.0;
    } else {
        return [subview frame].size.height == 0.0;
    }
}

-(void)setDividerStyle:(NSSplitViewDividerStyle)style {
    NSUnimplementedMethod();
}

-(void)adjustSubviews {
   NSRect  frame=[self bounds];
   int     i,count=[_subviews count];

   [self _postNoteWillResize];

   if([self isVertical]){
    float totalWidthBefore=0.;
    float totalWidthAfter=[self bounds].size.height-[self dividerThickness]*(count-1);

    for(i=0;i<count;i++)
     totalWidthBefore+=[[_subviews objectAtIndex:i] frame].size.height;

    for(i=0;i<count;i++){
     frame.size.width=[[_subviews objectAtIndex:i] frame].size.width*(totalWidthAfter/totalWidthBefore);
     [[_subviews objectAtIndex:i] setFrame:frame];
  
     frame.origin.x+=frame.size.width;
     frame.origin.x+=[self dividerThickness];
    }
   }
   else {
    float totalHeightBefore=0.;
    float totalHeightAfter=[self bounds].size.height-[self dividerThickness]*(count-1);

    for(i=0;i<count;i++)
     totalHeightBefore+=[[_subviews objectAtIndex:i] frame].size.height;

    for(i=0;i<count;i++){
     frame.size.height=[[_subviews objectAtIndex:i] frame].size.height*(totalHeightAfter/totalHeightBefore);
     frame.size.height=floor(frame.size.height);

     [[_subviews objectAtIndex:i] setFrame:frame];

     frame.origin.y+=frame.size.height;
     frame.origin.y+=[self dividerThickness];
    }
   }

   [self _postNoteDidResize];
}

-(float)dividerThickness {
   return 5;
}

-(NSImage *)dimpleImage {
   if([self isVertical])
    return [NSImage imageNamed:@"NSSplitViewVDimple"];
   else
    return [NSImage imageNamed:@"NSSplitViewHDimple"];
}

-(void)drawDividerInRect:(NSRect)rect {
   NSImage *image=[self dimpleImage];
   NSPoint  point;

   [[NSColor controlColor] setFill];
   NSRectFill(rect);

   point=rect.origin;

   if([self isVertical]){
    point.x+=floor((rect.size.width-[image size].width)/2);
    point.y+=floor((rect.size.height-[image size].height)/2);
   }
   else {
    point.x+=floor((rect.size.width-[image size].width)/2);
    point.y+=floor((rect.size.height-[image size].height)/2);
   }

   [image compositeToPoint:point operation:NSCompositeSourceOver];
}

-(void)addSubview:(NSView *)view {
   [super addSubview:view];
   [self adjustSubviews];
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize {
   NSSize  size=[self bounds].size;
   NSPoint origin=[self bounds].origin;
   int     i,count=[_subviews count];

   if(size.width<1) size.width=1;
   if(size.height<1) size.height=1;
   if(oldSize.width<1) oldSize.width=1;
   if(oldSize.height<1) oldSize.height=1;

   if([_delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)]) {
       [_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
       return;
   }

   [self _postNoteWillResize];

   for(i=0;i<count;i++){
    NSView *view=[_subviews objectAtIndex:i];
    NSRect  frame=[view frame];

    frame.origin=origin;

    if([self isVertical]){
     frame.size.height=size.height;

     if(i+1==count)
      frame.size.width=floor(size.width-frame.origin.x);
     else
      frame.size.width=floor(size.width*(frame.size.width/oldSize.width));

     origin.x+=frame.size.width;
     origin.x+=[self dividerThickness];
    }
    else {
     frame.size.width=size.width;

     if(i+1==count)
      frame.size.height=floor(size.height-frame.origin.y);
     else
      frame.size.height=floor(size.height*(frame.size.height/oldSize.height));

     origin.y+=frame.size.height;
     origin.y+=[self dividerThickness];
    }

    [view setFrame:frame];
   }

   [self _postNoteDidResize];
}

-(NSRect)dividerRectAtIndex:(unsigned)index {
   NSRect rect=[[_subviews objectAtIndex:index] frame];

   if([self isVertical]){
    rect.origin.x=rect.origin.x+rect.size.width;
    rect.size.width=[self dividerThickness];
   }
   else {
    rect.origin.y=rect.origin.y+rect.size.height;
    rect.size.height=[self dividerThickness];
   }

   return rect;
}

-(void)drawRect:(NSRect)rect {
   int i,count=[_subviews count];

   for(i=0;i<count-1;i++){
    if ([self dividerThickness] > 0)
     [self drawDividerInRect:[self dividerRectAtIndex:i]];
   }
}

-(unsigned)dividerIndexAtPoint:(NSPoint)point {
   int i,count=[[self subviews] count];

   for(i=0;i<count-1;i++){
    NSRect rect=[self dividerRectAtIndex:i];

    if(NSMouseInRect(point,rect,[self isFlipped]))
     return i;
   }

   return NSNotFound;
}

static float constrainTo(float value,float min,float max){
   if(value<min)
    value=min;
   if(value>max)
    value=max;
   return value;
}

-(void)mouseDown:(NSEvent *)event {
   NSPoint  firstPoint=[self convertPoint:[event locationInWindow] fromView:nil];
   unsigned divider=[self dividerIndexAtPoint:firstPoint];
   NSRect   frame0,frame1;
   float    maxSize,minSize;
   NSEventType eventType;
   BOOL delegateWantsTrackConstraining = [_delegate respondsToSelector:@selector(splitView:constrainSplitPosition:ofSubviewAt:)];

   if(divider==NSNotFound)
    return;

   [self _postNoteWillResize];

   frame0=[[[self subviews] objectAtIndex:divider] frame];
   frame1=[[[self subviews] objectAtIndex:divider+1] frame];
   if([self isVertical]){
    minSize=frame0.origin.x;
    maxSize=frame0.size.width+frame1.size.width;
   }
   else {
    minSize=frame0.origin.y;
    maxSize=frame0.size.height+frame1.size.height;
   }

   if([_delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:maxCoordinate:ofSubviewAt:)]) {
       float delegateMin=minSize, delegateMax=maxSize;
       
       [_delegate splitView:self constrainMinCoordinate:&delegateMin maxCoordinate:&delegateMax ofSubviewAt:divider];

       if (delegateMin > minSize)
           minSize = delegateMin;

       if (delegateMax < maxSize)
           maxSize = delegateMax;
   }

   do{
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    NSPoint point;
    float   delta;
    NSRect  resize0=frame0;
    NSRect  resize1=frame1;

    event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|
                          NSLeftMouseDraggedMask];
    eventType=[event type];

    point=[self convertPoint:[event locationInWindow] fromView:nil];
    if([self isVertical]){
     if(delegateWantsTrackConstraining) {
      point.x = [_delegate splitView:self constrainSplitPosition:point.x ofSubviewAt:divider];
     }
     point.x = constrainTo(point.x,minSize,maxSize);
        
     delta=floor(point.x-firstPoint.x);
     resize0.size.width+=delta;

     resize0.size.width=constrainTo(resize0.size.width,minSize,maxSize);

     resize1.size.width-=delta;
     resize1.size.width=constrainTo(resize1.size.width,0,maxSize);
     resize1.origin.x=(frame1.origin.x+frame1.size.width)-resize1.size.width;
    }
    else {
     if(delegateWantsTrackConstraining) {
       point.y = [_delegate splitView:self constrainSplitPosition:point.y ofSubviewAt:divider];
     }
     point.y = constrainTo(point.y,minSize,maxSize);

     delta=floor(point.y-firstPoint.y);

     resize0.size.height+=delta;
   //  resize0.size.height=constrainTo(resize0.size.height,minSize,maxSize);

     resize1.size.height-=delta;
   //  resize1.size.height=constrainTo(resize1.size.height,0,maxSize);
     resize1.origin.y=(frame1.origin.y+frame1.size.height)-resize1.size.height;
    }

    [[[self subviews] objectAtIndex:divider] setFrameOrigin:resize0.origin];
    [[[self subviews] objectAtIndex:divider] setFrameSize:resize0.size];
    [[[self subviews] objectAtIndex:divider+1] setFrameOrigin:resize1.origin];
    [[[self subviews] objectAtIndex:divider+1] setFrameSize:resize1.size];
 
    [self setNeedsDisplay:YES];

    [pool release];
   }while(eventType!=NSLeftMouseUp);

	if ([self dividerThickness] > 0)
		[[self window] invalidateCursorRectsForView:self];

   [self _postNoteDidResize];
}


-(void)resetCursorRects {
	
   if ([self dividerThickness] <= 0)
	   return;

	int       i,count=[_subviews count];
   NSCursor *cursor;

   if([self isVertical])
    cursor=[NSCursor resizeLeftRightCursor];
   else
    cursor=[NSCursor resizeUpDownCursor];

   for(i=0;i<count-1;i++){
    NSRect rect=[self dividerRectAtIndex:i];

// FIX
// The cursor is activated one pixel past NSMaxY(rect) if we don't do
// this, not sure where the problem is. 
    rect.origin.y-=1.;

    [self addCursorRect:rect cursor:cursor];
   }
}

@end

