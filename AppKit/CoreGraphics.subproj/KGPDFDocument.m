/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFDocument.h"

#import "KGPDFPage.h"
#import "KGPDFxref.h"
#import "KGPDFDictionary.h"
#import "KGPDFArray.h"
#import "KGPDFString.h"

#import <limits.h>

@implementation KGPDFDocument

-initWithData:(NSData *)data {   
   if(!KGPDFScanVersion([data bytes],[data length],&_version)){
    [self dealloc];
    return nil;
   }
   [_version retain];
   
   if(!KGPDFParse_xref(data,&_xref)){
    [self dealloc];
    return nil;
   }
   [_xref retain];
   
   return self;
}

-(void)dealloc{
   [_xref release];
   [super dealloc];
}

-(KGPDFxref *)xref {
   return _xref;
}

-(KGPDFDictionary *)trailer {
   return [_xref trailer];
}

-(KGPDFDictionary *)catalog {
   KGPDFDictionary *result;
   
   if(![[self trailer] getDictionaryForKey:"Root" value:&result])
    return nil;
    
   return result;
}

-(KGPDFDictionary *)infoDictionary {
   KGPDFDictionary *result;
   
   if(![[self trailer] getDictionaryForKey:"Info" value:&result])
    return nil;
    
   return result;
}

-(KGPDFDictionary *)encryptDictionary {
   KGPDFDictionary *result;
   
   if(![[self trailer] getDictionaryForKey:"Encrypt" value:&result])
    return nil;
    
   return result;
}

-(KGPDFDictionary *)pagesRoot {
   KGPDFDictionary *result;
   
   if(![[self catalog] getDictionaryForKey:"Pages" value:&result])
    return nil;
    
   return result;
}

-(int)pageCount {
   KGPDFInteger result;
   
   if(![[self pagesRoot] getIntegerForKey:"Count" value:&result])
    return 0;
    
   return result;
}

-(KGPDFPage *)pageAtNumber:(int)pageNumber {
   KGPDFDictionary *pages=[self pagesRoot];
   KGPDFArray      *kids;
   int              i=0,count,pageIndex=0;
   KGPDFInteger     pageCount,parentCount=INT_MAX;

   if(![pages getArrayForKey:"Kids" value:&kids])
    return nil;
    
   count=[kids count];
   
   while(i<count){
    KGPDFDictionary *check;
    const char      *type;
    
    if(![kids getDictionaryAtIndex:i++ value:&check])
     return nil;

    if([check getNameForKey:"Type" value:&type]){
    
     if(pageIndex>=pageNumber && strcmp(type,"Page")==0)
      return [KGPDFPage pdfPageWithDocument:self pageNumber:pageNumber dictionary:check];
    }
    
    if(![check getIntegerForKey:"Count" value:&pageCount])
     pageCount=0;

    if(pageCount<parentCount && (pageIndex+pageCount)<=pageNumber){
     pageIndex+=(pageCount==0)?1:pageCount;
    }
    else{
     if(![pages getArrayForKey:"Kids" value:&kids])
      count=0;
     else
      count=[kids count];
     i=0;
     parentCount=pageCount;
    }

   }
   return nil;
}

@end
