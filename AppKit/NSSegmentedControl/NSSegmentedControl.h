/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSControl.h>

@interface NSSegmentedControl : NSControl

-(int)segmentCount;

-(int)tagForSegment:(int)segment;
-(NSImage *)imageForSegment:(int)segment;
-(BOOL)isEnabledForSegment:(int)segment;
-(NSString *)labelForSegment:(int)segment;
-(NSMenu *)menuForSegment:(int)segment;
-(NSString *)toolTipForSegment:(int)segment;
-(float)widthForSegment:(int)segment;

-(int)selectedSegment;
-(BOOL)isSelectedForSegment:(int)segment;

-(void)setSegmentCount:(int)count;

-(void)setTag:(int)tag forSegment:(int)segment;
-(void)setImage:(NSImage *)image forSegment:(int)segment;
-(void)setEnabled:(BOOL)enabled forSegment:(int)segment;
-(void)setLabel:(NSString *)label forSegment:(int)segment;
-(void)setMenu:(NSMenu *)menu forSegment:(int)segment;
-(void)setToolTip:(NSString *)string forSegment:(int)segment;
-(void)setWidth:(float)width forSegment:(int)segment;

-(BOOL)selectSegmentWithTag:(int)tag;
-(void)setSelected:(BOOL)flag forSegment:(int)segment;
-(void)setSelectedSegment:(int)segment;

@end
