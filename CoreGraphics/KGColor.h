/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class KGColorSpace,KGPattern;

@interface KGColor : NSObject <NSCopying> {
  KGColorSpace *_colorSpace;
  unsigned      _numberOfComponents;
  CGFloat        *_components;
  KGPattern    *_pattern;
}

-initWithColorSpace:(KGColorSpace *)colorSpace pattern:(KGPattern *)pattern components:(const CGFloat *)components;
-initWithColorSpace:(KGColorSpace *)colorSpace components:(const CGFloat *)components;
-initWithColorSpace:(KGColorSpace *)colorSpace;

-initWithDeviceGray:(CGFloat)gray alpha:(CGFloat)alpha;
-initWithDeviceRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
-initWithDeviceCyan:(CGFloat)cyan magenta:(CGFloat)magenta yellow:(CGFloat)yellow black:(CGFloat)black alpha:(CGFloat)alpha;

-copyWithAlpha:(CGFloat)alpha;

-(KGColorSpace *)colorSpace;
-(unsigned)numberOfComponents;
-(CGFloat *)components;
-(CGFloat)alpha;
-(KGPattern *)pattern;

-(BOOL)isEqualToColor:(KGColor *)other;

-(KGColor *)convertToColorSpace:(KGColorSpace *)otherSpace;

@end
