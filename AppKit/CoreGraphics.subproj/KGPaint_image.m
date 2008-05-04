/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
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
#import "KGPaint_image.h"

@implementation KGPaint_image

static VGColorInternalFormat KGPaintReadPremultipliedImageNormalSpan(KGPaint_image *self,int x,int y,KGRGBAffff *span,int length){
   VGColorInternalFormat spanFormat;
   
   if(self->_interpolationQuality==kCGInterpolationHigh){
    spanFormat=KGImageResample_EWAOnMipmaps(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
    // spanFormat=KGImageResample_Bicubic(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   }
   else if(self->_interpolationQuality==kCGInterpolationLow)
    spanFormat=KGImageResample_Bilinear(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   else
    spanFormat=KGImageResample_PointSampling(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
  
   return spanFormat;
}

static VGColorInternalFormat multiply(KGPaint_image *self,int x,int y,KGRGBAffff *span,int length){
   VGColorInternalFormat paintFormat;

   paintFormat=self->_paint->_readRGBAffff(self->_paint,x,y,span,length);
   if(!(paintFormat&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(span,length);
    paintFormat|=VGColorPREMULTIPLIED;
   }

   KGRGBAffff imageSpan[length];
   VGColorInternalFormat imageFormat=KGPaintReadPremultipliedImageNormalSpan(self,x,y,imageSpan,length);
   if(!(imageFormat&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(span,length);
    imageFormat|=VGColorPREMULTIPLIED;
   }
   int i;
   
   for(i=0;i<length;i++,x++){
	//evaluate paint
	VGColor s=VGColorFromKGRGBA_ffff(span[i],paintFormat);
    VGColor im=VGColorFromKGRGBA_ffff(imageSpan[i],imageFormat);
    
	//apply image (vgDrawImage only)
	//1. paint: convert paint to dst space
	//2. image: convert image to dst space
	//3. paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst
	//4. paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply

		RI_ASSERT((s.m_format & VGColorLUMINANCE && s.r == s.g && s.r == s.b) || !(s.m_format & VGColorLUMINANCE));	//if luminance, r=g=b
		RI_ASSERT((im.m_format & VGColorLUMINANCE && im.r == im.g && im.r == im.b) || !(im.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

			//the result will be in image color space. If the number of channels in image and paint
			// colors differ, convert to the number of channels in the image color.
			//paint == RGB && image == RGB: RGB*RGB
			//paint == RGB && image == L  : (0.2126 R + 0.7152 G + 0.0722 B)*L
			//paint == L   && image == RGB: LLL*RGB
			//paint == L   && image == L  : L*L
			if(!(s.m_format & VGColorLUMINANCE) && im.m_format & VGColorLUMINANCE)
			{
				s.r = s.g = s.b = RI_MIN(0.2126f*s.r + 0.7152f*s.g + 0.0722f*s.b, s.a);
			}
 			RI_ASSERT(Matrix3x3IsAffine(self->m_paint->m_surfaceToPaintMatrix));
			im.r *= s.r;
			im.g *= s.g;
			im.b *= s.b;
			im.a *= s.a;
			s = im;
			// s=VGColorConvert(s,format);	//convert resulting color to destination color space

    span[i]=KGRGBAffffFromColor(s);
   }
   return imageFormat;
}
static VGColorInternalFormat stencil(KGPaint_image *self,int x,int y,KGRGBAffff *span,int length){
   VGColorInternalFormat paintFormat;

   paintFormat=self->_paint->_readRGBAffff(self->_paint,x,y,span,length);
   if(!(paintFormat&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(span,length);
    paintFormat|=VGColorPREMULTIPLIED;
   }

   KGRGBAffff imageSpan[length];
   VGColorInternalFormat imageFormat=KGPaintReadPremultipliedImageNormalSpan(self,x,y,imageSpan,length);
   if(!(imageFormat&VGColorPREMULTIPLIED)){
    KGRGBPremultiplySpan(span,length);
    imageFormat|=VGColorPREMULTIPLIED;
   }
   int i;
   
   for(i=0;i<length;i++,x++){
	//evaluate paint
	VGColor s=VGColorFromKGRGBA_ffff(span[i],paintFormat);
    VGColor im=VGColorFromKGRGBA_ffff(imageSpan[i],imageFormat);
    
	//apply image (vgDrawImage only)
	//1. paint: convert paint to dst space
	//2. image: convert image to dst space
	//3. paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst
	//4. paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply

		RI_ASSERT((s.m_format & VGColorLUMINANCE && s.r == s.g && s.r == s.b) || !(s.m_format & VGColorLUMINANCE));	//if luminance, r=g=b
		RI_ASSERT((im.m_format & VGColorLUMINANCE && im.r == im.g && im.r == im.b) || !(im.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

{
 // FIX
 // This needs to be changed to a nonpremultplied form. This is the only case which used ar, ag, ab premultiplied values for source.

	RIfloat ar = s.a, ag = s.a, ab = s.a;
			//the result will be in paint color space.
			//dst == RGB && image == RGB: RGB*RGB
			//dst == RGB && image == L  : RGB*LLL
			//dst == L   && image == RGB: L*(0.2126 R + 0.7152 G + 0.0722 B)
			//dst == L   && image == L  : L*L
			RI_ASSERT(self->m_imageMode == VG_DRAW_IMAGE_STENCIL);
#if 0
			if(format & VGColorLUMINANCE && !(im.m_format & VGColorLUMINANCE))
			{
				im.r = im.g = im.b = RI_MIN(0.2126f*im.r + 0.7152f*im.g + 0.0722f*im.b, im.a);
			}
			RI_ASSERT(Matrix3x3IsAffine(self->m_paint->m_surfaceToPaintMatrix));
			//s and im are both in premultiplied format. Each image channel acts as an alpha channel.
			s=VGColorConvert(s,format);	//convert paint color to destination space already here, since convert cannot deal with per channel alphas used in this mode.
#endif
			s.r *= im.r;
			s.g *= im.g;
			s.b *= im.b;
			s.a *= im.a;
			ar *= im.r;
			ag *= im.g;
			ab *= im.b;
			//in nonpremultiplied form the result is
			// s.rgb = paint.a * paint.rgb * image.a * image.rgb
			// s.a = paint.a * image.a
			// argb = paint.a * image.a * image.rgb

	RI_ASSERT(s.r >= 0.0f && s.r <= s.a && s.r <= ar);
	RI_ASSERT(s.g >= 0.0f && s.g <= s.a && s.g <= ag);
	RI_ASSERT(s.b >= 0.0f && s.b <= s.a && s.b <= ab);
}

    span[i]=KGRGBAffffFromColor(s);
   }
   
   return paintFormat;
}


-initWithImage:(KGImage *)image mode:(KGSurfaceMode)mode paint:(KGPaint *)paint interpolationQuality:(CGInterpolationQuality)interpolationQuality {
   KGPaintInit(self);
   switch(mode){
    case VG_DRAW_IMAGE_MULTIPLY:
     _readRGBAffff=(KGPaintReadSpan_RGBAffff)multiply;
     break;
    case VG_DRAW_IMAGE_STENCIL:
     _readRGBAffff=(KGPaintReadSpan_RGBAffff)stencil;
     break;
    default:
     _readRGBAffff=(KGPaintReadSpan_RGBAffff)KGPaintReadPremultipliedImageNormalSpan;
     break;
   }
   
   _image=[image retain];
   _mode=mode;
   _paint=[paint retain];
   _interpolationQuality=interpolationQuality;
   return self;
}

-(void)dealloc {
   [_image release];
   [_paint release];
   [super dealloc];
}

@end
