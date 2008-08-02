/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGImageSource_TIFF.h"
#import "NSTIFFReader.h"
#import "KGDataProvider.h"
#import "KGColorSpace.h"
#import "KGImage.h"

@implementation KGImageSource_TIFF

+(BOOL)isTypeOfData:(NSData *)data {
   const unsigned char *bytes=[data bytes];
   unsigned             length=[data length];
   
   static unsigned char tiff_big[4] = { 'M','M',00,42 };
   static unsigned char tiff_little[4] = { 'I','I',42,00 };
   int i;
   
   if(length<4)
    return NO;
    
   for (i=0; i < 4; ++i)
    if(tiff_big[i]!=bytes[i])
     break;
     
   if(i==4)
    return YES;

   for (i=0; i < 4; ++i)
    if(tiff_little[i]!=bytes[i])
     break;
     
   if(i==4)
    return YES;

   return NO;
}

-initWithData:(NSData *)data options:(NSDictionary *)options {
   if((_reader=[[NSTIFFReader alloc] initWithData:data])==nil){
    [self dealloc];
    return nil;
   }
   
   return self;
}

-(void)dealloc {
   [_reader release];
   [super dealloc];
}

-(unsigned)count {
   return [[_reader imageFileDirectory] count];
}

-(KGImage *)imageAtIndex:(unsigned)index options:(NSDictionary *)options {
   int            width=[_reader pixelsWide];
   int            height=[_reader pixelsHigh];
   int            bitsPerPixel=32;
   int            bytesPerRow=(bitsPerPixel/(sizeof(char)*8))*width;
   
   unsigned char *bytes;
   NSData        *bitmap;
   
   bytes=NSZoneMalloc([self zone],bytesPerRow*height);
   if(![_reader getRGBAImageBytes:bytes width:width height:height]){
    NSZoneFree([self zone],bytes);
    return nil;
   }

   bitmap=[[NSData alloc] initWithBytesNoCopy:bytes length:bytesPerRow*height];

   KGDataProvider *provider=[[KGDataProvider alloc] initWithData:bitmap];
   KGColorSpace *colorSpace=[[KGColorSpace alloc] initWithDeviceRGB];
   KGImage *image=[[KGImage alloc] initWithWidth:width height:height bitsPerComponent:8 bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow
      colorSpace:colorSpace bitmapInfo:kCGBitmapByteOrder32Big|kCGImageAlphaPremultipliedLast provider:provider decode:NULL interpolate:NO renderingIntent:kCGRenderingIntentDefault];
      
   [colorSpace release];
   [provider release];
   [bitmap release];
   
   return image;
}

@end
