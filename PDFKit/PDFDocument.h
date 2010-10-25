#import <Foundation/NSObject.h>
#import <PDFKit/PDFKitExport.h>
#import <ApplicationServices/ApplicationServices.h>

@class NSURL,NSArray,NSMutableArray,PDFPage,PDFSelection,NSTimer,NSNotification;

PDFKIT_EXPORT NSString *const PDFDocumentDidEndFindNotification;
PDFKIT_EXPORT NSString *const PDFDocumentDidFindMatchNotification;

@interface PDFDocument : NSObject {
   NSURL    *_documentURL;
   id        _delegate;
   CGPDFDocumentRef _documentRef;
   NSMutableArray *_pages;
   
   NSUInteger      _findOptions;
   NSUInteger      _findPatternLength;
   unichar        *_findPattern;
   NSInteger      *_findNext;
   NSInteger       _findPosition;
   NSInteger       _findPageIndex;   
   NSTimer        *_findTimer;
}

-initWithData:(NSData *)data;
-initWithURL:(NSURL *)url;

-(NSURL *)documentURL;

-(void)setDelegate: object;

-(Class)pageClass;

-(NSUInteger)pageCount;
-(PDFPage *)pageAtIndex:(NSUInteger)index;
-(NSUInteger)indexForPage:(PDFPage *)page;

-(BOOL)isFinding;
-(void)cancelFindString;
-(void)beginFindString:(NSString *)string withOptions:(NSUInteger)options;
-(NSArray *)findString:(NSString *)string withOptions:(NSUInteger) options;

@end

@interface NSObject(PDFDocumentDelegate)
-(void)didMatchString:(PDFSelection *)selection;

-(void)documentDidBeginDocumentFind:(NSNotification *)note;
-(void)documentDidEndDocumentFind:(NSNotification *)note;

-(void)documentDidBeginPageFind:(NSNotification *)note;
-(void)documentDidEndPageFind:(NSNotification *)note;

-(void)documentDidFindMatch:(NSNotification *)note;

-(void)documentDidUnlock:(NSNotification *)note;
@end
