#import <AppKit/NSView.h>
#import <ApplicationServices/ApplicationServices.h>

@class PDFPage,PDFSelection;

@interface PDFPageView: NSView {
  PDFPage *_page;
  PDFSelection *_selection;
}

+(float)leftMargin;
+(float)rightMargin;
+(float)topMargin;
+(float)bottomMargin;

-(PDFPage *)page;
-(void)setPage:(PDFPage *)page;

-(void)setCurrentSelection:(PDFSelection *)selection;

@end
