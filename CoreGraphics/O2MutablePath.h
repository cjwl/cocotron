/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "O2Path.h"
#import <CoreGraphics/CoreGraphics.h>

@interface O2MutablePath : O2Path <NSCopying> {
   unsigned _capacityOfElements;
   unsigned _capacityOfPoints;
}

void O2PathReset(O2MutablePathRef self);

O2MutablePathRef O2PathCreateMutable(void);
void O2PathMoveToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat x,CGFloat y);
void O2PathAddLineToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat x,CGFloat y);
void O2PathAddCurveToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat cp1x,CGFloat cp1y,CGFloat cp2x,CGFloat cp2y,CGFloat x,CGFloat y);
void O2PathAddQuadCurveToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat cpx,CGFloat cpy,CGFloat x,CGFloat y);
void O2PathCloseSubpath(O2MutablePathRef self);
void O2PathAddLines(O2MutablePathRef self,const CGAffineTransform *matrix,const CGPoint *points,size_t count);
void O2PathAddRect(O2MutablePathRef self,const CGAffineTransform *matrix,CGRect rect);
void O2PathAddRects(O2MutablePathRef self,const CGAffineTransform *matrix,const CGRect *rects,size_t count);
void O2PathAddArc(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat x,CGFloat y,CGFloat radius,CGFloat startRadian,CGFloat endRadian,BOOL clockwise);
void O2PathAddArcToPoint(O2MutablePathRef self,const CGAffineTransform *matrix,CGFloat tx1,CGFloat ty1,CGFloat tx2,CGFloat ty2,CGFloat radius);
void O2PathAddEllipseInRect(O2MutablePathRef self,const CGAffineTransform *matrix,CGRect rect);
void O2PathAddPath(O2MutablePathRef self,const CGAffineTransform *matrix,O2PathRef other);

void O2PathApplyTransform(O2MutablePathRef self,const CGAffineTransform matrix);
void O2MutablePathEllipseToBezier(CGPoint *cp,float x,float y,float xrad,float yrad);

@end
