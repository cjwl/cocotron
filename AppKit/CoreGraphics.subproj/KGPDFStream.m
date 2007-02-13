/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFStream.h"
#import "KGPDFDictionary.h"
#import "KGPDFArray.h"
#import "KGPDFFilter.h"
#import "KGPDFxref.h"
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

@implementation KGPDFStream

-initWithDictionary:(KGPDFDictionary *)dictionary xref:(KGPDFxref *)xref position:(KGPDFInteger)position {
   _dictionary=[dictionary retain];
   _xref=[xref retain];
   _position=position;
   return self;
}

-(void)dealloc {
   [_dictionary release];
   [_xref release];
   [super dealloc];
}

-(KGPDFObjectType)objectType { return kKGPDFObjectTypeStream; }

-(BOOL)checkForType:(KGPDFObjectType)type value:(void *)value {
   if(type!=kKGPDFObjectTypeStream)
    return NO;
   
   *((KGPDFStream **)value)=self;
   return YES;
}

-(KGPDFxref *)xref {
   return _xref;
}

-(KGPDFDictionary *)dictionary {
   return _dictionary;
}

-(NSData *)data {
   KGPDFInteger     length;
   NSData          *result;
   const char      *name;
   KGPDFDictionary *parameters;
   KGPDFArray      *filters;

   if(![_dictionary getIntegerForKey:"Length" value:&length])
    return nil;

// FIX, can do nocopynofree here
   result=[[_xref data] subdataWithRange:NSMakeRange(_position,length)];
       
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

-(NSString *)description {
   return [NSString stringWithFormat:@"stream %@",_dictionary];
}

@end
