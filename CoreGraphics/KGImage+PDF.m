#import "KGImage+PDF.h"
#import "O2ColorSpace+PDF.h"
#import "KGDataProvider.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import "KGPDFStream.h"
#import "KGPDFContext.h"

@implementation O2Image(PDF)

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

-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context {
   O2PDFStream     *result=[O2PDFStream pdfStream];
   O2PDFDictionary *dictionary=[O2PDFDictionary pdfDictionary];

   [dictionary setNameForKey:"Type" value:"XObject"];
   [dictionary setNameForKey:"Subtype" value:"Image"];
   [dictionary setIntegerForKey:"Width" value:_width];
   [dictionary setIntegerForKey:"Height" value:_height];
   if(_colorSpace!=nil)
    [dictionary setObjectForKey:"ColorSpace" value:[_colorSpace encodeReferenceWithContext:context]];
   [dictionary setIntegerForKey:"BitsPerComponent" value:_bitsPerComponent];
   [dictionary setNameForKey:"Intent" value:KGImageNameWithIntent(_renderingIntent)];
   [dictionary setBooleanForKey:"ImageMask" value:_isMask];
   if(_mask!=nil)
    [dictionary setObjectForKey:"Mask" value:[_mask encodeReferenceWithContext:context]];
   if(_decode!=NULL)
    [dictionary setObjectForKey:"Decode" value:[O2PDFArray pdfArrayWithNumbers:_decode count:[_colorSpace numberOfComponents]*2]];
   [dictionary setBooleanForKey:"Interpolate" value:_interpolate];
   /* FIX, generate soft mask
    [dictionary setObjectForKey:"SMask" value:[softMask encodeReferenceWithContext:context]];
    */
  
   /* FIX
    */
    
   return [context encodeIndirectPDFObject:result];
}



+(O2Image *)imageWithPDFObject:(O2PDFObject *)object {
   O2PDFStream     *stream=(O2PDFStream *)object;
   O2PDFDictionary *dictionary=[stream dictionary];
   O2PDFInteger width;
   O2PDFInteger height;
   O2PDFObject *colorSpaceObject;
   O2PDFInteger bitsPerComponent;
   const char  *intent;
   O2PDFBoolean isImageMask;
   O2PDFObject *imageMaskObject=NULL;
   O2ColorSpaceRef colorSpace=NULL;
    int               componentsPerPixel;
   O2PDFArray     *decodeArray;
   float            *decode=NULL;
   BOOL              interpolate;
   O2PDFStream *softMaskStream=nil;
   O2Image *softMask=NULL;
    
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
   if((colorSpace=[O2ColorSpace colorSpaceFromPDFObject:colorSpaceObject])==NULL)
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
     O2PDFReal number;
      
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
    O2DataProvider * provider;
    O2Image *image=NULL;
       
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
    provider=[[O2DataProvider alloc] initWithData:data];
    if(isImageMask){      
     image=[[O2Image alloc] initMaskWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow provider:provider decode:decode interpolate:interpolate];
    }
    else {
     image=[[O2Image alloc] initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:0 provider:provider decode:decode interpolate:interpolate renderingIntent:KGImageRenderingIntentWithName(intent)];

     if(softMask!=NULL)
      [image addMask:softMask];
    }

    return image;
   }
   return nil;
}

@end

