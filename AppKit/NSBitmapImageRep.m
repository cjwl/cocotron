/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBitmapImageRep-Private.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSView.h>
#import <AppKit/NSColor.h>

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
   int i,numberOfPlanes=isPlanar?samplesPerPixel:1;
   
   _size=NSMakeSize(width,height);
   _colorSpaceName=[colorSpaceName copy];
   _bitsPerSample=bitsPerSample;
   _pixelsWide=width;
   _pixelsHigh=height;
   _hasAlpha=hasAlpha;

   _samplesPerPixel=samplesPerPixel;
   _isPlanar=isPlanar;
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
     _bitmapPlanes[i]=NSZoneCalloc(NULL,_bytesPerRow*_pixelsHigh,1);
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
   CGImageSourceRef imageSource=CGImageSourceCreateWithData(data,nil);
   CGImageRef       cgImage=CGImageSourceCreateImageAtIndex(imageSource,0,nil);
   
   if(cgImage==nil){
    [self dealloc];
    return nil;
   }
   NSDictionary *properties=CGImageSourceCopyPropertiesAtIndex(imageSource,0,nil);
   NSNumber *xres=[properties objectForKey:kCGImagePropertyDPIWidth];
   NSNumber *yres=[properties objectForKey:kCGImagePropertyDPIHeight];
      
   _size.width=CGImageGetWidth(cgImage);
   _size.height=CGImageGetHeight(cgImage);

   if(xres!=nil && [xres doubleValue]>0)
    _size.width*=72.0/[xres doubleValue];
    
   if(yres!=nil && [yres doubleValue]>0)
    _size.height*=72.0/[yres doubleValue];

   CGColorSpaceRef colorSpace=CGImageGetColorSpace(cgImage);
   
   // FIXME:
   _colorSpaceName=NSDeviceRGBColorSpace;
   _bitsPerSample=CGImageGetBitsPerComponent(cgImage);
   _pixelsWide=CGImageGetWidth(cgImage);
   _pixelsHigh=CGImageGetHeight(cgImage);
   
   switch(CGImageGetAlphaInfo(cgImage)){
    case kCGImageAlphaPremultipliedLast:
    case kCGImageAlphaPremultipliedFirst:
    case kCGImageAlphaLast:
    case kCGImageAlphaFirst:
     _hasAlpha=YES;
     break;
    default:
     _hasAlpha=NO;
     break;
   }
   
   _samplesPerPixel=CGColorSpaceGetNumberOfComponents(colorSpace);
   if(_hasAlpha)
    _samplesPerPixel++;
   _isPlanar=NO;
   _bitmapFormat=0;
   if(CGImageGetBitmapInfo(cgImage)&kCGBitmapFloatComponents)
    _bitmapFormat|=NSFloatingPointSamplesBitmapFormat;
   switch(CGImageGetAlphaInfo(cgImage)){
    case kCGImageAlphaNone:
     break;
    case kCGImageAlphaPremultipliedLast:
     break;
    case kCGImageAlphaPremultipliedFirst:
     _bitmapFormat|=NSAlphaFirstBitmapFormat;
     break;
    case kCGImageAlphaLast:
     _bitmapFormat|=NSAlphaNonpremultipliedBitmapFormat;
     break;
    case kCGImageAlphaFirst:
     _bitmapFormat|=NSAlphaFirstBitmapFormat;
     _bitmapFormat|=NSAlphaNonpremultipliedBitmapFormat;
     break;
    case kCGImageAlphaNoneSkipLast:
    case kCGImageAlphaNoneSkipFirst:
     break;
   }
    _bitmapFormat|=NSFloatingPointSamplesBitmapFormat;
    
   _bitsPerPixel=CGImageGetBitsPerPixel(cgImage);
   _bytesPerRow=CGImageGetBytesPerRow(cgImage);
   _freeWhenDone=YES;
   _bitmapPlanes[0]=NSZoneCalloc(NULL,_bytesPerRow*_pixelsHigh,1);
   
   CGDataProviderRef    provider=CGImageGetDataProvider(cgImage);
// FIXME: inefficient
   NSData              *bitmapData=(NSData *)CGDataProviderCopyData(provider);
   const unsigned char *bytes=[bitmapData bytes];
   int                  i,length=_bytesPerRow*_pixelsHigh;
   
   for(i=0;i<length;i++)
    _bitmapPlanes[0][i]=bytes[i];
   
   [bitmapData release];
   
   [properties release];
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
   int i,numberOfPlanes=_isPlanar?_samplesPerPixel:1;

   for(i=0;i<numberOfPlanes;i++)
    planes[i]=_bitmapPlanes[i];
    
   for(;i<5;i++)
    planes[i]=NULL;
}

-(void)getPixel:(unsigned int[])pixel atX:(int)x y:(int)y {
   NSUnimplementedMethod();
}

-(void)setPixel:(unsigned int[])pixel atX:(int)x y:(int)y {
   NSAssert(x>=0 && x<[self pixelsWide],@"x out of bounds");
   NSAssert(y>=0 && y<[self pixelsHigh],@"y out of bounds");

   
   if(_isPlanar)
    NSUnimplementedMethod();
   else {
    if(_bitsPerPixel/_samplesPerPixel!=8)
     NSUnimplementedMethod();

    unsigned char *bits=_bitmapPlanes[0]+_bytesPerRow*y+(x*_bitsPerPixel)/8;
    
    int i;
   
    for(i=0;i<_samplesPerPixel;i++){
     bits[i]=pixel[i];
    }

   }
}

-(NSColor *)colorAtX:(int)x y:(int)y {   
   NSUnimplementedMethod();
   return nil;
}

-(void)setColor:(NSColor *)color atX:(int)x y:(int)y {
   color=[color colorUsingColorSpaceName:[self colorSpaceName]];

   NSInteger i,numberOfComponents=[color numberOfComponents];
   CGFloat   components[numberOfComponents];
   unsigned  pixels[numberOfComponents];

   [color getComponents:components];
   
   if(!_hasAlpha)
    numberOfComponents--;
   else {
    if(!(_bitmapFormat&NSAlphaNonpremultipliedBitmapFormat)){ // premultiplied
     CGFloat alpha=components[numberOfComponents-1];
     
     for(i=0;i<numberOfComponents-1;i++)
      components[i]*=alpha;
    }
    
    if(_bitmapFormat&NSAlphaFirstBitmapFormat){
     CGFloat alpha=components[numberOfComponents-1];
     
     for(i=numberOfComponents;--i>=1;)
      components[i]=components[i-1];
      
     components[0]=alpha;
    }
   }

   if(_bitmapFormat&NSFloatingPointSamplesBitmapFormat){
    for(i=0;i<numberOfComponents;i++)
     ((float *)pixels)[i]=MAX(0.0f,MIN(1.0f,components[i])); // clamp just in case
   }
   else {
    int maxValue=(1<<[self bitsPerSample])-1;
    
    for(i=0;i<numberOfComponents;i++){
     pixels[i]=MAX(0,MIN(maxValue,(int)(components[i]*maxValue))); // clamp just in case
    }
   }
   
   [self setPixel:pixels atX:x y:y];
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

-(CGImageRef)createCGImage {
   if(_isPlanar)
    NSUnimplementedMethod();
    
  CGDataProviderRef provider=CGDataProviderCreateWithData(NULL,_bitmapPlanes[0],_bytesPerRow*_pixelsHigh,NULL);
  
  CGImageRef image=CGImageCreate(_pixelsWide,_pixelsHigh,_bitsPerPixel/_samplesPerPixel,_bitsPerPixel,_bytesPerRow,[self CGColorSpace],
     [self CGBitmapInfo],provider,NULL,NO,kCGRenderingIntentDefault);
     
  return image;
}

-(CGImageRef)CGImage {
   if(_image!=NULL)
    return _image;
    
   return [[self createCGImage] autorelease];
}

-(BOOL)draw {
   CGContextRef context=NSCurrentGraphicsPort();
   NSSize size=[self size];
   CGImageRef image=[_image retain];
   
   if(image==nil)
    image=[self createCGImage];

   CGContextDrawImage(context,NSMakeRect(0,0,size.width,size.height),image);
   
   CGImageRelease(image);
   
   return YES;
}

-(CGColorSpaceRef)CGColorSpace {
   if([_colorSpaceName isEqualToString:NSDeviceRGBColorSpace])
    return CGColorSpaceCreateDeviceRGB();
   if([_colorSpaceName isEqualToString:NSCalibratedRGBColorSpace])
    return CGColorSpaceCreateDeviceRGB();

   return NULL;
}

-(CGBitmapInfo)CGBitmapInfo {
   CGBitmapInfo result=kCGBitmapByteOrderDefault;
   
   if(![self hasAlpha])
    result|=kCGImageAlphaNone;
   else {
    if(_bitmapFormat&NSAlphaFirstBitmapFormat){
     if(_bitmapFormat&NSAlphaNonpremultipliedBitmapFormat)
      result|=kCGImageAlphaFirst;
     else
      result|=kCGImageAlphaPremultipliedFirst;
    }
    else {
     if(_bitmapFormat&NSAlphaNonpremultipliedBitmapFormat)
      result|=kCGImageAlphaLast;
     else
      result|=kCGImageAlphaPremultipliedLast;
    }
   }
   if(_bitmapFormat&NSFloatingPointSamplesBitmapFormat)
    result|=kCGBitmapFloatComponents;
   
   return result;
}

@end
