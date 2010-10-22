#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <ApplicationServices/ApplicationServices.h>

@class PDFDocument;

typedef enum {
kPDFDisplayBoxMediaBox=kCGPDFMediaBox,
kPDFDisplayBoxCropBox=kCGPDFCropBox,
kPDFDisplayBoxBleedBox=kCGPDFBleedBox,
kPDFDisplayBoxTrimBox=kCGPDFTrimBox,
kPDFDisplayBoxArtBox=kCGPDFArtBox,
} PDFDisplayBox;

@interface PDFPage : NSObject {
   PDFDocument *_document;
   CGPDFPageRef _pageRef;
   NSString    *_label;
   
   BOOL         _hasBeenDistilled;
   NSInteger    _capacityOfCharacters;
   NSInteger    _numberOfCharacters;
   unichar     *_characters;
   NSRect      *_characterRects;
}

-(PDFDocument *)document;
-(CGPDFPageRef)pageRef;
-(NSString *)label;

-(NSUInteger)numberOfCharacters;
-(NSString *)string;

-(NSRect)boundsForBox:(PDFDisplayBox)box;

-(void)transformContextForBox:(PDFDisplayBox)box;

-(void)drawWithBox:(PDFDisplayBox)box;

@end

@interface PDFPage(private)
-(void)_getRects:(NSRect *)rects range:(NSRange)range;
-(void)setPageRef:(CGPDFPageRef)pageRef;
-(void)setDocument:(PDFDocument *)document;
-(void)setLabel:(NSString *)value;
@end
