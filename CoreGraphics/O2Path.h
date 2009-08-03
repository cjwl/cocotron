/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class O2Path,O2MutablePath;

typedef O2Path *O2PathRef;
typedef O2MutablePath *O2MutablePathRef;

@interface O2Path : NSObject <NSCopying,NSMutableCopying> {
   unsigned       _numberOfElements;
   unsigned char *_elements;
   unsigned       _numberOfPoints;
   CGPoint       *_points;
}

-initWithOperators:(unsigned char *)elements numberOfElements:(unsigned)numberOfElements points:(CGPoint *)points numberOfPoints:(unsigned)numberOfPoints;

-(unsigned)numberOfElements;
-(const unsigned char *)elements;

-(unsigned)numberOfPoints;
-(const CGPoint *)points;

void      O2PathRelease(O2PathRef self);
O2PathRef O2PathRetain(O2PathRef self);

BOOL    O2PathEqualToPath(O2PathRef self,O2PathRef other);
CGRect  O2PathGetBoundingBox(O2PathRef self);
CGPoint O2PathGetCurrentPoint(O2PathRef self);
BOOL    O2PathIsEmpty(O2PathRef self);
BOOL    O2PathIsRect(O2PathRef self,CGRect *rect);
void    O2PathApply(O2PathRef self,void *info,CGPathApplierFunction function);
O2MutablePathRef O2PathCreateMutableCopy(O2PathRef self);
O2PathRef        O2PathCreateCopy(O2PathRef self);
BOOL             O2PathContainsPoint(O2PathRef self,const CGAffineTransform *xform,CGPoint point,BOOL evenOdd);

@end
