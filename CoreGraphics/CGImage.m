/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <CoreGraphics/CGImage.h>
#import <Foundation/NSString.h>
#import "KGImage.h"

CGImageRef CGImageRetain(CGImageRef image) {
   return [image retain];
}

void CGImageRelease(CGImageRef image) {
   [image release];
}

CGImageRef CGImageCreate(size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,CGColorSpaceRef colorSpace,CGBitmapInfo bitmapInfo,CGDataProviderRef dataProvider,const CGFloat *decode,BOOL interpolate,CGColorRenderingIntent renderingIntent) {
   return [[O2Image alloc] initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo provider:dataProvider decode:decode interpolate:interpolate renderingIntent:renderingIntent];
}

CGImageRef CGImageMaskCreate(size_t width,size_t height,size_t bitsPerComponent,size_t bitsPerPixel,size_t bytesPerRow,CGDataProviderRef dataProvider,const CGFloat *decode,BOOL interpolate) {
   return [[O2Image alloc] initMaskWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow provider:dataProvider decode:decode interpolate:interpolate];
}

CGImageRef CGImageCreateCopy(CGImageRef self) {
   return [self copy];
}

CGImageRef CGImageCreateCopyWithColorSpace(CGImageRef self,CGColorSpaceRef colorSpace) {
   return [self copyWithColorSpace:colorSpace];
}

CGImageRef CGImageCreateWithImageInRect(CGImageRef self,CGRect rect) {
   return [self childImageInRect:rect];
}

CGImageRef CGImageCreateWithJPEGDataProvider(CGDataProviderRef jpegProvider,const CGFloat *decode,BOOL interpolate,CGColorRenderingIntent renderingIntent) {
   return [[O2Image alloc] initWithJPEGDataProvider:jpegProvider decode:decode interpolate:interpolate renderingIntent:renderingIntent];
}

CGImageRef CGImageCreateWithPNGDataProvider(CGDataProviderRef pngProvider,const CGFloat *decode,BOOL interpolate,CGColorRenderingIntent renderingIntent) {
   return [[O2Image alloc] initWithPNGDataProvider:pngProvider decode:decode interpolate:interpolate renderingIntent:renderingIntent];
}

CGImageRef CGImageCreateWithMask(CGImageRef self,CGImageRef mask) {
   return [self copyWithMask:mask];
}

CGImageRef CGImageCreateWithMaskingColors(CGImageRef self,const CGFloat *components) {
   return [self copyWithMaskingColors:components];
}

size_t CGImageGetWidth(CGImageRef self) {
   return [self width];
}

size_t CGImageGetHeight(CGImageRef self) {
   return [self height];
}

size_t CGImageGetBitsPerComponent(CGImageRef self) {
   return [self bitsPerComponent];
}

size_t CGImageGetBitsPerPixel(CGImageRef self) {
   return [self bitsPerPixel];
}

size_t CGImageGetBytesPerRow(CGImageRef self) {
   return [self bytesPerRow];
}

CGColorSpaceRef CGImageGetColorSpace(CGImageRef self) {
   return [self colorSpace];
}

CGBitmapInfo CGImageGetBitmapInfo(CGImageRef self) {
   return [self bitmapInfo];
}

CGDataProviderRef CGImageGetDataProvider(CGImageRef self) {
   return [self dataProvider];
}

const CGFloat *CGImageGetDecode(CGImageRef self) {
   return [self decode];
}

BOOL CGImageGetShouldInterpolate(CGImageRef self) {
   return [self shouldInterpolate];
}

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef self) {
   return [self renderingIntent];
}

BOOL CGImageIsMask(CGImageRef self) {
   return [self isMask];
}

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef self) {
   return [self alphaInfo];
}

