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

static void KGPaintReadResampledHighSpan_lRGBAffff_PRE(KGPaint *selfX,int x,int y,KGRGBAffff *span,int length){   
   KGPaint_image *self=(KGPaint_image *)selfX;
   
   KGImageBicubic_lRGBAffff_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
}

static void KGPaintReadResampledLowSpan_lRGBAffff_PRE(KGPaint *selfX,int x,int y,KGRGBAffff *span,int length){   
   KGPaint_image *self=(KGPaint_image *)selfX;
   
   KGImageBilinear_lRGBAffff_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
}

static void KGPaintReadResampledNoneSpan_lRGBAffff_PRE(KGPaint *selfX,int x,int y,KGRGBAffff *span,int length){   
   KGPaint_image *self=(KGPaint_image *)selfX;
   
   KGImagePointSampling_lRGBAffff_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
}

//

static void KGPaintReadResampledHighSpan_lRGBA8888_PRE(KGPaint *selfX,int x,int y,KGRGBA8888 *span,int length){   
   KGPaint_image *self=(KGPaint_image *)selfX;

   KGImageBicubic_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
}

static void KGPaintReadResampledLowSpan_lRGBA8888_PRE(KGPaint *selfX,int x,int y,KGRGBA8888 *span,int length){   
   KGPaint_image *self=(KGPaint_image *)selfX;

   KGImageBilinear_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
}

static void KGPaintReadResampledNoneSpan_lRGBA8888_PRE(KGPaint *selfX,int x,int y,KGRGBA8888 *span,int length){   
   KGPaint_image *self=(KGPaint_image *)selfX;

   KGImagePointSampling_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
}

static void multiply(KGPaint *selfX,int x,int y,KGRGBAffff *span,int length){
   KGPaint_image *self=(KGPaint_image *)selfX;

   KGPaintReadSpan_lRGBAffff_PRE(self->_paint,x,y,span,length);

   KGRGBAffff imageSpan[length];
   
// FIXME: Should this take into account the interpolation quality? (depends on how it is used)
   KGPaintReadResampledNoneSpan_lRGBAffff_PRE(self,x,y,imageSpan,length);

   int i;
   
   for(i=0;i<length;i++,x++){
	//evaluate paint
	KGRGBAffff s=span[i];
    KGRGBAffff im=imageSpan[i];
    
	//apply image 
	// paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst

			im.r *= s.r;
			im.g *= s.g;
			im.b *= s.b;
			im.a *= s.a;
			s = im;

    span[i]=s;
   }
}
static void stencil(KGPaint *selfX,int x,int y,KGRGBAffff *span,int length){
   KGPaint_image *self=(KGPaint_image *)selfX;

   self->_paint->_read_lRGBAffff_PRE(self->_paint,x,y,span,length);

   KGRGBAffff imageSpan[length];
// FIXME: Should this take into account the interpolation quality? (depends on how it is used)
   KGPaintReadResampledNoneSpan_lRGBAffff_PRE(self,x,y,imageSpan,length);

   int i;
   
   for(i=0;i<length;i++,x++){
	//evaluate paint
	KGRGBAffff s=span[i];
    KGRGBAffff im=imageSpan[i];
    
	//apply image 
	// paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply

{
 // FIX
 // This needs to be changed to a nonpremultplied form. This is the only case which used ar, ag, ab premultiplied values for source.

	CGFloat ar = s.a, ag = s.a, ab = s.a;
			//the result will be in paint color space.
			//dst == RGB && image == RGB: RGB*RGB
			//dst == RGB && image == L  : RGB*LLL
			//dst == L   && image == RGB: L*(0.2126 R + 0.7152 G + 0.0722 B)
			//dst == L   && image == L  : L*L

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

    span[i]=s;
   }
}


-initWithImage:(KGImage *)image mode:(KGSurfaceMode)mode paint:(KGPaint *)paint interpolationQuality:(CGInterpolationQuality)interpolationQuality {
   [super init];
   switch(mode){
   
    case VG_DRAW_IMAGE_MULTIPLY:
     _read_lRGBAffff_PRE=multiply;
     break;
     
    case VG_DRAW_IMAGE_STENCIL:
     _read_lRGBAffff_PRE=stencil;
     break;
     
    default:
     switch(interpolationQuality){
     
      case kCGInterpolationHigh:
       _read_lRGBA8888_PRE=KGPaintReadResampledHighSpan_lRGBA8888_PRE;
       _read_lRGBAffff_PRE=KGPaintReadResampledHighSpan_lRGBAffff_PRE;
       break;
       
      case kCGInterpolationLow:
       _read_lRGBA8888_PRE=KGPaintReadResampledLowSpan_lRGBA8888_PRE;
       _read_lRGBAffff_PRE=KGPaintReadResampledLowSpan_lRGBAffff_PRE;
       break;

      case kCGInterpolationNone:
      default:
       _read_lRGBA8888_PRE=KGPaintReadResampledNoneSpan_lRGBA8888_PRE;
       _read_lRGBAffff_PRE=KGPaintReadResampledNoneSpan_lRGBAffff_PRE;
       break;
    
     }
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
