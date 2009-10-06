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

@implementation O2Paint_axialGradient

static int linear_span_lRGBA8888_PRE(O2Paint *selfX,int x,int y,KGRGBA8888 *span,int length){
   O2Paint_axialGradient *self=(O2Paint_axialGradient *)selfX;
   int i;
   int previous=-1;
   CGPoint point=CGPointMake(x+0.5f, y+0.5f);
   CGSize  delta=CGSizeMake(1.0f,0.0f);
   
   point=CGPointApplyAffineTransform(point,self->m_surfaceToPaintMatrix);
   point=Vector2Subtract(point,self->_startPoint);
   delta=CGSizeApplyAffineTransform(delta,self->m_surfaceToPaintMatrix);
   
   for(i=0;i<length;i++,x++,point.x+=delta.width){
    CGFloat g;
    
    if(self->_rho==0.0f)	//points are equal, gradient is always 1.0f
     g=1.0f;
    else { 
     CGPoint p=point;   

     g=Vector2Dot(p, self->_u)*self->_oou;
    }

    int skip=0;
    KGRGBAffff  value=O2PaintColorRamp(self,g, self->_rho,&skip);
    
    if(skip!=previous){
     if(previous==-1)
      previous=skip;
     else
      return (previous==1)?-i:i;
    }
    
    span[i]=KGRGBA8888FromKGRGBAffff(value);
   }
   return (previous==1)?-length:length;
}

static int linear_span_lRGBAffff_PRE(O2Paint *selfX,int x,int y,KGRGBAffff *span,int length){
   O2Paint_axialGradient *self=(O2Paint_axialGradient *)selfX;
   int i;
   int previous=-1;
   
   for(i=0;i<length;i++,x++){
    CGFloat g;
    
    if(self->_rho==0.0f)	//points are equal, gradient is always 1.0f
     g=1.0f;
    else {    
     CGPoint p=CGPointMake(x+0.5f, y+0.5f);
     p=CGPointApplyAffineTransform(p,self->m_surfaceToPaintMatrix);
     p=Vector2Subtract(p,self->_startPoint);
     g=Vector2Dot(p, self->_u)*self->_oou;
    }

    int skip=0;
    KGRGBAffff  value=O2PaintColorRamp(self,g, self->_rho,&skip);
    
    if(skip!=previous){
     if(previous==-1)
      previous=skip;
     else
      return (previous==1)?-i:i;
    }
    
    span[i]=(value);
   }
   return (previous==1)?-length:length;
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

   _paint_lRGBA8888_PRE=linear_span_lRGBA8888_PRE;
   _paint_lRGBAffff_PRE=linear_span_lRGBAffff_PRE;
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
