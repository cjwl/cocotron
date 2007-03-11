/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/CGAffineTransform.h>

enum {
   KGPathFill,
   KGPathEOFill,
   KGPathStroke,
   KGPathFillStroke,
   KGPathEOFillStroke
};

enum {
   KGPathOperatorMoveToPoint,
   KGPathOperatorLineToPoint,
   KGPathOperatorCurveToPoint,
   KGPathOperatorQuadCurveToPoint,
   KGPathOperatorCloseSubpath
};

@interface KGPath : NSObject <NSCopying,NSMutableCopying> {
   unsigned       _numberOfOperators;
   unsigned char *_operators;
   unsigned       _numberOfPoints;
   NSPoint       *_points;
}

-initWithOperators:(unsigned char *)operators numberOfOperators:(unsigned)numberOfOperators points:(NSPoint *)points numberOfPoints:(unsigned)numberOfPoints;

-(unsigned)numberOfOperators;
-(const unsigned char *)operators;

-(unsigned)numberOfPoints;
-(const NSPoint *)points;

-(NSPoint)currentPoint;

-(BOOL)isEqualToPath:(KGPath *)other;

-(BOOL)isEmpty;
-(BOOL)isRect;

-(BOOL)containsPoint:(NSPoint)point evenOdd:(BOOL)evenOdd withTransform:(CGAffineTransform *)matrix;

-(NSRect)boundingBox;

@end
