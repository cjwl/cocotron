#import <AppKit/NSView.h>

@class PDFDocument,PDFSelection;

@interface PDFDocumentView : NSView {
   PDFDocument    *_document;
   NSMutableArray *_pageViews;
   float           _scaleFactor;
}

-(void)setDocument:(PDFDocument *)document;

-(void)layoutDocumentView;

-(void)pageUp:sender;
-(void)pageDown:sender;

-(void)goToPageAtIndex:(NSUInteger)pageIndex;

-(void)setCurrentSelection:(PDFSelection *)selection;

@end
