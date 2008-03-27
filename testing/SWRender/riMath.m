/*------------------------------------------------------------------------
 *
 * OpenVG 1.0.1 Reference Implementation
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

#import "riMath.h"

/*-------------------------------------------------------------------*//*!
* \brief	Inverts a 3x3 m->matrix. Returns false if the matrix is singular.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

bool Matrix3x3InplaceInvert(Matrix3x3 *m)
{
	RIfloat det00 = m->matrix[1][1]*m->matrix[2][2] - m->matrix[2][1]*m->matrix[1][2];
	RIfloat det01 = m->matrix[2][0]*m->matrix[1][2] - m->matrix[1][0]*m->matrix[2][2];
	RIfloat det02 = m->matrix[1][0]*m->matrix[2][1] - m->matrix[2][0]*m->matrix[1][1];

	RIfloat d = m->matrix[0][0]*det00 + m->matrix[0][1]*det01 + m->matrix[0][2]*det02;
	if( d == 0.0f ) return false;	//singular, leave the m->matrix unmodified and return false
	d = 1.0f / d;

	Matrix3x3 t;
	t.matrix[0][0] = d * det00;
	t.matrix[1][0] = d * det01;
	t.matrix[2][0] = d * det02;
	t.matrix[0][1] = d * (m->matrix[2][1]*m->matrix[0][2] - m->matrix[0][1]*m->matrix[2][2]);
	t.matrix[1][1] = d * (m->matrix[0][0]*m->matrix[2][2] - m->matrix[2][0]*m->matrix[0][2]);
	t.matrix[2][1] = d * (m->matrix[2][0]*m->matrix[0][1] - m->matrix[0][0]*m->matrix[2][1]);
	t.matrix[0][2] = d * (m->matrix[0][1]*m->matrix[1][2] - m->matrix[1][1]*m->matrix[0][2]);
	t.matrix[1][2] = d * (m->matrix[1][0]*m->matrix[0][2] - m->matrix[0][0]*m->matrix[1][2]);
	t.matrix[2][2] = d * (m->matrix[0][0]*m->matrix[1][1] - m->matrix[1][0]*m->matrix[0][1]);
	*m = t;
	return true;
}
