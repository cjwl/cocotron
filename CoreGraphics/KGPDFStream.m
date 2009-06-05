/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGPDFStream.h"
#import "KGPDFDictionary.h"
#import "KGPDFArray.h"
#import "KGPDFFilter.h"
#import "KGPDFxref.h"
#import "KGPDFContext.h"
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

@implementation KGPDFStream

-initWithDictionary:(KGPDFDictionary *)dictionary xref:(KGPDFxref *)xref position:(KGPDFInteger)position {
   KGPDFInteger length;
   
   _dictionary=[dictionary retain];
   
   if(![_dictionary getIntegerForKey:"Length" value:&length])
    _data=nil;

// FIX, can do a more efficient subdata here
   _data=[[[xref data] subdataWithRange:NSMakeRange(position,length)] retain];
   _xref=[xref retain];
   return self;
}

-initWithDictionary:(KGPDFDictionary *)dictionary data:(NSData *)data {
   _dictionary=[dictionary retain];
   _data=[data retain];
   _xref=nil;
   return self;
}

-(void)dealloc {
   [_dictionary release];
   [_data release];
   [_xref release];
   [super dealloc];
}

+(KGPDFStream *)pdfStream {
   return [self pdfStreamWithData:[NSMutableData data]];
}

+(KGPDFStream *)pdfStreamWithData:(NSData *)data {
   KGPDFDictionary *dictionary=[KGPDFDictionary pdfDictionary];
   
   [dictionary setIntegerForKey:"Length" value:[data length]];
   
   return [[[self alloc] initWithDictionary:dictionary data:data] autorelease];
}

+(KGPDFStream *)pdfStreamWithBytes:(const void *)bytes length:(unsigned)length {
   return [self pdfStreamWithData:[NSData dataWithBytes:bytes length:length]];
}

-(KGPDFObjectType)objectType { return kKGPDFObjectTypeStream; }

-(BOOL)checkForType:(KGPDFObjectType)type value:(void *)value {
   if(type!=kKGPDFObjectTypeStream)
    return NO;
   
   *((KGPDFStream **)value)=self;
   return YES;
}

-(KGPDFDictionary *)dictionary {
   return _dictionary;
}

-(KGPDFxref *)xref {
   return _xref;
}

-(NSData *)data {
   KGPDFInteger     length;
   NSData          *result;
   const char      *name;
   KGPDFDictionary *parameters;
   KGPDFArray      *filters;

   if(![_dictionary getIntegerForKey:"Length" value:&length])
    return nil;

   result=_data;
       
   if([_dictionary getNameForKey:"Filter" value:&name]){
    
    if(![_dictionary getDictionaryForKey:"DecodeParms" value:&parameters])
     parameters=nil;

    result=KGPDFFilterWithName(name,result,parameters);
   }
   else if([_dictionary getArrayForKey:"Filter" value:&filters]){
    KGPDFArray *parameterArray;
    int         i,count=[filters count];
    
    if(![_dictionary getArrayForKey:"DecodeParms" value:&parameterArray])
     parameterArray=nil;
    
    for(i=0;i<count;i++){
     if(![filters getNameAtIndex:i value:&name]){
      NSLog(@"expecting filter name at %d",i);
      return nil;
     }
     if(![parameterArray getDictionaryAtIndex:i value:&parameters])
      parameters=nil;
	 result=KGPDFFilterWithName(name,result,parameters);
    }
    
   }
     
   return result;
}

-(NSMutableData *)mutableData {
   return (NSMutableData *)_data;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"stream %@",_dictionary];
}

-(BOOL)isByReference {
   return YES;
}

-(void)encodeWithPDFContext:(KGPDFContext *)encoder {
   [_dictionary setIntegerForKey:"Length" value:[_data length]];
   
   [encoder encodePDFObject:_dictionary];
   [encoder appendCString:"stream\n"];
   [encoder appendData:_data];
   [encoder appendCString:"\nendstream\n"];
}

@end
