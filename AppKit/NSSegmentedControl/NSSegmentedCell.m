/* Copyright (c) 2006-2007 Christopher J. W. Lloyd, 2008 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSegmentedCell.h>
#import <AppKit/NSRaise.h>
#import "NSSegmentItem.h"
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSPopUpWindow.h>

@implementation NSSegmentedCell

// For manually created segment cells
- (id)init {
	if (self = [super init]) {
		_segments = [[NSMutableArray arrayWithCapacity: 5] retain];
		_selectedSegment = NSNotFound; // initially empty
		_trackingMode = NSSegmentSwitchTrackingSelectOne; // default
	}
	return self;
}

// For nib created segment cells
-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];
   
   _segments=[[coder decodeObjectForKey:@"NSSegmentImages"] retain];
   _selectedSegment=[coder decodeIntForKey:@"NSSelectedSegment"];
   _trackingMode=[coder decodeIntForKey:@"NSTrackingMode"];
      
   return self;
      }
   
-(void)dealloc {
   [_segments release];
   [super dealloc];
}

-(NSInteger)segmentCount {
   return [_segments count];
}

-(NSSegmentStyle)segmentStyle {
   return _style;
}

-(NSSegmentSwitchTracking)trackingMode {
   return _trackingMode;
}

-(NSInteger)tagForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] tag];
}

-(NSImage *)imageForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] image];
}

-(BOOL)isEnabledForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] isEnabled];
}

-(NSString *)labelForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] label];
}

-(NSMenu *)menuForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] menu];
}

-(NSString *)toolTipForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] toolTip];
}

-(CGFloat)widthForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] width];
}

-(NSImageScaling)imageScalingForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] imageScaling];
}
   
-(NSInteger)selectedSegment {
   
   if(_selectedSegment==NSNotFound) {
      int i,count=[_segments count];
   
      for(i=0;i<count;i++)
         if([[_segments objectAtIndex:i] isSelected])
            return i;
   }
   
   return _selectedSegment;
}

-(BOOL)isSelectedForSegment:(NSInteger)segment {
   return [[_segments objectAtIndex:segment] isSelected];
}

-(void)setSegmentCount:(NSInteger)count {
	int currentCount = [_segments count];
	if (count == currentCount) return;
	if (count > currentCount) {
		while ([_segments count] < count) {
			NSSegmentItem* item = [[[NSSegmentItem alloc] init] autorelease];
			[_segments addObject: item];
		}
	} else {
		while ([_segments count] > count) {
			[_segments removeLastObject];
		}
	}
}

-(void)setSegmentStyle:(NSSegmentStyle)value {
   _style=value;
}

-(void)setTrackingMode:(NSSegmentSwitchTracking)trackingMode {
   _trackingMode=trackingMode;
}

-(void)setTag:(NSInteger)tag forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setTag:tag];
}

-(void)setImage:(NSImage *)image forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setImage:image];
}

-(void)setEnabled:(BOOL)enabled forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setEnabled:enabled];
}

-(void)setLabel:(NSString *)label forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setLabel:label];
}

-(void)setMenu:(NSMenu *)menu forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setMenu:menu];
}

-(void)setToolTip:(NSString *)string forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setToolTip:string];
}

-(void)setWidth:(CGFloat)width forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setWidth:width];
}

-(void)setImageScaling:(NSImageScaling)value forSegment:(NSInteger)segment {
   [[_segments objectAtIndex:segment] setImageScaling:value];
}

-(BOOL)selectSegmentWithTag:(NSInteger)tag {
   int i,count=[_segments count];   
   for(i=0;i<count;i++)
    if([[_segments objectAtIndex:i] tag]==tag){
       [self setSelectedSegment:i];
     return YES;
    }
   return NO;
}

-(void)setSelected:(BOOL)flag forSegment:(NSInteger)segment {
   [self willChangeValueForKey:@"selectedSegment"];
   _selectedSegment=NSNotFound;  // will be recomputed in -selectedSegment
   [[_segments objectAtIndex:segment] setSelected:flag];
   [self didChangeValueForKey:@"selectedSegment"];
}

-(void)setSelectedSegment:(NSInteger)segment {
   for(NSSegmentItem *item in _segments)
    [item setSelected:NO];

   _selectedSegment=segment;
   [[_segments objectAtIndex:segment] setSelected:YES];
}

-(void)makeNextSegmentKey {
   NSUnimplementedMethod();
}
-(void)makePreviousSegmentKey {
   NSUnimplementedMethod();
}

-(void)drawSegment:(NSInteger)idx inFrame:(NSRect)frame withView:(NSView *)view {
   NSSegmentItem *segment=[_segments objectAtIndex:idx];
   NSButtonCell *cell=[NSButtonCell new];
   NSString *label=[segment label];
   [cell setTitle:label];
   
   [cell setHighlighted:[segment isSelected]];
   [cell setEnabled:[segment isEnabled]];
   
   NSImage *image=[segment image];
   if(image)
   {
      [cell setImage:image];
      if([label length])
      {
         [cell setImagePosition:NSImageLeft];
      }
      else
      {
         // center if no label
         [cell setImagePosition:NSImageOnly];
      }
      // TODO: image scaling is unimplemented for NSButtonCell
      // [cell setImageScaling:[segment imageScaling]];
   }

   // TODO: implement setLineBreakMode on NSCell
   //[cell setLineBreakMode:NSLineBreakByTruncatingTail];
   
   [cell setControlView:view];
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

-(NSInteger)_segmentForPoint:(NSPoint)point {
   int i=0, count=[self segmentCount];
   NSRect segmentFrame=_lastDrawRect;

   for(i=0; i<count; i++) {
      NSSegmentItem *item=[_segments objectAtIndex:i];
      
      segmentFrame.size.width=[item width];
      if(NSPointInRect(point, segmentFrame)) {
         return i;
      }
      segmentFrame.origin.x+=segmentFrame.size.width;
   }
   return NSNotFound;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
   // save the segment clicked on and its state
   _firstTrackingSegmentIndex=[self _segmentForPoint:[controlView convertPoint:startPoint fromView:nil]];
   NSSegmentItem *trackingItem=[_segments objectAtIndex:_firstTrackingSegmentIndex];
   if(![trackingItem isEnabled])
      return YES;

   _firstTrackingSegmentInitialState=[trackingItem isSelected];
   [trackingItem setSelected:!_firstTrackingSegmentInitialState];

   [self continueTracking:startPoint at:startPoint inView:controlView];
   return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
   currentPoint=[controlView convertPoint:currentPoint fromView:nil];
   lastPoint=[controlView convertPoint:lastPoint fromView:nil];
   
   NSSegmentItem *trackingItem=[_segments objectAtIndex:_firstTrackingSegmentIndex];
   if(![trackingItem isEnabled])
      return YES;

   int currentSegmentIdx=[self _segmentForPoint:currentPoint];
   
   // change segments state depending on if inside or outside
   if(currentSegmentIdx==_firstTrackingSegmentIndex)  // we're inside, so switch state relative to initial state
   {
      [trackingItem setSelected:!_firstTrackingSegmentInitialState];
   }
   else  // we're outside, so state is initial state
   {
      [trackingItem setSelected:_firstTrackingSegmentInitialState];
   }
   
   [controlView setNeedsDisplayInRect:_lastDrawRect];

   return YES;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
   [self continueTracking:lastPoint at:stopPoint inView:controlView];
   
   NSSegmentItem *trackingItem=[_segments objectAtIndex:_firstTrackingSegmentIndex];
   if(![trackingItem isEnabled])
      return;
   
   [self willChangeValueForKey:@"selectedSegment"];
   _selectedSegment=NSNotFound;
   // if segment is still switched, it'll be the new "selected segment"
   if([trackingItem isSelected]!=_firstTrackingSegmentInitialState)
   {
      _selectedSegment=_firstTrackingSegmentIndex;
   }

   // adapt other segments to fit tracking model
   switch(_trackingMode)
   {
      case NSSegmentSwitchTrackingMomentary:
      {
         // deactivate all segments
         for(NSSegmentItem *item in _segments)
         {
            [item setSelected:NO];
         }
         break;
      }
      case NSSegmentSwitchTrackingSelectAny:
      {
         // nothing
         break;
      }
      case NSSegmentSwitchTrackingSelectOne:
      {
         if(_selectedSegment!=NSNotFound)
         {
            for(NSSegmentItem *item in _segments)
            {
               [item setSelected:NO];
            }
            // select only the selected item
            [[_segments objectAtIndex:_selectedSegment] setSelected:YES];
         }
         break;
      }
   }
   [self didChangeValueForKey:@"selectedSegment"];
   
}

-(BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
   NSPoint        startPoint=[event locationInWindow];
   NSInteger      segmentUnderMouse=[self _segmentForPoint:[controlView convertPoint:startPoint fromView:nil]];
   
   if(segmentUnderMouse==NSNotFound)
    return YES;
    
   NSSegmentItem *trackingItem=[_segments objectAtIndex:segmentUnderMouse];

   if(![trackingItem isEnabled])
      return YES;

   NSMenu *menu=[trackingItem menu];
   
   if(menu==nil)
    return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:flag];
   
   [self setSelectedSegment:segmentUnderMouse];
   
   [NSMenu popUpContextMenu:menu withEvent:event forView:controlView];
   
   return YES;
}

@end
