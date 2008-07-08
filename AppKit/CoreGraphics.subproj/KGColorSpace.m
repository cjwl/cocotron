/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGColorSpace.h"
#import <Foundation/NSString.h>

@implementation KGColorSpace

-initWithDeviceGray {
   _type=KGColorSpaceDeviceGray;
   return self;
}

-initWithDeviceRGB {
   _type=KGColorSpaceDeviceRGB;
   return self;
}

-initWithDeviceCMYK {
   _type=KGColorSpaceDeviceCMYK;
   return self;
}

-initWithPlatformRGB {
   _type=KGColorSpacePlatformRGB;
   return self;
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(KGColorSpaceType)type {
   return _type;
}

-(unsigned)numberOfComponents {
   switch(_type){
    case KGColorSpaceDeviceGray:
     return 1;
    case KGColorSpaceDeviceRGB: 
    case KGColorSpacePlatformRGB:
     return 3;
    case KGColorSpaceDeviceCMYK: return 4;
    case KGColorSpaceIndexed: return 1;
    default: return 0;
   }
}

-(BOOL)isEqualToColorSpace:(KGColorSpace *)other {
   if(self->_type!=other->_type)
    return NO;
   return YES;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@: %p, type=%d",isa,self,_type];
}

@end

@implementation KGColorSpace_indexed

-initWithColorSpace:(KGColorSpace *)baseColorSpace hival:(unsigned)hival bytes:(const unsigned char *)bytes  {
   int i,max=[baseColorSpace numberOfComponents]*(hival+1);
  
   _type=KGColorSpaceIndexed;
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

-(BOOL)isEqualToColorSpace:(KGColorSpace *)otherX {
   KGColorSpace_indexed *other=(KGColorSpace_indexed *)other;
   if(self->_type!=other->_type)
    return NO;
    
   if(![self->_base isEqualToColorSpace:other->_base])
    return NO;
   if(self->_hival!=other->_hival)
    return NO;
    
   int i,max=[self->_base numberOfComponents]*(self->_hival+1);
   for(i=0;i<max;i++)
    if(self->_bytes[i]!=other->_bytes[i])
     return NO;
     
   return YES;
}

-(KGColorSpace *)baseColorSpace {
   return _base;
}

-(unsigned)hival {
   return _hival;
}

-(const unsigned char *)paletteBytes {
   return _bytes;
}

@end
