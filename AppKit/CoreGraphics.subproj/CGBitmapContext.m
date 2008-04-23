/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <ApplicationServices/CGBitmapContext.h>
#import "KGBitmapContext.h"

CGContextRef CGBitmapContextCreate(void *bytes,size_t width,size_t height,size_t bitsPerComponent,size_t bytesPerRow,CGColorSpaceRef colorSpace,CGBitmapInfo bitmapInfo) {
   return [KGContext createWithBytes:bytes width:width height:height bitsPerComponent:bitsPerComponent bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo];
}

void *CGBitmapContextGetData(CGContextRef self) {
   return [self bytes];
}

size_t CGBitmapContextGetWidth(CGContextRef self) {
   return [self width];
}

size_t CGBitmapContextGetHeight(CGContextRef self) {
   return [self height];
}

size_t CGBitmapContextGetBitsPerComponent(CGContextRef self) {
   return [self bitsPerComponent];
}

size_t CGBitmapContextGetBytesPerRow(CGContextRef self) {
   return [self bytesPerRow];
}

CGColorSpaceRef CGBitmapContextGetColorSpace(CGContextRef self) {
   return [self colorSpace];
}

CGBitmapInfo CGBitmapContextGetBitmapInfo(CGContextRef self) {
   return [self bitmapInfo];
}

size_t CGBitmapContextGetBitsPerPixel(CGContextRef self) {
   return [self bitsPerPixel];
}

CGImageAlphaInfo CGBitmapContextGetAlphaInfo(CGContextRef self) {
   return [self alphaInfo];
}

CGImageRef CGBitmapContextCreateImage(CGContextRef self) {
   return [self createImage];
}
 
