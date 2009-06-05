/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <CoreGraphics/CGPath.h>
#import "KGPath.h"
#import "KGMutablePath.h"

void CGPathRelease(CGPathRef self) {
   [self release];
}

CGPathRef CGPathRetain(CGPathRef self) {
   return [self retain];
}

BOOL CGPathEqualToPath(CGPathRef self,CGPathRef other) {
   return [self isEqualToPath:other];
}

CGRect CGPathGetBoundingBox(CGPathRef self) {
   return [self boundingBox];
}

CGPoint CGPathGetCurrentPoint(CGPathRef self) {
   return [self currentPoint];
}

BOOL CGPathIsEmpty(CGPathRef self) {
   return [self isEmpty];
}

BOOL CGPathIsRect(CGPathRef self,CGRect *rect) {
   return [self isRect:rect];
}

void CGPathApply(CGPathRef self,void *info,CGPathApplierFunction function) {
   return [self applyWithInfo:info function:function];
}

CGMutablePathRef CGPathCreateMutableCopy(CGPathRef self) {
   return [self mutableCopy];
}

CGPathRef CGPathCreateCopy(CGPathRef self) {
   return [self copy];
}

BOOL CGPathContainsPoint(CGPathRef self,const CGAffineTransform *xform,CGPoint point,BOOL evenOdd) {
   return [self containsPoint:point evenOdd:evenOdd withTransform:xform];
}

CGMutablePathRef CGPathCreateMutable(void) {
   return [[KGMutablePath alloc] init];
}

void CGPathMoveToPoint(CGMutablePathRef self,const CGAffineTransform *xform,CGFloat x,CGFloat y) {
   [self moveToPoint:CGPointMake(x,y) withTransform:xform];
}

void CGPathAddLineToPoint(CGMutablePathRef self,const CGAffineTransform *xform,CGFloat x,CGFloat y) {
   [self addLineToPoint:CGPointMake(x,y) withTransform:xform];
}

void CGPathAddCurveToPoint(CGMutablePathRef self,const CGAffineTransform *xform,CGFloat cp1x,CGFloat cp1y,CGFloat cp2x,CGFloat cp2y,CGFloat x,CGFloat y) {
   [self addCurveToControlPoint:CGPointMake(cp1x,cp1y) controlPoint:CGPointMake(cp2x,cp2y) endPoint:CGPointMake(x,y) withTransform:xform];
}

void CGPathAddQuadCurveToPoint(CGMutablePathRef self,const CGAffineTransform *xform,CGFloat cpx,CGFloat cpy,CGFloat x,CGFloat y) {
   [self addQuadCurveToControlPoint:CGPointMake(cpx,cpy) endPoint:CGPointMake(x,y) withTransform:xform];
}

void CGPathCloseSubpath(CGMutablePathRef self) {
   [self closeSubpath];
}

void CGPathAddLines(CGMutablePathRef self,const CGAffineTransform *xform,const CGPoint *points,size_t count) {
   [self addLinesWithPoints:points count:count withTransform:xform];
}

void CGPathAddRect(CGMutablePathRef self,const CGAffineTransform *xform,CGRect rect) {
   [self addRect:rect withTransform:xform];
}

void CGPathAddRects(CGMutablePathRef self,const CGAffineTransform *xform,const CGRect *rects,size_t count) {
   [self addRects:rects count:count withTransform:xform];
}

void CGPathAddArc(CGMutablePathRef self,const CGAffineTransform *xform,CGFloat x,CGFloat y,CGFloat radius,CGFloat startRadian,CGFloat endRadian,BOOL clockwise) {
   [self addArcAtPoint:CGPointMake(x,y) radius:radius startAngle:startRadian endAngle:endRadian clockwise:clockwise withTransform:xform];
}

void CGPathAddArcToPoint(CGMutablePathRef self,const CGAffineTransform *xform,CGFloat tx1,CGFloat ty1,CGFloat tx2,CGFloat ty2,CGFloat radius) {
   [self addArcToPoint:CGPointMake(tx1,ty1) point:CGPointMake(tx2,ty2) radius:radius withTransform:xform];
}

void CGPathAddEllipseInRect(CGMutablePathRef self,const CGAffineTransform *xform,CGRect rect) {
   [self addEllipseInRect:rect withTransform:xform];
}

void CGPathAddPath(CGMutablePathRef self,const CGAffineTransform *xform,CGPathRef other) {
   [self addPath:other withTransform:xform];
}
