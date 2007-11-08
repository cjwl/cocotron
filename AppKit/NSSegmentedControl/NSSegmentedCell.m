/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSegmentedCell.h>
#import <Foundation/NSRaise.h>
#import "NSSegment.h"

@implementation NSSegmentedCell

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

-(void)drawSegment:(int)segment inFrame:(NSRect)frame withView:(NSView *)view {
   NSUnimplementedMethod();
}

@end
