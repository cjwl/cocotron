/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGImageSource_TIFF.h"
#import "NSTIFFReader.h"
#import "NSTIFFImageFileDirectory.h"
#import "KGDataProvider.h"
#import "KGColorSpace.h"
#import "KGImage.h"

@implementation KGImageSource_TIFF

+(BOOL)isPresentInDataProvider:(KGDataProvider *)provider {
   enum { signatureLength=4 };
   unsigned char signature[2][signatureLength] = {
    { 'M','M',00,42 },
    { 'I','I',42,00 }
   };
   unsigned char check[signatureLength];
   NSInteger     i,size=[provider getBytes:check range:NSMakeRange(0,signatureLength)];
   
   if(size!=signatureLength)
    return NO;
   
   int s;
   for(s=0;s<2;s++){
    for(i=0;i<signatureLength;i++)
     if(signature[s][i]!=check[i])
      break;
      
    if(i==signatureLength)
     return YES;
   }
   return NO;
}


-initWithDataProvider:(KGDataProvider *)provider options:(NSDictionary *)options {
   [super initWithDataProvider:provider options:options];
   
   NSData *data=[provider copyData];
   _reader=[[NSTIFFReader alloc] initWithData:data];
   [data release];
   
   if(_reader==nil){
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

-(NSDictionary *)copyPropertiesAtIndex:(unsigned)index options:(NSDictionary *)options {
   NSArray *entries=[_reader imageFileDirectory];
   
   if([entries count]<=index)
    return nil;
   
   NSTIFFImageFileDirectory *directory=[entries objectAtIndex:index];
   
   return [[directory properties] copy];
}


-(KGImage *)imageAtIndex:(unsigned)index options:(NSDictionary *)options {
   NSArray *entries=[_reader imageFileDirectory];
   
   if([entries count]<=index)
    return nil;
   
   NSTIFFImageFileDirectory *directory=[entries objectAtIndex:index];
   
   int            width=[directory imageWidth];
   int            height=[directory imageLength];
   int            bitsPerPixel=32;
   int            bytesPerRow=(bitsPerPixel/(sizeof(char)*8))*width;
   
   unsigned char *bytes;
   NSData        *bitmap;
   
   bytes=NSZoneMalloc([self zone],bytesPerRow*height);
   if(![directory getRGBAImageBytes:bytes data:[_reader data]]){
    NSZoneFree([self zone],bytes);
    return nil;
   }

// clamp premultiplied data, this should probably be moved into the KGImage init
   int i;
   for(i=0;i<bytesPerRow*height;i+=4){
    bytes[i]=MIN(bytes[i],bytes[i+3]);
    bytes[i+1]=MIN(bytes[i+1],bytes[i+3]);
    bytes[i+2]=MIN(bytes[i+2],bytes[i+3]);
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
