#import <AppKit/NSView.h>

@class PDFSelection,PDFDocument,NSScrollView,PDFPage;

typedef enum {
   kPDFDisplaySinglePage,
   kPDFDisplaySinglePageContinuous,
   kPDFDisplayTwoUp,
   kPDFDisplayTwoUpContinuous,
} PDFDisplayMode;

@interface PDFView : NSView {
   PDFDocument  *_document;
   PDFDisplayMode _displayMode;
   BOOL           _pageBreaks;
   float          _scaleFactor;
   BOOL           _autoScale;
   PDFSelection *_currentSelection;
   NSScrollView *_scrollView;
   id            _documentView;
}

-(PDFDocument *)document;
-(void)setDocument:(PDFDocument *)document;

-(void)layoutDocumentView;

-(PDFSelection *)currentSelection;
-(void)setCurrentSelection:(PDFSelection *)selection;
-(void)scrollSelectionToVisible:sender;

-(void)goToPage:(PDFPage *)page;

@end
