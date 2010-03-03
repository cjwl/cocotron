#import "O2ColorSpace+PDF.h"
#import "O2PDFObject_Name.h"
#import "O2PDFObject_Integer.h"
#import "O2PDFContext.h"
#import "O2PDFArray.h"
#import "O2PDFStream.h"
#import "O2PDFString.h"
#import "O2PDFDictionary.h"

@implementation O2ColorSpace(PDF)

-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context {
   O2PDFObject *name;
   
   switch(_type){
   
    case kO2ColorSpaceModelMonochrome:
     name=[O2PDFObject_Name pdfObjectWithCString:"DeviceGray"];
     break;
     
    case kO2ColorSpaceModelRGB:
     name=[O2PDFObject_Name pdfObjectWithCString:"DeviceRGB"];
     break;

    case kO2ColorSpaceModelCMYK:
     name=[O2PDFObject_Name pdfObjectWithCString:"DeviceCMYK"];
     break;

    default:
     return nil;
   }
   
   return [context encodeIndirectPDFObject:name];
}

+(O2ColorSpaceRef)colorSpaceFromPDFObject:(O2PDFObject *)object {
   const char  *colorSpaceName;
   O2PDFArray  *colorSpaceArray;

   if([object checkForType:kO2PDFObjectTypeName value:&colorSpaceName]){
    if(strcmp(colorSpaceName,"DeviceGray")==0)
     return O2ColorSpaceCreateDeviceGray();
    else if(strcmp(colorSpaceName,"DeviceRGB")==0)
     return O2ColorSpaceCreateDeviceRGB();
    else if(strcmp(colorSpaceName,"DeviceCMYK")==0)
     return O2ColorSpaceCreateDeviceCMYK();
    else {
     NSLog(@"does not handle color space named %s",colorSpaceName);
    }
   }
   else if([object checkForType:kO2PDFObjectTypeArray value:&colorSpaceArray]){
    const char *name;
     
    if(![colorSpaceArray getNameAtIndex:0 value:&name]){
     NSLog(@"first element of color space array is not name");
     return nil;
    }
    
    if(strcmp(name,"Indexed")==0){
     O2PDFObject    *baseObject;
     O2ColorSpaceRef baseColorSpace;
     O2PDFString    *tableString;
     O2PDFStream    *tableStream;
     int             baseNumberOfComponents;
     O2PDFInteger    hival,tableSize;

     if(![colorSpaceArray getObjectAtIndex:1 value:&baseObject]){
      NSLog(@"Indexed color space missing base");
      return nil;
     }

     if((baseColorSpace=[O2ColorSpace colorSpaceFromPDFObject:baseObject])==NULL){
      NSLog(@"Indexed color space invalid base %@",baseObject);
      return nil;
     }
     
     if(![colorSpaceArray getIntegerAtIndex:2 value:&hival]){
      NSLog(@"Indexed color space missing hival");
      return nil;
     }
     
     if(hival>255){
      NSLog(@"hival > 255, %d",hival);
      return nil;
     }
     baseNumberOfComponents=O2ColorSpaceGetNumberOfComponents(baseColorSpace);
     tableSize=baseNumberOfComponents*(hival+1);
     
     if([colorSpaceArray getStringAtIndex:3 value:&tableString]){
      if([tableString length]!=tableSize){
       NSLog(@"lookup invalid size,string length=%d,tableSize=%d",[tableString length],tableSize);
       return nil;
      }
      return [[O2ColorSpace_indexed alloc] initWithColorSpace:baseColorSpace hival:hival bytes:(const unsigned char *)[tableString bytes]];
     }
     else if([colorSpaceArray getStreamAtIndex:3 value:&tableStream]){
      NSData *data=[tableStream data];
      
      if([data length]!=tableSize){
       NSLog(@"lookup invalid size,data length=%d,tableSize=%d",[data length],tableSize);
       return nil;
      }
      return [[O2ColorSpace_indexed alloc] initWithColorSpace:baseColorSpace hival:hival bytes:(const unsigned char *)[data bytes]];
     }
     else {
      NSLog(@"indexed color space table invalid");
     }
    }
    else if(strcmp(name,"ICCBased")==0){
     O2PDFStream     *stream;
     O2PDFDictionary *dictionary;
     O2PDFInteger     numberOfComponents;
     
     if(![colorSpaceArray getStreamAtIndex:1 value:&stream]){
      NSLog(@"second element of ICCBased color space array is not a stream");
      return nil;
     }
     dictionary=[stream dictionary];
     if(![dictionary getIntegerForKey:"N" value:&numberOfComponents]){
      NSLog(@"Required key N missing from ICCBased stream");
      return nil;
     }
     switch(numberOfComponents){

      case 1:
       return O2ColorSpaceCreateDeviceGray();
       
      case 3:
       return O2ColorSpaceCreateDeviceRGB();
       
      case 4:
       return O2ColorSpaceCreateDeviceCMYK();
       
      default:
       NSLog(@"Invalid N in ICCBased stream");
       break;
     }
     
    }
    else {
     NSLog(@"does not handle color space %@",object);
    }
   }
   else {
    NSLog(@"invalid color space type %@",object);
   }

   
   return nil;
}

@end

@implementation O2ColorSpace_indexed(PDF)
-(O2PDFObject *)encodeReferenceWithContext:(O2PDFContext *)context {   
   O2PDFArray *result=[O2PDFArray pdfArray];
   int         max=O2ColorSpaceGetNumberOfComponents(_base)*(_hival+1);
    
   [result addObject:[O2PDFObject_Name pdfObjectWithCString:"Indexed"]];
   [result addObject:[_base encodeReferenceWithContext:context]];
   [result addObject:[O2PDFObject_Integer pdfObjectWithInteger:_hival]];
   [result addObject:[O2PDFStream pdfStreamWithBytes:_bytes length:max]];
   
   return [context encodeIndirectPDFObject:result];
}

@end

