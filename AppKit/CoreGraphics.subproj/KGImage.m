/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 * Copyright (c) 2007-2008 Christopher J. W. Lloyd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and /or associated documentation files
 * (the "Materials "), to deal in the Materials without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Materials,
 * and to permit persons to whom the Materials are furnished to do so,
 * subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Materials. 
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE MATERIALS OR
 * THE USE OR OTHER DEALINGS IN THE MATERIALS.
 *
 *-------------------------------------------------------------------*/

#import "KGImage.h"
#import "KGSurface.h"
#import "KGColorSpace.h"
#import "KGDataProvider.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFStream.h"
#import "KGPDFContext.h"
#import "KGExceptions.h"
#import <Foundation/NSData.h>

@implementation KGImage

static BOOL initFunctionsForParameters(KGImage *self,size_t bitsPerComponent,size_t bitsPerPixel,KGColorSpace *colorSpace,CGBitmapInfo bitmapInfo){

   switch(bitsPerComponent){
   
    case 32:
     switch(bitsPerPixel){
      case 32:
       break;
      case 128:
       switch(bitmapInfo&kCGBitmapByteOrderMask){
        case kCGBitmapByteOrderDefault:
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little:
         self->_readRGBAffff=KGImageRead_RGBAffffLittle_to_RGBAffff;
         return YES;
         
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big:
         self->_readRGBAffff=KGImageRead_RGBAffffBig_to_RGBAffff;
         return YES;
       }
     }
     break;
        
    case  8:
     switch(bitsPerPixel){
     
      case 8:
       self->_readRGBA8888=KGImageRead_G8_to_RGBA8888;
       self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
       return YES;
      
      case 16:
       self->_readRGBA8888=KGImageRead_GA88_to_RGBA8888;
       self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
       return YES;
       
      case 24:
       break;
       
      case 32:
       if([colorSpace type]==KGColorSpaceGenericRGB){
        switch(bitmapInfo&kCGBitmapByteOrderMask){
         case kCGBitmapByteOrderDefault:
         case kCGBitmapByteOrder16Little:
         case kCGBitmapByteOrder32Little:
          self->_readRGBA8888=KGImageRead_ABGR8888_to_RGBA8888;
          self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
          return YES;
         
         case kCGBitmapByteOrder16Big:
         case kCGBitmapByteOrder32Big:
          self->_readRGBA8888=KGImageRead_RGBA8888_to_RGBA8888;
          self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
          return YES;
        }
       }
       else if([colorSpace type]==KGColorSpaceGenericCMYK){
        switch(bitmapInfo&kCGBitmapByteOrderMask){
         case kCGBitmapByteOrderDefault:
         case kCGBitmapByteOrder16Little:
         case kCGBitmapByteOrder32Little:
          break;
         
         case kCGBitmapByteOrder16Big:
         case kCGBitmapByteOrder32Big:
          self->_readRGBA8888=KGImageRead_CMYK8888_to_RGBA8888;
          self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
          return YES;
        }
       }
       break;
     }
     break;
     
    case  4:
     switch(bitsPerPixel){
      case 4:
       break;
      case 12:
       break;
      case 16:
       switch(bitmapInfo&kCGBitmapByteOrderMask){
        case kCGBitmapByteOrderDefault:
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little:
         self->_readRGBA8888=KGImageRead_BARG4444_to_RGBA8888;
         self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
         return YES;
         
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big:
         self->_readRGBA8888=KGImageRead_RGBA4444_to_RGBA8888;
         self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
         return YES;
       }

       return YES;
     }
     break;
     
    case  2:
     switch(bitsPerPixel){
      case 2:
       break;
      case 6:
       break;
      case 8:
       self->_readRGBA8888=KGImageRead_RGBA2222_to_RGBA8888;
       self->_readRGBAffff=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;
       return YES;
     }
     break;

    case  1:
     switch(bitsPerPixel){
      case 1:
    //   self->_readRGBAffff=KGImageReadPixelSpan_01;
     //  return YES;
       
      case 3:
       break;
     }
     break;
   }
   return NO;
      
}

-initWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(unsigned)bitmapInfo provider:(KGDataProvider *)provider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent {
   _width=width;
   _height=height;
   _bitsPerComponent=bitsPerComponent;
   _bitsPerPixel=bitsPerPixel;
   _bytesPerRow=bytesPerRow;
   _colorSpace=[colorSpace retain];
   _bitmapInfo=bitmapInfo;
   _provider=[provider retain];
  // _decode=NULL;
   _interpolate=interpolate;
   _isMask=NO;
   _renderingIntent=renderingIntent;
   _mask=nil;
   
   _bytes=(void *)[_provider bytes];
   _clampExternalPixels=NO; // only do this if premultiplied format

   initFunctionsForParameters(self,bitsPerComponent,bitsPerPixel,colorSpace,bitmapInfo);
    size_t checkBPP;
    _imageFormat=VG_lRGBA_8888;
    switch(bitmapInfo&kCGBitmapAlphaInfoMask){
     case kCGImageAlphaPremultipliedLast:
     case kCGImageAlphaPremultipliedFirst:
      _imageFormat|=VGColorPREMULTIPLIED;
      break;
      
     case kCGImageAlphaNone:
     case kCGImageAlphaLast:
     case kCGImageAlphaFirst:
     case kCGImageAlphaNoneSkipLast:
     case kCGImageAlphaNoneSkipFirst:
      break;
    }
    
	self->m_desc=KGSurfaceParametersToPixelLayout(_imageFormat,&checkBPP,&(self->_colorFormat));
    RI_ASSERT(checkBPP==bitsPerPixel);
   m_ownsData=NO;
    _mipmapsCount=0;
    _mipmapsCapacity=2;
    _mipmaps=(KGSurface **)NSZoneMalloc(NULL,self->_mipmapsCapacity*sizeof(KGSurface *));
   return self;
}

-initWithJPEGDataProvider:(KGDataProvider *)jpegProvider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent {
   KGUnimplementedMethod();
   return nil;
}

-initWithPNGDataProvider:(KGDataProvider *)jpegProvider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent {
   KGUnimplementedMethod();
   return nil;
}

-initMaskWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate {
   _width=width;
   _height=height;
   _bitsPerComponent=bitsPerComponent;
   _bitsPerPixel=bitsPerPixel;
   _bytesPerRow=bytesPerRow;
   _colorSpace=nil;
   _bitmapInfo=0;
   _provider=[provider retain];
  // _decode=NULL;
   _interpolate=interpolate;
   _isMask=YES;
   _renderingIntent=0;
   _mask=nil;
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [_provider release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(KGImage *)copyWithColorSpace:(KGColorSpace *)colorSpace {
   KGUnimplementedMethod();
   return nil;
}

-(KGImage *)childImageInRect:(CGRect)rect {
   KGUnimplementedMethod();
   return nil;
}

-(void)addMask:(KGImage *)image {
   [image retain];
   [_mask release];
   _mask=image;
}

-copyWithMask:(KGImage *)image {
   KGUnimplementedMethod();
   return nil;
}

-copyWithMaskingColors:(const CGFloat *)components {
   KGUnimplementedMethod();
   return nil;
}

-(size_t)width {
   return _width;
}

-(size_t)height {
   return _height;
}

-(size_t)bitsPerComponent {
   return _bitsPerComponent;
}

-(size_t)bitsPerPixel {
   return _bitsPerPixel;
}

-(size_t)bytesPerRow {
   return _bytesPerRow;
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(CGBitmapInfo)bitmapInfo {
   return _bitmapInfo;
}

-(KGDataProvider *)dataProvider {
   return _provider;
}

-(const CGFloat *)decode {
   return _decode;
}

-(BOOL)shouldInterpolate {
   return _interpolate;
}

-(CGColorRenderingIntent)renderingIntent {
   return _renderingIntent;
}

-(BOOL)isMask {
   return _isMask;
}

-(CGImageAlphaInfo)alphaInfo {
   return _bitmapInfo&kCGBitmapAlphaInfoMask;
}

-(const void *)bytes {
   return [_provider bytes];
}

-(unsigned)length {
   return [_provider length];
}

CGColorRenderingIntent KGImageRenderingIntentWithName(const char *name) {
   if(name==NULL)
    return kCGRenderingIntentDefault;
    
   if(strcmp(name,"AbsoluteColorimetric")==0)
    return kCGRenderingIntentAbsoluteColorimetric;
   else if(strcmp(name,"RelativeColorimetric")==0)
    return kCGRenderingIntentRelativeColorimetric;
   else if(strcmp(name,"Saturation")==0)
    return kCGRenderingIntentSaturation;
   else if(strcmp(name,"Perceptual")==0)
    return kCGRenderingIntentPerceptual;
   else
    return kCGRenderingIntentDefault; // unknown
}

const char *KGImageNameWithIntent(CGColorRenderingIntent intent){
   switch(intent){
   
    case kCGRenderingIntentAbsoluteColorimetric:
     return "AbsoluteColorimetric";

    case kCGRenderingIntentRelativeColorimetric:
     return "RelativeColorimetric";

    case kCGRenderingIntentSaturation:
     return "Saturation";
     
    default:
    case kCGRenderingIntentDefault:
    case kCGRenderingIntentPerceptual:
     return "Perceptual";
   } 
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFStream     *result=[KGPDFStream pdfStream];
   KGPDFDictionary *dictionary=[KGPDFDictionary pdfDictionary];

   [dictionary setNameForKey:"Type" value:"XObject"];
   [dictionary setNameForKey:"Subtype" value:"Image"];
   [dictionary setIntegerForKey:"Width" value:_width];
   [dictionary setIntegerForKey:"Height" value:_height];
   if(_colorSpace!=nil)
    [dictionary setObjectForKey:"ColorSpace" value:[_colorSpace encodeReferenceWithContext:context]];
   [dictionary setIntegerForKey:"BitsPerComponent" value:_bitsPerComponent];
   [dictionary setNameForKey:"Intent" value:KGImageNameWithIntent(_renderingIntent)];
   [dictionary setBooleanForKey:"ImageMask" value:_isMask];
   if(_mask!=nil)
    [dictionary setObjectForKey:"Mask" value:[_mask encodeReferenceWithContext:context]];
   if(_decode!=NULL)
    [dictionary setObjectForKey:"Decode" value:[KGPDFArray pdfArrayWithNumbers:_decode count:[_colorSpace numberOfComponents]*2]];
   [dictionary setBooleanForKey:"Interpolate" value:_interpolate];
   /* FIX, generate soft mask
    [dictionary setObjectForKey:"SMask" value:[softMask encodeReferenceWithContext:context]];
    */
  
   /* FIX
    */
    
   return [context encodeIndirectPDFObject:result];
}



+(KGImage *)imageWithPDFObject:(KGPDFObject *)object {
   KGPDFStream     *stream=(KGPDFStream *)object;
   KGPDFDictionary *dictionary=[stream dictionary];
   KGPDFInteger width;
   KGPDFInteger height;
   KGPDFObject *colorSpaceObject;
   KGPDFInteger bitsPerComponent;
   const char  *intent;
   KGPDFBoolean isImageMask;
   KGPDFObject *imageMaskObject=NULL;
   KGColorSpace *colorSpace=NULL;
    int               componentsPerPixel;
   KGPDFArray     *decodeArray;
   float            *decode=NULL;
   BOOL              interpolate;
   KGPDFStream *softMaskStream=nil;
   KGImage *softMask=NULL;
    
   // NSLog(@"Image=%@",dictionary);
    
   if(![dictionary getIntegerForKey:"Width" value:&width]){
    NSLog(@"Image has no Width");
    return NULL;
   }
   if(![dictionary getIntegerForKey:"Height" value:&height]){
    NSLog(@"Image has no Height");
    return NULL;
   }
    
   if(![dictionary getObjectForKey:"ColorSpace" value:&colorSpaceObject]){
    NSLog(@"Image has no ColorSpace");
    return NULL;
   }
   if((colorSpace=[KGColorSpace colorSpaceFromPDFObject:colorSpaceObject])==NULL)
    return NULL;
     
   componentsPerPixel=[colorSpace numberOfComponents];
    
   if(![dictionary getIntegerForKey:"BitsPerComponent" value:&bitsPerComponent]){
    NSLog(@"Image has no BitsPerComponent");
    return NULL;
   }
   if(![dictionary getNameForKey:"Intent" value:&intent])
    intent=NULL;
   if(![dictionary getBooleanForKey:"ImageMask" value:&isImageMask])
    isImageMask=NO;
     
   if(!isImageMask && [dictionary getObjectForKey:"Mask" value:&imageMaskObject]){
    
    
   }

   if(![dictionary getArrayForKey:"Decode" value:&decodeArray])
    decode=NULL;
   else {
    int i,count=[decodeArray count];
     
    if(count!=componentsPerPixel*2){
     NSLog(@"Invalid decode array, count=%d, should be %d",count,componentsPerPixel*2);
     return NULL;
    }
    
    decode=__builtin_alloca(sizeof(float)*count);
    for(i=0;i<count;i++){
     KGPDFReal number;
      
     if(![decodeArray getNumberAtIndex:i value:&number]){
      NSLog(@"Invalid decode array entry at %d",i);
      return NULL;
     }
     decode[i]=number;
    }
   }
    
   if(![dictionary getBooleanForKey:"Interpolate" value:&interpolate])
    interpolate=NO;
    
   if([dictionary getStreamForKey:"SMask" value:&softMaskStream]){
//    NSLog(@"SMask=%@",[softMaskStream dictionary]);
    softMask=[self imageWithPDFObject:softMaskStream];
   }
    
   if(colorSpace!=NULL){
    int               bitsPerPixel=componentsPerPixel*bitsPerComponent;
    int               bytesPerRow=((width*bitsPerPixel)+7)/8;
    NSData           *data=[stream data];
    KGDataProvider * provider;
    KGImage *image=NULL;
       
//     NSLog(@"width=%d,height=%d,bpc=%d,bpp=%d,bpr=%d,cpp=%d",width,height,bitsPerComponent,bitsPerPixel,bytesPerRow,componentsPerPixel);
     
    if(height*bytesPerRow!=[data length]){
     NSMutableData *mutable=[NSMutableData dataWithLength:height*bytesPerRow];
     char *mbytes=[mutable mutableBytes];
      int i;
      for(i=0;i<height*bytesPerRow;i++)
       mbytes[i]=0x33;
       
     NSLog(@"Invalid data length=%d,should be %d=%d",[data length],height*bytesPerRow,[data length]-height*bytesPerRow);
     data=mutable;
      //return NULL;
    }
    provider=[[KGDataProvider alloc] initWithData:data];
    if(isImageMask){
     float decodeDefault[2]={0,1};
      
     if(decode==NULL)
      decode=decodeDefault;
      
     image=[[KGImage alloc] initMaskWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow provider:provider decode:decode interpolate:interpolate];
    }
    else {
     image=[[KGImage alloc] initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:0 provider:provider decode:decode interpolate:interpolate renderingIntent:KGImageRenderingIntentWithName(intent)];

     if(softMask!=NULL)
      [image addMask:softMask];
    }

    return image;
   }
   return nil;
}

size_t KGImageGetWidth(KGImage *self) {
   return self->_width;
}

size_t KGImageGetHeight(KGImage *self) {
   return self->_height;
}

VGColorInternalFormat KGImageColorFormat(KGImage *self) {
   return self->_colorFormat;
}

static  CGFloat byteToColor(unsigned char i){
	return (CGFloat)(i) / (CGFloat)0xFF;
}

void KGImageRead_ANY_to_RGBA8888_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length){
   KGRGBA8888 span8888[length];

   self->_readRGBA8888(self,x,y,span8888,length);
   int i;
   for(i=0;i<length;i++){
    KGRGBAffff  result;
    
    result.r = byteToColor(span8888[i].r);
    result.g = byteToColor(span8888[i].g);
    result.b = byteToColor(span8888[i].b);
	result.a = byteToColor(span8888[i].a);
    *span++=result;
   }
}

float bytesLittleToFloat(unsigned char *scanline){
   union {
    unsigned char bytes[4];
    float         f;
   } u;

#ifdef __LITTLE_ENDIAN__   
   u.bytes[0]=scanline[0];
   u.bytes[1]=scanline[1];
   u.bytes[2]=scanline[2];
   u.bytes[3]=scanline[3];
#else
   u.bytes[0]=scanline[3];
   u.bytes[1]=scanline[2];
   u.bytes[2]=scanline[1];
   u.bytes[3]=scanline[0];
#endif

   return u.f;
}

void KGImageRead_RGBAffffLittle_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*16;
   for(i=0;i<length;i++){
    KGRGBAffff result;
    
    result.r=bytesLittleToFloat(scanline);
    scanline+=4;
    result.g=bytesLittleToFloat(scanline);
    scanline+=4;
    result.b=bytesLittleToFloat(scanline);
    scanline+=4;
    result.a=bytesLittleToFloat(scanline);
    scanline+=4;
        
    *span++=result;
   }
}

float bytesBigToFloat(unsigned char *scanline){
   union {
    unsigned char bytes[4];
    float         f;
   } u;

#ifdef __BIG_ENDIAN__   
   u.bytes[0]=scanline[0];
   u.bytes[1]=scanline[1];
   u.bytes[2]=scanline[2];
   u.bytes[3]=scanline[3];
#else
   u.bytes[0]=scanline[3];
   u.bytes[1]=scanline[2];
   u.bytes[2]=scanline[1];
   u.bytes[3]=scanline[0];
#endif

   return u.f;
}

void KGImageRead_RGBAffffBig_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*16;
   for(i=0;i<length;i++){
    KGRGBAffff result;
    
    result.r=bytesBigToFloat(scanline);
    scanline+=4;
    result.g=bytesBigToFloat(scanline);
    scanline+=4;
    result.b=bytesBigToFloat(scanline);
    scanline+=4;
    result.a=bytesBigToFloat(scanline);
    scanline+=4;
        
    *span++=result;
   }
}

void KGImageRead_G8_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x;
   for(i=0;i<length;i++){
    KGRGBA8888 result;
    
    result.r=*scanline++;
    result.g=result.r;
    result.b=result.r;
    result.a=0xFF;
    
    *span++=result;
   }
}

void KGImageRead_GA88_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline++;
    result.g=result.r;
    result.b=result.r;
	result.a = *scanline++;
    *span++=result;
   }
}

void KGImageRead_RGBA8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline++;
    result.g = *scanline++;
    result.b = *scanline++;
	result.a = *scanline++;
    *span++=result;
   }
}

void KGImageRead_ABGR8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.a = *scanline++;
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    *span++=result;
   }
}

void KGImageRead_RGBA4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline&0xF0;
    result.g = (*scanline&0x0F)<<4;
    scanline++;
    result.b = *scanline&0xF0;
    result.a = (*scanline&0x0F)<<4;
    scanline++;
    *span++=result;
   }
}

void KGImageRead_BARG4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.b = *scanline&0xF0;
    result.a = (*scanline&0x0F)<<4;
    scanline++;
    result.r = *scanline&0xF0;
    result.g = (*scanline&0x0F)<<4;
    scanline++;
    *span++=result;
   }
}

void KGImageRead_RGBA2222_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline&0xC0;
    result.g = (*scanline&0x03)<<2;
    result.b = (*scanline&0x0C)<<4;
	result.a = (*scanline&0x03)<<6;
    scanline++;
    *span++=result;
   }
}

void KGImageRead_CMYK8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
// poor results
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    unsigned char c=*scanline++;
    unsigned char y=*scanline++;
    unsigned char m=*scanline++;
    unsigned char k=*scanline++;
    unsigned char w=0xff-k;
    
    result.r = c>w?0:w-c;
    result.g = m>w?0:w-m;
    result.b = y>w?0:w-y;
	result.a = 1;
    *span++=result;
   }
}

// accuracy doesn't seem to matter much, it appears
static inline float fastExp(float value){
   static float table[10];
   static BOOL initTable=YES;
   
   if(initTable){
    initTable=NO;
    int i;
    for(i=0;i<10;i++)
     table[i]=exp(-i/2.0);
   }
   return table[(int)(-value*2)];
}

KGImage *KGSurfaceMipMapForLevel(KGImage *self,int level){
	KGImage* image = self;
    
	if( level > 0 ){
		RI_ASSERT(level <= self->_mipmapsCount);
		image = self->_mipmaps[level-1];
	}
	RI_ASSERT(image);
    return image;
}


VGColorInternalFormat KGImageResample_EWAOnMipmaps(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   int i;
   		CGFloat m_pixelFilterRadius = 1.25f;
		CGFloat m_resamplingFilterRadius = 1.25f;

   KGSurfaceMakeMipMaps(self);
   
   CGPoint uv=CGPointMake(0,0);
   uv=CGAffineTransformTransformVector2(surfaceToImage ,uv);

   
		CGFloat Ux = (surfaceToImage.a ) * m_pixelFilterRadius;
		CGFloat Vx = (surfaceToImage.b ) * m_pixelFilterRadius;
		CGFloat Uy = (surfaceToImage.c ) * m_pixelFilterRadius;
		CGFloat Vy = (surfaceToImage.d ) * m_pixelFilterRadius;

		//calculate mip level
		int level = 0;
		CGFloat axis1sq = Ux*Ux + Vx*Vx;
		CGFloat axis2sq = Uy*Uy + Vy*Vy;
		CGFloat minorAxissq = RI_MIN(axis1sq,axis2sq);
		while(minorAxissq > 9.0f && level < self->_mipmapsCount)	//half the minor axis must be at least three texels
		{
			level++;
			minorAxissq *= 0.25f;
		}

		CGFloat sx = 1.0f;
		CGFloat sy = 1.0f;
		if(level > 0)
		{
			sx = (CGFloat)KGImageGetWidth(self->_mipmaps[level-1]) / (CGFloat)self->_width;
			sy = (CGFloat)KGImageGetHeight(self->_mipmaps[level-1]) / (CGFloat)self->_height;
		}
        KGImage *mipmap=KGSurfaceMipMapForLevel(self,level);
        
		Ux *= sx;
		Vx *= sx;
		Uy *= sy;
		Vy *= sy;

		//clamp filter size so that filtering doesn't take excessive amount of time (clamping results in aliasing)
		CGFloat lim = 100.0f;
		axis1sq = Ux*Ux + Vx*Vx;
		axis2sq = Uy*Uy + Vy*Vy;
		if( axis1sq > lim*lim )
		{
			CGFloat s = lim / (CGFloat)sqrt(axis1sq);
			Ux *= s;
			Vx *= s;
		}
		if( axis2sq > lim*lim )
		{
			CGFloat s = lim / (CGFloat)sqrt(axis2sq);
			Uy *= s;
			Vy *= s;
		}

		//form elliptic filter by combining texel and pixel filters
		CGFloat A = Vx*Vx + Vy*Vy + 1.0f;
		CGFloat B = -2.0f*(Ux*Vx + Uy*Vy);
		CGFloat C = Ux*Ux + Uy*Uy + 1.0f;
		//scale by the user-defined size of the kernel
		A *= m_resamplingFilterRadius;
		B *= m_resamplingFilterRadius;
		C *= m_resamplingFilterRadius;

		//calculate bounding box in texture space
		CGFloat usize = (CGFloat)sqrt(C);
		CGFloat vsize = (CGFloat)sqrt(A);

		//scale the filter so that Q = 1 at the cutoff radius
		CGFloat F = A*C - 0.25f * B*B;
		if( F <= 0.0f ){
         for(i=0;i<length;i++)
		  span[i]=KGRGBAffffInit(0,0,0,0);	//invalid filter shape due to numerical inaccuracies => return black
          
         return  self->_colorFormat;
        }
		CGFloat ooF = 1.0f / F;
		A *= ooF;
		B *= ooF;
		C *= ooF;

   for(i=0;i<length;i++,x++){
    uv=CGPointMake(x+0.5,y+0.5);
    uv=CGAffineTransformTransformVector2(surfaceToImage ,uv);
   
		CGFloat U0 = uv.x;
		CGFloat V0 = uv.y;
		U0 *= sx;
		V0 *= sy;
		
		int u1 = RI_FLOOR_TO_INT(U0 - usize + 0.5f);
		int u2 = RI_FLOOR_TO_INT(U0 + usize + 0.5f);
		int v1 = RI_FLOOR_TO_INT(V0 - vsize + 0.5f);
		int v2 = RI_FLOOR_TO_INT(V0 + vsize + 0.5f);
		if( u1 == u2 || v1 == v2 ){
			span[i]=KGRGBAffffInit(0,0,0,0);
            continue;
        }
        
		
		//evaluate filter by using forward differences to calculate Q = A*U^2 + B*U*V + C*V^2
		KGRGBAffff color=KGRGBAffffInit(0,0,0,0);
		CGFloat sumweight = 0.0f;
		CGFloat DDQ = 2.0f * A;
		CGFloat U = (CGFloat)u1 - U0 + 0.5f;
        int v;
        
		for(v=v1;v<v2;v++)
		{
			CGFloat V = (CGFloat)v - V0 + 0.5f;
			CGFloat DQ = A*(2.0f*U+1.0f) + B*V;
			CGFloat Q = (C*V+B*U)*V + A*U*U;
            int u;
            
            KGRGBAffff texel[u2-u1];
            KGSurfaceReadTexelTilePad(mipmap,u1, v,texel,(u2-u1));
			for(u=u1;u<u2;u++)
			{
				if( Q >= 0.0f && Q < 1.0f )
				{	//Q = r^2, fit gaussian to the range [0,1]
#if 0
					CGFloat weight = (CGFloat)expf(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
#else
					CGFloat weight = (CGFloat)fastExp(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
#endif
                    
					color=KGRGBAffffAdd(color,  KGRGBAffffMultiplyByFloat(texel[u-u1],weight));
					sumweight += weight;
				}
				Q += DQ;
				DQ += DDQ;
			}
		}
		if( sumweight == 0.0f ){
			span[i]=KGRGBAffffInit(0,0,0,0);
            continue;
        }
		RI_ASSERT(sumweight > 0.0f);
		sumweight = 1.0f / sumweight;
		span[i]=KGRGBAffffMultiplyByFloat(color,sumweight);
	}


   return self->_colorFormat;
}


static inline float cubic(float v0,float v1,float v2,float v3,float fraction){
  float p = (v3 - v2) - (v0 - v1);
  float q = (v0 - v1) - p;

  return RI_CLAMP((p * (fraction*fraction*fraction)) + (q * fraction*fraction) + ((v2 - v0) * fraction) + v1,0,1);
}

KGRGBAffff bicubicInterpolate(KGRGBAffff a,KGRGBAffff b,KGRGBAffff c,KGRGBAffff d,float fraction)
{
  return KGRGBAffffInit(
   cubic(a.r, b.r, c.r, d.r, fraction),
   cubic(a.g, b.g, c.g, d.g, fraction),
   cubic(a.b, b.b, c.b, d.b, fraction),
   cubic(a.a, b.a, c.a, d.a, fraction));
}

VGColorInternalFormat KGImageResample_Bicubic(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   int i;
   
   for(i=0;i<length;i++,x++){
	CGPoint uv=CGPointMake(x+0.5,y+0.5);
	uv = CGAffineTransformTransformVector2(surfaceToImage ,uv);

    uv.x -= 0.5f;
    uv.y -= 0.5f;
    int u = RI_FLOOR_TO_INT(uv.x);
    float ufrac=uv.x-u;
        
    int v = RI_FLOOR_TO_INT(uv.y);
    float vfrac=uv.y-v;
        
    KGRGBAffff t0,t1,t2,t3;
    KGRGBAffff cspan[4];
     
    KGSurfaceReadTexelTilePad(self,u - 1,v - 1,cspan,4);
    t0 = bicubicInterpolate(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
      
    KGSurfaceReadTexelTilePad(self,u - 1,v,cspan,4);
    t1 = bicubicInterpolate(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    KGSurfaceReadTexelTilePad(self,u - 1,v+1,cspan,4);     
    t2 = bicubicInterpolate(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    KGSurfaceReadTexelTilePad(self,u - 1,v+2,cspan,4);     
    t3 = bicubicInterpolate(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);

    span[i]=bicubicInterpolate(t0,t1,t2,t3, vfrac);
   }

   return self->_colorFormat;
}

VGColorInternalFormat KGImageResample_Bilinear(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   int i;

   for(i=0;i<length;i++,x++){
	CGPoint uv=CGPointMake(x+0.5,y+0.5);
	uv = CGAffineTransformTransformVector2(surfaceToImage,uv);

    uv.x -= 0.5f;
	uv.y -= 0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	KGRGBAffff c00c01[2];
    KGSurfaceReadTexelTilePad(self,u,v,c00c01,2);

    KGRGBAffff c01c11[2];
    KGSurfaceReadTexelTilePad(self,u,v+1,c01c11,2);

    CGFloat fu = uv.x - (CGFloat)u;
    CGFloat fv = uv.y - (CGFloat)v;
    KGRGBAffff c0 = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c00c01[0],(1.0f - fu)),KGRGBAffffMultiplyByFloat(c00c01[1],fu));
    KGRGBAffff c1 = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c01c11[0],(1.0f - fu)),KGRGBAffffMultiplyByFloat(c01c11[1],fu));
    span[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c0,(1.0f - fv)),KGRGBAffffMultiplyByFloat(c1, fv));
   }

   return self->_colorFormat;
}

VGColorInternalFormat KGImageResample_PointSampling(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(x+0.5,y+0.5);
	uv = CGAffineTransformTransformVector2(surfaceToImage ,uv);

    KGSurfaceReadTexelTilePad(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);
   }
   return self->_colorFormat;
}

@end
