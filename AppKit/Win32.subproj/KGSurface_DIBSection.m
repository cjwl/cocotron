/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "KGSurface_DIBSection.h"
#import "KGDeviceContext_gdiDIBSection.h"
#import <CoreGraphics/O2ColorSpace.h>

@implementation KGSurface_DIBSection

-initWithWidth:(size_t)width height:(size_t)height compatibleWithDeviceContext:(KGDeviceContext_gdi *)compatible {
   _deviceContext=[[KGDeviceContext_gdiDIBSection alloc] initWithWidth:width height:height deviceContext:compatible];

   if(_deviceContext==nil){
    [super dealloc];
    return nil;
   }
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceRGB();
   
   if([super initWithBytes:[_deviceContext bitmapBytes] width:width height:height bitsPerComponent:[_deviceContext bitsPerComponent] bytesPerRow:[_deviceContext bytesPerRow] colorSpace:colorSpace bitmapInfo:kO2ImageAlphaPremultipliedFirst|kO2BitmapByteOrder32Little]==nil){
    [colorSpace release];
    return nil;
   }
   [colorSpace release];

   return self;

}

-(void)dealloc {
   [_deviceContext release];
   [super dealloc];
}

-(KGDeviceContext_gdi *)deviceContext {
   return _deviceContext;
}

@end
