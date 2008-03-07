#ifndef __RIDEFS_H
#define __RIDEFS_H

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
 * \brief	Platform- and compiler-dependent type and macro definitions.
 * \note	
 *//*-------------------------------------------------------------------*/

#include <float.h>
#include <math.h>
#include <assert.h>
#include <new>	//for bad_alloc

namespace OpenVGRI
{

//make for-clause scope c++ standard compliant on msvc
#if defined (_MSC_VER)
#	if !defined (for)
		__forceinline bool getFalse (void) { return false; }
#		define for if(getFalse()); else for
#	endif // for

#pragma warning(disable:4710)	//disable function not inlined warning
#pragma warning(disable:4714)	//disable function not __forceinlined warning
#endif  // _MSC_VER

//=======================================================================

typedef int				RIint32;
typedef unsigned int	RIuint32;
typedef short			RIint16;
typedef unsigned short	RIuint16;
typedef signed char		RIint8;
typedef unsigned char	RIuint8;
typedef float			RIfloat32;
//TODO add compile-time assertions to guarantee the sizes

#if defined (_MSC_VER) // MSVC WIN32
#	define RI_INLINE __forceinline
#elif defined __APPLE__ || defined (__GNUC__) || defined (__GCC32__)
#	define RI_INLINE inline
#endif

/*!< Unsigned int that can hold a pointer to any type */
/*!< Signed int that can hold a pointer to any type */
#if defined (_MSC_VER) && (_MSC_VER >= 1300)
typedef uintptr_t		RIuintptr;
typedef intptr_t		RIintptr;
#else
typedef unsigned long   RIuintptr;
typedef signed long     RIintptr;
#endif

#define RI_UINT32_MAX (0xffffffffu)
#define RI_INT32_MAX  (0x7fffffff)
#define RI_INT32_MIN  (-0x7fffffff-1)

/* maximum mantissa is 23 */
#define RI_MANTISSA_BITS 23

/* maximum exponent is 8 */
#define RI_EXPONENT_BITS 8

typedef union
{
	RIfloat32	f;
	RIuint32	i;
} RIfloatInt;

RI_INLINE float	getFloatMax()
{
	RIfloatInt v;
	v.i = (((1<<(RI_EXPONENT_BITS-1))-1+127) << 23) | (((1<<RI_MANTISSA_BITS)-1) << (23-RI_MANTISSA_BITS));
	return v.f;
}
#define RI_FLOAT_MAX  getFloatMax()

#define RI_MAX_IMAGE_WIDTH				16384
#define RI_MAX_IMAGE_HEIGHT				16384
#define RI_MAX_IMAGE_PIXELS				(RI_MAX_IMAGE_WIDTH*RI_MAX_IMAGE_HEIGHT)
#define RI_MAX_IMAGE_BYTES				(4*RI_MAX_IMAGE_WIDTH*RI_MAX_IMAGE_HEIGHT)
#define RI_MAX_DASH_COUNT				256
#define RI_MAX_COLOR_RAMP_STOPS			256
#define RI_MAX_KERNEL_SIZE				256
#define RI_MAX_SEPARABLE_KERNEL_SIZE	256
#define RI_MAX_GAUSSIAN_STD_DEVIATION	128.0f
#define RI_MAX_SCISSOR_RECTANGLES		256
#define RI_MAX_EDGES					262144

#define RI_ASSERT assert
#define RI_DEBUG
#define RI_UNREF(X) ((void)(X))
#define RI_APIENTRY

#define RI_NEW(TYPE, PARAMS)           (new TYPE PARAMS)
#define RI_NEW_ARRAY(TYPE, ITEMS)      (new TYPE[ITEMS])
#define RI_DELETE(PARAMS)              (delete (PARAMS))
#define RI_DELETE_ARRAY(PARAMS)        (delete[] (PARAMS))

bool			isValidImageFormat(int format);

//=======================================================================

}	//namespace OpenVGRI

#endif /* __RIDEFS_H */
