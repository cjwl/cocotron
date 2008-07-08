#import "KGColorSpace+PDF.h"
#import "KGPDFObject_Name.h"
#import "KGPDFObject_Integer.h"
#import "KGPDFContext.h"
#import "KGPDFArray.h"
#import "KGPDFStream.h"
#import "KGPDFString.h"
#import "KGPDFDictionary.h"

@implementation KGColorSpace(PDF)

-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {
   KGPDFObject *name;
   
   switch(_type){
   
    case KGColorSpaceDeviceGray:
     name=[KGPDFObject_Name pdfObjectWithCString:"DeviceGray"];
     break;
     
    case KGColorSpaceDeviceRGB:
    case KGColorSpacePlatformRGB:  // wrong
     name=[KGPDFObject_Name pdfObjectWithCString:"DeviceRGB"];
     break;

    case KGColorSpaceDeviceCMYK:
     name=[KGPDFObject_Name pdfObjectWithCString:"DeviceCMYK"];
     break;

    default:
     return nil;
   }
   
   return [context encodeIndirectPDFObject:name];
}

+(KGColorSpace *)colorSpaceFromPDFObject:(KGPDFObject *)object {
   const char  *colorSpaceName;
   KGPDFArray  *colorSpaceArray;

   if([object checkForType:kKGPDFObjectTypeName value:&colorSpaceName]){
    if(strcmp(colorSpaceName,"DeviceGray")==0)
     return [[KGColorSpace alloc] initWithDeviceGray];
    else if(strcmp(colorSpaceName,"DeviceRGB")==0)
     return [[KGColorSpace alloc] initWithDeviceRGB];
    else if(strcmp(colorSpaceName,"DeviceCMYK")==0)
     return [[KGColorSpace alloc] initWithDeviceCMYK];
    else {
     NSLog(@"does not handle color space named %s",colorSpaceName);
    }
   }
   else if([object checkForType:kKGPDFObjectTypeArray value:&colorSpaceArray]){
    const char *name;
     
    if(![colorSpaceArray getNameAtIndex:0 value:&name]){
     NSLog(@"first element of color space array is not name");
     return nil;
    }
    
    if(strcmp(name,"Indexed")==0){
     KGPDFObject    *baseObject;
     KGColorSpace *baseColorSpace;
     KGPDFString    *tableString;
     KGPDFStream    *tableStream;
     int             baseNumberOfComponents;
     KGPDFInteger    hival,tableSize;

     if(![colorSpaceArray getObjectAtIndex:1 value:&baseObject]){
      NSLog(@"Indexed color space missing base");
      return nil;
     }

     if((baseColorSpace=[KGColorSpace colorSpaceFromPDFObject:baseObject])==NULL){
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
     baseNumberOfComponents=[baseColorSpace numberOfComponents];
     tableSize=baseNumberOfComponents*(hival+1);
     
     if([colorSpaceArray getStringAtIndex:3 value:&tableString]){
      if([tableString length]!=tableSize){
       NSLog(@"lookup invalid size,string length=%d,tableSize=%d",[tableString length],tableSize);
       return nil;
      }
      return [[KGColorSpace_indexed alloc] initWithColorSpace:baseColorSpace hival:hival bytes:(const unsigned char *)[tableString bytes]];
     }
     else if([colorSpaceArray getStreamAtIndex:3 value:&tableStream]){
      NSData *data=[tableStream data];
      
      if([data length]!=tableSize){
       NSLog(@"lookup invalid size,data length=%d,tableSize=%d",[data length],tableSize);
       return nil;
      }
      return [[KGColorSpace_indexed alloc] initWithColorSpace:baseColorSpace hival:hival bytes:(const unsigned char *)[data bytes]];
     }
     else {
      NSLog(@"indexed color space table invalid");
     }
    }
    else if(strcmp(name,"ICCBased")==0){
     KGPDFStream     *stream;
     KGPDFDictionary *dictionary;
     KGPDFInteger     numberOfComponents;
     
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
       return [[KGColorSpace alloc] initWithDeviceGray];
       
      case 3:
       return [[KGColorSpace alloc] initWithDeviceRGB];
       
      case 4:
       return [[KGColorSpace alloc] initWithDeviceCMYK];
       
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

@implementation KGColorSpace_indexed(PDF)
-(KGPDFObject *)encodeReferenceWithContext:(KGPDFContext *)context {   
   KGPDFArray *result=[KGPDFArray pdfArray];
   int         max=[_base numberOfComponents]*(_hival+1);
     
   [result addObject:[KGPDFObject_Name pdfObjectWithCString:"Indexed"]];
   [result addObject:[_base encodeReferenceWithContext:context]];
   [result addObject:[KGPDFObject_Integer pdfObjectWithInteger:_hival]];
   [result addObject:[KGPDFStream pdfStreamWithBytes:_bytes length:max]];
   
   return [context encodeIndirectPDFObject:result];
}

@end

