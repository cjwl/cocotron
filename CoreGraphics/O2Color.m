/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "O2Color.h"
#import "O2ColorSpace.h"

@implementation O2Color

-initWithColorSpace:(O2ColorSpaceRef)colorSpace pattern:(KGPattern *)pattern components:(const CGFloat *)components {
   int i;
   
   _colorSpace=[colorSpace retain];
   _pattern=[pattern retain];
   _numberOfComponents=[_colorSpace numberOfComponents]+1;
   _components=NSZoneMalloc([self zone],sizeof(CGFloat)*_numberOfComponents);
   for(i=0;i<_numberOfComponents;i++)
    _components[i]=components[i];
    
   return self;
}

-initWithColorSpace:(O2ColorSpaceRef)colorSpace components:(const CGFloat *)components {
   int i;
   
   _colorSpace=[colorSpace retain];
   _pattern=nil;
   _numberOfComponents=[_colorSpace numberOfComponents]+1;
   _components=NSZoneMalloc([self zone],sizeof(CGFloat)*_numberOfComponents);
   for(i=0;i<_numberOfComponents;i++)
    _components[i]=components[i];
    
   return self;
}

-initWithDeviceGray:(CGFloat)gray alpha:(CGFloat)alpha {
   CGFloat components[2]={gray,alpha};
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceGray];
   [self initWithColorSpace:colorSpace components:components];
   [colorSpace release];
   return self;
}

-initWithDeviceRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
   CGFloat components[4]={red,green,blue,alpha};
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceRGB];
   [self initWithColorSpace:colorSpace components:components];
   [colorSpace release];
   return self;
}

-initWithDeviceCyan:(CGFloat)cyan magenta:(CGFloat)magenta yellow:(CGFloat)yellow black:(CGFloat)black alpha:(CGFloat)alpha {
   CGFloat components[5]={cyan,magenta,yellow,black,alpha};
   O2ColorSpaceRef colorSpace=[[O2ColorSpace alloc] initWithDeviceCMYK];
   [self initWithColorSpace:colorSpace components:components];
   [colorSpace release];
   return self;
}

O2ColorRef O2ColorCreate(O2ColorSpaceRef colorSpace,const CGFloat *components) {
   return [[O2Color alloc] initWithColorSpace:colorSpace components:components];
}

O2ColorRef O2ColorCreateGenericGray(CGFloat gray,CGFloat a) {
   return [[O2Color alloc] initWithDeviceGray:gray alpha:a];
}

O2ColorRef O2ColorCreateGenericRGB(CGFloat r,CGFloat g,CGFloat b,CGFloat a) {
   return [[O2Color alloc] initWithDeviceRed:r green:g blue:b alpha:a];
}

O2ColorRef O2ColorCreateGenericCMYK(CGFloat c,CGFloat m,CGFloat y,CGFloat k,CGFloat a) {
   return [[O2Color alloc] initWithDeviceCyan:c magenta:m yellow:y black:k alpha:a];
}

O2ColorRef O2ColorCreateWithPattern(O2ColorSpaceRef colorSpace,CGPatternRef pattern,const CGFloat *components) {
   return [[O2Color alloc] initWithColorSpace:colorSpace pattern:pattern components:components];
}

-init {
   O2ColorSpaceRef gray=[[O2ColorSpace alloc] initWithDeviceGray];
   CGFloat       components[2]={0,1};
   
   [self initWithColorSpace:gray components:components];
   [gray release];
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [_pattern release];
   NSZoneFree([self zone],_components);
   [super dealloc];
}

O2ColorRef O2ColorCreateCopy(O2ColorRef self) {
   return [self retain];
}

O2ColorRef O2ColorCreateCopyWithAlpha(O2ColorRef self,CGFloat alpha) {
   int   i;
   CGFloat components[self->_numberOfComponents];

   for(i=0;i<self->_numberOfComponents-1;i++)
    components[i]=self->_components[i];
   components[i]=alpha;
      
   return [[self->isa alloc] initWithColorSpace:self->_colorSpace components:components];
}

O2ColorRef O2ColorRetain(O2ColorRef self) {
   return [self retain];
}

void O2ColorRelease(O2ColorRef self) {
   [self release];
}

O2ColorSpaceRef O2ColorGetColorSpace(O2ColorRef self) {
   return self->_colorSpace;
}

size_t O2ColorGetNumberOfComponents(O2ColorRef self) {
   return self->_numberOfComponents;
}

const CGFloat *O2ColorGetComponents(O2ColorRef self) {
   return self->_components;
}

CGFloat O2ColorGetAlpha(O2ColorRef self) {
   return self->_components[self->_numberOfComponents-1];
}

CGPatternRef O2ColorGetPattern(O2ColorRef self) {
   return self->_pattern;
}

BOOL O2ColorEqualToColor(O2ColorRef self,O2ColorRef other) {
   if(![self->_colorSpace isEqualToColorSpace:other->_colorSpace])
    return NO;

   int i;
   for(i=0;i<self->_numberOfComponents;i++)
    if(self->_components[i]!=other->_components[i])
     return NO;

   return YES;
}

@end
