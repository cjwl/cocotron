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
 * \brief	Math functions, Vector and Matrix classes.
 * \note	
 *//*-------------------------------------------------------------------*/

#import <float.h>
#import <math.h>
#import <assert.h>
#import <new>	//for bad_alloc
#import <ApplicationServices/ApplicationServices.h>

typedef unsigned char	RIuint8;
typedef float RIfloat;

#define RI_ASSERT(_) assert(_)

#define RI_INT32_MAX  (0x7fffffff)
#define RI_INT32_MIN  (-0x7fffffff-1)

inline int RI_ISNAN(float a) {
    return (a!=a)?1:0;
}

inline RIfloat	RI_MAX(RIfloat a, RIfloat b)				{ return (a > b) ? a : b; }
inline RIfloat	RI_MIN(RIfloat a, RIfloat b)				{ return (a < b) ? a : b; }
inline RIfloat	RI_CLAMP(RIfloat a, RIfloat l, RIfloat h)	{ if(RI_ISNAN(a)) return l; RI_ASSERT(l <= h); return (a < l) ? l : (a > h) ? h : a; }
inline void		RI_SWAP(RIfloat &a, RIfloat &b)				{ RIfloat tmp = a; a = b; b = tmp; }
inline RIfloat	RI_ABS(RIfloat a)							{ return (a < 0.0f) ? -a : a; }
inline RIfloat	RI_SQR(RIfloat a)							{ return a * a; }
inline RIfloat	RI_DEG_TO_RAD(RIfloat a)					{ return a * M_PI / 180.0f; }
inline RIfloat	RI_RAD_TO_DEG(RIfloat a)					{ return a * 180.0f/ M_PI; }
inline RIfloat	RI_MOD(RIfloat a, RIfloat b)				{ if(RI_ISNAN(a) || RI_ISNAN(b)) return 0.0f; RI_ASSERT(b >= 0.0f); if(b == 0.0f) return 0.0f; RIfloat f = (RIfloat)fmod(a, b); if(f < 0.0f) f += b; RI_ASSERT(f >= 0.0f && f <= b); return f; }

inline int		RI_INT_MAX(int a, int b)			{ return (a > b) ? a : b; }
inline int		RI_INT_MIN(int a, int b)			{ return (a < b) ? a : b; }
inline int		RI_INT_MOD(int a, int b)			{ RI_ASSERT(b >= 0); if(!b) return 0; int i = a % b; if(i < 0) i += b; RI_ASSERT(i >= 0 && i < b); return i; }
inline int		RI_INT_ADDSATURATE(int a, int b)	{ RI_ASSERT(b >= 0); int r = a + b; return (r >= a) ? r : RI_INT32_MAX; }

class Vector2 {
public:
	inline					Vector2			() : x(0.0f), y(0.0f)					{}
	inline					Vector2			( const Vector2& v ) : x(v.x), y(v.y)	{}
	inline					Vector2			( RIfloat fx, RIfloat fy ) : x(fx), y(fy)	{}
	inline const Vector2		operator-		() const						{ return Vector2(-x,-y); }
	inline void				set				( RIfloat fx, RIfloat fy )			{ x = fx; y = fy; }
	inline RIfloat			length			() const						{ return (RIfloat)sqrt((double)x*(double)x+(double)y*(double)y); }
	inline bool				normalize		()								{ double l = (double)x*(double)x+(double)y*(double)y; if( l == 0.0 ) return false; l = 1.0 / sqrt(l); x = (RIfloat)((double)x * l); y = (RIfloat)((double)y * l); return true; }
	inline void				operator*=		( RIfloat f )						{ x *= f; y *= f; }
	inline void				operator-=		( const Vector2& v )			{ x -= v.x; y -= v.y; }

	RIfloat						x,y;
};

inline bool			operator==	( const Vector2& v1, const Vector2& v2 )	{ return (v1.x == v2.x) && (v1.y == v2.y); }
inline bool			operator!=	( const Vector2& v1, const Vector2& v2 )	{ return (v1.x != v2.x) || (v1.y != v2.y); }
inline bool			isZero		( const Vector2& v )						{ return (v.x == 0.0f) && (v.y == 0.0f); }
inline const Vector2	operator*	( RIfloat f, const Vector2& v )				{ return Vector2(v.x*f,v.y*f); }
inline const Vector2	operator*	( const Vector2& v, RIfloat f )				{ return Vector2(v.x*f,v.y*f); }
inline const Vector2	operator+	( const Vector2& v1, const Vector2& v2 )	{ return Vector2(v1.x+v2.x, v1.y+v2.y); }
inline const Vector2	operator-	( const Vector2& v1, const Vector2& v2 )	{ return Vector2(v1.x-v2.x, v1.y-v2.y); }
inline RIfloat		dot			( const Vector2& v1, const Vector2& v2 )	{ return v1.x*v2.x+v1.y*v2.y; }
//if v is a zero vector, returns a zero vector
inline const Vector2	normalize	( const Vector2& v )						{ double l = (double)v.x*(double)v.x+(double)v.y*(double)v.y; if( l != 0.0 ) l = 1.0 / sqrt(l); return Vector2((RIfloat)((double)v.x * l), (RIfloat)((double)v.y * l)); }

inline const Vector2 perpendicularCW(const Vector2& v)						{ return Vector2(v.y, -v.x); }
inline const Vector2 perpendicularCCW(const Vector2& v)						{ return Vector2(-v.y, v.x); }
inline const Vector2 perpendicular(const Vector2& v, bool cw)				{ if(cw) return Vector2(v.y, -v.x); return Vector2(-v.y, v.x); }


class Vector3 {
public:
	inline					Vector3			( RIfloat fx, RIfloat fy ) : x(fx), y(fy), z(1)	{}
	inline					Vector3			( RIfloat fx, RIfloat fy, RIfloat fz ) : x(fx), y(fy), z(fz)	{}
	inline const RIfloat&	operator[]		( int i ) const					{ RI_ASSERT(i>=0&&i<3); return (&x)[i]; }
	inline RIfloat&			operator[]		( int i )						{ RI_ASSERT(i>=0&&i<3); return (&x)[i]; }
	inline void				set				( RIfloat fx, RIfloat fy, RIfloat fz ){ x = fx; y = fy; z = fz; }

	RIfloat						x,y,z;
};

static inline Vector3 Vector3MultiplyByFloat(Vector3 v,RIfloat f){
   v.x *= f;
   v.y *= f;
   v.z *= f; 
   return v;
}

//indexing: matrix[row][column]

class Matrix3x3 {
public:

inline					Matrix3x3	()									{ identity(); }
inline					Matrix3x3	( const Matrix3x3& m )				{ *this = m; }
inline					Matrix3x3	( RIfloat m00, RIfloat m01, RIfloat m02, RIfloat m10, RIfloat m11, RIfloat m12, RIfloat m20, RIfloat m21, RIfloat m22 )	{ set(m00,m01,m02,m10,m11,m12,m20,m21,m22); }
inline                   Matrix3x3       (CGAffineTransform transform) {
   matrix[0][0]=transform.a;
   matrix[0][1]=transform.c;
   matrix[0][2]=transform.tx;
   matrix[1][0]=transform.b;
   matrix[1][1]=transform.d;
   matrix[1][2]=transform.ty;
   matrix[2][0]=0;
   matrix[2][1]=0;
   matrix[2][2]=1;
}

inline Matrix3x3&		operator=	( const Matrix3x3& m )				{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] = m.matrix[i][j]; return *this; }
inline Vector3&			operator[]	( int i )							{ RI_ASSERT(i>=0&&i<3); return (Vector3&)matrix[i][0]; }
inline const Vector3&	operator[]	( int i ) const						{ RI_ASSERT(i>=0&&i<3); return (const Vector3&)matrix[i][0]; }
inline void				set			( RIfloat m00, RIfloat m01, RIfloat m02, RIfloat m10, RIfloat m11, RIfloat m12, RIfloat m20, RIfloat m21, RIfloat m22 ) { matrix[0][0] = m00; matrix[0][1] = m01; matrix[0][2] = m02; matrix[1][0] = m10; matrix[1][1] = m11; matrix[1][2] = m12; matrix[2][0] = m20; matrix[2][1] = m21; matrix[2][2] = m22; }
	inline void				operator*=		( const Matrix3x3& m );
inline void				operator*=	( RIfloat f )							{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] *= f; }
inline void				operator+=	( const Matrix3x3& m )				{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] += m.matrix[i][j]; }
inline void				operator-=	( const Matrix3x3& m )				{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] -= m.matrix[i][j]; }
inline void				identity		()									{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) matrix[i][j] = (i == j) ? 1.0f : 0.0f; }
	bool						invert			();	//if the matrix is singular, returns false and leaves it unmodified
	inline bool				isAffine		() const;

// private
	RIfloat						matrix[3][3];
};

//Matrix3x3 global functions
inline bool				operator==	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ for(int i=0;i<3;i++) for(int j=0;j<3;j++) if( m1[i][j] != m2[i][j] ) return false; return true; }
inline bool				operator!=	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ return !(m1 == m2); }
inline const Matrix3x3	operator*	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ Matrix3x3 t; for(int i=0;i<3;i++) for(int j=0;j<3;j++) t[i][j] = m1[i][0] * m2[0][j] + m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j]; return t; }
inline const Matrix3x3	operator*	( RIfloat f, const Matrix3x3& m )					{ Matrix3x3 t(m); t *= f; return t; }
inline const Matrix3x3	operator*	( const Matrix3x3& m, RIfloat f )					{ Matrix3x3 t(m); t *= f; return t; }
inline const Matrix3x3	operator+	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ Matrix3x3 t(m1); t += m2; return t; }
inline const Matrix3x3	operator-	( const Matrix3x3& m1, const Matrix3x3& m2 )	{ Matrix3x3 t(m1); t -= m2; return t; }
// if the matrix is singular, returns it unmodified
inline const Matrix3x3	invert		( const Matrix3x3& m )							{ Matrix3x3 t(m); t.invert(); return t; }

//Matrix3x3 inline functions (cannot be inside the class because Vector3 is not defined yet when Matrix3x3 is defined)
inline void				Matrix3x3::operator*=	( const Matrix3x3& m )				{ *this = *this * m; }
inline bool				Matrix3x3::isAffine		() const							{ if(matrix[2][0] == 0.0f && matrix[2][1] == 0.0f && matrix[2][2] == 1.0f) return true; return false; }


//matrix * column vector. The input vector2 is implicitly expanded to (x,y,1)
inline const Vector2 affineTransform( const Matrix3x3& m, const Vector2& v )	{ RI_ASSERT(m.isAffine()); return Vector2(v.x * m[0][0] + v.y * m[0][1] + m[0][2], v.x * m[1][0] + v.y * m[1][1] + m[1][2]); }
//matrix * column vector. The input vector2 is implicitly expanded to (x,y,0)
inline const Vector2 affineTangentTransform(const Matrix3x3& m, const Vector2& v)	{ RI_ASSERT(m.isAffine()); return Vector2(v.x * m[0][0] + v.y * m[0][1], v.x * m[1][0] + v.y * m[1][1]); }


//matrix * column vector
inline const Vector3	operator*	( const Matrix3x3& m, const Vector3& v)		{ return Vector3( v.x*m[0][0]+v.y*m[0][1]+v.z*m[0][2], v.x*m[1][0]+v.y*m[1][1]+v.z*m[1][2], v.x*m[2][0]+v.y*m[2][1]+v.z*m[2][2] ); }


