/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGContext.h"
#import <Foundation/NSMapTable.h>

@class KGPDFContext, KGPDFxref,KGPDFObject, KGPDFDictionary,KGPDFArray,NSMutableData,NSMutableDictionary,KGDataConsumer;

@interface KGPDFContext : KGContext {
   KGDataConsumer  *_dataConsumer;
   NSMutableData   *_mutableData;
   NSMutableDictionary *_fontCache;
   NSMapTable     *_objectToRef;
   NSMutableArray *_indirectObjects;
   NSMutableArray *_indirectEntries;
   unsigned        _nextNumber;
   KGPDFxref       *_xref;
   KGPDFDictionary *_info;
   KGPDFDictionary *_catalog;
   KGPDFDictionary *_pages;
   KGPDFArray      *_kids;
   KGPDFDictionary *_page;
   NSMutableDictionary *_categoryToNext;
   NSMutableArray  *_textStateStack;
   NSMutableArray  *_contentStreamStack;
}

-initWithConsumer:(KGDataConsumer *)consumer mediaBox:(const CGRect *)mediaBox auxiliaryInfo:(NSDictionary *)auxiliaryInfo;

-(unsigned)length;
-(NSData *)data;

-(void)appendData:(NSData *)data;
-(void)appendBytes:(const void *)ptr length:(unsigned)length;
-(void)appendCString:(const char *)cString;
-(void)appendString:(NSString *)string;
-(void)appendFormat:(NSString *)format,...;
-(void)appendPDFStringWithBytes:(const void *)bytes length:(unsigned)length;

-(KGPDFObject *)referenceForFontWithName:(NSString *)name size:(float)size;
-(void)setReference:(KGPDFObject *)reference forFontWithName:(NSString *)name size:(float)size;
-(KGPDFObject *)referenceForObject:(KGPDFObject *)object;

-(void)encodePDFObject:(KGPDFObject *)object;
-(KGPDFObject *)encodeIndirectPDFObject:(KGPDFObject *)object;

@end
