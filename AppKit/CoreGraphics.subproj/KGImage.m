/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGImage.h"
#import "KGColorSpace.h"
#import "KGDataProvider.h"
#import "KGPDFDictionary.h"

@implementation KGImage

-initWithWidth:(unsigned)width height:(unsigned)height bitsPerComponent:(unsigned)bitsPerComponent bitsPerPixel:(unsigned)bitsPerPixel bytesPerRow:(unsigned)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(unsigned)bitmapInfo provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate renderingIntent:(unsigned)renderingIntent {
   _width=width;
   _height=height;
   _bitsPerComponent=bitsPerComponent;
   _bitsPerPixel=bitsPerPixel;
   _bytesPerRow=bytesPerRow;
   _colorSpace=[colorSpace retain];
   _bitmapInfo=bitmapInfo;
   _provider=[provider retain];
  // _decode=NULL;
   _interpolate=interpolate;
   _intent=renderingIntent;
   _mask=nil;
   return self;
}

-initMaskWithWidth:(unsigned)width height:(unsigned)height bitsPerComponent:(unsigned)bitsPerComponent bitsPerPixel:(unsigned)bitsPerPixel bytesPerRow:(unsigned)bytesPerRow provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate {
   _width=width;
   _height=height;
   _bitsPerComponent=bitsPerComponent;
   _bitsPerPixel=bitsPerPixel;
   _bytesPerRow=bytesPerRow;
   _colorSpace=nil;
   _bitmapInfo=0;
   _provider=[provider retain];
  // _decode=NULL;
   _interpolate=interpolate;
   _intent=0;
   _mask=nil;
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [_provider release];
   [super dealloc];
}

-(void)addMask:(KGImage *)image {
   [image retain];
   [_mask release];
   _mask=image;
}

-(unsigned)width {
   return _width;
}

-(unsigned)height {
   return _height;
}

-(unsigned)bitsPerComponent {
   return _bitsPerComponent;
}

-(unsigned)bitsPerPixel {
   return _bitsPerPixel;
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(unsigned)bitmapInfo {
   return _bitmapInfo;
}

-(const void *)bytes {
   return [_provider bytes];
}

-(unsigned)length {
   return [_provider length];
}

-(KGPDFObject *)pdfObjectInContext:(KGPDFContext *)context {
   KGPDFDictionary *result=[KGPDFDictionary pdfDictionary];

   [result setNameForKey:"Type" value:"Font"];
   
   return result;
}

@end
