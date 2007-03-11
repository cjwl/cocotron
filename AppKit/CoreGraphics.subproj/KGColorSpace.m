/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGColorSpace.h"

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

-initWithColorSpace:(KGColorSpace *)baseColorSpace hival:(unsigned)hival bytes:(const unsigned char *)bytes  {
   [self dealloc];
   return [[KGColorSpace_indexed alloc] initWithColorSpace:baseColorSpace hival:hival bytes:bytes];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(unsigned)numberOfComponents {
   switch(_type){
    case KGColorSpaceDeviceGray: return 1;
    case KGColorSpaceDeviceRGB: return 3;
    case KGColorSpaceDeviceCMYK: return 4;
    case KGColorSpaceIndexed: return 1;
    default: return 0;
   }
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

@end
