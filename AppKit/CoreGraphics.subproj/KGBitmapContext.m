/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGBitmapContext.h"
#import "KGGraphicsState.h"
#import "KGImage.h"
#import "KGDataProvider.h"
#import "KGColorSpace.h"
#import "KGExceptions.h"
#import "KGSurface.h"

@implementation KGBitmapContext

-initWithSurface:(KGSurface *)surface {
   CGAffineTransform flip={1,0,0,-1,0,[surface height]};
   KGGraphicsState  *initialState=[[[KGGraphicsState alloc] initWithDeviceTransform:flip] autorelease];
   [super initWithGraphicsState:initialState];
   _surface=[surface retain];
   return self;
}

-initWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo {
   KGSurface *surface=[[KGSurface alloc] initWithBytes:bytes width:width height:height bitsPerComponent:bitsPerComponent bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo];

   [self initWithSurface:surface];
   [surface release];
   return self;
}

-(void)dealloc {
   [_surface release];
   [super dealloc];
}

-(void *)mutableBytes {
   return [_surface mutableBytes];
}

-(size_t)width {
   return [_surface width];
}

-(size_t)height {
   return [_surface height];
}

-(size_t)bitsPerComponent {
   return [_surface bitsPerComponent];
}

-(size_t)bytesPerRow {
   return [_surface bytesPerRow];
}

-(KGColorSpace *)colorSpace {
   return [_surface colorSpace];
}

-(CGBitmapInfo)bitmapInfo {
   return [_surface bitmapInfo];
}

-(size_t)bitsPerPixel {
   size_t result=[self bitsPerComponent]*[[self colorSpace] numberOfComponents];
   
   switch([self bitmapInfo]&kCGBitmapAlphaInfoMask){
   
    case kCGImageAlphaNone:
     break;
     
    case kCGImageAlphaPremultipliedLast:
     result+=[self bitsPerComponent];
     break;

    case kCGImageAlphaPremultipliedFirst:
     result+=[self bitsPerComponent];
     break;

    case kCGImageAlphaLast:
     result+=[self bitsPerComponent];
     break;

    case kCGImageAlphaFirst:
     result+=[self bitsPerComponent];
     break;

    case kCGImageAlphaNoneSkipLast:
     break;

    case kCGImageAlphaNoneSkipFirst:
     break;
   }
   
   return result;
}

-(CGImageAlphaInfo)alphaInfo {
   return [self bitmapInfo]&kCGBitmapAlphaInfoMask;
}

-(KGImage *)createImage {
#if 1
   return _surface;
#else
  CGDataProviderRef provider=CGDataProviderCreateWithData(NULL,_data,_pixelsWide*_pixelsHigh*4,NULL);
  
  KGImage *image=CGImageCreate(_width,_height,_bitsPerComponent,_bitsPerPixel,_bytesPerRow,_colorSpace,
     _bitmapInfo,provider,NULL,NO,kCGRenderingIntentDefault);
     
  return image;
#endif
}

@end
