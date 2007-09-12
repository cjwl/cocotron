/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/KGLayer.h>

@implementation NSCachedImageRep

-initWithSize:(NSSize)size {
   _size=size;
   _layer=[[KGLayer alloc] initWithSize:size];
   return self;
}

-initWithWindow:(NSWindow *)window rect:(NSRect)rect {
   NSUnimplementedMethod();
   return nil;
}

-initWithSize:(NSSize)size depth:(NSWindowDepth)windowDepth separate:(BOOL)separateWindow alpha:(BOOL)hasAlpha {
   NSUnimplementedMethod();
   return nil;
}

-(void)dealloc {
   [_layer release];
   [super dealloc];
}

-(NSWindow *)window {
   NSUnimplementedMethod();
   return nil;
}

-(NSRect)rect {
   NSUnimplementedMethod();
   return NSZeroRect;
}

-(KGContext *)cgContext {
   return [_layer cgContext];
}

-(BOOL)drawAtPoint:(NSPoint)point {
   NSRect rect={point,_size};
   
   CGContextDrawLayerInRect(NSCurrentGraphicsPort(),rect,_layer);
   return YES;
}

@end
