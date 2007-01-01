/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSForm.h>
#import <AppKit/NSFormCell.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSStringDrawing.h>

@implementation NSForm

-(void)resizeWithOldSuperviewSize:(NSSize)oldSize {
   [super resizeWithOldSuperviewSize:oldSize];

   _cellSize.width=[self bounds].size.width;
}

-(void)calcSize {
   NSArray *cells=[self cells];
   int      i,count=[cells count];
   float    maxTitleWidth=0;

   for(i=0;i<count;i++){
    NSFormCell         *cell=[cells objectAtIndex:i];
    NSAttributedString *title=[cell attributedTitle];
    float               width=[title size].width;

    if(width>maxTitleWidth)
     maxTitleWidth=width;
   }

   maxTitleWidth=ceil(maxTitleWidth);
   maxTitleWidth+=1;

   for(i=0;i<count;i++){
    NSFormCell *cell=[cells objectAtIndex:i];
    [cell setTitleWidth:maxTitleWidth];
   }
}

@end
