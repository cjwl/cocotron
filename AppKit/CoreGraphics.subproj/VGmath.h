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
typedef float RIfloat;

//#define RI_ASSERT(_) NSCParameterAssert(_)
#define RI_ASSERT(_) 

#define RI_INT32_MAX  (0x7fffffff)
#define RI_INT32_MIN  (-0x7fffffff-1)

static inline int RI_ISNAN(float a) {
    return (a!=a)?1:0;
}

static inline RIfloat	RI_MAX(RIfloat a, RIfloat b)				{ return (a > b) ? a : b; }
static inline RIfloat	RI_MIN(RIfloat a, RIfloat b)				{ return (a < b) ? a : b; }
static inline RIfloat	RI_CLAMP(RIfloat a, RIfloat l, RIfloat h)	{ if(RI_ISNAN(a)) return l; RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }
static inline void		RI_SWAP(RIfloat *a, RIfloat *b)				{ RIfloat tmp = *a; *a = *b; *b = tmp; }
static inline RIfloat	RI_ABS(RIfloat a)							{ return (a < 0.0f) ? -a : a; }
static inline RIfloat	RI_SQR(RIfloat a)							{ return a * a; }
static inline RIfloat	RI_DEG_TO_RAD(RIfloat a)					{ return (RIfloat)(a * M_PI / 180.0f); }
static inline RIfloat	RI_RAD_TO_DEG(RIfloat a)					{ return (RIfloat)(a * 180.0f/ M_PI); }
static inline RIfloat	RI_MOD(RIfloat a, RIfloat b){
   if(RI_ISNAN(a) || RI_ISNAN(b))
    return 0.0f;
    
   RI_ASSERT(b >= 0.0f);
   
   if(b == 0.0f)
    return 0.0f;
    
   RIfloat f = (RIfloat)fmod(a, b);
   
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

static inline int RI_FLOOR_TO_INT(RIfloat value){
   if(value<0)
    return floor(value);
    
   return value;
}

typedef CGPoint Vector2;

static inline Vector2 Vector2Make(RIfloat fx,RIfloat fy){
   Vector2 result;
   result.x=fx;
   result.y=fy;
   return result;
}

static inline Vector2 Vector2Negate(Vector2 result){
   return Vector2Make(-result.x,-result.y);
}

static inline RIfloat Vector2Length(Vector2 v){
   return (RIfloat)sqrt((double)v.x*(double)v.x+(double)v.y*(double)v.y);
}

static inline BOOL Vector2IsEqual(Vector2 v1,Vector2 v2 ){
   return (v1.x == v2.x) && (v1.y == v2.y);
}

static inline BOOL Vector2IsZero(Vector2 v){
  return (v.x == 0.0f) && (v.y == 0.0f);
}

static inline Vector2 Vector2MultiplyByFloat(Vector2 v,RIfloat f){
   return Vector2Make(v.x*f,v.y*f);
}

static inline Vector2 Vector2Add(Vector2 v1,Vector2 v2 ){
   return Vector2Make(v1.x+v2.x, v1.y+v2.y);
}

static inline Vector2 Vector2Subtract(Vector2 v1,Vector2 v2){
   return Vector2Make(v1.x-v2.x, v1.y-v2.y);
}

static inline RIfloat Vector2Dot(Vector2 v1,Vector2 v2){
   return v1.x*v2.x+v1.y*v2.y;
}

//if v is a zero vector, returns a zero vector
static inline Vector2 Vector2Normalize(Vector2 v){
   double l = (double)v.x*(double)v.x+(double)v.y*(double)v.y;
   
   if( l != 0.0 )
    l = 1.0 / sqrt(l);
    
   return Vector2Make((RIfloat)((double)v.x * l), (RIfloat)((double)v.y * l));
}

static inline Vector2 Vector2PerpendicularCW(Vector2 v){
   return Vector2Make(v.y, -v.x);
}

static inline Vector2 Vector2PerpendicularCCW(Vector2 v){
   return Vector2Make(-v.y, v.x);
}

static inline Vector2 Vector2Perpendicular(Vector2 v, BOOL cw){
   if(cw)
    return Vector2Make(v.y, -v.x);
    
   return Vector2Make(-v.y, v.x);
}

typedef struct  {
   RIfloat x,y,z;
} Vector3;

static inline Vector3 Vector3Make( RIfloat fx, RIfloat fy, RIfloat fz ){
   Vector3 result;
   result.x=fx;
   result.y=fy;
   result.z=fz;
   return result;
}

static inline Vector3 Vector3MultiplyByFloat(Vector3 v,RIfloat f){
   v.x *= f;
   v.y *= f;
   v.z *= f; 
   return v;
}

typedef struct {    
   RIfloat matrix[3][3];
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
static inline Vector2 Matrix3x3TransformVector2(Matrix3x3 m,Vector2 v){
   RI_ASSERT(Matrix3x3IsAffine(m));
   return Vector2Make(v.x * m.matrix[0][0] + v.y * m.matrix[0][1] + m.matrix[0][2], v.x * m.matrix[1][0] + v.y * m.matrix[1][1] + m.matrix[1][2]);
}

//matrix * column vector
static inline Vector3 Matrix3x3MultiplyVector3( Matrix3x3 m,Vector3 v){
   return Vector3Make(v.x*m.matrix[0][0]+v.y*m.matrix[0][1]+v.z*m.matrix[0][2],v.x*m.matrix[1][0]+v.y*m.matrix[1][1]+v.z*m.matrix[1][2], v.x*m.matrix[2][0]+v.y*m.matrix[2][1]+v.z*m.matrix[2][2] );
}


