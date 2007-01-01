/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSCursor.h>
#import <AppKit/NSDisplay.h>
#import <Foundation/NSNull.h>

@implementation NSCursor

-initWithCoder:(NSCoder *)coder {
   [self dealloc];
   return [NSNull null];
}

-initWithIBeam {
   _cursor=[[[NSDisplay currentDisplay] cursorWithName:@"IBeam"] retain];
   return self;
}

-initWithArrow {
   _cursor=[[[NSDisplay currentDisplay] cursorWithName:@"Arrow"] retain];
   return self;
}

-initWithHorizontalResize {
   _cursor=[[[NSDisplay currentDisplay] cursorWithName:@"HorizontalResize"] retain];
   return self;
}

-initWithVerticalResize {
   _cursor=[[[NSDisplay currentDisplay] cursorWithName:@"VerticalResize"] retain];
   return self;
}

+(NSCursor *)arrowCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithArrow];

   return shared;
}

+(NSCursor *)IBeamCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithIBeam];

   return shared;
}

+(NSCursor *)_horizontalResizeCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithHorizontalResize];

   return shared;
}

+(NSCursor *)_verticalResizeCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithVerticalResize];

   return shared;
}

+(void)hide {
   [[NSDisplay currentDisplay] hideCursor];
}

+(void)unhide {
   [[NSDisplay currentDisplay] unhideCursor];
}

+(void)setHiddenUntilMouseMoves:(BOOL)flag {
   if(flag)
    [self hide];
   else
    [self unhide];
}

-(void)set {
   [[NSDisplay currentDisplay] setCursor:_cursor];
}

@end
