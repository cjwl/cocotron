/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2ImageSource_JPEG.h>
#import <Onyx2D/O2ImageSource_TIFF.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Onyx2D/O2DataProvider.h>
#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2Image.h>
#import "O2ImageDecoder_JPEG_libjpeg.h"
#import "O2ImageDecoder_JPEG_stb.h"

#import <assert.h>
#import <string.h>

@implementation O2ImageSource_JPEG

static O2ImageDecoder *createImageDecoderWithDataProvider(O2DataProviderRef dataProvider){
#ifdef LIBJPEG_PRESENT
    return [[O2ImageDecoder_JPEG_libjpeg alloc] initWithDataProvider: dataProvider];
#else
    return [[O2ImageDecoder_JPEG_stb alloc] initWithDataProvider: dataProvider];
#endif
}

NSData *O2DCTDecode(NSData *data) {
    O2DataProviderRef dataProvider=O2DataProviderCreateWithCFData((CFDataRef)data);
    O2ImageDecoderRef decoder=createImageDecoderWithDataProvider(dataProvider);
    CFDataRef result=O2ImageDecoderCreatePixelData(decoder);
    
    [decoder release];
    O2DataProviderRelease(dataProvider);
    
    return (NSData *)result;
}

+(BOOL)isPresentInDataProvider:(O2DataProvider *)provider {
   enum { signatureLength=2 };
   unsigned char signature[signatureLength] = {0xFF,0xD8};
   unsigned char check[signatureLength];
   NSInteger     i,size=[provider getBytes:check range:NSMakeRange(0,signatureLength)];
   
   if(size!=signatureLength)
    return NO;
    
   for(i=0;i<signatureLength;i++)
    if(signature[i]!=check[i])
     return NO;

   return YES;
}

-initWithDataProvider:(O2DataProviderRef)provider options:(NSDictionary *)options {
   [super initWithDataProvider:provider options:options];
   _jpg=O2DataProviderCopyData(provider);
   return self;
}

-(void)dealloc {
    CFRelease(_jpg);
   [super dealloc];
}

-(unsigned)count {
   return 1;
}

-(O2ImageRef)createImageAtIndex:(unsigned)index options:(CFDictionaryRef)options {
    O2DataProviderRef encodedProvider=O2DataProviderCreateWithCFData(_jpg);
    O2ImageDecoderRef decoder=createImageDecoderWithDataProvider(encodedProvider);
    O2DataProviderRef provider=O2ImageDecoderCreatePixelDataProvider(decoder);
        
    O2Image        *image=[[O2Image alloc] initWithWidth:O2ImageDecoderGetWidth(decoder)
                                                  height:O2ImageDecoderGetHeight(decoder)
                                        bitsPerComponent:O2ImageDecoderGetBitsPerComponent(decoder)
                                            bitsPerPixel:O2ImageDecoderGetBitsPerPixel(decoder)
                                             bytesPerRow:O2ImageDecoderGetBytesPerRow(decoder)
                                              colorSpace:O2ImageDecoderGetColorSpace(decoder)
                                              bitmapInfo:O2ImageDecoderGetBitmapInfo(decoder)
                                                 decoder:decoder
                                                provider:provider
                                                  decode:NULL
                                             interpolate:NO
                                         renderingIntent:kO2RenderingIntentDefault];
    
    O2DataProviderRelease(provider);
    [decoder release];
    O2DataProviderRelease(encodedProvider);
    
    return image;
}

@end
