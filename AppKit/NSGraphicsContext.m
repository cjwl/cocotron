/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSBitmapImageRep.h>
#import <ApplicationServices/CGContext.h>

@class NSColor;

@implementation NSGraphicsContext

-initWithWindow:(NSWindow *)window {
   _graphicsPort=CGContextRetain([window cgContext]);
   _focusStack=[NSMutableArray new];
   _isDrawingToScreen=YES;
   _isFlipped=NO;
   return self;
}

-initWithGraphicsPort:(KGContext *)context flipped:(BOOL)flipped {
   _graphicsPort=CGContextRetain(context);
   _focusStack=[NSMutableArray new];
   _isDrawingToScreen=NO;
   _isFlipped=flipped;
   return self;
}

static CGColorSpaceRef colorSpaceWithName(NSString *name){
   if([name isEqualToString:NSDeviceRGBColorSpace])
    return CGColorSpaceCreateDeviceRGB();
   if([name isEqualToString:NSCalibratedRGBColorSpace])
    return CGColorSpaceCreateDeviceRGB();

   return NULL;
}

static CGBitmapInfo bitmapInfoForBitmapFormat(NSBitmapFormat bitmapFormat){
   CGBitmapInfo result=kCGBitmapByteOrderDefault;
   
   if(bitmapFormat&NSAlphaFirstBitmapFormat){
    if(bitmapFormat&NSAlphaNonpremultipliedBitmapFormat)
     result|=kCGImageAlphaFirst;
    else
     result|=kCGImageAlphaPremultipliedFirst;
   }
   else {
    if(bitmapFormat&NSAlphaNonpremultipliedBitmapFormat)
     result|=kCGImageAlphaLast;
    else
     result|=kCGImageAlphaPremultipliedLast;
   }
   if(bitmapFormat&NSFloatingPointSamplesBitmapFormat)
    result|=kCGBitmapFloatComponents;
   
   return result;
}

-initWithBitmapImageRep:(NSBitmapImageRep *)imageRep {
   CGColorSpaceRef colorSpace=colorSpaceWithName([imageRep colorSpaceName]);
   
   if(colorSpace==nil){
    [self dealloc];
    return nil;
   }
   
   _graphicsPort=CGBitmapContextCreate([imageRep bitmapData],[imageRep pixelsWide],[imageRep pixelsHigh],[imageRep bitsPerSample],[imageRep bytesPerRow],colorSpace,bitmapInfoForBitmapFormat([imageRep bitmapFormat]));
   CGColorSpaceRelease(colorSpace);
   
   if(_graphicsPort==nil){
    [self dealloc];
    return nil;
   }
   
   _focusStack=[NSMutableArray new];
   _isDrawingToScreen=YES;
   _isFlipped=NO;
   return self;
}

-(void)dealloc {
   if(_graphicsPort!=NULL)
    CGContextRelease(_graphicsPort);
   [_focusStack release];
   [super dealloc];
}

+(NSGraphicsContext *)graphicsContextWithWindow:(NSWindow *)window {
   return [[[self alloc] initWithWindow:window] autorelease];
}

+(NSGraphicsContext *)graphicsContextWithGraphicsPort:(KGContext *)context flipped:(BOOL)flipped {
   return [[[self alloc] initWithGraphicsPort:context flipped:flipped] autorelease];
}

+(NSGraphicsContext *)graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)imageRep {
   return [[[self alloc] initWithBitmapImageRep:imageRep] autorelease];
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

NSMutableArray *NSCurrentFocusStack() {
   return _currentContext()->_focusStack;
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

-(KGContext *)graphicsPort {
   return _graphicsPort;
}

-(NSMutableArray *)focusStack {
   return _focusStack;
}

-(BOOL)isDrawingToScreen {
   return _isDrawingToScreen;
}

-(BOOL)isFlipped {
   NSView *focusView=[_focusStack lastObject];
   
   if(focusView!=nil)
    return [focusView isFlipped];
    
   return _isFlipped;
}

-(void)setShouldAntialias:(BOOL)flag {
   CGContextSetShouldAntialias(_graphicsPort,flag);
}

-(void)setImageInterpolation:(NSImageInterpolation)value {
   CGContextSetInterpolationQuality(_graphicsPort,value);
}

-(void)setColorRenderingIntent:(NSColorRenderingIntent)value {
   CGContextSetRenderingIntent(_graphicsPort,value);
}

-(void)setCompositingOperation:(NSCompositingOperation)value {
   CGBlendMode blendMode[]={
    kCGBlendModeClear,
    kCGBlendModeCopy,
    kCGBlendModeNormal,
    kCGBlendModeSourceIn,
    kCGBlendModeSourceOut,
    kCGBlendModeSourceAtop,
    kCGBlendModeDestinationOver,
    kCGBlendModeDestinationIn,
    kCGBlendModeDestinationOut,
    kCGBlendModeDestinationAtop,
    kCGBlendModeXOR,
    kCGBlendModePlusDarker,
    kCGBlendModeNormal,
    kCGBlendModePlusLighter,
   };
   if(value<NSCompositeClear || value>NSCompositePlusLighter)
    return;
   
   CGContextSetBlendMode(_graphicsPort,blendMode[value]);
}

-(void)saveGraphicsState {
   NSInvalidAbstractInvocation();
}

-(void)restoreGraphicsState {
   NSInvalidAbstractInvocation();
}

-(void)flushGraphics {
   CGContextFlush(_graphicsPort);
}

@end


