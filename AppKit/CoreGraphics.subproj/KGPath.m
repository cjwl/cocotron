/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPath.h"
#import "KGMutablePath.h"
#import "KGExceptions.h"

@implementation KGPath

-initWithOperators:(unsigned char *)operators numberOfOperators:(unsigned)numberOfOperators points:(CGPoint *)points numberOfPoints:(unsigned)numberOfPoints {
   int i;
   
   _numberOfOperators=numberOfOperators;
   _operators=NSZoneMalloc(NULL,(_numberOfOperators==0)?1:_numberOfOperators);
   for(i=0;i<_numberOfOperators;i++)
    _operators[i]=operators[i];

   _numberOfPoints=numberOfPoints;
   _points=NSZoneMalloc(NULL,(_numberOfPoints==0?1:_numberOfPoints)*sizeof(CGPoint));
   for(i=0;i<_numberOfPoints;i++)
    _points[i]=points[i];
    
   return self;
}

-init {
   return [self initWithOperators:NULL numberOfOperators:0 points:NULL numberOfPoints:0];
}

-(void)dealloc {
   NSZoneFree(NULL,_operators);
   NSZoneFree(NULL,_points);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [[KGMutablePath allocWithZone:zone] initWithOperators:_operators numberOfOperators:_numberOfOperators points:_points numberOfPoints:_numberOfPoints];
}

-(unsigned)numberOfOperators {
   return _numberOfOperators;
}

-(const unsigned char *)operators {
   return _operators;
}

-(unsigned)numberOfPoints {
   return _numberOfPoints;
}

-(const CGPoint *)points {
   return _points;
}

-(CGPoint)currentPoint {
// this is wrong w/ closepath last
   return (_numberOfPoints==0)?CGPointZero:_points[_numberOfPoints-1];
}

-(BOOL)isEqualToPath:(KGPath *)other {
   unsigned otherNumberOfOperators=[other numberOfOperators];
   
   if(_numberOfOperators==otherNumberOfOperators){
    unsigned otherNumberOfPoints=[other numberOfPoints];
    
    if(_numberOfPoints==otherNumberOfPoints){
     const unsigned char *otherOperators=[other operators];
     const CGPoint       *otherPoints;
     int i;
     
     for(i=0;i<_numberOfOperators;i++)
      if(_operators[i]!=otherOperators[i])
       return NO;
       
     otherPoints=[other points];
     for(i=0;i<_numberOfPoints;i++)
      if(!CGPointEqualToPoint(_points[i],otherPoints[i]))
       return NO;
       
     return YES;
    }
    
   }
   return NO;
}

-(BOOL)isEmpty {
   return _numberOfOperators==0;
}

-(BOOL)isRect:(CGRect *)rect {   
   if(_numberOfOperators!=5)
    return NO;
   if(_operators[0]!=kCGPathElementMoveToPoint)
    return NO;
   if(_operators[1]!=kCGPathElementAddLineToPoint)
    return NO;
   if(_operators[2]!=kCGPathElementAddLineToPoint)
    return NO;
   if(_operators[3]!=kCGPathElementAddLineToPoint)
    return NO;
   if(_operators[4]!=kCGPathElementCloseSubpath)
    return NO;
   
   if(_points[0].y!=_points[1].y)
    return NO;
   if(_points[1].x!=_points[2].x)
    return NO;
   if(_points[3].y!=_points[3].y)
    return NO;
   if(_points[3].x!=_points[0].x)
    return NO;
   
   rect->origin=_points[0];
   rect->size=CGSizeMake(_points[1].x-_points[0].x,_points[2].y-_points[0].y);
   
   return YES;
}

-(BOOL)containsPoint:(CGPoint)point evenOdd:(BOOL)evenOdd withTransform:(CGAffineTransform *)matrix {
   KGUnimplementedMethod();
   return NO;
}

-(CGRect)boundingBox {
   CGRect result;
   int i;
   
   if(_numberOfPoints==0)
    return CGRectZero;
   
   result.origin=_points[0];
   result.size=CGSizeMake(0,0);
   for(i=1;i<_numberOfPoints;i++){
    CGPoint point=_points[i];
    
    if(point.x>CGRectGetMaxX(result))
     result.size.width=point.x-CGRectGetMinX(result);
    else if(point.x<result.origin.x){
     result.size.width=CGRectGetMaxX(result)-point.x;
     result.origin.x=point.x;
    }
    
    if(point.y>CGRectGetMaxY(result))
     result.size.height=point.y-CGRectGetMinY(result);
    else if(point.y<result.origin.y){
     result.size.height=CGRectGetMaxY(result)-point.y;
     result.origin.y=point.y;
    }
   }   

   return result;
}

@end
