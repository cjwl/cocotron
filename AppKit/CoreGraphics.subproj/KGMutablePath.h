/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPath.h"
#import <AppKit/CGAffineTransform.h>

void KGMutablePathEllipseToBezier(NSPoint *cp,float x,float y,float xradius,float yradius);

@interface KGMutablePath : KGPath <NSCopying> {
   unsigned _capacityOfOperators;
   unsigned _capacityOfPoints;
}

-(void)reset;

-(void)moveToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix;
-(void)addLineToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix;
-(void)addCurveToControlPoint:(NSPoint)cp1 controlPoint:(NSPoint)cp2 endPoint:(NSPoint)endPoint withTransform:(CGAffineTransform *)matrix;
-(void)addCurveToControlPoint:(NSPoint)cp1 endPoint:(NSPoint)endPoint withTransform:(CGAffineTransform *)matrix;
-(void)closeSubpath;

-(void)relativeMoveToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix;
-(void)addRelativeLineToPoint:(NSPoint)point withTransform:(CGAffineTransform *)matrix;
-(void)addRelativeCurveToControlPoint:(NSPoint)cp1 controlPoint:(NSPoint)cp2 endPoint:(NSPoint)endPoint withTransform:(CGAffineTransform *)matrix;

-(void)addLinesWithPoints:(NSPoint *)points count:(unsigned)count withTransform:(CGAffineTransform *)matrix;

-(void)addRect:(NSRect)rect withTransform:(CGAffineTransform *)matrix;
-(void)addRects:(NSRect *)rects count:(unsigned)count withTransform:(CGAffineTransform *)matrix;

-(void)addArcAtPoint:(NSPoint)point radius:(float)radius startAngle:(float)startRadian endAngle:(float)endRadian clockwise:(BOOL)clockwise withTransform:(CGAffineTransform *)matrix;
-(void)addArcToPoint:(NSPoint)point1 point:(NSPoint)point2 radius:(float)radius withTransform:(CGAffineTransform *)matrix;

-(void)addEllipseInRect:(NSRect)rect withTransform:(CGAffineTransform *)matrix;

-(void)addPath:(KGPath *)path withTransform:(CGAffineTransform *)matrix;

-(void)applyTransform:(CGAffineTransform)matrix;

-(void)setPoints:(NSPoint *)points count:(unsigned)count atIndex:(unsigned)index;

@end
