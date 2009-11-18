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

#import "O2Image.h"
#import "O2Surface.h"
#import "O2ColorSpace.h"
#import "O2DataProvider.h"
#import "O2Exceptions.h"
#import <Foundation/NSData.h>

@implementation O2Image

/*-------------------------------------------------------------------*//*!
* \brief	Creates a pixel format descriptor out of O2ImageFormat
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGPixelDecode O2ImageParametersToPixelLayout(O2ImageFormat format,size_t *bitsPerPixel,VGColorInternalFormat	*colorFormat){
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

static BOOL initFunctionsForRGBColorSpace(O2Image *self,size_t bitsPerComponent,size_t bitsPerPixel,O2BitmapInfo bitmapInfo){   

   switch(bitsPerComponent){
   
    case 32:
     switch(bitsPerPixel){
      case 32:
       break;
      case 128:
       switch(bitmapInfo&kO2BitmapByteOrderMask){
        case kO2BitmapByteOrder16Little:
        case kO2BitmapByteOrder32Little:
         self->_read_lRGBAffff_PRE=O2ImageRead_RGBAffffLittle_to_RGBAffff;
         return YES;
         
        case kO2BitmapByteOrder16Big:
        case kO2BitmapByteOrder32Big:
         self->_read_lRGBAffff_PRE=O2ImageRead_RGBAffffBig_to_RGBAffff;
         return YES;
       }
     }
     break;
        
    case  8:
     switch(bitsPerPixel){
     
      case 8:
       self->_readA8=O2ImageRead_G8_to_A8;
       self->_read_lRGBA8888_PRE=O2ImageRead_G8_to_RGBA8888;
       return YES;
      
      case 16:
       self->_read_lRGBA8888_PRE=O2ImageRead_GA88_to_RGBA8888;
       return YES;
       
      case 24:
       switch(bitmapInfo&kO2BitmapAlphaInfoMask){
        case kO2ImageAlphaNone:
          // FIXME: how is endian ness interpreted ?
         self->_read_lRGBA8888_PRE=O2ImageRead_RGB888_to_RGBA8888;
         return YES;
       }
       break;
       
      case 32:
        switch(bitmapInfo&kO2BitmapAlphaInfoMask){
         case kO2ImageAlphaNone:
          break;
          
         case kO2ImageAlphaLast:
         case kO2ImageAlphaPremultipliedLast:
          switch(bitmapInfo&kO2BitmapByteOrderMask){
           case kO2BitmapByteOrder16Little:
           case kO2BitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=O2ImageRead_ABGR8888_to_RGBA8888;
            return YES;

           case kO2BitmapByteOrder16Big:
           case kO2BitmapByteOrder32Big:
            self->_read_lRGBA8888_PRE=O2ImageRead_RGBA8888_to_RGBA8888;
            return YES;
          }
          break;

         case kO2ImageAlphaPremultipliedFirst:
          switch(bitmapInfo&kO2BitmapByteOrderMask){
           case kO2BitmapByteOrder16Little:
           case kO2BitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=O2ImageRead_BGRA8888_to_RGBA8888;
            return YES;
          }
          break;
                    
         case kO2ImageAlphaFirst:
          break;
          
         case kO2ImageAlphaNoneSkipLast:
          switch(bitmapInfo&kO2BitmapByteOrderMask){
           case kO2BitmapByteOrder16Little:
           case kO2BitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=O2ImageRead_ABGR8888_to_RGBA8888;
            return YES;

           case kO2BitmapByteOrder16Big:
           case kO2BitmapByteOrder32Big:
            self->_read_lRGBA8888_PRE=O2ImageRead_RGBA8888_to_RGBA8888;
            return YES;
          }
          break;
          
         case kO2ImageAlphaNoneSkipFirst:
          switch(bitmapInfo&kO2BitmapByteOrderMask){
           
           case kO2BitmapByteOrder16Little:
           case kO2BitmapByteOrder32Little:
            self->_read_lRGBA8888_PRE=O2ImageRead_BGRX8888_to_RGBA8888;
            return YES;

           case kO2BitmapByteOrder16Big:
           case kO2BitmapByteOrder32Big:
            self->_read_lRGBA8888_PRE=O2ImageRead_XRGB8888_to_RGBA8888;
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
       if(bitmapInfo==(kO2BitmapByteOrder16Little|kO2ImageAlphaNoneSkipFirst)){
        self->_read_lRGBA8888_PRE=O2ImageRead_G3B5X1R5G2_to_RGBA8888;
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
       switch(bitmapInfo&kO2BitmapByteOrderMask){
        case kO2BitmapByteOrder16Little:
        case kO2BitmapByteOrder32Little:
         self->_read_lRGBA8888_PRE=O2ImageRead_BARG4444_to_RGBA8888;
         return YES;
         
        case kO2BitmapByteOrder16Big:
        case kO2BitmapByteOrder32Big:
         self->_read_lRGBA8888_PRE=O2ImageRead_RGBA4444_to_RGBA8888;
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
       self->_read_lRGBA8888_PRE=O2ImageRead_RGBA2222_to_RGBA8888;
       return YES;
     }
     break;

    case  1:
     switch(bitsPerPixel){
      case 1:
    //   self->_read_lRGBAffff_PRE=O2ImageReadPixelSpan_01;
     //  return YES;
       
      case 3:
       break;
     }
     break;
   }
   return NO;
      
}

static BOOL initFunctionsForCMYKColorSpace(O2Image *self,size_t bitsPerComponent,size_t bitsPerPixel,O2BitmapInfo bitmapInfo){   
   switch(bitsPerComponent){
        
    case  8:
     switch(bitsPerPixel){
     
      case 32:
        switch(bitmapInfo&kO2BitmapByteOrderMask){
         case kO2BitmapByteOrder16Big:
         case kO2BitmapByteOrder32Big:
          self->_read_lRGBA8888_PRE=O2ImageRead_CMYK8888_to_RGBA8888;
          return YES;
        }
       break;
     }
     break;
   }
   return NO;
}

static BOOL initFunctionsForIndexedColorSpace(O2Image *self,size_t bitsPerComponent,size_t bitsPerPixel,O2ColorSpaceRef colorSpace,O2BitmapInfo bitmapInfo){

   switch([[(O2ColorSpace_indexed *)colorSpace baseColorSpace] type]){
    case O2ColorSpaceDeviceRGB:
     self->_read_lRGBA8888_PRE=O2ImageRead_I8_to_RGBA8888;
     return YES;
   }
   
   return NO;
}

static BOOL initFunctionsForParameters(O2Image *self,size_t bitsPerComponent,size_t bitsPerPixel,O2ColorSpaceRef colorSpace,O2BitmapInfo bitmapInfo){

   self->_readA8=O2ImageRead_ANY_to_RGBA8888_to_A8;
   self->_readAf=O2ImageRead_ANY_to_A8_to_Af;
   self->_read_lRGBAffff_PRE=O2ImageRead_ANY_to_RGBA8888_to_RGBAffff;

   if((bitmapInfo&kO2BitmapByteOrderMask)==kO2BitmapByteOrderDefault)
    bitmapInfo|=kO2BitmapByteOrder32Big;
   
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

-initWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(unsigned)bitmapInfo provider:(O2DataProvider *)provider decode:(const O2Float *)decode interpolate:(BOOL)interpolate renderingIntent:(O2ColorRenderingIntent)renderingIntent {
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
    NSLog(@"O2Image failed to init with bpc=%d, bpp=%d,colorSpace=%@,bitmapInfo=0x%0X",bitsPerComponent,bitsPerPixel,colorSpace,bitmapInfo);
    [self dealloc];
    return nil;
   }
   
    O2ImageFormat imageFormat=VG_lRGBA_8888;
    switch(bitmapInfo&kO2BitmapAlphaInfoMask){
     case kO2ImageAlphaPremultipliedLast:
     case kO2ImageAlphaPremultipliedFirst:
      imageFormat|=VGColorPREMULTIPLIED;
      break;
      
     case kO2ImageAlphaNone:
     case kO2ImageAlphaLast:
     case kO2ImageAlphaFirst:
     case kO2ImageAlphaNoneSkipLast:
     case kO2ImageAlphaNoneSkipFirst:
      break;
    }
    
    size_t checkBPP;
	O2ImageParametersToPixelLayout(imageFormat,&checkBPP,&(self->_colorFormat));
    RI_ASSERT(checkBPP==bitsPerPixel);
    m_mipmapsValid=NO;
    _mipmapsCount=0;
    _mipmapsCapacity=0;
    _mipmaps=NULL;
   return self;
}

-initWithJPEGDataProvider:(O2DataProvider *)jpegProvider decode:(const O2Float *)decode interpolate:(BOOL)interpolate renderingIntent:(O2ColorRenderingIntent)renderingIntent {
   O2UnimplementedMethod();
   return nil;
}

-initWithPNGDataProvider:(O2DataProvider *)jpegProvider decode:(const O2Float *)decode interpolate:(BOOL)interpolate renderingIntent:(O2ColorRenderingIntent)renderingIntent {
   O2UnimplementedMethod();
   return nil;
}

-initMaskWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow provider:(O2DataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate {
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

-(O2Image *)copyWithColorSpace:(O2ColorSpaceRef)colorSpace {
   O2UnimplementedMethod();
   return nil;
}

-(O2Image *)childImageInRect:(O2Rect)rect {
   O2UnimplementedMethod();
   return nil;
}

-(void)addMask:(O2Image *)image {
   [image retain];
   [_mask release];
   _mask=image;
}

-copyWithMask:(O2Image *)image {
   O2UnimplementedMethod();
   return nil;
}

-copyWithMaskingColors:(const O2Float *)components {
   O2UnimplementedMethod();
   return nil;
}

static inline const void *directBytes(O2Image *self){
   if(self->_directBytes==NULL){
    if([self->_provider isDirectAccess]){
     self->_directData=[[self->_provider data] retain];
     self->_directBytes=[self->_provider bytes];
     self->_directLength=[self->_provider length];
   }
    else {
     self->_directData=O2DataProviderCopyData(self->_provider);
     self->_directBytes=[self->_directData bytes];
     self->_directLength=[self->_directData length];
    }
   }
   return self->_directBytes;
}

static inline const void *scanlineAtY(O2Image *self,int y){
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

O2ImageRef O2ImageCreate(size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,O2ColorSpaceRef colorSpace,O2BitmapInfo bitmapInfo,O2DataProviderRef dataProvider,const O2Float *decode,BOOL shouldInterpolate,O2ColorRenderingIntent renderingIntent) {
   return [[O2Image alloc] initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo provider:dataProvider decode:decode interpolate:shouldInterpolate renderingIntent:renderingIntent];
}

O2ImageRef O2ImageMaskCreate(size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,O2DataProviderRef dataProvider,const O2Float *decode,BOOL shouldInterpolate) {
   return [[O2Image alloc] initMaskWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow provider:dataProvider decode:decode interpolate:shouldInterpolate];
}

O2ImageRef O2ImageCreateCopy(O2ImageRef self) {
   return [self copy];
}

O2ImageRef O2ImageCreateCopyWithColorSpace(O2ImageRef self,O2ColorSpaceRef colorSpace) {
   return [self copyWithColorSpace:colorSpace];
}

O2ImageRef O2ImageCreateWithJPEGDataProvider(O2DataProviderRef jpegProvider,const O2Float *decode,BOOL interpolate,O2ColorRenderingIntent renderingIntent) {
   return [[O2Image alloc] initWithJPEGDataProvider:jpegProvider decode:decode interpolate:interpolate renderingIntent:renderingIntent];
}

O2ImageRef O2ImageCreateWithPNGDataProvider(O2DataProviderRef pngProvider,const O2Float *decode,BOOL interpolate,O2ColorRenderingIntent renderingIntent) {
   return [[O2Image alloc] initWithPNGDataProvider:pngProvider decode:decode interpolate:interpolate renderingIntent:renderingIntent];
}

O2ImageRef O2ImageCreateWithImageInRect(O2ImageRef self,O2Rect rect) {
   return [self childImageInRect:rect];
}

O2ImageRef O2ImageCreateWithMask(O2ImageRef self,O2ImageRef mask) {
   return [self copyWithMask:mask];
}

O2ImageRef O2ImageCreateWithMaskingColors(O2ImageRef self,const O2Float *components) {
   return [self copyWithMaskingColors:components];
}

O2ImageRef O2ImageRetain(O2ImageRef self) {
   return [self retain];
}

void O2ImageRelease(O2ImageRef self) {
   [self release];
}

BOOL O2ImageIsMask(O2ImageRef self) {
   return self->_isMask;
}

size_t O2ImageGetWidth(O2Image *self) {
   return self->_width;
}

size_t O2ImageGetHeight(O2Image *self) {
   return self->_height;
}

size_t O2ImageGetBitsPerComponent(O2ImageRef self) {
   return self->_bitsPerComponent;
}

size_t O2ImageGetBitsPerPixel(O2ImageRef self) {
   return self->_bitsPerPixel;
}

size_t O2ImageGetBytesPerRow(O2ImageRef self) {
   return self->_bytesPerRow;
}

O2ColorSpaceRef O2ImageGetColorSpace(O2ImageRef self) {
   return self->_colorSpace;
}

O2ImageAlphaInfo O2ImageGetAlphaInfo(O2ImageRef self) {
   return self->_bitmapInfo&kO2BitmapAlphaInfoMask;
}

O2DataProviderRef O2ImageGetDataProvider(O2ImageRef self) {
   return self->_provider;
}

const O2Float *O2ImageGetDecode(O2ImageRef self) {
   return self->_decode;
}

BOOL O2ImageGetShouldInterpolate(O2ImageRef self) {
   return self->_interpolate;
}

O2ColorRenderingIntent O2ImageGetRenderingIntent(O2ImageRef self) {
   return self->_renderingIntent;
}

O2BitmapInfo O2ImageGetBitmapInfo(O2ImageRef self) {
   return self->_bitmapInfo;
}

O2argb32f *O2ImageRead_ANY_to_RGBA8888_to_RGBAffff(O2Image *self,int x,int y,O2argb32f *span,int length){
   O2argb8u *span8888=__builtin_alloca(length*sizeof(O2argb8u));
   O2argb8u *direct=self->_read_lRGBA8888_PRE(self,x,y,span8888,length);
   
   if(direct!=NULL)
    span8888=direct;
    
   int i;
   for(i=0;i<length;i++){
    O2argb32f  result;
    
    result.r = O2Float32FromByte(span8888[i].r);
    result.g = O2Float32FromByte(span8888[i].g);
    result.b = O2Float32FromByte(span8888[i].b);
	result.a = O2Float32FromByte(span8888[i].a);
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

O2argb32f *O2ImageRead_RGBAffffLittle_to_RGBAffff(O2Image *self,int x,int y,O2argb32f *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;
    
   scanline+=x*16;
   for(i=0;i<length;i++){
    O2argb32f result;
    
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

O2argb32f *O2ImageRead_RGBAffffBig_to_RGBAffff(O2Image *self,int x,int y,O2argb32f *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;
    
   scanline+=x*16;
   for(i=0;i<length;i++){
    O2argb32f result;
    
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

uint8_t *O2ImageRead_G8_to_A8(O2Image *self,int x,int y,uint8_t *alpha,int length) {
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

uint8_t *O2ImageRead_ANY_to_RGBA8888_to_A8(O2Image *self,int x,int y,uint8_t *alpha,int length) {
   O2argb8u *span=__builtin_alloca(length*sizeof(O2argb8u));
   int i;
   
   O2argb8u *direct=self->_read_lRGBA8888_PRE(self,x,y,span,length);
   if(direct!=NULL)
    span=direct;
    
   for(i=0;i<length;i++){
    *alpha++=span[i].a;
   }
   return NULL;
}

O2Float *O2ImageRead_ANY_to_A8_to_Af(O2Image *self,int x,int y,O2Float *alpha,int length) {
   uint8_t span[length];
   int     i;
   
   self->_readA8(self,x,y,span,length);
   for(i=0;i<length;i++)
    alpha[i]=O2Float32FromByte(span[i]);
    
   return NULL;
}

O2argb8u *O2ImageRead_G8_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;

   if(scanline==NULL)
    return NULL;
    
   scanline+=x;
   for(i=0;i<length;i++){
    O2argb8u result;
    
    result.r=*scanline++;
    result.g=result.r;
    result.b=result.r;
    result.a=0xFF;
    
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_GA88_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;

   if(scanline==NULL)
    return NULL;
    
   scanline+=x*2;
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.r = *scanline++;
    result.g=result.r;
    result.b=result.r;
	result.a = *scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_RGBA8888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.r = *scanline++;
    result.g = *scanline++;
    result.b = *scanline++;
	result.a = *scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_ABGR8888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.a = *scanline++;
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_BGRA8888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
#ifdef __LITTLE_ENDIAN__
   return (O2argb8u *)scanline;
#endif
   
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    result.a = *scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_RGB888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*3;
   
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.r = *scanline++;
    result.g = *scanline++;
	result.b = *scanline++;
    result.a = 255;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_BGRX8888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;

   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.b = *scanline++;
    result.g = *scanline++;
	result.r = *scanline++;
    result.a = 255; scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_XRGB8888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length) {
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.a = *scanline++;
    result.r = *scanline++;
	result.g = *scanline++;
    result.b = *scanline++;
    *span++=result;
   }
   return NULL;
}

// kO2BitmapByteOrder16Little|kO2ImageAlphaNoneSkipFirst
O2argb8u *O2ImageRead_G3B5X1R5G2_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*2;
   for(i=0;i<length;i++){
    unsigned short low=*scanline++;
    unsigned short high=*scanline;
    unsigned short value=low|(high<<8);
    O2argb8u  result;
    
    result.r = ((value>>10)&0x1F)<<3;
    result.g = ((value>>5)&0x1F)<<3;
    result.b = ((value&0x1F)<<3);
    result.a = 255;
    scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_RGBA4444_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*2;
   for(i=0;i<length;i++){
    O2argb8u  result;
    
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

O2argb8u *O2ImageRead_BARG4444_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*2;
   for(i=0;i<length;i++){
    O2argb8u  result;
    
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

O2argb8u *O2ImageRead_RGBA2222_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x;
   for(i=0;i<length;i++){
    O2argb8u  result;
    
    result.r = *scanline&0xC0;
    result.g = (*scanline&0x03)<<2;
    result.b = (*scanline&0x0C)<<4;
	result.a = (*scanline&0x03)<<6;
    scanline++;
    *span++=result;
   }
   return NULL;
}

O2argb8u *O2ImageRead_CMYK8888_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length){
// poor results
   const uint8_t *scanline = scanlineAtY(self,y);
   int i;
   
   if(scanline==NULL)
    return NULL;

   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb8u  result;
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

O2argb8u *O2ImageRead_I8_to_RGBA8888(O2Image *self,int x,int y,O2argb8u *span,int length) {
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
    O2argb8u argb;

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

/* O2ImageReadTileSpanExtendEdge__ is used by the image resampling functions to read
   translated spans. When a coordinate is outside the image it uses the edge
   value. This works better than say, zero, with averaging algorithms (bilinear,bicubic, etc)
   as you get good values at the edges.
   
   Ideally the averaging algorithms would only use the available pixels on the edges */
   
void O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(O2Image *self,int u, int v, O2argb8u *span,int length){
   int i;
   O2argb8u *direct;
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

void O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(O2Image *self,int u, int v, O2argb32f *span,int length){
   int i;
   O2argb32f *direct;
   
   v = RI_INT_CLAMP(v,0,self->_height-1);
   
   for(i=0;i<length && u<0;u++,i++){
    direct=O2ImageReadSpan_lRGBAffff_PRE(self,0,v,span+i,1);
    if(direct!=NULL)
     span[i]=direct[0];
   }
   
   int chunk=RI_MIN(length-i,self->_width-u);
   direct=O2ImageReadSpan_lRGBAffff_PRE(self,u,v,span+i,chunk);
   if(direct!=NULL) {
    int k;
    
    for(k=0;k<chunk;k++)
     span[i+k]=direct[k];
   }
   i+=chunk;
   u+=chunk;

   for(;i<length;i++){
    direct=O2ImageReadSpan_lRGBAffff_PRE(self,self->_width-1,v,span+i,1);
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

void O2ImageMakeMipMaps(O2Image *self) {
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
		O2Image* prev = self;
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
              
             self->_mipmaps=(O2Surface **)NSZoneRealloc(NULL,self->_mipmaps,sizeof(O2Surface *)*self->_mipmapsCapacity);
            }
            self->_mipmapsCount++;
			self->_mipmaps[self->_mipmapsCount-1] = NULL;

			O2Surface* next =[[O2Surface alloc] initWithBytes:NULL width:nextw height:nexth bitsPerComponent:self->_bitsPerComponent bytesPerRow:self->_bytesPerRow colorSpace:self->_colorSpace bitmapInfo:self->_bitmapInfo];
            
            int j;
			for(j=0;j<O2ImageGetHeight(next);j++)
			{
				for(i=0;i<O2ImageGetWidth(next);i++)
				{
					O2Float u0 = (O2Float)i / (O2Float)O2ImageGetWidth(next);
					O2Float u1 = (O2Float)(i+1) / (O2Float)O2ImageGetWidth(next);
					O2Float v0 = (O2Float)j / (O2Float)O2ImageGetHeight(next);
					O2Float v1 = (O2Float)(j+1) / (O2Float)O2ImageGetHeight(next);

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
							VGColor p = O2SurfaceReadPixel(prev,x, y);
							p=VGColorConvert(p,procFormat);
							c=VGColorAdd(c, p);
							samples++;
						}
					}
					c=VGColorMultiplyByFloat(c,(1.0f/samples));
					c=VGColorConvert(c,self->_colorFormat);
					O2SurfaceWritePixel(next,i,j,c);
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

O2Image *O2ImageMipMapForLevel(O2Image *self,int level){
	O2Image* image = self;
    
	if( level > 0 ){
		RI_ASSERT(level <= self->_mipmapsCount);
		image = self->_mipmaps[level-1];
	}
	RI_ASSERT(image);
    return image;
}


void O2ImageEWAOnMipmaps_lRGBAffff_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage){
   int i;
   		O2Float m_pixelFilterRadius = 1.25f;
		O2Float m_resamplingFilterRadius = 1.25f;

   O2ImageMakeMipMaps(self);
   
   O2Point uv=O2PointMake(0,0);
   uv=O2PointApplyAffineTransform(uv,surfaceToImage);

   
		O2Float Ux = (surfaceToImage.a ) * m_pixelFilterRadius;
		O2Float Vx = (surfaceToImage.b ) * m_pixelFilterRadius;
		O2Float Uy = (surfaceToImage.c ) * m_pixelFilterRadius;
		O2Float Vy = (surfaceToImage.d ) * m_pixelFilterRadius;

		//calculate mip level
		int level = 0;
		O2Float axis1sq = Ux*Ux + Vx*Vx;
		O2Float axis2sq = Uy*Uy + Vy*Vy;
		O2Float minorAxissq = RI_MIN(axis1sq,axis2sq);
		while(minorAxissq > 9.0f && level < self->_mipmapsCount)	//half the minor axis must be at least three texels
		{
			level++;
			minorAxissq *= 0.25f;
		}

		O2Float sx = 1.0f;
		O2Float sy = 1.0f;
		if(level > 0)
		{
			sx = (O2Float)O2ImageGetWidth(self->_mipmaps[level-1]) / (O2Float)self->_width;
			sy = (O2Float)O2ImageGetHeight(self->_mipmaps[level-1]) / (O2Float)self->_height;
		}
        O2Image *mipmap=O2ImageMipMapForLevel(self,level);
        
		Ux *= sx;
		Vx *= sx;
		Uy *= sy;
		Vy *= sy;

		//clamp filter size so that filtering doesn't take excessive amount of time (clamping results in aliasing)
		O2Float lim = 100.0f;
		axis1sq = Ux*Ux + Vx*Vx;
		axis2sq = Uy*Uy + Vy*Vy;
		if( axis1sq > lim*lim )
		{
			O2Float s = lim / (O2Float)sqrt(axis1sq);
			Ux *= s;
			Vx *= s;
		}
		if( axis2sq > lim*lim )
		{
			O2Float s = lim / (O2Float)sqrt(axis2sq);
			Uy *= s;
			Vy *= s;
		}

		//form elliptic filter by combining texel and pixel filters
		O2Float A = Vx*Vx + Vy*Vy + 1.0f;
		O2Float B = -2.0f*(Ux*Vx + Uy*Vy);
		O2Float C = Ux*Ux + Uy*Uy + 1.0f;
		//scale by the user-defined size of the kernel
		A *= m_resamplingFilterRadius;
		B *= m_resamplingFilterRadius;
		C *= m_resamplingFilterRadius;

		//calculate bounding box in texture space
		O2Float usize = (O2Float)sqrt(C);
		O2Float vsize = (O2Float)sqrt(A);

		//scale the filter so that Q = 1 at the cutoff radius
		O2Float F = A*C - 0.25f * B*B;
		if( F <= 0.0f ){
         for(i=0;i<length;i++)
		  span[i]=O2argb32fInit(0,0,0,0);	//invalid filter shape due to numerical inaccuracies => return black
          
         return ;
        }
		O2Float ooF = 1.0f / F;
		A *= ooF;
		B *= ooF;
		C *= ooF;

   for(i=0;i<length;i++,x++){
    uv=O2PointMake(x+0.5f,y+0.5f);
    uv=O2PointApplyAffineTransform(uv,surfaceToImage);
   
		O2Float U0 = uv.x;
		O2Float V0 = uv.y;
		U0 *= sx;
		V0 *= sy;
		
		int u1 = RI_FLOOR_TO_INT(U0 - usize + 0.5f);
		int u2 = RI_FLOOR_TO_INT(U0 + usize + 0.5f);
		int v1 = RI_FLOOR_TO_INT(V0 - vsize + 0.5f);
		int v2 = RI_FLOOR_TO_INT(V0 + vsize + 0.5f);
		if( u1 == u2 || v1 == v2 ){
			span[i]=O2argb32fInit(0,0,0,0);
            continue;
        }
        
		
		//evaluate filter by using forward differences to calculate Q = A*U^2 + B*U*V + C*V^2
		O2argb32f color=O2argb32fInit(0,0,0,0);
		O2Float sumweight = 0.0f;
		O2Float DDQ = 2.0f * A;
		O2Float U = (O2Float)u1 - U0 + 0.5f;
        int v;
        
		for(v=v1;v<v2;v++)
		{
			O2Float V = (O2Float)v - V0 + 0.5f;
			O2Float DQ = A*(2.0f*U+1.0f) + B*V;
			O2Float Q = (C*V+B*U)*V + A*U*U;
            int u;
            
            O2argb32f texel[u2-u1];
            O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(mipmap,u1, v,texel,(u2-u1));
			for(u=u1;u<u2;u++)
			{
				if( Q >= 0.0f && Q < 1.0f )
				{	//Q = r^2, fit gaussian to the range [0,1]
#if 0
					O2Float weight = (O2Float)expf(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
#else
					O2Float weight = (O2Float)fastExp(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
#endif
                    
					color=O2argb32fAdd(color,  O2argb32fMultiplyByFloat(texel[u-u1],weight));
					sumweight += weight;
				}
				Q += DQ;
				DQ += DDQ;
			}
		}
		if( sumweight == 0.0f ){
			span[i]=O2argb32fInit(0,0,0,0);
            continue;
        }
		RI_ASSERT(sumweight > 0.0f);
		sumweight = 1.0f / sumweight;
		span[i]=O2argb32fMultiplyByFloat(color,sumweight);
	}
}

static inline int cubic_8(int v0,int v1,int v2,int v3,int fraction){
  int p = (v3 - v2) - (v0 - v1);
  int q = (v0 - v1) - p;

  return RI_INT_CLAMP((p * (fraction*fraction*fraction))/(256*256*256) + (q * fraction*fraction)/(256*256) + ((v2 - v0) * fraction)/256 + v1,0,255);
}

static inline O2argb8u bicubic_lRGBA8888_PRE(O2argb8u a,O2argb8u b,O2argb8u c,O2argb8u d,int fraction) {
  return O2argb8uInit(
   cubic_8(a.r, b.r, c.r, d.r, fraction),
   cubic_8(a.g, b.g, c.g, d.g, fraction),
   cubic_8(a.b, b.b, c.b, d.b, fraction),
   cubic_8(a.a, b.a, c.a, d.a, fraction));
}

void O2ImageBicubic_lRGBA8888_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    uv.x -= 0.5f;
    uv.y -= 0.5f;
    int u = RI_FLOOR_TO_INT(uv.x);
    int ufrac=coverageFromZeroToOne(uv.x-u);
        
    int v = RI_FLOOR_TO_INT(uv.y);
    int vfrac=coverageFromZeroToOne(uv.y-v);
        
    O2argb8u t0,t1,t2,t3;
    O2argb8u cspan[4];
     
    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v - 1,cspan,4);
    t0 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
      
    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v,cspan,4);
    t1 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v+1,cspan,4);     
    t2 = bicubic_lRGBA8888_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u - 1,v+2,cspan,4);     
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

O2argb32f bicubic_lRGBAffff_PRE(O2argb32f a,O2argb32f b,O2argb32f c,O2argb32f d,float fraction) {
  return O2argb32fInit(
   cubic_f(a.r, b.r, c.r, d.r, fraction),
   cubic_f(a.g, b.g, c.g, d.g, fraction),
   cubic_f(a.b, b.b, c.b, d.b, fraction),
   cubic_f(a.a, b.a, c.a, d.a, fraction));
}

void O2ImageBicubic_lRGBAffff_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    uv.x -= 0.5f;
    uv.y -= 0.5f;
    int u = RI_FLOOR_TO_INT(uv.x);
    float ufrac=uv.x-u;
        
    int v = RI_FLOOR_TO_INT(uv.y);
    float vfrac=uv.y-v;
        
    O2argb32f t0,t1,t2,t3;
    O2argb32f cspan[4];
     
    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v - 1,cspan,4);
    t0 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
      
    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v,cspan,4);
    t1 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v+1,cspan,4);     
    t2 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);
     
    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u - 1,v+2,cspan,4);     
    t3 = bicubic_lRGBAffff_PRE(cspan[0],cspan[1],cspan[2],cspan[3],ufrac);

    span[i]=bicubic_lRGBAffff_PRE(t0,t1,t2,t3, vfrac);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void O2ImageBilinear_lRGBA8888_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);
    uv.x-=0.5f;
    uv.y-=0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	O2argb8u c00c01[2];
    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u,v,c00c01,2);

    O2argb8u c01c11[2];
    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,u,v+1,c01c11,2);

    int fu = coverageFromZeroToOne(uv.x - (O2Float)u);
    int oneMinusFu=inverseCoverage(fu);
    int fv = coverageFromZeroToOne(uv.y - (O2Float)v);
    int oneMinusFv=inverseCoverage(fv);
    O2argb8u c0 = O2argb8uAdd(O2argb8uMultiplyByCoverage(c00c01[0],oneMinusFu),O2argb8uMultiplyByCoverage(c00c01[1],fu));
    O2argb8u c1 = O2argb8uAdd(O2argb8uMultiplyByCoverage(c01c11[0],oneMinusFu),O2argb8uMultiplyByCoverage(c01c11[1],fu));
    span[i]=O2argb8uAdd(O2argb8uMultiplyByCoverage(c0,oneMinusFv),O2argb8uMultiplyByCoverage(c1, fv));
    
    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}


void O2ImageBilinear_lRGBAffff_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;

   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    uv.x -= 0.5f;
	uv.y -= 0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	O2argb32f c00c01[2];
    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u,v,c00c01,2);

    O2argb32f c01c11[2];
    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,u,v+1,c01c11,2);

    O2Float fu = uv.x - (O2Float)u;
    O2Float fv = uv.y - (O2Float)v;
    O2argb32f c0 = O2argb32fAdd(O2argb32fMultiplyByFloat(c00c01[0],(1.0f - fu)),O2argb32fMultiplyByFloat(c00c01[1],fu));
    O2argb32f c1 = O2argb32fAdd(O2argb32fMultiplyByFloat(c01c11[0],(1.0f - fu)),O2argb32fMultiplyByFloat(c01c11[1],fu));
    span[i]=O2argb32fAdd(O2argb32fMultiplyByFloat(c0,(1.0f - fv)),O2argb32fMultiplyByFloat(c1, fv));

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void O2ImagePointSampling_lRGBA8888_PRE(O2Image *self,int x, int y,O2argb8u *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    O2ImageReadTileSpanExtendEdge_lRGBA8888_PRE(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void O2ImagePointSampling_lRGBAffff_PRE(O2Image *self,int x, int y,O2argb32f *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    O2ImageReadTileSpanExtendEdge__lRGBAffff_PRE(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

//clamp premultiplied color to alpha to enforce consistency
static void clampSpan_lRGBAffff_PRE(O2argb32f *span,int length){
   int i;
   
   for(i=0;i<length;i++){
    span[i].r = RI_MIN(span[i].r, span[i].a);
    span[i].g = RI_MIN(span[i].g, span[i].a);
    span[i].b = RI_MIN(span[i].b, span[i].a);
   }
}

static inline void O2RGBPremultiplySpan(O2argb32f *span,int length){
   int i;
      
   for(i=0;i<length;i++){
    span[i].r*=span[i].a;
    span[i].g*=span[i].a;
    span[i].b*=span[i].a; 
   }
}

O2argb32f *O2ImageReadSpan_lRGBAffff_PRE(O2Image *self,int x,int y,O2argb32f *span,int length) {
   VGColorInternalFormat format=self->_colorFormat;
   
   O2argb32f *direct=self->_read_lRGBAffff_PRE(self,x,y,span,length);
   
   if(direct!=NULL)
    span=direct;
    
   if(format&VGColorNONLINEAR){
    O2argb32fConvertSpan(span,length,format,VGColor_lRGBA_PRE);
   }
   if(!(format&VGColorPREMULTIPLIED)){
    O2RGBPremultiplySpan(span,length);
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

uint8_t *O2ImageReadSpan_A8_MASK(O2Image *self,int x,int y,uint8_t *coverage,int length){
   return self->_readA8(self,x,y,coverage,length);
}

O2Float *O2ImageReadSpan_Af_MASK(O2Image *self,int x,int y,O2Float *coverage,int length) {
   return self->_readAf(self,x,y,coverage,length);
}


/*-------------------------------------------------------------------*//*!
* \brief	Maps point (x,y) to an image and returns a filtered,
*			premultiplied color value.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2ImageReadTexelTileRepeat(O2Image *self,int u, int v, O2argb32f *span,int length){
   int i;

   v = RI_INT_MOD(v, self->_height);
   
   for(i=0;i<length;i++,u++){
    u = RI_INT_MOD(u, self->_width);

    O2argb32f *direct=O2ImageReadSpan_lRGBAffff_PRE(self,u,v,span+i,1);
    if(direct!=NULL)
     span[i]=direct[0];
   }
}

void O2ImagePattern_Bilinear(O2Image *self,O2Float x, O2Float y,O2argb32f *span,int length, O2AffineTransform surfaceToImage){
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    uv.x -= 0.5f;
	uv.y -= 0.5f;
	int u = RI_FLOOR_TO_INT(uv.x);
	int v = RI_FLOOR_TO_INT(uv.y);
	O2argb32f c00c01[2];
    O2ImageReadTexelTileRepeat(self,u,v,c00c01,2);

    O2argb32f c01c11[2];
    O2ImageReadTexelTileRepeat(self,u,v+1,c01c11,2);

    O2Float fu = uv.x - (O2Float)u;
    O2Float fv = uv.y - (O2Float)v;
    O2argb32f c0 = O2argb32fAdd(O2argb32fMultiplyByFloat(c00c01[0],(1.0f - fu)),O2argb32fMultiplyByFloat(c00c01[1],fu));
    O2argb32f c1 = O2argb32fAdd(O2argb32fMultiplyByFloat(c01c11[0],(1.0f - fu)),O2argb32fMultiplyByFloat(c01c11[1],fu));
    span[i]=O2argb32fAdd(O2argb32fMultiplyByFloat(c0,(1.0f - fv)),O2argb32fMultiplyByFloat(c1, fv));

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void O2ImagePattern_PointSampling(O2Image *self,O2Float x, O2Float y,O2argb32f *span,int length, O2AffineTransform surfaceToImage){	//point sampling
   double du=(x+0.5) * surfaceToImage.a+(y+0.5)* surfaceToImage.c+surfaceToImage.tx;
   double dv=(x+0.5) * surfaceToImage.b+(y+0.5)* surfaceToImage.d+surfaceToImage.ty;
   int i;
   
   for(i=0;i<length;i++,x++){
    O2Point uv=O2PointMake(du,dv);

    O2ImageReadTexelTileRepeat(self,RI_FLOOR_TO_INT(uv.x), RI_FLOOR_TO_INT(uv.y),span+i,1);

    du+=surfaceToImage.a;
    dv+=surfaceToImage.b;
   }
}

void O2ImageReadPatternSpan_lRGBAffff_PRE(O2Image *self,O2Float x, O2Float y, O2argb32f *span,int length, O2AffineTransform surfaceToImage, O2PatternTiling distortion)	{
    
   switch(distortion){
    case kO2PatternTilingNoDistortion:
      O2ImagePattern_PointSampling(self,x,y,span,length,surfaceToImage);
      break;

    case kO2PatternTilingConstantSpacingMinimalDistortion:
    case kO2PatternTilingConstantSpacing:
     default:
      O2ImagePattern_Bilinear(self,x,y,span,length,surfaceToImage);
      break;
   }
}


@end
