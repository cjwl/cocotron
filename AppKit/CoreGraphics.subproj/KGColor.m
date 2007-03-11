/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGColor.h"
#import "KGColorSpace.h"

@implementation KGColor

-initWithColorSpace:(KGColorSpace *)colorSpace components:(const float *)components {
   int i;
   
   _colorSpace=[colorSpace retain];
   _numberOfComponents=[_colorSpace numberOfComponents]+1;
   _components=NSZoneMalloc([self zone],sizeof(float)*_numberOfComponents);
   for(i=0;i<_numberOfComponents;i++)
    _components[i]=components[i];
    
   return self;
}

-init {
   KGColorSpace *gray=[[[KGColorSpace alloc] initWithDeviceGray] autorelease];
   float         components[2]={0,1};
   
   return [self initWithColorSpace:gray components:components];
}

-(void)dealloc {
   [_colorSpace release];
   NSZoneFree([self zone],_components);
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-copyWithAlpha:(float)alpha {
   int   i;
   float components[_numberOfComponents];

   for(i=0;i<_numberOfComponents-1;i++)
    components[i]=_components[i];
   components[i]=alpha;
      
   return [[isa alloc] initWithColorSpace:_colorSpace components:components];
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(unsigned)numberOfComponents {
   return _numberOfComponents;
}

-(float *)components {
   return _components;
}

-(float)alpha {
   return _components[_numberOfComponents-1];
}

@end
