/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "O2ColorSpace.h"
#import <Foundation/NSString.h>

@implementation O2ColorSpace

-initWithDeviceGray {
   _type=O2ColorSpaceDeviceGray;
   return self;
}

-initWithDeviceRGB {
   _type=O2ColorSpaceDeviceRGB;
   return self;
}

-initWithDeviceCMYK {
   _type=O2ColorSpaceDeviceCMYK;
   return self;
}

-initWithPlatformRGB {
   _type=O2ColorSpacePlatformRGB;
   return self;
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(O2ColorSpaceType)type {
   return _type;
}

O2ColorSpaceRef O2ColorSpaceRetain(O2ColorSpaceRef self) {
   return [self retain];
}

void O2ColorSpaceRelease(O2ColorSpaceRef self) {
   [self release];
}

O2ColorSpaceRef O2ColorSpaceCreateDeviceGray(void) {
   return [[O2ColorSpace alloc] initWithDeviceGray];
}

O2ColorSpaceRef O2ColorSpaceCreateDeviceRGB(void) {
   return [[O2ColorSpace alloc] initWithDeviceRGB];
}

O2ColorSpaceRef O2ColorSpaceCreateDeviceCMYK(void) {
   return [[O2ColorSpace alloc] initWithDeviceCMYK];
}

size_t O2ColorSpaceGetNumberOfComponents(O2ColorSpaceRef self) {
   switch(self->_type){
    case O2ColorSpaceDeviceGray:
     return 1;
    case O2ColorSpaceDeviceRGB: 
    case O2ColorSpacePlatformRGB:
     return 3;
    case O2ColorSpaceDeviceCMYK:
     return 4;
    case O2ColorSpaceIndexed:
     return 1;
    default:
     return 0;
   }
}

-(BOOL)isEqualToColorSpace:(O2ColorSpaceRef)other {
   if(self->_type!=other->_type)
    return NO;
   return YES;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@: %p, type=%d>",isa,self,_type];
}

@end

@implementation O2ColorSpace_indexed

-initWithColorSpace:(O2ColorSpaceRef)baseColorSpace hival:(unsigned)hival bytes:(const unsigned char *)bytes  {
   int i,max=O2ColorSpaceGetNumberOfComponents(baseColorSpace)*(hival+1);
  
   _type=O2ColorSpaceIndexed;
   _base=[baseColorSpace retain];
   _hival=hival;
   _bytes=NSZoneMalloc(NSDefaultMallocZone(),max);
   for(i=0;i<max;i++)
    _bytes[i]=bytes[i];
   return self;
}

-(void)dealloc {
   [_base release];
   NSZoneFree(NSDefaultMallocZone(),_bytes);
   [super dealloc];
}

-(BOOL)isEqualToColorSpace:(O2ColorSpaceRef)otherX {
   O2ColorSpace_indexed *other=(O2ColorSpace_indexed *)other;
   if(self->_type!=other->_type)
    return NO;
    
   if(![self->_base isEqualToColorSpace:other->_base])
    return NO;
   if(self->_hival!=other->_hival)
    return NO;
    
   int i,max=O2ColorSpaceGetNumberOfComponents(self->_base)*(self->_hival+1);
   for(i=0;i<max;i++)
    if(self->_bytes[i]!=other->_bytes[i])
     return NO;
     
   return YES;
}

-(O2ColorSpaceRef)baseColorSpace {
   return _base;
}

-(unsigned)hival {
   return _hival;
}

-(const unsigned char *)paletteBytes {
   return _bytes;
}

@end


