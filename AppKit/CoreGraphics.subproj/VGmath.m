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
 *//**
 * \file
 * \brief	Implementation of non-inline matrix functions.
 * \note	
 *//*-------------------------------------------------------------------*/

#import "VGmath.h"

/*-------------------------------------------------------------------*//*!
* \brief	Inverts a 3x3 m->mat. Returns NO if the matrix is singular.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

BOOL Matrix3x3InplaceInvert(CGAffineTransform *m)
{
	CGFloat det00 = m->d ;
	CGFloat det01 =  - m->b;

	CGFloat d = m->a*det00 + m->c*det01 ;
	if( d == 0.0f ) return NO;	//singular, leave the m->mat unmodified and return NO
	d = 1.0f / d;

	CGAffineTransform t;
	t.a = d * det00;
	t.b = d * det01;
	t.c = d * ( - m->c);
	t.d = d * (m->a );
	t.tx = d * (m->c*m->ty - m->d*m->tx);
	t.ty = d * (m->b*m->tx - m->a*m->ty);
	*m = t;
	return YES;
}
