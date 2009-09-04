/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>
#import "O2ColorSpace.h"

@class O2ColorSpace,KGFunction;

@interface KGShading : NSObject {
   O2ColorSpaceRef _colorSpace;
   CGPoint       _startPoint;
   CGPoint       _endPoint;
   KGFunction   *_function;
   BOOL          _extendStart;
   BOOL          _extendEnd;
   BOOL          _isRadial;
   float         _startRadius;
   float         _endRadius;
   float         _domain[2];
}

-initWithColorSpace:(O2ColorSpaceRef)colorSpace startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd domain:(float[2])domain;

-initWithColorSpace:(O2ColorSpaceRef)colorSpace startPoint:(CGPoint)startPoint startRadius:(float)startRadius endPoint:(CGPoint)endPoint endRadius:(float)endRadius function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd domain:(float[2])domain;

-(O2ColorSpaceRef)colorSpace;

-(CGPoint)startPoint;
-(CGPoint)endPoint;

-(float)startRadius;
-(float)endRadius;

-(BOOL)extendStart;
-(BOOL)extendEnd;

-(KGFunction *)function;

-(BOOL)isAxial;

@end
