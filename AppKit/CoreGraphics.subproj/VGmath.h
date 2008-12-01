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

#import <math.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>

typedef unsigned char	RIuint8;

//#define RI_ASSERT(_) NSCParameterAssert(_)
#define RI_ASSERT(_) 

static inline int RI_ISNAN(float a) {
    return (a!=a)?1:0;
}

static inline CGFloat	RI_MAX(CGFloat a, CGFloat b)				{ return (a > b) ? a : b; }
static inline CGFloat	RI_MIN(CGFloat a, CGFloat b)				{ return (a < b) ? a : b; }
static inline CGFloat	RI_CLAMP(CGFloat a, CGFloat l, CGFloat h)	{ if(RI_ISNAN(a)) return l; RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }
static inline CGFloat	RI_ABS(CGFloat a)							{ return (a < 0.0f) ? -a : a; }
static inline CGFloat	RI_SQR(CGFloat a)							{ return a * a; }
static inline CGFloat	RI_MOD(CGFloat a, CGFloat b){
   if(RI_ISNAN(a) || RI_ISNAN(b))
    return 0.0f;
    
   RI_ASSERT(b >= 0.0f);
   
   if(b == 0.0f)
    return 0.0f;
    
   CGFloat f = (CGFloat)fmod(a, b);
   
   if(f < 0.0f)
    f += b;
   RI_ASSERT(f >= 0.0f && f <= b);
   return f;
}

static inline int RI_INT_MAX(int a, int b)			{ return (a > b) ? a : b; }
static inline int RI_INT_MIN(int a, int b)			{ return (a < b) ? a : b; }
static inline int RI_INT_MOD(int a, int b)			{ RI_ASSERT(b >= 0); if(!b) return 0; int i = a % b; if(i < 0) i += b; RI_ASSERT(i >= 0 && i < b); return i; }
static inline int RI_INT_CLAMP(int a, int l, int h)	{ RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }

static inline int RI_FLOOR_TO_INT(CGFloat value){
   if(value<0)
    return floor(value);
    
   return value;
}

static inline CGPoint Vector2Subtract(CGPoint v1,CGPoint v2){
   return CGPointMake(v1.x-v2.x, v1.y-v2.y);
}

static inline CGFloat Vector2Dot(CGPoint v1,CGPoint v2){
   return v1.x*v2.x+v1.y*v2.y;
}

//matrix * column vector. 

static inline CGPoint CGAffineTransformTransformVector2(CGAffineTransform m,CGPoint v){
   return CGPointMake(v.x * m.a + v.y * m.c + m.tx, v.x * m.b + v.y * m.d + m.ty);
}

