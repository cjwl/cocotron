/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSAffineTransform.h>

@implementation NSAffineTransform

static inline NSAffineTransformStruct multiplyStruct(NSAffineTransformStruct start, NSAffineTransformStruct append){
   NSAffineTransformStruct result;

   result.m11=append.m11*start.m11+append.m12*start.m21;
   result.m12=append.m11*start.m12+append.m12*start.m22;
   result.m21=append.m21*start.m11+append.m22*start.m21;
   result.m22=append.m21*start.m12+append.m22*start.m22;
   result.tX=append.tX*start.m11+append.tY*start.m21+start.tX;
   result.tY=append.tX*start.m12+append.tY*start.m22+start.tY;

   return result;
}

static inline NSAffineTransformStruct invertStruct(NSAffineTransformStruct matrix){
   NSAffineTransformStruct result;
   float determinant;

   determinant=matrix.m11*matrix.m22-matrix.m21*matrix.m12;

   result.m11=matrix.m22/determinant;
   result.m12=-matrix.m12/determinant;
   result.m21=-matrix.m21/determinant;
   result.m22=matrix.m11/determinant;
   result.tX=(-matrix.m22*matrix.tX+matrix.m21*matrix.tY)/determinant;
   result.tY=(matrix.m12*matrix.tX-matrix.m11*matrix.tY)/determinant;

   return result;
}

-init {
   _matrix.m11=1;
   _matrix.m12=0;
   _matrix.m21=0;
   _matrix.m22=1;
   _matrix.tX=0;
   _matrix.tY=0;
   return self;
}

-initWithTransform:(NSAffineTransform *)other {
   _matrix=[other transformStruct];
   return self;
}

-copyWithZone:(NSZone *)zone {
   return [[NSAffineTransform alloc] initWithTransform:self];
}

+(NSAffineTransform *)transform {
   return [[self new] autorelease];
}

-(NSAffineTransformStruct)transformStruct {
   return _matrix;
}

-(void)setTransformStruct:(NSAffineTransformStruct)matrix {
   _matrix=matrix;
}

-(void)invert {
   _matrix=invertStruct(_matrix);
}

-(void)appendTransform:(NSAffineTransform *)other {
   _matrix=multiplyStruct(_matrix,[other transformStruct]);
}

-(void)prependTransform:(NSAffineTransform *)other {
   _matrix=multiplyStruct([other transformStruct],_matrix);
}

-(void)translateXBy:(float)xby yBy:(float)yby {
   NSAffineTransformStruct translate={1,0,0,1,xby,yby};
   _matrix=multiplyStruct(_matrix,translate);
}

-(NSPoint)transformPoint:(NSPoint)point {
   NSPoint result;

   result.x=_matrix.m11*point.x+_matrix.m21*point.y+_matrix.tX;
   result.y=_matrix.m12*point.x+_matrix.m22*point.y+_matrix.tY;

   return result;
}

@end
