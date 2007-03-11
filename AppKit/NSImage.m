/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSImage.h>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSImage

+(NSArray *)imageUnfilteredFileTypes {
   return [NSImageRep imageUnfilteredFileTypes];
}

+(NSArray *)checkBundles {
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
    NSArray *bundles=[self checkBundles];
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

-initWithSize:(NSSize)size {
   _name=nil;
   _size=size;
   _representations=[NSMutableArray new];
   return self;
}

-(void)dealloc {
   [_name release];
   [_representations release];
   [super dealloc];
}

-(NSSize)size {
   return _size;
}

-(NSArray *)representations {
   return _representations;
}

-(BOOL)isCachedSeparately {
   NSUnimplementedMethod();
   return NO;
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

-(void)addRepresentation:(NSImageRep *)imageRep {
   [_representations addObject:imageRep];
}

-(void)setScalesWhenResized:(BOOL)flag {
   NSUnimplementedMethod();
}

-(void)setCachedSeparately:(BOOL)flag {
   //NSUnimplementedMethod();
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
    cached=[[[NSCachedImageRep alloc] initWithSize:_size] autorelease];
    [self addRepresentation:cached];
   }

   context=[NSGraphicsContext graphicsContextWithCachedImageRep:cached];

   [NSGraphicsContext saveGraphicsState];
   [NSGraphicsContext setCurrentContext:context];

   graphicsPort=NSCurrentGraphicsPort();
   CGContextSaveGState(graphicsPort);
   CGContextClipToRect(graphicsPort,NSMakeRect(0,0,[cached size].width,[cached size].height));
}

-(void)unlockFocus {
   KGContext *graphicsPort=NSCurrentGraphicsPort();

   CGContextRestoreGState(graphicsPort);

   [NSGraphicsContext restoreGraphicsState];
}

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation {
   [self compositeToPoint:point operation:operation fraction:1.0];
}

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation fraction:(float)fraction {
   NSImageRep *rep=[_representations lastObject];

   if([rep isKindOfClass:[NSBitmapImageRep class]])
    [(NSBitmapImageRep *)rep compositeToPoint:point operation:operation fraction:fraction];
   else
    [rep drawAtPoint:point];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] name: %@ size: { %f, %f } representations: %@>", [self class], self, _name, _size.width, _size.height, _representations];
}

@end

@implementation NSBundle(NSImage)

-(NSString *)pathForImageResource:(NSString *)name {
   NSArray *types=[NSImage imageUnfilteredFileTypes];
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

