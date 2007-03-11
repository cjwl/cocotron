/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/CGContext.h>

@class NSColor;

@implementation NSGraphicsContext

-initWithWindow:(NSWindow *)window {
   _graphicsPort=CGContextRetain([window graphicsContext]);
   _isDrawingToScreen=YES;
   return self;
}

-initWithWithCachedImageRep:(NSCachedImageRep *)imageRep {
   _graphicsPort=CGContextRetain([imageRep graphicsContext]);
   _isDrawingToScreen=YES;
   return self;
}

-initWithPrintingContext:(KGContext *)context {
   _graphicsPort=CGContextRetain(context);
   _isDrawingToScreen=NO;
   return self;
}

+(NSGraphicsContext *)graphicsContextWithWindow:(NSWindow *)window {
   return [[[self alloc] initWithWindow:window] autorelease];
}

+(NSGraphicsContext *)graphicsContextWithCachedImageRep:(NSCachedImageRep *)imageRep {
   return [[[self alloc] initWithWithCachedImageRep:imageRep] autorelease];
}

+(NSGraphicsContext *)graphicsContextWithPrintingContext:(KGContext *)context {
   return [[[self alloc] initWithPrintingContext:context] autorelease];
}

+(NSMutableArray *)_contextStack {
   NSMutableDictionary *shared=[NSCurrentThread() sharedDictionary];
   NSMutableArray      *stack=[shared objectForKey:@"NSGraphicsContext.stack"];

   if(stack==nil){
    stack=[NSMutableArray array];
    [shared setObject:stack forKey:@"NSGraphicsContext.stack"];
   }

   return stack;
}

static NSGraphicsContext *_currentContext() {
   return NSThreadSharedInstanceDoNotCreate(@"NSGraphicsContext");
}

KGContext *NSCurrentGraphicsPort() {
   return _currentContext()->_graphicsPort;
}

+(NSGraphicsContext *)currentContext {
   NSGraphicsContext   *current=_currentContext();

   if(current==nil)
    [NSException raise:NSInvalidArgumentException format:@"+[%@ %s] is *nil*",self,SELNAME(_cmd)];

   return current;
}


+(void)setCurrentContext:(NSGraphicsContext *)context {
   [NSCurrentThread() setSharedObject:context forClassName:@"NSGraphicsContext"];
}

+(void)saveGraphicsState {
   NSGraphicsContext *current=_currentContext();

   if(current!=nil)
    [[self _contextStack] addObject:current];
}

+(void)restoreGraphicsState {
   NSGraphicsContext *current=[[self _contextStack] lastObject];

   if(current!=nil){
    [self setCurrentContext:current];
    [[self _contextStack] removeLastObject];
   }
}

+(BOOL)currentContextDrawingToScreen {
   return [[NSGraphicsContext currentContext] isDrawingToScreen];
}

-(void)dealloc {
   CGContextRelease(_graphicsPort);
   [super dealloc];
}

-(KGContext *)graphicsPort {
   return _graphicsPort;
}

-(BOOL)isDrawingToScreen {
   return _isDrawingToScreen;
}

-(void)setShouldAntialias:(BOOL)flag {
}

-(void)saveGraphicsState {
   NSInvalidAbstractInvocation();
}

-(void)restoreGraphicsState {
   NSInvalidAbstractInvocation();
}

-(void)flushGraphics {
}

@end


