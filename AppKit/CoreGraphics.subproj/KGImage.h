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

#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>
#import "VGmath.h"

@class KGColorSpace,KGDataProvider,KGPDFObject,KGPDFContext;

typedef enum {
  /* RGB{A,X} channel ordering */
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

  /* {A,X}RGB channel ordering */
  VG_sXRGB_8888                               =  0 | (1 << 6),
  VG_sARGB_8888                               =  1 | (1 << 6),
  VG_sARGB_8888_PRE                           =  2 | (1 << 6),
  VG_sARGB_1555                               =  4 | (1 << 6),
  VG_sARGB_4444                               =  5 | (1 << 6),
  VG_lXRGB_8888                               =  7 | (1 << 6),
  VG_lARGB_8888                               =  8 | (1 << 6),
  VG_lARGB_8888_PRE                           =  9 | (1 << 6),

  /* BGR{A,X} channel ordering */
  VG_sBGRX_8888                               =  0 | (1 << 7),
  VG_sBGRA_8888                               =  1 | (1 << 7),
  VG_sBGRA_8888_PRE                           =  2 | (1 << 7),
  VG_sBGR_565                                 =  3 | (1 << 7),
  VG_sBGRA_5551                               =  4 | (1 << 7),
  VG_sBGRA_4444                               =  5 | (1 << 7),
  VG_lBGRX_8888                               =  7 | (1 << 7),
  VG_lBGRA_8888                               =  8 | (1 << 7),
  VG_lBGRA_8888_PRE                           =  9 | (1 << 7),

  /* {A,X}BGR channel ordering */
  VG_sXBGR_8888                               =  0 | (1 << 6) | (1 << 7),
  VG_sABGR_8888                               =  1 | (1 << 6) | (1 << 7),
  VG_sABGR_8888_PRE                           =  2 | (1 << 6) | (1 << 7),
  VG_sABGR_1555                               =  4 | (1 << 6) | (1 << 7),
  VG_sABGR_4444                               =  5 | (1 << 6) | (1 << 7),
  VG_lXBGR_8888                               =  7 | (1 << 6) | (1 << 7),
  VG_lABGR_8888                               =  8 | (1 << 6) | (1 << 7),
  VG_lABGR_8888_PRE                           =  9 | (1 << 6) | (1 << 7)
} KGImageFormat;

enum {
 VGColorNONLINEAR		= (1<<0),
 VGColorPREMULTIPLIED	= (1<<1),
 VGColorLUMINANCE		= (1<<2)
};

typedef enum {
 VGColor_lRGBA			= 0,
 VGColor_sRGBA			= VGColorNONLINEAR,
 VGColor_lRGBA_PRE		= VGColorPREMULTIPLIED,
 VGColor_sRGBA_PRE		= VGColorPREMULTIPLIED|VGColorNONLINEAR,
 VGColor_lLA            = VGColorLUMINANCE,
 VGColor_sLA			= VGColorLUMINANCE|VGColorNONLINEAR,
 VGColor_lLA_PRE		= VGColorLUMINANCE|VGColorPREMULTIPLIED,
 VGColor_sLA_PRE        = VGColorLUMINANCE|VGColorPREMULTIPLIED|VGColorNONLINEAR
} VGColorInternalFormat;

typedef struct  {
   int redBits;
   int redShift;
   int greenBits;
   int greenShift;
   int blueBits;
   int blueShift;
   int alphaBits;
   int alphaShift;
   int luminanceBits;
   int luminanceShift;
} VGPixelDecode;


typedef struct {
   CGFloat r;
   CGFloat g;
   CGFloat b;
   CGFloat a;
} KGRGBAffff;

static inline KGRGBAffff KGRGBAffffInit(CGFloat r,CGFloat g,CGFloat b,CGFloat a){
   KGRGBAffff result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}

static inline KGRGBAffff KGRGBAffffMultiplyByFloat(KGRGBAffff result,CGFloat value){
   result.r*=value;
   result.g*=value;
   result.b*=value;
   result.a*=value;
   return result;
}

static inline KGRGBAffff KGRGBAffffAdd(KGRGBAffff result,KGRGBAffff other){
   result.r+=other.r;
   result.g+=other.g;
   result.b+=other.b;
   result.a+=other.a;
   return result;
}

static inline void KGRGBPremultiplySpan(KGRGBAffff *span,int length){
   int i;
      
   for(i=0;i<length;i++){
    span[i].r*=span[i].a;
    span[i].g*=span[i].a;
    span[i].b*=span[i].a; 
   }
}

typedef struct {
   uint8_t r;
   uint8_t g;
   uint8_t b;
   uint8_t a;
} KGRGBA8888;

static inline KGRGBA8888 KGRGBA8888Init(int r,int g,int b,int a){
   KGRGBA8888 result;
   result.r=r;
   result.g=g;
   result.b=b;
   result.a=a;
   return result;
}


static inline CGFloat CGFloatFromByte(uint8_t i){
	return (CGFloat)(i) / (CGFloat)0xFF;
}

static inline uint8_t CGByteFromFloat(CGFloat c){
	return RI_INT_MIN(RI_INT_MAX(RI_FLOOR_TO_INT(c * (CGFloat)0xFF + 0.5), 0), 0xFF);
}

static inline KGRGBA8888 KGRGBA8888FromKGRGBAffff(KGRGBAffff rgba){
   KGRGBA8888 result;
   result.r=CGByteFromFloat(rgba.r);
   result.g=CGByteFromFloat(rgba.g);
   result.b=CGByteFromFloat(rgba.b);
   result.a=CGByteFromFloat(rgba.a);
   return result;
}

static inline KGRGBA8888 KGRGBA8888MultiplyByCoverageByte(KGRGBA8888 result,int value){
   result.r=((int)result.r*value)/255;
   result.g=((int)result.g*value)/255;
   result.b=((int)result.b*value)/255;
   result.a=((int)result.a*value)/255;

   return result;
}

static inline KGRGBA8888 KGRGBA8888Add(KGRGBA8888 result,KGRGBA8888 other){
   result.r=RI_INT_CLAMP((int)result.r+(int)other.r,0,255);
   result.g=RI_INT_CLAMP((int)result.g+(int)other.g,0,255);
   result.b=RI_INT_CLAMP((int)result.b+(int)other.b,0,255);
   result.a=RI_INT_CLAMP((int)result.a+(int)other.a,0,255);
   return result;
}

@class KGImage;
 
typedef void (*KGImageReadSpan_RGBA8888)(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
typedef void (*KGImageReadSpan_RGBAffff)(KGImage *self,int x,int y,KGRGBAffff *span,int length);

@interface KGImage : NSObject <NSCopying> {
   size_t _width;
   size_t _height;
   size_t _bitsPerComponent;
   size_t _bitsPerPixel;
   size_t _bytesPerRow;
   
   KGColorSpace          *_colorSpace;
   CGBitmapInfo           _bitmapInfo;
   KGDataProvider        *_provider;
   float                 *_decode;
   BOOL                   _interpolate;
   BOOL                   _isMask;
   CGColorRenderingIntent _renderingIntent;
   KGImage               *_mask;

   unsigned char *_bytes;
   BOOL           _clampExternalPixels;
   KGImageFormat         _imageFormat;
   VGColorInternalFormat _colorFormat;

   KGImageReadSpan_RGBA8888 _readRGBA8888;
   KGImageReadSpan_RGBAffff _readRGBAffff;
    
	VGPixelDecode	m_desc;
	BOOL				m_ownsData;
	BOOL				m_mipmapsValid;
    int                 _mipmapsCount;
    int                 _mipmapsCapacity;
    struct KGSurface    **_mipmaps;
}

-initWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(unsigned)bitmapInfo provider:(KGDataProvider *)provider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent;

-initMaskWithWidth:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bitsPerPixel:(size_t)bitsPerPixel bytesPerRow:(size_t)bytesPerRow provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate ;

-initWithJPEGDataProvider:(KGDataProvider *)jpegProvider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent;
-initWithPNGDataProvider:(KGDataProvider *)jpegProvider decode:(const CGFloat *)decode interpolate:(BOOL)interpolate renderingIntent:(CGColorRenderingIntent)renderingIntent;

-(KGImage *)copyWithColorSpace:(KGColorSpace *)colorSpace;
-(KGImage *)childImageInRect:(CGRect)rect;

-(void)addMask:(KGImage *)mask;
-copyWithMask:(KGImage *)image;
-copyWithMaskingColors:(const CGFloat *)components;

-(size_t)width;
-(size_t)height;
-(size_t)bitsPerComponent;
-(size_t)bitsPerPixel;
-(size_t)bytesPerRow;
-(KGColorSpace *)colorSpace;
-(CGBitmapInfo)bitmapInfo;
-(KGDataProvider *)dataProvider;
-(const CGFloat *)decode;
-(BOOL)shouldInterpolate;
-(CGColorRenderingIntent)renderingIntent;
-(BOOL)isMask;
-(CGImageAlphaInfo)alphaInfo;

-(const void *)bytes;
-(unsigned)length;

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGImage *)imageWithPDFObject:(KGPDFObject *)object;

@end

VGPixelDecode KGImageParametersToPixelLayout(KGImageFormat format,size_t *bitsPerPixel,VGColorInternalFormat *colorFormat);

CGColorRenderingIntent KGImageRenderingIntentWithName(const char *name);
const char *KGImageNameWithIntent(CGColorRenderingIntent intent);

size_t KGImageGetWidth(KGImage *self);
size_t KGImageGetHeight(KGImage *self);
VGColorInternalFormat KGImageColorFormat(KGImage *self);

void KGImageRead_G8_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_GA88_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_RGBA8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_ABGR8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_RGBA4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_BARG4444_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_RGBA2222_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageRead_CMYK8888_to_RGBA8888(KGImage *self,int x,int y,KGRGBA8888 *span,int length);

void KGImageRead_ANY_to_RGBA8888_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length);

void KGImageRead_RGBAffffLittle_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length);
void KGImageRead_RGBAffffBig_to_RGBAffff(KGImage *self,int x,int y,KGRGBAffff *span,int length);

void KGImageReadSpan_lRGBA8888_PRE(KGImage *self,int x,int y,KGRGBA8888 *span,int length);
void KGImageReadSpan_lRGBAffff_PRE(KGImage *self,int x,int y,KGRGBAffff *span,int length);
void KGImageReadSpan_A8_MASK(KGImage *self,int x,int y,uint8_t *coverage,int length);
void KGImageReadSpan_Af_MASK(KGImage *self,int x,int y,CGFloat *coverage,int length);

void KGImageEWAOnMipmaps_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);
void KGImageBicubic_lRGBA8888_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage);
void KGImageBicubic_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);
void KGImageBilinear_lRGBA8888_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage);
void KGImageBilinear_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);
void KGImagePointSampling_lRGBA8888_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBA8888 *span,int length, CGAffineTransform surfaceToImage);
void KGImagePointSampling_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y,KGRGBAffff *span,int length, CGAffineTransform surfaceToImage);

void KGImageReadPatternSpan_lRGBAffff_PRE(KGImage *self,CGFloat x, CGFloat y, KGRGBAffff *span,int length, CGAffineTransform surfaceToImage, CGPatternTiling distortion);
