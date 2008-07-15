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
#import "KGPaint_axialGradient.h"
#import "KGShading.h"

@implementation KGPaint_axialGradient

static inline KGRGBAffff linearGradientColorAt(KGPaint_axialGradient *self,int x,int y){
   CGFloat g;
   
   if(self->_rho==0.0f)	//points are equal, gradient is always 1.0f
    g=1.0f;
   else {
    CGPoint p=CGPointApplyAffineTransform(CGPointMake(x+0.5f, y+0.5f),self->m_surfaceToPaintMatrix);
    
    p=Vector2Subtract(p,self->_startPoint);

    g=Vector2Dot(p, self->_u) * self->_oou;
   }
   
   return KGPaintColorRamp(self,g, self->_rho);
}

static void linear_span_lRGBA8888_PRE(KGPaint *selfX,int x,int y,KGRGBA8888 *span,int length){
   KGPaint_axialGradient *self=(KGPaint_axialGradient *)selfX;
   int i;
   
   for(i=0;i<length;i++,x++){
    span[i]=KGRGBA8888FromKGRGBAffff(linearGradientColorAt(self,x,y));
   }
}

static void linear_span_lRGBAffff_PRE(KGPaint *selfX,int x,int y,KGRGBAffff *span,int length){
   KGPaint_axialGradient *self=(KGPaint_axialGradient *)selfX;
   int i;
   
   for(i=0;i<length;i++,x++){
    span[i]=linearGradientColorAt(self,x,y);
   }
}

-initWithShading:(KGShading *)shading deviceTransform:(CGAffineTransform)deviceTransform {

// Calculate the number of samples based on the length of the gradient in device space
   CGPoint startPoint=[shading startPoint];
   CGPoint endPoint=[shading endPoint];
   CGPoint deviceStart=CGPointApplyAffineTransform(startPoint,deviceTransform);
   CGPoint deviceEnd=CGPointApplyAffineTransform(endPoint,deviceTransform);
   CGFloat deltax=deviceStart.x-deviceEnd.x;
   CGFloat deltay=deviceStart.y-deviceEnd.y;
   CGFloat distance=sqrt(deltax*deltax+deltay*deltay);
   int     numberOfSamples=RI_INT_CLAMP(distance,2,8192);

   [super initWithShading:shading deviceTransform:deviceTransform numberOfSamples:numberOfSamples];

   _read_lRGBA8888_PRE=linear_span_lRGBA8888_PRE;
   _read_lRGBAffff_PRE=linear_span_lRGBAffff_PRE;
   _u=Vector2Subtract(_endPoint,_startPoint);
   CGFloat usq=Vector2Dot(_u,_u);
   
   if(usq<=0.0f){	//points are equal, gradient is always 1.0f
    _oou=0.0f;
    _rho=0.0f;
   }
   else {
    _oou = 1.0f / usq;
    CGFloat dgdx = _oou * _u.x * self->m_surfaceToPaintMatrix.a + _oou * _u.y * self->m_surfaceToPaintMatrix.b;
    CGFloat dgdy = _oou * _u.x * self->m_surfaceToPaintMatrix.c + _oou * _u.y * self->m_surfaceToPaintMatrix.d;
    _rho = (CGFloat)sqrt(dgdx*dgdx + dgdy*dgdy);
   }

   return self;
}


@end
