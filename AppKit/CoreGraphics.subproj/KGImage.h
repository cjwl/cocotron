/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGColorSpace,KGDataProvider,KGPDFObject,KGPDFContext;

@interface KGImage : NSObject {
   unsigned        _width;
   unsigned        _height;
   unsigned        _bitsPerComponent;
   unsigned        _bitsPerPixel;
   unsigned        _bytesPerRow;
   KGColorSpace   *_colorSpace;
   unsigned        _bitmapInfo;
   KGDataProvider *_provider;
   float          *_decode;
   BOOL            _interpolate;
   BOOL            _isMask;
   unsigned        _intent;
   KGImage        *_mask;
}

-initWithWidth:(unsigned)width height:(unsigned)height bitsPerComponent:(unsigned)bitsPerComponent bitsPerPixel:(unsigned)bitsPerPixel bytesPerRow:(unsigned)bytesPerRow colorSpace:(KGColorSpace *)colorSpace bitmapInfo:(unsigned)bitmapInfo provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate renderingIntent:(unsigned)renderingIntent;

-initMaskWithWidth:(unsigned)width height:(unsigned)height bitsPerComponent:(unsigned)bitsPerComponent bitsPerPixel:(unsigned)bitsPerPixel bytesPerRow:(unsigned)bytesPerRow provider:(KGDataProvider *)provider decode:(const float *)decode interpolate:(BOOL)interpolate ;

-(void)addMask:(KGImage *)image;

-(unsigned)width;
-(unsigned)height;
-(unsigned)bitsPerComponent;
-(unsigned)bitsPerPixel;
-(KGColorSpace *)colorSpace;
-(unsigned)bitmapInfo;

-(const void *)bytes;
-(unsigned)length;

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context;
+(KGImage *)imageWithPDFObject:(KGPDFObject *)object;

@end

CGColorRenderingIntent KGImageRenderingIntentWithName(const char *name);
const char *KGImageNameWithIntent(CGColorRenderingIntent intent);
