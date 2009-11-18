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
#import "O2Paint_color.h"
#import "O2Surface.h"

@implementation O2Paint_color

static int color_lRGBA8888_PRE(O2Paint *selfX,int x,int y,O2argb8u *span,int length){
   O2Paint_color *self=(O2Paint_color *)selfX;
   O2argb8u  rgba=self->_RGBA8888_PRE;
   int i;
   
   for(i=0;i<length;i++)
    span[i]=rgba;
    
   return length;
}

static int color_lRGBAffff_PRE(O2Paint *selfX,int x,int y,O2argb32f *span,int length){
   O2Paint_color *self=(O2Paint_color *)selfX;
   O2argb32f  rgba=self->_RGBAffff_PRE;
   int i;
   
   for(i=0;i<length;i++)
    span[i]=rgba;

   return length;
}

-initWithGray:(O2Float)gray alpha:(O2Float)alpha {
   self->m_surfaceToPaintMatrix=O2AffineTransformIdentity;
   _paint_lRGBA8888_PRE=color_lRGBA8888_PRE;
   _paint_lRGBAffff_PRE=color_lRGBAffff_PRE;
   m_paintColor=VGColorRGBA(gray,gray,gray,alpha,VGColor_lRGBA);
   m_paintColor=VGColorClamp(m_paintColor);
   m_paintColor=VGColorPremultiply(m_paintColor);
   _RGBAffff_PRE=O2argb32fFromColor(VGColorConvert(self->m_paintColor,VGColor_lRGBA_PRE));
   _RGBA8888_PRE=O2argb8uFromO2argb32f(_RGBAffff_PRE);
   return self;
}

-initWithRed:(O2Float)red green:(O2Float)green blue:(O2Float)blue alpha:(O2Float)alpha {
   self->m_surfaceToPaintMatrix=O2AffineTransformIdentity;
   _paint_lRGBA8888_PRE=color_lRGBA8888_PRE;
   _paint_lRGBAffff_PRE=color_lRGBAffff_PRE;
   m_paintColor=VGColorRGBA(red,green,blue,alpha,VGColor_lRGBA);
   m_paintColor=VGColorClamp(m_paintColor);
   m_paintColor=VGColorPremultiply(m_paintColor);
   _RGBAffff_PRE=O2argb32fFromColor(VGColorConvert(self->m_paintColor,VGColor_lRGBA_PRE));
   _RGBA8888_PRE=O2argb8uFromO2argb32f(_RGBAffff_PRE);
   return self;
}

@end
