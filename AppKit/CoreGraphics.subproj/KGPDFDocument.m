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
#import "KGPDFScanner.h"

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

-(KGPDFPage *)pageAtNumber:(int)pageNumber pages:(KGPDFDictionary *)pages pagesOffset:(int)pagesOffset {
   KGPDFArray  *kids;
   KGPDFInteger i,kidsCount,pageCount;
   
   if(![pages getArrayForKey:"Kids" value:&kids])
    return nil;

   if(![pages getIntegerForKey:"Count" value:&pageCount])
    return nil;
   
   kidsCount=[kids count];
   for(i=0;i<kidsCount;i++){
    KGPDFDictionary *check;
    const char      *type;
        
    if(![kids getDictionaryAtIndex:i value:&check])
     return nil;

    if(![check getNameForKey:"Type" value:&type])
     return nil;
    
    if(strcmp(type,"Page")==0){
     if(pagesOffset==pageNumber)
      return [KGPDFPage pdfPageWithDocument:self pageNumber:pageNumber dictionary:check];
      
     pagesOffset++;
    }
    else if(strcmp(type,"Pages")==0){
     KGPDFPage *checkPage=[self pageAtNumber:pageNumber pages:check pagesOffset:pagesOffset];
     
     if(checkPage!=nil)
      return checkPage;
     else {
      KGPDFInteger checkCount;
     
      if(![check getIntegerForKey:"Count" value:&checkCount])
       return nil;
     
      pagesOffset+=checkCount;
     }
    }
    else
     return nil;
   }
   return nil;
}

-(KGPDFPage *)pageAtNumber:(int)pageNumber {
   KGPDFDictionary *pages=[self pagesRoot];
   KGPDFPage       *page=[self pageAtNumber:pageNumber pages:pages pagesOffset:0];

   return page;
}

@end
