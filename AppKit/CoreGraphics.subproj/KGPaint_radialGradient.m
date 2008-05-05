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
#import "KGPaint_radialGradient.h"

@implementation KGPaint_radialGradient

void KGPaintRadialGradient(KGPaint_radialGradient *self,CGFloat *g, CGFloat *rho, CGFloat x, CGFloat y) {
	RI_ASSERT(self);
	if( self->m_radialGradientRadius <= 0.0f )
	{
		*g = 1.0f;
		*rho = 0.0f;
		return;
	}

	CGFloat r = self->m_radialGradientRadius;
	CGPoint c = self->m_radialGradientCenter;
	CGPoint f = self->m_radialGradientFocalPoint;
	CGPoint gx=CGPointMake(self->m_surfaceToPaintMatrix.a, self->m_surfaceToPaintMatrix.b);
	CGPoint gy=CGPointMake(self->m_surfaceToPaintMatrix.c,self->m_surfaceToPaintMatrix.d);

	CGPoint fp = Vector2Subtract(f,c);

	//clamp the focal point inside the gradient circle
	CGFloat fpLen = Vector2Length(fp);
	if( fpLen > 0.999f * r )
		fp = Vector2MultiplyByFloat(fp, (0.999f * r / fpLen));

	CGFloat D = -1.0f / (Vector2Dot(fp,fp) - r*r);
	CGPoint p=CGPointMake(x, y);
	p = Vector2Subtract(Matrix3x3TransformVector2(self->m_surfaceToPaintMatrix, p), c);
	CGPoint d = Vector2Subtract(p,fp);
	CGFloat s = (CGFloat)sqrt(r*r*Vector2Dot(d,d) - RI_SQR(p.x*fp.y - p.y*fp.x));
	*g = (Vector2Dot(fp,d) + s) * D;
	if(RI_ISNAN(*g))
		*g = 0.0f;
	CGFloat dgdx = D*Vector2Dot(fp,gx) + (r*r*Vector2Dot(d,gx) - (gx.x*fp.y - gx.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	CGFloat dgdy = D*Vector2Dot(fp,gy) + (r*r*Vector2Dot(d,gy) - (gy.x*fp.y - gy.y*fp.x)*(p.x*fp.y - p.y*fp.x)) * (D / s);
	*rho = (CGFloat)sqrt(dgdx*dgdx + dgdy*dgdy);
	if(RI_ISNAN(*rho))
		*rho = 0.0f;
	RI_ASSERT(*rho >= 0.0f);
}


static inline VGColor radialGradientColorAt(KGPaint_radialGradient *self,int x,int y){
   VGColor result;
   
   CGFloat g, rho;
   KGPaintRadialGradient(self,&g, &rho, x+0.5f, y+0.5f);
   result = KGPaintColorRamp(self,g, rho);
   RI_ASSERT((result.m_format == VGColor_sRGBA && !self->m_colorRampPremultiplied) || (result.m_format == VGColor_sRGBA_PRE && self->m_colorRampPremultiplied));

   return VGColorPremultiply(result);
}

VGColorInternalFormat KGPaintReadPremultipliedRadialGradientSpan(KGPaint_radialGradient *self,int x,int y,KGRGBAffff *span,int length){
    VGColorInternalFormat result=0;
   int i;
   
   for(i=0;i<length;i++,x++){
    VGColor s=radialGradientColorAt(self,x,y);
    result=s.m_format;
    span[i]=KGRGBAffffFromColor(s);
   }
   return result;
}

-init {
   [super init];
        self->_readRGBAffff=(KGPaintReadSpan_RGBAffff)KGPaintReadPremultipliedRadialGradientSpan;
	self->m_radialGradientRadius=1.0f;
	self->m_radialGradientCenter=CGPointMake(0,0);
	self->m_radialGradientFocalPoint=CGPointMake(0,0);
   return self;
}


@end
