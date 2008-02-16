/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSView.h>
#import <AppKit/CoreGraphics.h>
#import <AppKit/KGImageSource.h>
#import <AppKit/KGImage.h>

@implementation NSBitmapImageRep

+(NSArray *)imageUnfilteredFileTypes {
   return [NSArray arrayWithObjects:@"tiff",@"tif",@"png",@"jpg",@"bmp",nil];
}

+(NSArray *)imageRepsWithContentsOfFile:(NSString *)path {
   NSMutableArray *result=[NSMutableArray array];
   
   [result addObject:[[[NSBitmapImageRep alloc] initWithContentsOfFile:path] autorelease]];
   
   return result;
}

+(void)getTIFFCompressionTypes:(const NSTIFFCompression **)types count:(int *)count {
   NSUnimplementedMethod();
}

+(NSString *)localizedNameForTIFFCompressionType:(NSTIFFCompression)type {
   NSUnimplementedMethod();
   return nil;
}

+(NSData *)TIFFRepresentationOfImageRepsInArray:(NSArray *)array {
   NSUnimplementedMethod();
   return nil;
}

+(NSData *)TIFFRepresentationOfImageRepsInArray:(NSArray *)array usingCompression:(NSTIFFCompression)compression factor:(float)factor {
   NSUnimplementedMethod();
   return nil;
}

+(NSData *)representationOfImageRepsInArray:(NSArray *)array usingType:(NSBitmapImageFileType)type properties:(NSDictionary *)properties {
   NSUnimplementedMethod();
   return nil;
}

+imageRepWithData:(NSData *)data {
   return [[[self alloc] initWithData:data] autorelease];
}

-initWithBitmapDataPlanes:(unsigned char **)planes pixelsWide:(int)width pixelsHigh:(int)height bitsPerSample:(int)bitsPerSample samplesPerPixel:(int)samplesPerPixel hasAlpha:(BOOL)hasAlpha isPlanar:(BOOL)isPlanar colorSpaceName:(NSString *)colorSpaceName bitmapFormat:(NSBitmapFormat)bitmapFormat bytesPerRow:(int)bytesPerRow bitsPerPixel:(int)bitsPerPixel {
   int i,numberOfPlanes=isPlanar?1:samplesPerPixel;
   
   _pixelsWide=width;
   _pixelsHigh=height;
   _bitsPerSample=bitsPerSample;
   _samplesPerPixel=samplesPerPixel;
   _hasAlpha=hasAlpha;
   _isPlanar=isPlanar;
   _colorSpaceName=[colorSpaceName copy];
   _bitmapFormat=bitmapFormat;
   
   if(bitsPerPixel!=0)
    _bitsPerPixel=bitsPerPixel;
   else
    _bitsPerPixel=_bitsPerSample*_samplesPerPixel;

   if(bytesPerRow!=0)
    _bytesPerRow=bytesPerRow;
   else
    _bytesPerRow=(_bitsPerPixel*_pixelsWide+7)/8;

   _freeWhenDone=NO;
   if(planes==NULL)
    _freeWhenDone=YES;
   else {
    int i;
    
    for(i=0;i<numberOfPlanes;i++)
     if(planes[i]!=NULL)
      break;
      
    if(i==numberOfPlanes)
     _freeWhenDone=YES;
   }
   
   _bitmapPlanes=NSZoneCalloc(NULL,numberOfPlanes,sizeof(unsigned char *));
   for(i=0;i<numberOfPlanes;i++){
    if(!_freeWhenDone)
     _bitmapPlanes[i]=planes[i];
    else
     _bitmapPlanes[i]=NSZoneCalloc(NULL,_bytesPerRow,1);
   }

   return self;
}

-initWithBitmapDataPlanes:(unsigned char **)planes pixelsWide:(int)width pixelsHigh:(int)height bitsPerSample:(int)bitsPerSample samplesPerPixel:(int)samplesPerPixel hasAlpha:(BOOL)hasAlpha isPlanar:(BOOL)isPlanar colorSpaceName:(NSString *)colorSpaceName bytesPerRow:(int)bytesPerRow bitsPerPixel:(int)bitsPerPixel {
   return [self initWithBitmapDataPlanes:planes pixelsWide:width pixelsHigh:height bitsPerSample:bitsPerSample samplesPerPixel:samplesPerPixel hasAlpha:hasAlpha isPlanar:isPlanar colorSpaceName:colorSpaceName bitmapFormat:0 bytesPerRow:bytesPerRow bitsPerPixel:bitsPerPixel];
}

-initForIncrementalLoad {
   NSUnimplementedMethod();
   return nil;
}

-initWithFocusedViewRect:(NSRect)rect {
   return [self initWithData:CGContextCaptureBitmap(NSCurrentGraphicsPort(), rect)];
}

-initWithData:(NSData *)data {
   KGImageSource *imageSource=[KGImageSource newImageSourceWithData:data options:nil];
   
   _image=[imageSource imageAtIndex:0 options:nil];
   _size.width=CGImageGetWidth(_image);
   _size.height=CGImageGetHeight(_image);
   
   [imageSource release];
   return self;
}

-initWithContentsOfFile:(NSString *)path {
   NSData *data=[NSData dataWithContentsOfFile:path];
   
   if(data==nil){
    [self dealloc];
    return nil;
   }
   
   return [self initWithData:data];
}

-(void)dealloc {
   [_image release];
   [super dealloc];
}


-(int)incrementalLoadFromData:(NSData *)data complete:(BOOL)complete {
   NSUnimplementedMethod();
   return 0;
}


-(int)bitsPerPixel {
   return _bitsPerPixel;
}

-(int)samplesPerPixel {
   return _samplesPerPixel;
}

-(int)bytesPerRow {
   return _bytesPerRow;
}

-(BOOL)isPlanar {
   return _isPlanar;
}

-(int)numberOfPlanes {
   return _numberOfPlanes;
}

-(int)bytesPerPlane {
   return _bytesPerPlane;
}

-(NSBitmapFormat)bitmapFormat {
   return _bitmapFormat;
}

-(unsigned char *)bitmapData {
   return _bitmapPlanes[0];
}

-(void)getBitmapDataPlanes:(unsigned char **)planes {
   int i,numberOfPlanes=_isPlanar?1:_samplesPerPixel;

   for(i=0;i<numberOfPlanes;i++)
    planes[i]=_bitmapPlanes[i];
    
   for(;i<5;i++)
    planes[i]=NULL;
}

-(void)getPixel:(unsigned int[])pixel atX:(int)x y:(int)y {
   NSUnimplementedMethod();
}

-(void)setPixel:(unsigned int[])pixel atX:(int)x y:(int)y {
   NSUnimplementedMethod();
}

-(NSColor *)colorAtX:(int)x y:(int)y {   
   NSUnimplementedMethod();
   return nil;
}

-(void)setColor:(NSColor *)color atX:(int)x y:(int)y {
   NSUnimplementedMethod();
}

-valueForProperty:(NSString *)property {
   return [_properties objectForKey:property];
}

-(void)setProperty:(NSString *)property withValue:value {
   [_properties setObject:value forKey:property];
}

-(void)colorizeByMappingGray:(float)gray toColor:(NSColor *)color blackMapping:(NSColor *)blackMapping whiteMapping:(NSColor *)whiteMapping {
   NSUnimplementedMethod();
}

-(void)getCompression:(NSTIFFCompression *)compression factor:(float *)factor {
   NSUnimplementedMethod();
}

-(void)setCompression:(NSTIFFCompression)compression factor:(float)factor {
   NSUnimplementedMethod();
}

-(BOOL)canBeCompressedUsing:(NSTIFFCompression)compression {
   NSUnimplementedMethod();
   return NO;
}

-(NSData *)representationUsingType:(NSBitmapImageFileType)type properties:(NSDictionary *)properties {
   NSUnimplementedMethod();
   return nil;
}

-(NSData *)TIFFRepresentation {
   NSUnimplementedMethod();
   return nil;
}

-(NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)compression factor:(float)factor {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)draw {
   CGContextRef context=NSCurrentGraphicsPort();
   NSSize size=[self size];
   
   CGContextDrawImage(context,NSMakeRect(0,0,size.width,size.height),_image);
   return YES;
}

@end
