/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 * Copyright (c) 2008 Christopher J. W. Lloyd
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
#import "O2ColorSpace.h"
#import "KGDataProvider.h"
#import "KGExceptions.h"
#import <Foundation/NSData.h>

@implementation KGImage

/*-------------------------------------------------------------------*//*!
* \brief	Creates a pixel format descriptor out of KGImageFormat
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGPixelDecode KGImageParametersToPixelLayout(KGImageFormat format,size_t *bitsPerPixel,VGColorInternalFormat	*colorFormat){
	VGPixelDecode desc;
	memset(&desc, 0, sizeof(VGPixelDecode));

	int baseFormat = (int)format & 15;
	RI_ASSERT(baseFormat >= 0 && baseFormat <= 12);
	int swizzleBits = ((int)format >> 6) & 3;

	/* base formats
	VG_sRGBX_8888                               =  0,
	VG_sRGBA_8888                               =  1,
	VG_sRGBA_8888_PRE                           =  2,
	VG_sRGB_565                                 =  3,
	VG_sRGBA_5551                               =  4,
	VG_sRGBA_4444                               =  5,
	VG_sL_8                                     =  6,
	VG_lRGBX_8888                               =  7,
	VG_lRGBA_8888                               =  8,
	VG_lRGBA_8888_PRE                           =  9,
	VG_lL_8                                     = 10,
	VG_A_8                                      = 11,
	VG_BW_1                                     = 12,
	*/

	static const int redBits[13] =       {8, 8, 8, 5, 5, 4, 0, 8, 8, 8, 0, 0, 0};
	static const int greenBits[13] =     {8, 8, 8, 6, 5, 4, 0, 8, 8, 8, 0, 0, 0};
	static const int blueBits[13] =      {8, 8, 8, 5, 5, 4, 0, 8, 8, 8, 0, 0, 0};
	static const int alphaBits[13] =     {0, 8, 8, 0, 1, 4, 0, 0, 8, 8, 0, 8, 0};
	static const int luminanceBits[13] = {0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 8, 0, 1};

	static const int redShifts[4*13] =   {24, 24, 24, 11, 11, 12, 0, 24, 24, 24, 0, 0, 0,	//RGBA
                                          16, 16, 16, 11, 10, 8,  0, 16, 16, 16, 0, 0, 0,	//ARGB
                                          8,  8,  8,  0,  1,  4,  0, 8,  8,  8,  0, 0, 0,	//BGRA
                                          0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0};	//ABGR

	static const int greenShifts[4*13] = {16, 16, 16, 5,  6,  8,  0, 16, 16, 16, 0, 0, 0,	//RGBA
                                          8,  8,  8,  5,  5,  4,  0, 8,  8,  8,  0, 0, 0,	//ARGB
                                          16, 16, 16, 5,  6,  8,  0, 16, 16, 16, 0, 0, 0,	//BGRA
                                          8,  8,  8,  5,  5,  4,  0, 8,  8,  8,  0, 0, 0};	//ABGR

	static const int blueShifts[4*13] =  {8,  8,  8,  0,  1,  4,  0, 8,  8,  8,  0, 0, 0,	//RGBA
                                          0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0,	//ARGB
                                          24, 24, 24, 11, 11, 12, 0, 24, 24, 24, 0, 0, 0,	//BGRA
                                          16, 16, 16, 11, 10, 8,  0, 16, 16, 16, 0, 0, 0};	//ABGR

	static const int alphaShifts[4*13] = {0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0,	//RGBA
                                          0,  24, 24, 0,  15, 12, 0, 0,  24, 24, 0, 0, 0,	//ARGB
                                          0,  0,  0,  0,  0,  0,  0, 0,  0,  0,  0, 0, 0,	//BGRA
                                          0,  24, 24, 0,  15, 12, 0, 0,  24, 24, 0, 0, 0};	//ABGR

	static const int bpps[13] = {32, 32, 32, 16, 16, 16, 8, 32, 32, 32, 8, 8, 1};

	static const VGColorInternalFormat internalFormats[13] = {VGColor_sRGBA, VGColor_sRGBA, VGColor_sRGBA_PRE, VGColor_sRGBA, VGColor_sRGBA, VGColor_sRGBA, VGColor_sLA, VGColor_lRGBA, VGColor_lRGBA, VGColor_lRGBA_PRE, VGColor_lLA, VGColor_lRGBA, VGColor_lLA};

	desc.redBits = redBits[baseFormat];
	desc.greenBits = greenBits[baseFormat];
	desc.blueBits = blueBits[baseFormat];
	desc.alphaBits = alphaBits[baseFormat];
	desc.luminanceBits = luminanceBits[baseFormat];

	desc.redShift = redShifts[swizzleBits * 13 + baseFormat];
	desc.greenShift = greenShifts[swizzleBits * 13 + baseFormat];
	desc.blueShift = blueShifts[swizzleBits * 13 + baseFormat];
	desc.alphaShift = alphaShifts[swizzleBits * 13 + baseFormat];
	desc.luminanceShift = 0;	//always zero

	*bitsPerPixel = bpps[baseFormat];
	*colorFormat = internalFormats[baseFormat];

	return desc;
}

static BOOL initFunctionsForRGBColorSpace(KGImage *self,size_t bitsPerComponent,size_t bitsPerPixel,CGBitmapInfo bitmapInfo){   

   switch(bitsPerComponent){
   
    case 32:
     switch(bitsPerPixel){
      case 32:
       break;
      case 128:
       switch(bitmapInfo&kCGBitmapByteOrderMask){
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little:
         self->_read_lRGBAffff_PRE=KGImageRead_RGBAffffLittle_to_RGBAffff;
         return YES;
         
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big:
         self->_read_lRGBAffff_PRE=KGImageRead_RGBAffffBig_to_RGBAffff;
         return YES;
       }
     }
     break;
        
    case  8:
     switch(bitsPerPixel){
     
      case 8:
       self->_readA8=KGImageRead_G8_to_A8;
       self->_read_lRGBA8888_PRE=KGImageRead_G8_to_RGBA8888;
       return YES;
      
      case 16:
       self->_read_lRGBA8888_PRE=KGImageRead_GA88_to_RGBA8888;
       return YES;
       
      case 24:
       switch(bitmapInfo&kCGBitmapAlphaInfoMask){
        case kCGImageAlphaNone:
          // FIXME: how is endian ness interpreted ?
         self->_read_lRGBA8888_PRE=KGImageRead_RGB888_to_RGBA8888;
         return YES;
       }
       break;
       
      case 32:
        switch(bitmapInfo&kCGBitmapAlphaInfoMask){
         case kCGImageAlphaNone:
          break;
          
         case kCGImageAlphaLast:
         case kCGImageAlphaPremultipliedLast:
          switch(bitmapInfo&kCGBitmapByteOrderMask){
           case kCGBitmapByteOrder16Little:
           case kCGBitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=KGImageRead_ABGR8888_to_RGBA8888;
            return YES;

           case kCGBitmapByteOrder16Big:
           case kCGBitmapByteOrder32Big:
            self->_read_lRGBA8888_PRE=KGImageRead_RGBA8888_to_RGBA8888;
            return YES;
          }
          break;

         case kCGImageAlphaPremultipliedFirst:
          switch(bitmapInfo&kCGBitmapByteOrderMask){
           case kCGBitmapByteOrder16Little:
           case kCGBitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=KGImageRead_BGRA8888_to_RGBA8888;
            return YES;
          }
          break;
                    
         case kCGImageAlphaFirst:
          break;
          
         case kCGImageAlphaNoneSkipLast:
          switch(bitmapInfo&kCGBitmapByteOrderMask){
           case kCGBitmapByteOrder16Little:
           case kCGBitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=KGImageRead_ABGR8888_to_RGBA8888;
            return YES;

           case kCGBitmapByteOrder16Big:
           case kCGBitmapByteOrder32Big:
            self->_read_lRGBA8888_PRE=KGImageRead_RGBA8888_to_RGBA8888;
            return YES;
          }
          break;
          
         case kCGImageAlphaNoneSkipFirst:
          switch(bitmapInfo&kCGBitmapByteOrderMask){
           
           case kCGBitmapByteOrder16Little:
           case kCGBitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=KGImageRead_BGRX8888_to_RGBA8888;
            return YES;

           case kCGBitmapByteOrder16Big:
           case kCGBitmapByteOrder32Big:
            self->_read_lRGBA8888_PRE=KGImageRead_XRGB8888_to_RGBA8888;
            return YES;
          }
          break;
        }
              
        break;
     }
     break;
    
    case 5:
     switch(bitsPerPixel){
     
      case 16:
       if(bitmapInfo==(kCGBitmapByteOrder16Little|kCGImageAlphaNoneSkipFirst)){
        self->_read_lRGBA8888_PRE=KGImageRead_G3B5X1R5G2_to_RGBA8888;
        return YES;
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
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little:
         self->_read_lRGBA8888_PRE=KGImageRead_BARG4444_to_RGBA8888;
         return YES;
         
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big:
         self->_read_lRGBA8888_PRE=KGImageRead_RGBA4444_to_RGBA8888;
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
       self->_read_lRGBA8888_PRE=KGImageRead_RGBA2222_to_RGBA8888;
       return YES;
     }
     break;

    case  1:
     switch(bitsPerPixel){
      case 1:
    //   self->_read_lRGBAffff_PRE=KGImageReadPixelSpan_01;
     //  return YES;
       
      case 3:
       break;
     }
     break;
   }
   return NO;
      
}

static BOOL initFunctionsForCMYKColorSpace(KGImage *self,size_t bitsPerComponent,size_t bitsPerPixel,CGBitmapInfo bitmapInfo){   
   switch(bitsPerComponent){
        
    case  8:
     switch(bitsPerPixel){
     
      case 32:
        switch(bitmapInfo&kCGBitmapByteOrderMask){
         case kCGBitmapByteOrder16Big:
         case kCGBitmapByteOrder32Big:
          self->_read_lRGBA8888_PRE=KGImageRead_CMYK8888_to_RGBA8888;
          return YES;
        }
       break;
     }
     break;
   }
   return NO;
}

static BOOL initFunctionsForIndexedColorSpace(KGImage *self,size_t bitsPerComponent,size_t bitsPerPixel,O2ColorSpaceRef colorSpace,CGBitmapInfo bitmapInfo){

   switch([[(O2ColorSpace_indexed *)colorSpace baseColorSpace] type]){
    case O2ColorSpaceDeviceRGB:
     self->_read_lRGBA8888_PRE=KGImageRead_I8_to_RGBA8888;
     return YES;
   }
   
   return NO;
}

static BOOL initFunctionsForParameters(KGImage *self,size_t bitsPerComponent,size_t bitsPerPixel,O2ColorSpaceRef colorSpace,CGBitmapInfo bitmapInfo){

   self->_readA8=KGImageRead_ANY_to_RGBA8888_to_A8;
   self->_readAf=KGImageRead_ANY_to_A8_to_Af;
   self->_read_lRGBAffff_PRE=KGImageRead_ANY_to_RGBA8888_to_RGBAffff;

   if((bitmapInfo&kCGBitmapByteOrderMask)==kCGBitmapByteOrderDefault)
    bitmapInfo|=kCGBitmapByteOrder32Big;
   
   switch([colorSpace type]){
    case O2ColorSpaceDeviceGray:
     break;
    case O2ColorSpaceDeviceRGB:
     return initFunctionsForRGBColorSpace(self,bitsPerComponent,bitsPerPixel,bitmapInfo);
    case O2ColorSpaceDeviceCMYK:
     return initFunctionsForCMYKColorSpace(self,bitsPerComponent,bitsPerPixel,bitmapInfo);
    case O2ColorSpaceIndexed:
     return initFunctionsForIndexedColorSpace(self,bitsPerComponent,bitsPerPixel,colorSpace,bitmapInfo);
   }
   
   return NO;
      
}

-initWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(unsigned)bitmapInfo provider:(KGDataProvider *)provider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent {
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
   
    _directBytes=NULL;
    _directLength=0;

   _clampExternalPixels=NO; // only do this if premultiplied format
   if(!initFunctionsForParameters(self,bitsPerComponent,bitsPerPixel,colorSpace,bitmapInfo)){
    NSLog(@"KGImage failed to init with bpc=%d, bpp=%d,colorSpace=%@,bitmapInfo=0x%0X",bitsPerComponent,bitsPerPixel,colorSpace,bitmapInfo);
    [self dealloc];
    return nil;
   }
   
    KGImageFormat imageFormat=VG_lRGBA_8888;
    switch(bitmapInfo&kCGBitmapAlphaInfoMask){
     case kCGImageAlphaPremultipliedLast:
     case kCGImageAlphaPremultipliedFirst:
      imageFormat|=VGColorPREMULTIPLIED;
      break;
      
     case kCGImageAlphaNone:
     case kCGImageAlphaLast:
     case kCGImageAlphaFirst:
     case kCGImageAlphaNoneSkipLast:
     case kCGImageAlphaNoneSkipFirst:
      break;
    }
    
    size_t checkBPP;
	KGImageParametersToPixelLayout(imageFormat,&checkBPP,&(self->_colorFormat));
    RI_ASSERT(checkBPP==bitsPerPixel);
    m_mipmapsValid=NO;
    _mipmapsCount=0;
    _mipmapsCapacity=0;
    _mipmaps=NULL;
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
   if(_decode!=NULL)
    NSZoneFree(NULL,_decode);
   [_mask release];
   [_directData release];
   if(_mipmaps!=NULL)
    NSZoneFree(NULL,_mipmaps);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(KGImage *)copyWithColorSpace:(O2ColorSpaceRef)colorSpace {
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

-(O2ColorSpaceRef)colorSpace {
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

static inline const void *directBytes(KGImage *self){
   if(self->_directBytes==NULL){
    if([self->_provider isDirectAccess]){
     self->_directData=[[self->_provider data] retain];
     self->_directBytes=[self->_provider bytes];
     self->_directLength=[self->_provider length];
   }
    else {
     self->_directData=[self->_provider copyData];
     self->_directBytes=[self->_directData bytes];
     self->_directLength=[self->_directData length];
    }
   }
   return self->_directBytes;
}

static inline const void *scanlineAtY(KGImage *self,int y){
   const void *bytes=directBytes(self);
   int         offset=self->_bytesPerRow*y;
   int         max=offset+self->_bytesPerRow;
   
   if(max<=self->_directLength)
    return bytes+offset;
    
   return NULL;
}

-(NSData *)directData {
   directBytes(self);
   return _directData;
}

-(const void *)directBytes {
   return directBytes(self);
}

-(void)releaseDirectDataIfPossible {
   if(![_provider isDirectAccess]){
    [_directData release];
    _directData=nil;
    _directBytes=NULL;
    _directLength=0;
   }
}

size_t KGImageGetWidth(KGImage *self) {
   return self->_width;
}

size_t KGImageGetHeight(KGImage *self) {
   return self->_height;
}

KGRGBAffff *KGImageRead_ANY_to_RGBA8888_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length){
   KGRGBA8888 *span8888=__builtin_alloca(length*sizeof(KGRGBA8888));
   KGRGBA8888 *direct=self->_read_lRGBA8888_PRE(self,x,y,span8888,length);
   
   if(direct!=NULL)
    span8888=direct;
    
   int i;
   for(i=0;i<length;i++){
    KGRGBAffff  result;
    
    result.r = CGFloatFromByte(span8888[i].r);
    result.g = CGFloatFromByte(span8888[i].g);
    result.b = CGFloatFromByte(span8888[i].b);
	result.a = CGFloatFromByte(span8888[i].a);
    *span++=result;
   }
   return NULL;
}

float bytesLittleToFloat(const unsigned char *scanline){
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

KGRGBAffff *KGImageRead_RGBAffffLittle_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;
    
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
   return NULL;
}

float bytesBigToFloat(const unsigned char *scanline){
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

KGRGBAffff *KGImageRead_RGBAffffBig_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;
    
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
   return NULL;
}

uint8_t *KGImageRead_G8_to_A8(KGImage *self,int x,int y,uint8_t *alpha,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;
    
   scanline+=x;
   for(i=0;i<length;i++){
    *alpha++=*scanline++;
   }
   return NULL;
}

uint8_t *KGImageRead_ANY_to_RGBA8888_to_A8(KGImage *self,int x,int y,uint8_t *alpha,int length) {
   KGRGBA8888 *span=__builtin_alloca(length*sizeof(KGRGBA8888));
   int i;
   
   KGRGBA8888 *direct=self->_read_lRGBA8888_PRE(self,x,y,span,length);
   if(direct!=NULL)
    span=direct;
    
   for(i=0;i<length;i++){
    *alpha++=span[i].a;
   }
   return NULL;
}

CGFloat *KGImageRead_ANY_to_A8_to_Af(KGImage *self,int x,int y,CGFloat *alpha,int length) {
   uint8_t span[length];
   int     i;
   
   self->_readA8(self,x,y,span,length);
   for(i=0;i<length;i++)
    alpha[i]=CGFloatFromByte(span[i]);
    
   return NULL;
}

KGRGBA8888 *KGImageRead_G8_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;

   if(scanline==NULL)
    return NULL;
    
   scanline+=x;
   for(i=0;i<length;i++){
    KGRGBA8888 result;
    
    result.r=*scanline++;
    result.g=result.r;
    result.b=result.r;
    result.a=0xFF;
    
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_GA88_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;

   if(scanline==NULL)
    return NULL;
    
   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline++;
    result.g=result.r;
    result.b=result.r;
	result.a = *scanline++;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_RGBA8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline++;
    result.g = *scanline++;
    result.b = *scanline++;
	result.a = *scanline++;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_ABGR8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.a = *scanline++;
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_BGRA8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
#ifdef __LITTLE_ENDIAN__
   return (KGRGBA8888 *)scanline;
#endif
   
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    result.a = *scanline++;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_RGB888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*3;
   
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.r = *scanline++;
    result.g = *scanline++;
	result.b = *scanline++;
    result.a = 255;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_BGRX8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;

   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    result.a = 255; scanline++;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_XRGB8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   
   for(i=0;i<length;i++){
    KGRGBA8888  result;
    
    result.a = *scanline++;
    result.r = *scanline++;
	result.g = *scanline++;
    result.b = *scanline++;
    *span++=result;
   }
   return NULL;
}

// kCGBitmapByteOrder16Little|kCGImageAlphaNoneSkipFirst
KGRGBA8888 *KGImageRead_G3B5X1R5G2_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*2;
   for(i=0;i<length;i++){
    unsigned short low=*scanline++;
    unsigned short high=*scanline;
    unsigned short value=low|(high<<8);
    KGRGBA8888  result;
    
    result.r = ((value>>10)&0x1F)<<3;
    result.g = ((value>>5)&0x1F)<<3;
    result.b = ((value&0x1F)<<3);
    result.a = 255;
    scanline++;
    *span++=result;
   }
   return NULL;
}

KGRGBA8888 *KGImageRead_RGBA4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

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
   return NULL;
}

KGRGBA8888 *KGImageRead_BARG4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

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
   return NULL;
}

KGRGBA8888 *KGImageRead_RGBA2222_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

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
   return NULL;
}

KGRGBA8888 *KGImageRead_CMYK8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length){
// poor results
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

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
   return NULL;
}

KGRGBA8888 *KGImageRead_I8_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length) {
   O2ColorSpace_indexed *indexed=(O2ColorSpace_indexed *)self->_colorSpace;
   unsigned hival=[indexed hival];
   const unsigned char *palette=[indexed paletteBytes];

   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;
   
   scanline+=x;

   for(i=0;i<length;i++){
    unsigned index=*scanline++;
    KGRGBA8888 argb;

    RI_INT_CLAMP(index,0,hival); // it is external data after all
    
    argb.r=palette[index*3+0];
    argb.g=palette[index*3+1];
    argb.b=palette[index*3+2];
    argb.a=255;
    *span++=argb;
   }
   
   return NULL;
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a texel (u,v) at the given mipmap level. Tiling modes and
*			color space conversion are applied. Outputs color in premultiplied
*			format.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

/* KGImageReadTileSpanExtendEdge__ is used by the image resampling functions to read
   translated spans. When a coordinate is outside the image it uses the edge
   value. This works better than say, zero, with averaging algorithms (bilinear,bicubic, etc)
   as you get good values at the edges.
   
   Ideally the averaging algorithms would only use the available pixels on the edges */
   
void KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(KGImage *self,int u, int v, KGRGBA8888 *span,int length){
   int i;
   KGRGBA8888 *direct;
   v = RI_INT_CLAMP(v,0,self->_height-1);
      
   for(i=0;i<length && u<0;u++,i++){
    direct=self->_read_lRGBA8888_PRE(self,0,v,span+i,1);

    if(direct!=NULL)
     span[i]=direct[0];
   }   

   int chunk=RI_MIN(length-i,self->_width-u);
   direct=self->_read_lRGBA8888_PRE(self,u,v,span+i,chunk);
   if(direct!=NULL) {
    int k;
    
    for(k=0;k<chunk;k++)
     span[i+k]=direct[k];
   }
   
   i+=chunk;
   u+=chunk;

   for(;i<length;i++){
    direct=self->_read_lRGBA8888_PRE(self,self->_width-1,v,span+i,1);
    
    if(direct!=NULL)
     span[i]=direct[0];
   }
}

void KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(KGImage *self,int u, int v, KGRGBAffff *span,int length){
   int i;
   KGRGBAffff *direct;
   
   v = RI_INT_CLAMP(v,0,self->_height-1);
   
   for(i=0;i<length && u<0;u++,i++){
    direct=KGImageReadSpan_lRGBAffff_PRE(self,0,v,span+i,1);
    if(direct!=NULL)
     span[i]=direct[0];
   }
   
   int chunk=RI_MIN(length-i,self->_width-u);
   direct=KGImageReadSpan_lRGBAffff_PRE(self,u,v,span+i,chunk);
   if(direct!=NULL) {
    int k;
    
    for(k=0;k<chunk;k++)
     span[i+k]=direct[k];
   }
   i+=chunk;
   u+=chunk;

   for(;i<length;i++){
    direct=KGImageReadSpan_lRGBAffff_PRE(self,self->_width-1,v,span+i,1);
    if(direct!=NULL)
     span[i]=direct[0];
   }
}


/*-------------------------------------------------------------------*//*!
* \brief	Generates mip maps for an image.
* \param	
* \return	
* \note		Downsampling is done in the input color space. We use a box
*			filter for downsampling.
*//*-------------------------------------------------------------------*/

void KGImageMakeMipMaps(KGImage *self) {
	RI_ASSERT(directBytes(self));

	if(self->m_mipmapsValid)
		return;

	//delete existing mipmaps
    int i;
	for(i=0;i<self->_mipmapsCount;i++)
     [self->_mipmaps[i] release];
	self->_mipmapsCount=0;

//	try
	{
		VGColorInternalFormat procFormat = self->_colorFormat;
		procFormat = (VGColorInternalFormat)(procFormat | VGColorPREMULTIPLIED);	//premultiplied

		//generate mipmaps until width and height are one
		KGImage* prev = self;
		while( prev->_width > 1 || prev->_height > 1 )
		{
			int nextw = (int)ceil(prev->_width*0.5f);
			int nexth = (int)ceil(prev->_height*0.5f);
			RI_ASSERT(nextw >= 1 && nexth >= 1);
			RI_ASSERT(nextw < prev->_width || nexth < prev->_height);

            if(self->_mipmapsCount+1>self->_mipmapsCapacity){
             if(self->_mipmapsCapacity==0)
              self->_mipmapsCapacity=self->_mipmapsCount+1;
             else
              self->_mipmapsCapacity*=2;
              
             self->_mipmaps=(KGSurface **)NSZoneRealloc(NULL,self->_mipmaps,sizeof(KGSurface *)*self->_mipmapsCapacity);
            }
            self->_mipmapsCount++;
			self->_mipmaps[self->_mipmapsCount-1] = NULL;

			KGSurface* next =[[KGSurface alloc] initWithBytes:NULL width:nextw height:nexth bitsPerComponent:self->_bitsPerComponent bytesPerRow:self->_bytesPerRow colorSpace:self->_colorSpace bitmapInfo:self->_bitmapInfo];
            
            int j;
			for(j=0;j<KGImageGetHeight(next);j++)
			{
				for(i=0;i<KGImageGetWidth(next);i++)
				{
					CGFloat u0 = (CGFloat)i / (CGFloat)KGImageGetWidth(next);
					CGFloat u1 = (CGFloat)(i+1) / (CGFloat)KGImageGetWidth(next);
					CGFloat v0 = (CGFloat)j / (CGFloat)KGImageGetHeight(next);
					CGFloat v1 = (CGFloat)(j+1) / (CGFloat)KGImageGetHeight(next);

					u0 *= prev->_width;
					u1 *= prev->_width;
					v0 *= prev->_height;
					v1 *= prev->_height;

					int su = RI_FLOOR_TO_INT(u0);
					int eu = (int)ceil(u1);
					int sv = RI_FLOOR_TO_INT(v0);
					int ev = (int)ceil(v1);

					VGColor c=VGColorRGBA(0,0,0,0,procFormat);
					int samples = 0;
                    int y;
					for(y=sv;y<ev;y++)
					{
                        int x;
						for(x=su;x<eu;x++)
						{
							VGColor p = KGSurfaceReadPixel(prev,x, y);
							p=VGColorConvert(p,procFormat);
							c=VGColorAdd(c, p);
							samples++;
						}
					}
					c=VGColorMultiplyByFloat(c,(1.0f/samples));
					c=VGColorConvert(c,self->_colorFormat);
					KGSurfaceWritePixel(next,i,j,c);
				}
			}
			self->_mipmaps[self->_mipmapsCount-1] = next;
			prev = next;
		}
		RI_ASSERT(prev->_width == 1 && prev->_height == 1);
		self->m_mipmapsValid = YES;
	}
#if 0
	catch(std::bad_alloc)
	{
		//delete existing mipmaps
		for(int i=0;i<self->_mipmapsCount;i++)
		{
			if(self->_mipmaps[i])
			{
					[self->_mipmaps[i] release];
			}
		}
		self->_mipmapsCount=0;
		self->m_mipmapsValid = NO;
		throw;
	}
#endif
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

KGImage *KGImageMipMapForLevel(KGImage *self,int level){
	KGImage* image = self;
    
	if( level > 0 ){
		RI_ASSERT(level <= self->_mipmapsCount);
		image = self->_mipmaps[level-1];
	}
	RI_ASSERT(image);
    return image;
}


void KGImageEWAOnMipmaps_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   int i;
   		CGFloat m_pixelFilterRadius = 1.25f;
		CGFloat m_resamplingFilterRadius = 1.25f;

   KGImageMakeMipMaps(self);
   
   CGPoint uv=CGPointMake(0,0);
   uv=CGPointApplyAffineTransform(uv,surfaceToImage);

   
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
        KGImage *mipmap=KGImageMipMapForLevel(self,level);
        
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
          
         return ;
        }
		CGFloat ooF = 1.0f / F;
		A *= ooF;
		B *= ooF;
		C *= ooF;

   for(i=0;i<length;i++,x++){
    uv=CGPointMake(x+0.5f,y+0.5f);
    uv=CGPointApplyAffineTransform(uv,surfaceToImage);
   
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
            KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(mipmap,u1, v,texel,(u2-u1));
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
}

static inline int cubic_8(int v0,int v1,int v2,int v3,int fraction){
  int p = (v3 - v2) - (v0 - v1);
  int q = (v0 - v1) - p;

  return RI_INT_CLAMP((p * (fraction*fraction*fraction))/(256*256*256) + (q * fraction*fraction)/(256*256) + ((v2 - v0) * fraction)/256 + v1,0,255);
}

static inline KGRGBA8888 bicubic_lRGBA8888_PRE(KGRGBA8888 a,KGRGBA8888 b,KGRGBA8888 c,KGRGBA8888 d,int fraction) {
  return KGRGBA8888Init(
   cubic_8(a.r, b.r, c.r, d.r, fraction),
   cubic_8(a.g, b.g, c.g, d.g, fraction),
   cubic_8(a.b, b.b, c.b, d.b, fraction),
   cubic_8(a.a, b.a, c.a, d.a, fraction));
}

void KGImageBicubic_lRGBA8888_PRE(KGImage *self,int x, int y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    uv.x -= 0.5f;
    uv.y -= 0.5f;
    int u = RI_FLOOR_TO_INT(uv.x);
    int ufrac=coverageFromZeroToOne(uv.x-u);
        
    int v = RI_FLOOR_TO_INT(uv.y);
    int vfrac=coverageFromZeroToOne(uv.y-v);
        
    KGRGBA8888 t0,t1,t2,t3;
    KGRGBA8888 cspan[4];
     
    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v - 1,cspan,4);
    t0 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
      
    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v,cspan,4);
    t1 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v+1,cspan,4);     
    t2 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v+2,cspan,4);     
    t3 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);

    span[i]=bicubic_lRGBA8888_PRE(t0,t1,t2,t3, vfrac);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

static inline float cubic_f(float v0,float v1,float v2,float v3,float fraction){
  float p = (v3 - v2) - (v0 - v1);
  float q = (v0 - v1) - p;

  return RI_CLAMP((p * (fraction*fraction*fraction)) + (q * fraction*fraction) + ((v2 - v0) * fraction) + v1,0,1);
}

KGRGBAffff bicubic_lRGBAffff_PRE(KGRGBAffff a,KGRGBAffff b,KGRGBAffff c,KGRGBAffff d,float fraction) {
  return KGRGBAffffInit(
   cubic_f(a.r, b.r, c.r, d.r, fraction),
   cubic_f(a.g, b.g, c.g, d.g, fraction),
   cubic_f(a.b, b.b, c.b, d.b, fraction),
   cubic_f(a.a, b.a, c.a, d.a, fraction));
}

void KGImageBicubic_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    uv.x -= 0.5f;
    uv.y -= 0.5f;
    int u = RI_FLOOR_TO_INT(uv.x);
    float ufrac=uv.x-u;
        
    int v = RI_FLOOR_TO_INT(uv.y);
    float vfrac=uv.y-v;
        
    KGRGBAffff t0,t1,t2,t3;
    KGRGBAffff cspan[4];
     
    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v - 1,cspan,4);
    t0 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
      
    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v,cspan,4);
    t1 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v+1,cspan,4);     
    t2 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v+2,cspan,4);     
    t3 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);

    span[i]=bicubic_lRGBAffff_PRE(t0,t1,t2,t3, vfrac);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void KGImageBilinear_lRGBA8888_PRE(KGImage *self,int x, int y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);
    uv.x-=0.5f;
    uv.y-=0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	KGRGBA8888 c00c01[2];
    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u,v,c00c01,2);

    KGRGBA8888 c01c11[2];
    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u,v+1,c01c11,2);

    int fu = coverageFromZeroToOne(uv.x - (CGFloat)u);
    int oneMinusFu=inverseCoverage(fu);
    int fv = coverageFromZeroToOne(uv.y - (CGFloat)v);
    int oneMinusFv=inverseCoverage(fv);
    KGRGBA8888 c0 = KGRGBA8888Add(KGRGBA8888MultiplyByCoverage(c00c01[0],oneMinusFu),KGRGBA8888MultiplyByCoverage(c00c01[1],fu));
    KGRGBA8888 c1 = KGRGBA8888Add(KGRGBA8888MultiplyByCoverage(c01c11[0],oneMinusFu),KGRGBA8888MultiplyByCoverage(c01c11[1],fu));
    span[i]=KGRGBA8888Add(KGRGBA8888MultiplyByCoverage(c0,oneMinusFv),KGRGBA8888MultiplyByCoverage(c1, fv));
    
    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}


void KGImageBilinear_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;

   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    uv.x -= 0.5f;
	uv.y -= 0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	KGRGBAffff c00c01[2];
    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u,v,c00c01,2);

    KGRGBAffff c01c11[2];
    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u,v+1,c01c11,2);

    CGFloat fu = uv.x - (CGFloat)u;
    CGFloat fv = uv.y - (CGFloat)v;
    KGRGBAffff c0 = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c00c01[0],(1.0f - fu)),KGRGBAffffMultiplyByFloat(c00c01[1],fu));
    KGRGBAffff c1 = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c01c11[0],(1.0f - fu)),KGRGBAffffMultiplyByFloat(c01c11[1],fu));
    span[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c0,(1.0f - fv)),KGRGBAffffMultiplyByFloat(c1, fv));

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void KGImagePointSampling_lRGBA8888_PRE(KGImage *self,int x, int y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    KGImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void KGImagePointSampling_lRGBAffff_PRE(KGImage *self,int x, int y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    KGImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

//clamp premultiplied color to alpha to enforce consistency
static void clampSpan_lRGBAffff_PRE(KGRGBAffff *span,int length){
   int i;
   
   for(i=0;i<length;i++){
    span[i].r = RI_MIN(span[i].r, span[i].a);
    span[i].g = RI_MIN(span[i].g, span[i].a);
    span[i].b = RI_MIN(span[i].b, span[i].a);
   }
}

KGRGBAffff *KGImageReadSpan_lRGBAffff_PRE(KGImage *self,int x,int y,KGRGBAffff *span,int length) {
   VGColorInternalFormat format=self->_colorFormat;
   
   KGRGBAffff *direct=self->_read_lRGBAffff_PRE(self,x,y,span,length);
   
   if(direct!=NULL)
    span=direct;
    
   if(format&VGColorNONLINEAR){
    KGRGBAffffConvertSpan(span,length,format,VGColor_lRGBA_PRE);
   }
   if(!(format&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(span,length);
    format|=VGColorPREMULTIPLIED;
   }
   else {
    if(self->_clampExternalPixels)
      clampSpan_lRGBAffff_PRE(span,length); // We don't need to do this for internally generated images (context)
   }
   return NULL;
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads the pixel (x,y) and converts it into an alpha mask value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

uint8_t *KGImageReadSpan_A8_MASK(KGImage *self,int x,int y,uint8_t *coverage,int length){
   return self->_readA8(self,x,y,coverage,length);
}

CGFloat *KGImageReadSpan_Af_MASK(KGImage *self,int x,int y,CGFloat *coverage,int length) {
   return self->_readAf(self,x,y,coverage,length);
}


/*-------------------------------------------------------------------*//*!
* \brief	Maps point (x,y) to an image and returns a filtered,
*			premultiplied color value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGImageReadTexelTileRepeat(KGImage *self,int u, int v, KGRGBAffff *span,int length){
   int i;

   v = RI_INT_MOD(v, self->_height);
   
   for(i=0;i<length;i++,u++){
    u = RI_INT_MOD(u, self->_width);

    KGRGBAffff *direct=KGImageReadSpan_lRGBAffff_PRE(self,u,v,span+i,1);
    if(direct!=NULL)
     span[i]=direct[0];
   }
}

void KGImagePattern_Bilinear(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    uv.x -= 0.5f;
	uv.y -= 0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	KGRGBAffff c00c01[2];
    KGImageReadTexelTileRepeat(self,u,v,c00c01,2);

    KGRGBAffff c01c11[2];
    KGImageReadTexelTileRepeat(self,u,v+1,c01c11,2);

    CGFloat fu = uv.x - (CGFloat)u;
    CGFloat fv = uv.y - (CGFloat)v;
    KGRGBAffff c0 = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c00c01[0],(1.0f - fu)),KGRGBAffffMultiplyByFloat(c00c01[1],fu));
    KGRGBAffff c1 = KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c01c11[0],(1.0f - fu)),KGRGBAffffMultiplyByFloat(c01c11[1],fu));
    span[i]=KGRGBAffffAdd(KGRGBAffffMultiplyByFloat(c0,(1.0f - fv)),KGRGBAffffMultiplyByFloat(c1, fv));

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void KGImagePattern_PointSampling(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage){	//point sampling
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    CGPoint uv=CGPointMake(du,dv);

    KGImageReadTexelTileRepeat(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void KGImageReadPatternSpan_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y, KGRGBAffff *span,int length, CGAffineTransform surfaceToImage, CGPatternTiling distortion)	{
    
   switch(distortion){
    case kCGPatternTilingNoDistortion:
      KGImagePattern_PointSampling(self,x,y,span,length,surfaceToImage);
      break;

    case kCGPatternTilingConstantSpacingMinimalDistortion:
    case kCGPatternTilingConstantSpacing:
     default:
      KGImagePattern_Bilinear(self,x,y,span,length,surfaceToImage);
      break;
   }
}


@end
