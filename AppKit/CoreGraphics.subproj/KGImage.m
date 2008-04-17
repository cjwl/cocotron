/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGImage.h"
#import "KGColorSpace.h"
#import "KGDataProvider.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFStream.h"
#import "KGPDFContext.h"
#import <Foundation/NSData.h>

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
   _isMask=NO;
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
   _isMask=YES;
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

CGColorRenderingIntent KGImageRenderingIntentWithName(const char *name) {
   if(name==NULL)
    return kCGRenderingIntentDefault;
    
   if(strcmp(name,"AbsoluteColorimetric")==0)
    return kCGRenderingIntentAbsoluteColorimetric;
   else if(strcmp(name,"RelativeColorimetric")==0)
    return kCGRenderingIntentRelativeColorimetric;
   else if(strcmp(name,"Saturation")==0)
    return kCGRenderingIntentSaturation;
   else if(strcmp(name,"Perceptual")==0)
    return kCGRenderingIntentPerceptual;
   else
    return kCGRenderingIntentDefault; // unknown
}

const char *KGImageNameWithIntent(CGColorRenderingIntent intent){
   switch(intent){
   
    case kCGRenderingIntentAbsoluteColorimetric:
     return "AbsoluteColorimetric";

    case kCGRenderingIntentRelativeColorimetric:
     return "RelativeColorimetric";

    case kCGRenderingIntentSaturation:
     return "Saturation";
     
    default:
    case kCGRenderingIntentDefault:
    case kCGRenderingIntentPerceptual:
     return "Perceptual";
   } 
}

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFStream     *result=[KGPDFStream pdfStream];
   KGPDFDictionary *dictionary=[KGPDFDictionary pdfDictionary];

   [dictionary setNameForKey:"Type" value:"XObject"];
   [dictionary setNameForKey:"Subtype" value:"Image"];
   [dictionary setIntegerForKey:"Width" value:_width];
   [dictionary setIntegerForKey:"Height" value:_height];
   if(_colorSpace!=nil)
    [dictionary setObjectForKey:"ColorSpace" value:[_colorSpace encodeReferenceWithContext:context]];
   [dictionary setIntegerForKey:"BitsPerComponent" value:_bitsPerComponent];
   [dictionary setNameForKey:"Intent" value:KGImageNameWithIntent(_intent)];
   [dictionary setBooleanForKey:"ImageMask" value:_isMask];
   if(_mask!=nil)
    [dictionary setObjectForKey:"Mask" value:[_mask encodeReferenceWithContext:context]];
   if(_decode!=NULL)
    [dictionary setObjectForKey:"Decode" value:[KGPDFArray pdfArrayWithNumbers:_decode count:[_colorSpace numberOfComponents]*2]];
   [dictionary setBooleanForKey:"Interpolate" value:_interpolate];
   /* FIX, generate soft mask
    [dictionary setObjectForKey:"SMask" value:[softMask encodeReferenceWithContext:context]];
    */
  
   /* FIX
    */
    
   return [context encodeIndirectPDFObject:result];
}



+(KGImage *)imageWithPDFObject:(KGPDFObject *)object {
   KGPDFStream     *stream=(KGPDFStream *)object;
   KGPDFDictionary *dictionary=[stream dictionary];
   KGPDFInteger width;
   KGPDFInteger height;
   KGPDFObject *colorSpaceObject;
   KGPDFInteger bitsPerComponent;
   const char  *intent;
   KGPDFBoolean isImageMask;
   KGPDFObject *imageMaskObject=NULL;
   KGColorSpace *colorSpace=NULL;
    int               componentsPerPixel;
   KGPDFArray     *decodeArray;
   float            *decode=NULL;
   BOOL              interpolate;
   KGPDFStream *softMaskStream=nil;
   KGImage *softMask=NULL;
    
   // NSLog(@"Image=%@",dictionary);
    
   if(![dictionary getIntegerForKey:"Width" value:&width]){
    NSLog(@"Image has no Width");
    return NULL;
   }
   if(![dictionary getIntegerForKey:"Height" value:&height]){
    NSLog(@"Image has no Height");
    return NULL;
   }
    
   if(![dictionary getObjectForKey:"ColorSpace" value:&colorSpaceObject]){
    NSLog(@"Image has no ColorSpace");
    return NULL;
   }
   if((colorSpace=[KGColorSpace colorSpaceFromPDFObject:colorSpaceObject])==NULL)
    return NULL;
     
   componentsPerPixel=[colorSpace numberOfComponents];
    
   if(![dictionary getIntegerForKey:"BitsPerComponent" value:&bitsPerComponent]){
    NSLog(@"Image has no BitsPerComponent");
    return NULL;
   }
   if(![dictionary getNameForKey:"Intent" value:&intent])
    intent=NULL;
   if(![dictionary getBooleanForKey:"ImageMask" value:&isImageMask])
    isImageMask=NO;
     
   if(!isImageMask && [dictionary getObjectForKey:"Mask" value:&imageMaskObject]){
    
    
   }

   if(![dictionary getArrayForKey:"Decode" value:&decodeArray])
    decode=NULL;
   else {
    int i,count=[decodeArray count];
     
    if(count!=componentsPerPixel*2){
     NSLog(@"Invalid decode array, count=%d, should be %d",count,componentsPerPixel*2);
     return NULL;
    }
    
    decode=__builtin_alloca(sizeof(float)*count);
    for(i=0;i<count;i++){
     KGPDFReal number;
      
     if(![decodeArray getNumberAtIndex:i value:&number]){
      NSLog(@"Invalid decode array entry at %d",i);
      return NULL;
     }
     decode[i]=number;
    }
   }
    
   if(![dictionary getBooleanForKey:"Interpolate" value:&interpolate])
    interpolate=NO;
    
   if([dictionary getStreamForKey:"SMask" value:&softMaskStream]){
//    NSLog(@"SMask=%@",[softMaskStream dictionary]);
    softMask=[self imageWithPDFObject:softMaskStream];
   }
    
   if(colorSpace!=NULL){
    int               bitsPerPixel=componentsPerPixel*bitsPerComponent;
    int               bytesPerRow=((width*bitsPerPixel)+7)/8;
    NSData           *data=[stream data];
    KGDataProvider * provider;
    KGImage *image=NULL;
       
//     NSLog(@"width=%d,height=%d,bpc=%d,bpp=%d,bpr=%d,cpp=%d",width,height,bitsPerComponent,bitsPerPixel,bytesPerRow,componentsPerPixel);
     
    if(height*bytesPerRow!=[data length]){
     NSMutableData *mutable=[NSMutableData dataWithLength:height*bytesPerRow];
     char *mbytes=[mutable mutableBytes];
      int i;
      for(i=0;i<height*bytesPerRow;i++)
       mbytes[i]=0x33;
       
     NSLog(@"Invalid data length=%d,should be %d=%d",[data length],height*bytesPerRow,[data length]-height*bytesPerRow);
     data=mutable;
      //return NULL;
    }
    provider=[[KGDataProvider alloc] initWithData:data];
    if(isImageMask){
     float decodeDefault[2]={0,1};
      
     if(decode==NULL)
      decode=decodeDefault;
      
     image=[[KGImage alloc] initMaskWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow provider:provider decode:decode interpolate:interpolate];
    }
    else {
     image=[[KGImage alloc] initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:0 provider:provider decode:decode interpolate:interpolate renderingIntent:KGImageRenderingIntentWithName(intent)];

     if(softMask!=NULL)
      [image addMask:softMask];
    }

    return image;
   }
   return nil;
}

@end
