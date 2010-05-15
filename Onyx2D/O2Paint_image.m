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
#import <Onyx2D/O2Paint_image.h>

@implementation O2Paint_image

ONYX2D_STATIC int O2PaintReadResampledHighSpan_lRGBAffff_PRE(O2Paint *selfX,int x,int y,O2argb32f *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;
   
   O2ImageBicubic_lRGBAffff_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

ONYX2D_STATIC int O2PaintReadResampledLowSpan_lRGBAffff_PRE(O2Paint *selfX,int x,int y,O2argb32f *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;
   
   O2ImageBilinear_lRGBAffff_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

ONYX2D_STATIC int O2PaintReadResampledNoneSpan_lRGBAffff_PRE(O2Paint *selfX,int x,int y,O2argb32f *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;
   
   O2ImagePointSampling_lRGBAffff_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

//

ONYX2D_STATIC int O2PaintReadResampledHighSpan_lRGBA8888_PRE(O2Paint *selfX,int x,int y,O2argb8u *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;

   O2ImageBicubic_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

ONYX2D_STATIC int O2PaintReadResampledLowSpan_lRGBA8888_PRE(O2Paint *selfX,int x,int y,O2argb8u *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;

   O2ImageBilinear_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

ONYX2D_STATIC int O2PaintReadResampledLowSpanFloatTranslate_lRGBA8888_PRE(O2Paint *selfX,int x,int y,O2argb8u *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;

   O2ImageBilinearFloatTranslate_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

ONYX2D_STATIC int O2PaintReadResampledNoneSpan_lRGBA8888_PRE(O2Paint *selfX,int x,int y,O2argb8u *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;

   O2ImagePointSampling_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}


ONYX2D_STATIC int O2PaintReadIntegerTranslateSpan_lRGBA8888_PRE(O2Paint *selfX,int x,int y,O2argb8u *span,int length){   
   O2Paint_image *self=(O2Paint_image *)selfX;
   O2ImageIntegerTranslate_lRGBA8888_PRE(self->_image,x,y,span,length,self->m_surfaceToPaintMatrix);
   return length;
}

ONYX2D_STATIC int multiply(O2Paint *selfX,int x,int y,O2argb32f *span,int length){
   O2Paint_image *self=(O2Paint_image *)selfX;

   O2PaintReadSpan_lRGBAffff_PRE(self->_paint,x,y,span,length);

   O2argb32f imageSpan[length];
   
// FIXME: Should this take into account the interpolation quality? (depends on how it is used)
   O2PaintReadResampledNoneSpan_lRGBAffff_PRE(self,x,y,imageSpan,length);

   int i;
   
   for(i=0;i<length;i++,x++){
	//evaluate paint
	O2argb32f s=span[i];
    O2argb32f im=imageSpan[i];
    
	//apply image 
	// paint MULTIPLY image: convert paint to image number of channels, multiply with image, and convert to dst

			im.r *= s.r;
			im.g *= s.g;
			im.b *= s.b;
			im.a *= s.a;
			s = im;

    span[i]=s;
   }
   return length;
}

ONYX2D_STATIC int stencil(O2Paint *selfX,int x,int y,O2argb32f *span,int length){
   O2Paint_image *self=(O2Paint_image *)selfX;

   self->_paint->_paint_lRGBAffff_PRE(self->_paint,x,y,span,length);

   O2argb32f imageSpan[length];
// FIXME: Should this take into account the interpolation quality? (depends on how it is used)
   O2PaintReadResampledNoneSpan_lRGBAffff_PRE(self,x,y,imageSpan,length);

   int i;
   
   for(i=0;i<length;i++,x++){
	//evaluate paint
	O2argb32f s=span[i];
    O2argb32f im=imageSpan[i];
    
	//apply image 
	// paint STENCIL image: convert paint to dst, convert image to dst number of channels, multiply

{
 // FIX
 // This needs to be changed to a nonpremultplied form. This is the only case which used ar, ag, ab premultiplied values for source.

	O2Float ar = s.a, ag = s.a, ab = s.a;
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
   return length;
}


-initWithImage:(O2Image *)image mode:(O2SurfaceMode)mode paint:(O2Paint *)paint interpolationQuality:(O2InterpolationQuality)interpolationQuality surfaceToPaintTransform:(O2AffineTransform)xform {
   bool integerTranslate=FALSE;
   bool floatTranslate=FALSE;
   
   O2PaintInitWithTransform(self,xform);
   
   
   if(xform.a==1.0f && xform.b==0.0f && xform.c==0.0f && ABS(xform.d)==1.0f){
    if(xform.tx==RI_FLOOR_TO_INT(xform.tx) && xform.ty==RI_FLOOR_TO_INT(xform.ty))
     integerTranslate=TRUE;
    else
     floatTranslate=TRUE;
   }
#if 0
   else
      NSLog(@"xform a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f",xform.a,xform.b,xform.c,xform.d,xform.tx,xform.ty);
#endif

   switch(mode){
   
    case VG_DRAW_IMAGE_MULTIPLY:
     _paint_lRGBAffff_PRE=multiply;
     break;
     
    case VG_DRAW_IMAGE_STENCIL:
     _paint_lRGBAffff_PRE=stencil;
     break;
     
    default:
     switch(interpolationQuality){
     
      case kO2InterpolationHigh:
       if(integerTranslate)
        _paint_lRGBA8888_PRE=O2PaintReadIntegerTranslateSpan_lRGBA8888_PRE;
       else
       _paint_lRGBA8888_PRE=O2PaintReadResampledHighSpan_lRGBA8888_PRE;
       _paint_lRGBAffff_PRE=O2PaintReadResampledHighSpan_lRGBAffff_PRE;
       break;
       
      case kO2InterpolationLow:
      
       if(integerTranslate)
        _paint_lRGBA8888_PRE=O2PaintReadIntegerTranslateSpan_lRGBA8888_PRE;
       else if(floatTranslate)
        _paint_lRGBA8888_PRE=O2PaintReadResampledLowSpanFloatTranslate_lRGBA8888_PRE;
       else
       _paint_lRGBA8888_PRE=O2PaintReadResampledLowSpan_lRGBA8888_PRE;
        
       _paint_lRGBAffff_PRE=O2PaintReadResampledLowSpan_lRGBAffff_PRE;
       break;

      case kO2InterpolationNone:
      default:
       if(integerTranslate)
        _paint_lRGBA8888_PRE=O2PaintReadIntegerTranslateSpan_lRGBA8888_PRE;
       else
       _paint_lRGBA8888_PRE=O2PaintReadResampledNoneSpan_lRGBA8888_PRE;
       _paint_lRGBAffff_PRE=O2PaintReadResampledNoneSpan_lRGBAffff_PRE;
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
   O2PaintRelease(_paint);
   [super dealloc];
}

@end
