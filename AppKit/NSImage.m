/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSImage.h>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSImage

+(NSArray *)imageFileTypes {
   return [self imageUnfilteredFileTypes];
}

+(NSArray *)imageUnfilteredFileTypes {
   NSMutableArray *result=[NSMutableArray array];
   NSArray        *allClasses=[NSImageRep registeredImageRepClasses];
   int             i,count=[allClasses count];
   
   for(i=0;i<count;i++)
    [result addObjectsFromArray:[[allClasses objectAtIndex:i] imageUnfilteredFileTypes]];

   return result;
}

+(NSArray *)imagePasteboardTypes {
   return [self imageUnfilteredPasteboardTypes];
}

+(NSArray *)imageUnfilteredPasteboardTypes{
   NSMutableArray *result=[NSMutableArray array];
   NSArray        *allClasses=[NSImageRep registeredImageRepClasses];
   int             i,count=[allClasses count];
   
   for(i=0;i<count;i++)
    [result addObjectsFromArray:[[allClasses objectAtIndex:i] imageUnfilteredPasteboardTypes]];

   return result;
}

+(BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
   NSString *available=[pasteboard availableTypeFromArray:[self imageUnfilteredPasteboardTypes]];
   
   return (available!=nil)?YES:NO;
}

+(NSArray *)_checkBundles {
   return [NSArray arrayWithObjects:
    [NSBundle bundleForClass:self],
    [NSBundle mainBundle],
    nil];
}

+(NSMutableDictionary *)allImages {
   NSMutableDictionary *result=[[[NSThread currentThread] threadDictionary] objectForKey:@"__allImages"];

   if(result==nil){
    result=[NSMutableDictionary dictionary];
    [[[NSThread currentThread] threadDictionary] setObject:result forKey:@"__allImages"];
   }

   return result;
}

+imageNamed:(NSString *)name {
   NSImage *image=[[self allImages] objectForKey:name];

   if(image==nil){
    NSArray *bundles=[self _checkBundles];
    int      i,count=[bundles count];

    for(i=0;i<count;i++){
     NSBundle *bundle=[bundles objectAtIndex:i];
     NSString *path=[bundle pathForImageResource:name];

     if(path!=nil){
      image=[[[NSImage alloc] initWithContentsOfFile:path] autorelease];
      [image setName:name];
     }
    }
   }

   return image;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    unsigned              length;
    const unsigned char  *tiff=[keyed decodeBytesForKey:@"NSTIFFRepresentation" returnedLength:&length];
    NSBitmapImageRep     *rep;
    
    if(tiff==NULL){
     [self dealloc];
     return nil;
    }
   
    rep=[NSBitmapImageRep imageRepWithData:[NSData dataWithBytes:tiff length:length]];
    if(rep==nil){
     [self dealloc];
     return nil;
    }
    
    _name=nil;
    _size=[rep size];
    _representations=[NSMutableArray new];

    [_representations addObject:rep];
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }
   return nil;
}

-initWithSize:(NSSize)size {
   _name=nil;
   _size=size;
   _representations=[NSMutableArray new];
   return self;
}

-initWithData:(NSData *)data {
   NSUnimplementedMethod();
   return nil;
}

-initWithContentsOfFile:(NSString *)path {
   NSArray *reps=[NSImageRep imageRepsWithContentsOfFile:path];

   if([reps count]==0){
    [self dealloc];
    return nil;
   }

   _name=nil;
   _size=[[reps lastObject] size];
   _representations=[NSMutableArray new];

   [_representations addObjectsFromArray:reps];

   return self;
}

-initWithContentsOfURL:(NSURL *)url {
   NSUnimplementedMethod();
   return 0;
}

-initWithPasteboard:(NSPasteboard *)pasteboard {
   NSUnimplementedMethod();
   return 0;
}

-initByReferencingFile:(NSString *)path {
   NSUnimplementedMethod();
   return nil;
}

-initByReferencingURL:(NSURL *)url {
   NSUnimplementedMethod();
   return 0;
}

-(void)dealloc {
   [_name release];
   [_representations release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(NSString *)name {
   return _name;
}

-(NSSize)size {
   return _size;
}

-(NSColor *)backgroundColor {
   return _backgroundColor;
}

-(BOOL)isFlipped {
   return _isFlipped;
}

-(BOOL)scalesWhenResized {
   return _scalesWhenResized;
}

-(BOOL)matchesOnMultipleResolution {
   return _matchesOnMultipleResolution;
}

-(BOOL)usesEPSOnResolutionMismatch {
   return _usesEPSOnResolutionMismatch;
}

-(BOOL)prefersColorMatch {
   return _prefersColorMatch;
}

-(NSImageCacheMode)cacheMode {
   return _cacheMode;
}

-(BOOL)isCachedSeparately {
   return _isCachedSeparately;
}

-(BOOL)cacheDepthMatchesImageDepth {
   return _cacheDepthMatchesImageDepth;
}

-(BOOL)isDataRetained {
   return _isDataRetained;
}

-delegate {
   return _delegate;
}

-(BOOL)setName:(NSString *)name {
   if(_name!=nil && [[NSImage allImages] objectForKey:_name]==self)
    [[NSImage allImages] removeObjectForKey:_name];

   name=[name copy];
   [_name release];
   _name=name;

   if([[NSImage allImages] objectForKey:_name]!=nil)
    return NO;

   [[NSImage allImages] setObject:self forKey:_name];
   return YES;
}

-(void)setSize:(NSSize)size {
   _size=size;
   [self recache];
}

-(void)setBackgroundColor:(NSColor *)value {
   value=[value copy];
   [_backgroundColor release];
   _backgroundColor=value;
}

-(void)setFlipped:(BOOL)value {
   _isFlipped=value;
}

-(void)setScalesWhenResized:(BOOL)value {
   _scalesWhenResized=value;
}

-(void)setMatchesOnMultipleResolution:(BOOL)value {
   _matchesOnMultipleResolution=value;
}

-(void)setUsesEPSOnResolutionMismatch:(BOOL)value {
   _usesEPSOnResolutionMismatch=value;
}

-(void)setPrefersColorMatch:(BOOL)value {
   _prefersColorMatch=value;
}

-(void)setCacheMode:(NSImageCacheMode)value {
   _cacheMode=value;
}

-(void)setCachedSeparately:(BOOL)value {
   _isCachedSeparately=value;
}

-(void)setCacheDepthMatchesImageDepth:(BOOL)value {
   _cacheDepthMatchesImageDepth=value;
}

-(void)setDataRetained:(BOOL)value {
   _isDataRetained=value;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(BOOL)isValid {
   NSUnimplementedMethod();
   return 0;
}

-(NSArray *)representations {
   return _representations;
}

-(void)addRepresentation:(NSImageRep *)representation {
   [_representations addObject:representation];
}

-(void)addRepresentations:(NSArray *)array {
   int i,count=[array count];
   
   for(i=0;i<count;i++)
    [self addRepresentation:[array objectAtIndex:i]];
}

-(void)removeRepresentation:(NSImageRep *)representation {
   [_representations removeObjectIdenticalTo:representation];
}

-(NSImageRep *)bestRepresentationForDevice:(NSDictionary *)device {
   NSUnimplementedMethod();
   return 0;
}

-(void)recache {
   NSUnimplementedMethod();
}

-(void)cancelIncrementalLoad {
   NSUnimplementedMethod();
}

-(NSData *)TIFFRepresentation {
   NSUnimplementedMethod();
   return nil;
}

-(NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)compression factor:(float)factor {
   NSUnimplementedMethod();
   return nil;
}

-(NSCachedImageRep *)_cachedImageRep {
   int i,count=[_representations count];

   for(i=0;i<count;i++){
    NSCachedImageRep *check=[_representations objectAtIndex:i];

    if([check isKindOfClass:[NSCachedImageRep class]])
     return check;
   }
   return nil;
}

-(void)lockFocus {
   NSCachedImageRep  *cached=[self _cachedImageRep];
   NSGraphicsContext *context;
   KGContext         *graphicsPort;

   if(cached==nil){
    cached=[[[NSCachedImageRep alloc] initWithSize:_size depth:0 separate:YES alpha:YES] autorelease];
    [self addRepresentation:cached];
   }

   context=[NSGraphicsContext graphicsContextWithWindow:[cached window]];

   [NSGraphicsContext saveGraphicsState];
   [NSGraphicsContext setCurrentContext:context];

   graphicsPort=NSCurrentGraphicsPort();
   CGContextSaveGState(graphicsPort);
   CGContextClipToRect(graphicsPort,NSMakeRect(0,0,[cached size].width,[cached size].height));
}

-(void)lockFocusOnRepresentation:(NSImageRep *)representation {
   NSUnimplementedMethod();
}

-(void)unlockFocus {
   KGContext *graphicsPort=NSCurrentGraphicsPort();

   CGContextRestoreGState(graphicsPort);

   [NSGraphicsContext restoreGraphicsState];
}

-(BOOL)drawRepresentation:(NSImageRep *)representation inRect:(NSRect)rect {
   [[self backgroundColor] set];
   NSRectFill(rect);
   
   return [representation drawInRect:rect];
}

-(void)compositeToPoint:(NSPoint)point fromRect:(NSRect)rect operation:(NSCompositingOperation)operation {
   [self compositeToPoint:point fromRect:rect operation:operation fraction:1.0];
}

-(void)compositeToPoint:(NSPoint)point fromRect:(NSRect)rect operation:(NSCompositingOperation)operation fraction:(float)fraction {
   CGContextRef context=NSCurrentGraphicsPort();
   
   CGContextSaveGState(context);
   CGContextSetAlpha(context,fraction);
   [[_representations lastObject] drawAtPoint:point];
   CGContextRestoreGState(context);
}

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation {
   [self compositeToPoint:point operation:operation fraction:1.0];
}

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation fraction:(float)fraction {
   NSSize size=[self size];
   
   [self compositeToPoint:point fromRect:NSMakeRect(0,0,size.width,size.height) operation:operation fraction:1.0];
}

-(void)dissolveToPoint:(NSPoint)point fraction:(float)fraction {
   NSUnimplementedMethod();
}

-(void)dissolveToPoint:(NSPoint)point fromRect:(NSRect)rect fraction:(float)fraction {
   NSUnimplementedMethod();
}

-(void)drawAtPoint:(NSPoint)point fromRect:(NSRect)source operation:(NSCompositingOperation)operation fraction:(float)fraction {
   NSUnimplementedMethod();
}

-(void)drawInRect:(NSRect)rect fromRect:(NSRect)source operation:(NSCompositingOperation)operation fraction:(float)fraction {
	CGContextRef context=NSCurrentGraphicsPort();
	
	CGContextSaveGState(context);
	CGContextSetAlpha(context,fraction);
	// TODO: source rect, operation unimplemented
	[[_representations lastObject] drawInRect:rect];
	CGContextRestoreGState(context);
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] name: %@ size: { %f, %f } representations: %@>", [self class], self, _name, _size.width, _size.height, _representations];
}

@end

@implementation NSBundle(NSImage)

-(NSString *)pathForImageResource:(NSString *)name {
   NSArray *types=[NSImage imageFileTypes];
   int      i,count=[types count];

   for(i=0;i<count;i++){
    NSString *type=[types objectAtIndex:i];
    NSString *path=[self pathForResource:name ofType:type];

    if(path!=nil)
     return path;
   }

   return nil;
}

@end

