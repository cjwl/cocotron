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

#define RI_INT32_MAX  (0x7fffffff)
#define RI_INT32_MIN  (-0x7fffffff-1)

static inline int RI_ISNAN(float a) {
    return (a!=a)?1:0;
}

static inline CGFloat	RI_MAX(CGFloat a, CGFloat b)				{ return (a > b) ? a : b; }
static inline CGFloat	RI_MIN(CGFloat a, CGFloat b)				{ return (a < b) ? a : b; }
static inline CGFloat	RI_CLAMP(CGFloat a, CGFloat l, CGFloat h)	{ if(RI_ISNAN(a)) return l; RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }
static inline void		RI_SWAP(CGFloat *a, CGFloat *b)				{ CGFloat tmp = *a; *a = *b; *b = tmp; }
static inline CGFloat	RI_ABS(CGFloat a)							{ return (a < 0.0f) ? -a : a; }
static inline CGFloat	RI_SQR(CGFloat a)							{ return a * a; }
static inline CGFloat	RI_DEG_TO_RAD(CGFloat a)					{ return (CGFloat)(a * M_PI / 180.0f); }
static inline CGFloat	RI_RAD_TO_DEG(CGFloat a)					{ return (CGFloat)(a * 180.0f/ M_PI); }
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
static inline int RI_INT_ADDSATURATE(int a, int b)	{ RI_ASSERT(b >= 0); int r = a + b; return (r >= a) ? r : RI_INT32_MAX; }
static inline int RI_INT_CLAMP(int a, int l, int h)	{ RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }

static inline int RI_FLOOR_TO_INT(CGFloat value){
   if(value<0)
    return floor(value);
    
   return value;
}

static inline CGPoint Vector2Make(CGFloat fx,CGFloat fy){
   CGPoint result;
   result.x=fx;
   result.y=fy;
   return result;
}

static inline CGPoint Vector2Negate(CGPoint result){
   return Vector2Make(-result.x,-result.y);
}

static inline CGFloat Vector2Length(CGPoint v){
   return (CGFloat)sqrt((double)v.x*(double)v.x+(double)v.y*(double)v.y);
}

static inline BOOL Vector2IsEqual(CGPoint v1,CGPoint v2 ){
   return (v1.x == v2.x) && (v1.y == v2.y);
}

static inline BOOL Vector2IsZero(CGPoint v){
  return (v.x == 0.0f) && (v.y == 0.0f);
}

static inline CGPoint Vector2MultiplyByFloat(CGPoint v,CGFloat f){
   return Vector2Make(v.x*f,v.y*f);
}

static inline CGPoint Vector2Add(CGPoint v1,CGPoint v2 ){
   return Vector2Make(v1.x+v2.x, v1.y+v2.y);
}

static inline CGPoint Vector2Subtract(CGPoint v1,CGPoint v2){
   return Vector2Make(v1.x-v2.x, v1.y-v2.y);
}

static inline CGFloat Vector2Dot(CGPoint v1,CGPoint v2){
   return v1.x*v2.x+v1.y*v2.y;
}

//if v is a zero vector, returns a zero vector
static inline CGPoint Vector2Normalize(CGPoint v){
   double l = (double)v.x*(double)v.x+(double)v.y*(double)v.y;
   
   if( l != 0.0 )
    l = 1.0 / sqrt(l);
    
   return Vector2Make((CGFloat)((double)v.x * l), (CGFloat)((double)v.y * l));
}

static inline CGPoint Vector2PerpendicularCW(CGPoint v){
   return Vector2Make(v.y, -v.x);
}

static inline CGPoint Vector2PerpendicularCCW(CGPoint v){
   return Vector2Make(-v.y, v.x);
}

static inline CGPoint Vector2Perpendicular(CGPoint v, BOOL cw){
   if(cw)
    return Vector2Make(v.y, -v.x);
    
   return Vector2Make(-v.y, v.x);
}

typedef struct {    
   CGFloat matrix[3][3];
} Matrix3x3;

static inline Matrix3x3 Matrix3x3Identity(){
   Matrix3x3 result;
   int       i,j;
   
   for(i=0;i<3;i++)
    for(j=0;j<3;j++)
     result.matrix[i][j] = (i == j) ? 1.0f : 0.0f;
     
   return result;
}

static inline Matrix3x3 Matrix3x3WithCGAffineTransform(CGAffineTransform transform) {
   Matrix3x3 result;

   result.matrix[0][0]=transform.a;
   result.matrix[0][1]=transform.c;
   result.matrix[0][2]=transform.tx;
   result.matrix[1][0]=transform.b;
   result.matrix[1][1]=transform.d;
   result.matrix[1][2]=transform.ty;
   result.matrix[2][0]=0;
   result.matrix[2][1]=0;
   result.matrix[2][2]=1;

   return result;
}

BOOL Matrix3x3InplaceInvert(Matrix3x3 *m);

static inline Matrix3x3 Matrix3x3Multiply(Matrix3x3 m1,Matrix3x3 m2){
   Matrix3x3 t;
   int       i,j;
   
   for(i=0;i<3;i++)
    for(j=0;j<3;j++)
     t.matrix[i][j] = m1.matrix[i][0] * m2.matrix[0][j] + m1.matrix[i][1] * m2.matrix[1][j] + m1.matrix[i][2] * m2.matrix[2][j];
     
   return t;
}

static inline BOOL Matrix3x3IsAffine(Matrix3x3 m){
   return (m.matrix[2][0] == 0.0f && m.matrix[2][1] == 0.0f && m.matrix[2][2] == 1.0f)?YES:NO;
}

 static inline void Matrix3x3ForceAffinity(Matrix3x3 *xform){
   xform->matrix[2][0]=0;
   xform->matrix[2][1]=0;
   xform->matrix[2][2]=1;
}

//matrix * column vector. The input vector2 is implicitly expanded to (x,y,1)
static inline CGPoint Matrix3x3TransformVector2(Matrix3x3 m,CGPoint v){
   RI_ASSERT(Matrix3x3IsAffine(m));
   return Vector2Make(v.x * m.matrix[0][0] + v.y * m.matrix[0][1] + m.matrix[0][2], v.x * m.matrix[1][0] + v.y * m.matrix[1][1] + m.matrix[1][2]);
}



