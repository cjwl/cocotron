#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class PDFPage;

@interface PDFSelectedRange : NSObject <NSCopying> {
   PDFPage  *_page;
   NSRange   _range;
}

-initWithPage:(PDFPage *)page range:(NSRange)range;

-(PDFPage *)page;
-(NSRange)range;

@end
