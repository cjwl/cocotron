/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSGeometry.h>

typedef struct {
   float m11;
   float m12;
   float m21;
   float m22;
   float tX;
   float tY;
} NSAffineTransformStruct;

@interface NSAffineTransform : NSObject <NSCopying> {
   NSAffineTransformStruct _matrix;
}

-initWithTransform:(NSAffineTransform *)other;

+(NSAffineTransform *)transform;

-(NSAffineTransformStruct)transformStruct;
-(void)setTransformStruct:(NSAffineTransformStruct)matrix;

-(void)invert;

-(void)appendTransform:(NSAffineTransform *)other;
-(void)prependTransform:(NSAffineTransform *)other;

-(void)translateXBy:(float)xby yBy:(float)yby;

-(NSPoint)transformPoint:(NSPoint)point;


@end
