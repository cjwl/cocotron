/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <ApplicationServices/CoreGraphicsExport.h>

typedef float CGFloat;

typedef NSPoint CGPoint;
typedef NSSize CGSize;
typedef NSRect CGRect;

COREGRAPHICS_EXPORT CGRect CGRectZero;
COREGRAPHICS_EXPORT CGPoint CGPointZero;
COREGRAPHICS_EXPORT CGSize CGSizeZero;

static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
   return NSMakeRect(x,y,width,height);
}

static inline CGPoint CGPointMake(CGFloat x,CGFloat y){
   return NSMakePoint(x,y);
}

static inline CGSize CGSizeMake(CGFloat x,CGFloat y){
   CGSize result={x,y};
   return result;
}

static inline CGFloat CGRectGetMinX(CGRect rect){
   return rect.origin.x;
}

static inline CGFloat CGRectGetMaxX(CGRect rect){
   return rect.origin.x+rect.size.width;
}

static inline CGFloat CGRectGetMinY(CGRect rect){
   return rect.origin.y;
}

static inline CGFloat CGRectGetMaxY(CGRect rect){
   return rect.origin.y+rect.size.height;
}

static inline BOOL CGPointEqualToPoint(CGPoint a,CGPoint b){
   return ((a.x==b.x) && (a.y==b.y))?YES:NO;
}

