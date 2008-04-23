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

static BOOL initFunctionsForParameters(KGImage *self,size_t bitsPerComponent,size_t bitsPerPixel,KGColorSpace *colorSpace,CGBitmapInfo bitmapInfo,KGSurfaceFormat imageFormat){

   switch(bitsPerComponent){
    case 32:
     break;
     
    case  8:
     switch(bitsPerPixel){
     }
     break;
     
    case  4:
    case  2:
    case  1:
     break;
   }
   
   switch(imageFormat){
    case VG_sRGBA_8888:
    case VG_lRGBA_8888:
     self->_readSpan=KGImageReadPixelSpan_RGBA_8888;
     return YES;
     
    case VG_sRGBA_8888_PRE:
    case VG_lRGBA_8888_PRE:
     self->_readSpan=KGImageReadPixelSpan_RGBA_8888;
     return YES;

    default:
     switch(bitsPerPixel){
      case 32:
       if(bitmapInfo&kCGBitmapFloatComponents){
       }
       else {
        switch(bitmapInfo&kCGBitmapAlphaInfoMask){
         case kCGImageAlphaNone:
          break;
        }
        
        self->_readSpan=KGImageReadPixelSpan_32;
        return YES;
       }

      case 16:
       self->_readSpan=KGImageReadPixelSpan_16;
       return YES;
 
      case  8:
       self->_readSpan=KGImageReadPixelSpan_08;
       return YES;
     
      case  1:
       self->_readSpan=KGImageReadPixelSpan_01;
       return YES;
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
   _imageFormat=VG_lRGBA_8888;
   initFunctionsForParameters(self,bitsPerComponent,bitsPerPixel,colorSpace,bitmapInfo,_imageFormat);
    size_t checkBPP;
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

static inline RIfloat intToColor(unsigned int i, unsigned int maxi)
{
	return (RIfloat)(i & maxi) / (RIfloat)maxi;
}

KGRGBA KGRGBAUnpack(unsigned int inputData,KGImage *img){
   KGRGBA result;
   
	int rb = img->m_desc.redBits;
	int gb = img->m_desc.greenBits;
	int bb = img->m_desc.blueBits;
	int ab = img->m_desc.alphaBits;
	int lb = img->m_desc.luminanceBits;
	int rs = img->m_desc.redShift;
	int gs = img->m_desc.greenShift;
	int bs = img->m_desc.blueShift;
	int as = img->m_desc.alphaShift;
	int ls = img->m_desc.luminanceShift;

	if(lb)
	{	//luminance
		result.r = result.g = result.b = intToColor(inputData >> ls, (1<<lb)-1);
		result.a = 1.0f;
	}
	else
	{	//rgba
		result.r = rb ? intToColor(inputData >> rs, (1<<rb)-1) : (RIfloat)1.0f;
		result.g = gb ? intToColor(inputData >> gs, (1<<gb)-1) : (RIfloat)1.0f;
		result.b = bb ? intToColor(inputData >> bs, (1<<bb)-1) : (RIfloat)1.0f;
		result.a = ab ? intToColor(inputData >> as, (1<<ab)-1) : (RIfloat)1.0f;
	}
    return result;
}

static  RIfloat byteToColor(unsigned char i){
	return (RIfloat)(i) / (RIfloat)0xFF;
}

void KGImageReadPixelSpan_RGBA_8888(KGImage *self,int x,int y,KGRGBA *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int i;

   scanline+=x*4;
   for(i=0;i<length;i++){
#if 0
// The original implementation "RGBA"  = in host endianess, so until endian-ness is fixed everywhere
    unsigned char r=*scanline++;
    unsigned char g=*scanline++;
    unsigned char b=*scanline++;
    unsigned char a=*scanline++;
#else
// use this
    unsigned char a=*scanline++;
    unsigned char b=*scanline++;
    unsigned char g=*scanline++;
    unsigned char r=*scanline++;
#endif
    KGRGBA  result;
    
    result.r = byteToColor(r);
    result.g = byteToColor(g);
    result.b = byteToColor(b);
	result.a = byteToColor(a);
    *span++=result;
   }
}

void KGImageReadPixelSpan_32(KGImage *self,int x,int y,KGRGBA *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int          i;
   unsigned int p;

        for(i=0;i<length;i++,x++){
            RIuint32* s = (((RIuint32*)scanline) + x);
            p = (unsigned int)*s;
            span[i]=KGRGBAUnpack(p, self);
        }
}

void KGImageReadPixelSpan_16(KGImage *self,int x,int y,KGRGBA *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int          i;
   unsigned int p;

        for(i=0;i<length;i++,x++){
            RIuint16* s = ((RIuint16*)scanline) + x;
            p = (unsigned int)*s;
            span[i]=KGRGBAUnpack(p, self);
        }
}

void KGImageReadPixelSpan_08(KGImage *self,int x,int y,KGRGBA *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int          i;
   unsigned int p;

        for(i=0;i<length;i++,x++){
            RIuint8* s = ((RIuint8*)scanline) + x;
            p = (unsigned int)*s;
            span[i]=KGRGBAUnpack(p, self);
        }
}

void KGImageReadPixelSpan_01(KGImage *self,int x,int y,KGRGBA *span,int length){
   RIuint8 *scanline = self->_bytes + y * self->_bytesPerRow;
   int          i;
   unsigned int p;

        for(i=0;i<length;i++,x++){
            RIuint8* s = scanline + (x>>3);
            p = (((unsigned int)*s) >> (x&7)) & 1u;
            span[i]=KGRGBAUnpack(p, self);
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


VGColorInternalFormat KGImageResample_EWAOnMipmaps(KGImage *self,RIfloat x, RIfloat y,KGRGBA *span,int length, Matrix3x3 surfaceToImage){
// Visual test indicates this is very close to what Apple is using 
   int i;
   		RIfloat m_pixelFilterRadius = 1.25f;
		RIfloat m_resamplingFilterRadius = 1.25f;

   KGSurfaceMakeMipMaps(self);
   
   Vector3 uvw=Vector3Make(0,0,1);
   uvw=Matrix3x3MultiplyVector3(surfaceToImage ,uvw);
   RIfloat oow = 1.0f / uvw.z;
   RIfloat VxPRE = (surfaceToImage.matrix[1][0] - uvw.y * surfaceToImage.matrix[2][0]) * oow * m_pixelFilterRadius;
   RIfloat VyPRE = (surfaceToImage.matrix[1][1] - uvw.y * surfaceToImage.matrix[2][1]) * oow * m_pixelFilterRadius;
   
		RIfloat Ux = (surfaceToImage.matrix[0][0] - uvw.x * surfaceToImage.matrix[2][0]) * oow * m_pixelFilterRadius;
		RIfloat Vx = VxPRE;
		RIfloat Uy = (surfaceToImage.matrix[0][1] - uvw.x * surfaceToImage.matrix[2][1]) * oow * m_pixelFilterRadius;
		RIfloat Vy = VyPRE;

		//calculate mip level
		int level = 0;
		RIfloat axis1sq = Ux*Ux + Vx*Vx;
		RIfloat axis2sq = Uy*Uy + Vy*Vy;
		RIfloat minorAxissq = RI_MIN(axis1sq,axis2sq);
		while(minorAxissq > 9.0f && level < self->_mipmapsCount)	//half the minor axis must be at least three texels
		{
			level++;
			minorAxissq *= 0.25f;
		}

		RIfloat sx = 1.0f;
		RIfloat sy = 1.0f;
		if(level > 0)
		{
			sx = (RIfloat)KGImageGetWidth(self->_mipmaps[level-1]) / (RIfloat)self->_width;
			sy = (RIfloat)KGImageGetHeight(self->_mipmaps[level-1]) / (RIfloat)self->_height;
		}
        KGImage *mipmap=KGSurfaceMipMapForLevel(self,level);

   for(i=0;i<length;i++,x++){
    uvw=Vector3Make(x+0.5,y+0.5,1);
    uvw=Matrix3x3MultiplyVector3(surfaceToImage ,uvw);
	uvw=Vector3MultiplyByFloat(uvw,oow);
   
		 Ux = (surfaceToImage.matrix[0][0] - uvw.x * surfaceToImage.matrix[2][0]) * oow * m_pixelFilterRadius;
		 Vx = VxPRE;
		 Uy = (surfaceToImage.matrix[0][1] - uvw.x * surfaceToImage.matrix[2][1]) * oow * m_pixelFilterRadius;
		 Vy = VyPRE;

		RIfloat U0 = uvw.x;
		RIfloat V0 = uvw.y;
		Ux *= sx;
		Vx *= sx;
		U0 *= sx;
		Uy *= sy;
		Vy *= sy;
		V0 *= sy;
		
		//clamp filter size so that filtering doesn't take excessive amount of time (clamping results in aliasing)
		RIfloat lim = 100.0f;
		axis1sq = Ux*Ux + Vx*Vx;
		axis2sq = Uy*Uy + Vy*Vy;
		if( axis1sq > lim*lim )
		{
			RIfloat s = lim / (RIfloat)sqrt(axis1sq);
			Ux *= s;
			Vx *= s;
		}
		if( axis2sq > lim*lim )
		{
			RIfloat s = lim / (RIfloat)sqrt(axis2sq);
			Uy *= s;
			Vy *= s;
		}
		
		
		//form elliptic filter by combining texel and pixel filters
		RIfloat A = Vx*Vx + Vy*Vy + 1.0f;
		RIfloat B = -2.0f*(Ux*Vx + Uy*Vy);
		RIfloat C = Ux*Ux + Uy*Uy + 1.0f;
		//scale by the user-defined size of the kernel
		A *= m_resamplingFilterRadius;
		B *= m_resamplingFilterRadius;
		C *= m_resamplingFilterRadius;
		
		//calculate bounding box in texture space
		RIfloat usize = (RIfloat)sqrt(C);
		RIfloat vsize = (RIfloat)sqrt(A);
		int u1 = RI_FLOOR_TO_INT(U0 - usize + 0.5f);
		int u2 = RI_FLOOR_TO_INT(U0 + usize + 0.5f);
		int v1 = RI_FLOOR_TO_INT(V0 - vsize + 0.5f);
		int v2 = RI_FLOOR_TO_INT(V0 + vsize + 0.5f);
		if( u1 == u2 || v1 == v2 ){
			span[i]=KGRGBAInit(0,0,0,0);
            continue;
        }
        
		//scale the filter so that Q = 1 at the cutoff radius
		RIfloat F = A*C - 0.25f * B*B;
		if( F <= 0.0f ){
			span[i]=KGRGBAInit(0,0,0,0);	//invalid filter shape due to numerical inaccuracies => return black
            continue;
        }
		RIfloat ooF = 1.0f / F;
		A *= ooF;
		B *= ooF;
		C *= ooF;
		
		//evaluate filter by using forward differences to calculate Q = A*U^2 + B*U*V + C*V^2
		KGRGBA color=KGRGBAInit(0,0,0,0);
		RIfloat sumweight = 0.0f;
		RIfloat DDQ = 2.0f * A;
		RIfloat U = (RIfloat)u1 - U0 + 0.5f;
        int v;
        
		for(v=v1;v<v2;v++)
		{
			RIfloat V = (RIfloat)v - V0 + 0.5f;
			RIfloat DQ = A*(2.0f*U+1.0f) + B*V;
			RIfloat Q = (C*V+B*U)*V + A*U*U;
            int u;
            
            KGRGBA texel[u2-u1];
            KGSurfaceReadTexelTilePad(mipmap,u1, v,texel,(u2-u1));
			for(u=u1;u<u2;u++)
			{
				if( Q >= 0.0f && Q < 1.0f )
				{	//Q = r^2, fit gaussian to the range [0,1]
#if 0
					RIfloat weight = (RIfloat)expf(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
#else
					RIfloat weight = (RIfloat)fastExp(-0.5f * 10.0f * Q);	//gaussian at radius 10 equals 0.0067
#endif
                    
					color=KGRGBAAdd(color,  KGRGBAMultiplyByFloat(texel[u-u1],weight));
					sumweight += weight;
				}
				Q += DQ;
				DQ += DDQ;
			}
		}
		if( sumweight == 0.0f ){
			span[i]=KGRGBAInit(0,0,0,0);
            continue;
        }
		RI_ASSERT(sumweight > 0.0f);
		sumweight = 1.0f / sumweight;
		span[i]=KGRGBAMultiplyByFloat(color,sumweight);
	}


   return self->_colorFormat;
}


static inline float cubic(float v0,float v1,float v2,float v3,float fraction){
  float p = (v3 - v2) - (v0 - v1);
  float q = (v0 - v1) - p;

  return RI_CLAMP((p * (fraction*fraction*fraction)) + (q * fraction*fraction) + ((v2 - v0) * fraction) + v1,0,1);
}

KGRGBA bicubicInterpolate(KGRGBA a,KGRGBA b,KGRGBA c,KGRGBA d,float fraction)
{
  return KGRGBAInit(
   cubic(a.r, b.r, c.r, d.r, fraction),
   cubic(a.g, b.g, c.g, d.g, fraction),
   cubic(a.b, b.b, c.b, d.b, fraction),
   cubic(a.a, b.a, c.a, d.a, fraction));
}

VGColorInternalFormat KGImageResample_Bicubic(KGImage *self,RIfloat x, RIfloat y,KGRGBA *span,int length, Matrix3x3 surfaceToImage){
   int i;
   
   for(i=0;i<length;i++,x++){
	Vector3 uvw=Vector3Make(x+0.5,y+0.5,1);
	uvw = Matrix3x3MultiplyVector3(surfaceToImage ,uvw);
	RIfloat oow = 1.0f / uvw.z;
	uvw=Vector3MultiplyByFloat(uvw,oow);
    uvw.x -= 0.5f;
    uvw.y -= 0.5f;
    int u = RI_FLOOR_TO_INT(uvw.x);
    float ufrac=uvw.x-u;
        
    int v = RI_FLOOR_TO_INT(uvw.y);
    float vfrac=uvw.y-v;
        
    KGRGBA t0,t1,t2,t3;
    KGRGBA cspan[4];
     
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

VGColorInternalFormat KGImageResample_Bilinear(KGImage *self,RIfloat x, RIfloat y,KGRGBA *span,int length, Matrix3x3 surfaceToImage){
   int i;

   for(i=0;i<length;i++,x++){
	Vector3 uvw=Vector3Make(x+0.5,y+0.5,1);
	uvw = Matrix3x3MultiplyVector3(surfaceToImage,uvw);
	RIfloat oow = 1.0f / uvw.z;
	uvw=Vector3MultiplyByFloat(uvw,oow);
    uvw.x -= 0.5f;
	uvw.y -= 0.5f;
	int u = RI_FLOOR_TO_INT(uvw.x);
	int v = RI_FLOOR_TO_INT(uvw.y);
	KGRGBA c00c01[2];
    KGSurfaceReadTexelTilePad(self,u,v,c00c01,2);

    KGRGBA c01c11[2];
    KGSurfaceReadTexelTilePad(self,u,v+1,c01c11,2);

    RIfloat fu = uvw.x - (RIfloat)u;
    RIfloat fv = uvw.y - (RIfloat)v;
    KGRGBA c0 = KGRGBAAdd(KGRGBAMultiplyByFloat(c00c01[0],(1.0f - fu)),KGRGBAMultiplyByFloat(c00c01[1],fu));
    KGRGBA c1 = KGRGBAAdd(KGRGBAMultiplyByFloat(c01c11[0],(1.0f - fu)),KGRGBAMultiplyByFloat(c01c11[1],fu));
    span[i]=KGRGBAAdd(KGRGBAMultiplyByFloat(c0,(1.0f - fv)),KGRGBAMultiplyByFloat(c1, fv));
   }

   return self->_colorFormat;
}

VGColorInternalFormat KGImageResample_PointSampling(KGImage *self,RIfloat x, RIfloat y,KGRGBA *span,int length, Matrix3x3 surfaceToImage){
   int i;
   
   for(i=0;i<length;i++,x++){
    Vector3 uvw=Vector3Make(x+0.5,y+0.5,1);
	uvw = Matrix3x3MultiplyVector3(surfaceToImage ,uvw);
	RIfloat oow = 1.0f / uvw.z;
	uvw=Vector3MultiplyByFloat(uvw,oow);
    KGSurfaceReadTexelTilePad(self,RI_FLOOR_TO_INT(uvw.x), RI_FLOOR_TO_INT(uvw.y),span+i,1);
   }
   return self->_colorFormat;
}

@end
