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
#import <Onyx2D/O2Paint_pattern.h>
#import <Onyx2D/O2Surface.h>

@implementation O2Paint_pattern

static int O2PaintReadPremultipliedPatternSpan(O2Paint *selfX,int x,int y,O2argb32f *span,int length){
   O2Paint_pattern *self=(O2Paint_pattern *)selfX;
   
   O2ImageReadPatternSpan_lRGBAffff_PRE(self->m_pattern,x, y,span,length, self->m_surfaceToPaintMatrix, kO2PatternTilingConstantSpacing);
   return length;
}

-initWithImage:(O2Image *)image {
   self->m_surfaceToPaintMatrix=O2AffineTransformIdentity;
   _paint_lRGBAffff_PRE=O2PaintReadPremultipliedPatternSpan;
   m_pattern=[image retain];
   return self;
}

-(void)dealloc {
   [m_pattern release];
   [super dealloc];
}

@end
