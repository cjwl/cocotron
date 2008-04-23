/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGBitmapContext.h"
#import "KGImage.h"
#import "KGDataProvider.h"
#import "KGColorSpace.h"
#import "KGExceptions.h"

@implementation KGBitmapContext

-initWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo {
   [super init];
   _bytes=bytes;
   _width=width;
   _height=height;
   _bitsPerComponent=bitsPerComponent;
   _bytesPerRow=bytesPerRow;
   _colorSpace=[colorSpace retain];
   _bitmapInfo=bitmapInfo;
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [super dealloc];
}

-(void *)bytes {
   return _bytes;
}

-(size_t)width {
   return _width;
}

-(size_t)height {
   return _height;
}

-(size_t)bitsPerComponent {
   return _bitsPerComponent;
}

-(size_t)bytesPerRow {
   return _bytesPerRow;
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(CGBitmapInfo)bitmapInfo {
   return _bitmapInfo;
}

-(size_t)bitsPerPixel {
   size_t result=_bitsPerComponent*[_colorSpace numberOfComponents];
   
   switch(_bitmapInfo&kCGBitmapAlphaInfoMask){
   
    case kCGImageAlphaNone:
     break;
     
    case kCGImageAlphaPremultipliedLast:
     result+=_bitsPerComponent;
     break;

    case kCGImageAlphaPremultipliedFirst:
     result+=_bitsPerComponent;
     break;

    case kCGImageAlphaLast:
     result+=_bitsPerComponent;
     break;

    case kCGImageAlphaFirst:
     result+=_bitsPerComponent;
     break;

    case kCGImageAlphaNoneSkipLast:
     break;

    case kCGImageAlphaNoneSkipFirst:
     break;
   }
   
   return result;
}

-(CGImageAlphaInfo)alphaInfo {
   return _bitmapInfo&kCGBitmapAlphaInfoMask;
}

-(KGImage *)createImage {
#if 1
   return nil;
#else
  CGDataProviderRef provider=CGDataProviderCreateWithData(NULL,_data,_pixelsWide*_pixelsHigh*4,NULL);
  
  KGImage *image=CGImageCreate(_width,_height,_bitsPerComponent,_bitsPerPixel,_bytesPerRow,_colorSpace,
     _bitmapInfo,provider,NULL,NO,kCGRenderingIntentDefault);
     
  return image;
#endif
}

@end
