/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSSegmentedControl.h>
#import <AppKit/NSSegmentedCell.h>

@implementation NSSegmentedControl

-(int)segmentCount {
   return [_cell segmentCount];
}

-(int)tagForSegment:(int)segment {
   return [_cell tagForSegment:segment];
}

-(NSImage *)imageForSegment:(int)segment {
   return [_cell imageForSegment:segment];
}

-(BOOL)isEnabledForSegment:(int)segment {
   return [_cell isEnabledForSegment:segment];
}

-(NSString *)labelForSegment:(int)segment {
   return [_cell labelForSegment:segment];
}

-(NSMenu *)menuForSegment:(int)segment {
   return [_cell menuForSegment:segment];
}

-(NSString *)toolTipForSegment:(int)segment {
   return [_cell toolTipForSegment:segment];
}

-(float)widthForSegment:(int)segment {
   return [_cell widthForSegment:segment];
}

-(int)selectedSegment {
   return [_cell selectedSegment];
}

-(BOOL)isSelectedForSegment:(int)segment {
   return [_cell isSelectedForSegment:segment];
}

-(void)setSegmentCount:(int)count {
   return [_cell setSegmentCount:count];
}

-(void)setTag:(int)tag forSegment:(int)segment {
   [_cell setTag:tag forSegment:segment];
}

-(void)setImage:(NSImage *)image forSegment:(int)segment {
   [_cell setImage:image forSegment:segment];
   [self setNeedsDisplay:YES];
}

-(void)setEnabled:(BOOL)enabled forSegment:(int)segment {
   [_cell setEnabled:enabled forSegment:segment];
   [self setNeedsDisplay:YES];
}

-(void)setLabel:(NSString *)label forSegment:(int)segment {
   [_cell setLabel:label forSegment:segment];
   [self setNeedsDisplay:YES];
}

-(void)setMenu:(NSMenu *)menu forSegment:(int)segment {
   [_cell setMenu:menu forSegment:segment];
}

-(void)setToolTip:(NSString *)string forSegment:(int)segment {
   [_cell setToolTip:string forSegment:segment];
}

-(void)setWidth:(float)width forSegment:(int)segment {
   [_cell setWidth:width forSegment:segment];
   [self setNeedsDisplay:YES];
}

-(BOOL)selectSegmentWithTag:(int)tag {
   BOOL result=[_cell selectSegmentWithTag:tag];

   [self setNeedsDisplay:YES];

   return result;
}

-(void)setSelected:(BOOL)flag forSegment:(int)segment {
   [_cell setSelected:flag forSegment:segment];
   [self setNeedsDisplay:YES];
}

-(void)setSelectedSegment:(int)segment {
   [_cell setSelectedSegment:segment];
   [self setNeedsDisplay:YES];
}

@end
