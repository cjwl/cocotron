/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <CoreGraphics/CoreGraphicsExport.h>
#import <CoreFoundation/CFBase.h>
#import <stdbool.h>

COREGRAPHICS_EXPORT const CGRect CGRectZero;
COREGRAPHICS_EXPORT const CGPoint CGPointZero;
COREGRAPHICS_EXPORT const CGSize CGSizeZero;

static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
   CGRect result={{x,y},{width,height}};
   return result;
}

static inline CGPoint CGPointMake(CGFloat x,CGFloat y){
   CGPoint result={x,y};
   return result;
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

static inline CGFloat CGRectGetWidth(CGRect rect){
        return rect.size.width;
}

static inline CGFloat CGRectGetHeight(CGRect rect){
        return rect.size.height;
}

static inline bool CGRectContainsPoint(CGRect rect,CGPoint point) {
   return (point.x>=CGRectGetMinX(rect) && point.x<=CGRectGetMaxX(rect)) && (point.y>=CGRectGetMinY(rect) && point.y<=CGRectGetMaxY(rect));
}

static inline bool CGPointEqualToPoint(CGPoint a,CGPoint b){
   return ((a.x==b.x) && (a.y==b.y))?TRUE:FALSE;
}

static inline CGRect CGRectInset(CGRect rect,CGFloat dx,CGFloat dy) {
   rect.origin.x+=dx;
   rect.origin.y+=dy;
   rect.size.width-=dx*2;
   rect.size.height-=dy*2;
   return rect;
}

static inline bool CGRectIsEmpty(CGRect rect) {
   return ((rect.size.width==0) && (rect.size.height==0))?TRUE:FALSE;
}

static inline bool CGRectIntersectsRect(CGRect a, CGRect b)
{
    if(b.origin.x > a.origin.x + a.size.width)
        return false;
    if(b.origin.y > a.origin.y + a.size.height)
        return false;
    if(a.origin.x > b.origin.x + b.size.width)
        return false;
    if(a.origin.y > b.origin.y + b.size.height)
        return false;
    return true;
}
