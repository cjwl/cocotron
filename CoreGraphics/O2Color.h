/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>
#import "O2ColorSpace.h"

@class KGPattern;
@class O2Color;

typedef O2Color *O2ColorRef;

@interface O2Color : NSObject {
  O2ColorSpaceRef _colorSpace;
  unsigned      _numberOfComponents;
  CGFloat      *_components;
  KGPattern    *_pattern;
}

O2ColorRef O2ColorRetain(O2ColorRef self);
void       O2ColorRelease(O2ColorRef self);

O2ColorRef O2ColorCreate(O2ColorSpaceRef colorSpace,const CGFloat *components);
O2ColorRef O2ColorCreateGenericGray(CGFloat gray,CGFloat a);
O2ColorRef O2ColorCreateGenericRGB(CGFloat r,CGFloat g,CGFloat b,CGFloat a);
O2ColorRef O2ColorCreateGenericCMYK(CGFloat c,CGFloat m,CGFloat y,CGFloat k,CGFloat a);
O2ColorRef O2ColorCreateWithPattern(O2ColorSpaceRef colorSpace,CGPatternRef pattern,const CGFloat *components);

O2ColorRef O2ColorCreateCopy(O2ColorRef self);
O2ColorRef O2ColorCreateCopyWithAlpha(O2ColorRef self,CGFloat a);

BOOL       O2ColorEqualToColor(O2ColorRef self,O2ColorRef other);

O2ColorSpaceRef O2ColorGetColorSpace(O2ColorRef self);
size_t          O2ColorGetNumberOfComponents(O2ColorRef self);
const CGFloat  *O2ColorGetComponents(O2ColorRef self);
CGFloat         O2ColorGetAlpha(O2ColorRef self);

CGPatternRef    O2ColorGetPattern(O2ColorRef self);

@end
