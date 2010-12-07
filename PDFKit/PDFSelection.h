#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <PDFKit/PDFPage.h>

@class PDFDocument,NSColor,NSArray,NSMutableArray,NSAttributedString,PDFPage;

@interface PDFSelection : NSObject <NSCopying> {
   PDFDocument *_document;
   NSColor     *_color;
   NSArray     *_ranges;
}

-initWithDocument:(PDFDocument *)document;

-(NSColor *)color;
-(void)setColor:(NSColor *)value;

-(NSArray *)pages;
-(NSString *)string;
-(NSAttributedString *)attributedString;

-(void)addSelection:(PDFSelection *)selection;
-(void)addSelections:(NSArray *)selections;

-(NSArray *)selectionsByLine;

-(void)extendSelectionAtEnd:(NSInteger)delta;
-(void)extendSelectionAtStart:(NSInteger)delta;

-(NSRect)boundsForPage:(PDFPage *)page;

-(void)drawForPage:(PDFPage *)page active:(BOOL)active;
-(void)drawForPage:(PDFPage *)page withBox:(PDFDisplayBox)box active:(BOOL)active;

@end

@interface PDFSelection(private)
-(NSArray *)_selectedRanges;
-(void)_setSelectedRanges:(NSArray *)ranges;
@end
