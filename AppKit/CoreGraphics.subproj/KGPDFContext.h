#import "KGContext.h"

@class KGPDFContext, KGPDFxref,KGPDFObject, KGPDFDictionary,KGPDFArray;

@interface KGPDFContext : KGContext {
   NSMutableData  *_mutableData;
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
   NSMutableArray  *_contentStreamStack;
}

-initWithMutableData:(NSMutableData *)data;

-(unsigned)length;
-(NSData *)data;

-(void)appendData:(NSData *)data;
-(void)appendBytes:(const void *)ptr length:(unsigned)length;
-(void)appendCString:(const char *)cString;
-(void)appendString:(NSString *)string;
-(void)appendFormat:(NSString *)format,...;

-(void)encodePDFObject:(KGPDFObject *)object;

@end
