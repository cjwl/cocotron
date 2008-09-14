/* Copyright (c) 2006-2007 Christopher J. W. Lloyd, 2008 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSegmentedCell.h>
#import <Foundation/NSRaise.h>
#import "NSSegmentItem.h"
#import <AppKit/NSButtonCell.h>

@implementation NSSegmentedCell

- (id)initWithCoder:(NSCoder *)decoder {
   _segments=[[decoder decodeObjectForKey:@"NSSegmentImages"] retain];
   
   NSView* view=[decoder decodeObjectForKey:@"NSControlView"];
   if(view) {
      float totalWidth=0;
      int numUndefined=0;
      for(NSSegmentItem *item in _segments)
      {
         float w=[item width];
         totalWidth+=w;
         if(w==0.0)
            numUndefined++;
      }
      float remainingWidth=[view frame].size.width-totalWidth;
      
      for(NSSegmentItem *item in _segments)
      {
         if([item width]==0.0)
            [item setWidth:remainingWidth/(float)numUndefined];
      }
   }
   
   return [super initWithCoder:decoder];
}

-(void)dealloc {
   [_segments release];
   [super dealloc];
}

-(int)segmentCount {
   return [_segments count];
}

-(NSSegmentSwitchTracking)trackingMode {
   return _trackingMode;
}

-(int)tagForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] tag];
}

-(NSImage *)imageForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] image];
}

-(BOOL)isEnabledForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] isEnabled];
}

-(NSString *)labelForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] label];
}

-(NSMenu *)menuForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] menu];
}

-(NSString *)toolTipForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] toolTip];
}

-(float)widthForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] width];
}

-(int)selectedSegment {
   int i,count=[_segments count];
   
   for(i=0;i<count;i++)
    if([[_segments objectAtIndex:i] isSelected])
     return i;
   
   return -1;
}

-(BOOL)isSelectedForSegment:(int)segment {
   return [[_segments objectAtIndex:segment] isSelected];
}

-(void)setSegmentCount:(int)count {
   NSUnimplementedMethod();
}

-(void)setTrackingMode:(NSSegmentSwitchTracking)trackingMode {
   _trackingMode=trackingMode;
}

-(void)setTag:(int)tag forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setTag:tag];
}

-(void)setImage:(NSImage *)image forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setImage:image];
}

-(void)setEnabled:(BOOL)enabled forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setEnabled:enabled];
}

-(void)setLabel:(NSString *)label forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setLabel:label];
}

-(void)setMenu:(NSMenu *)menu forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setMenu:menu];
}

-(void)setToolTip:(NSString *)string forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setToolTip:string];
}

-(void)setWidth:(float)width forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setWidth:width];
}

-(BOOL)selectSegmentWithTag:(int)tag {
   int i,count=[_segments count];
   
   for(i=0;i<count;i++)
    if([[_segments objectAtIndex:i] tag]==tag){
     [self setSelected:YES forSegment:i];
     return YES;
    }
   
   return NO;
}

-(void)setSelected:(BOOL)flag forSegment:(int)segment {
   [[_segments objectAtIndex:segment] setSelected:flag];
}

-(void)setSelectedSegment:(int)segment {
   [[_segments objectAtIndex:segment] setSelected:YES];
}

-(void)makeNextSegmentKey {
   NSUnimplementedMethod();
}
-(void)makePreviousSegmentKey {
   NSUnimplementedMethod();
}

-(void)drawSegment:(int)idx inFrame:(NSRect)frame withView:(NSView *)view {
   NSSegmentItem *segment=[_segments objectAtIndex:idx];
   NSButtonCell *cell=[NSButtonCell new];
   [cell setTitle:[segment label]];
   [cell setHighlighted:[segment isSelected]];
   
   // TODO: implement setLineBreakMode on NSCell
   //[cell setLineBreakMode:NSLineBreakByTruncatingTail];
   
   [cell drawWithFrame:frame inView:view];
   
   [cell release];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

   int i=0, count=[self segmentCount];
   NSRect segmentFrame=cellFrame;
   
   for(i=0; i<count; i++) {
      segmentFrame.size.width=[[_segments objectAtIndex:i] width];
      [self drawSegment:i inFrame:segmentFrame withView:controlView];
      segmentFrame.origin.x+=segmentFrame.size.width;
   }
   
   _lastDrawRect=cellFrame;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
   [self continueTracking:startPoint at:startPoint inView:controlView];
   return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
   NSSegmentItem *selectedSegment=nil;
   NSSegmentItem *newSegment=nil;
   
   NSPoint point=[controlView convertPoint:currentPoint fromView:nil];
   
   int i=0, count=[self segmentCount];
   NSRect segmentFrame=_lastDrawRect;
   
   for(i=0; i<count; i++) {
      NSSegmentItem *item=[_segments objectAtIndex:i];
      
      segmentFrame.size.width=[item width];
      if(NSPointInRect(point, segmentFrame)) {
         newSegment=item;
      }
      if([item isSelected]) {
         selectedSegment=item;
      }
      segmentFrame.origin.x+=segmentFrame.size.width;
   }
   
   if(newSegment && newSegment!=selectedSegment) {
      [selectedSegment setSelected:NO];
      [newSegment setSelected:YES];
      [self drawWithFrame:_lastDrawRect inView:controlView];
   }
   return YES;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
   [self continueTracking:lastPoint at:stopPoint inView:controlView];
}

@end
