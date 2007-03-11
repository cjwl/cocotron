/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/Win32DeviceContextBitmap.h>
#import <AppKit/KGImage_context.h>

@implementation NSCachedImageRep

-initWithSize:(NSSize)size {
   _size=size;
   _renderingContext=[[Win32DeviceContextBitmap alloc] initWithSize:size];
   return self;
}

-(void)dealloc {
   [_renderingContext release];
   [super dealloc];
}

-(KGContext *)graphicsContext {
   return [_renderingContext graphicsContextWithSize:[self size]];
}

-(BOOL)drawAtPoint:(NSPoint)point {
   KGImage *image=[[KGImage_context alloc] initWithRenderingContext:_renderingContext];
   NSRect   rect={point,_size};
   
   CGContextDrawImage(NSCurrentGraphicsPort(),rect,image);
   return YES;
}

@end
