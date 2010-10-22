#import "PDFPageView.h"
#import <PDFKit/PDFPage.h>
#import <PDFKit/PDFSelection.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContext.h>

@implementation PDFPageView

+(float)leftMargin {
   return 4;
}

+(float)rightMargin {
   return 4;
}

+(float)topMargin {
   return 1;
}

+(float)bottomMargin {
   return 4;
}

-(PDFPage *)page {
   return _page;
}

-(void)setPage:(PDFPage *)page {
   page=[page retain];
   [_page release];
   _page=page;
}

-(void)setCurrentSelection:(PDFSelection *)selection {
   selection=[selection retain];
   [_selection release];
   _selection=selection;
   [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)rect {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   CGPDFPageRef page=[_page pageRef];
   NSRect bounds=[self bounds];
   
   [[NSColor darkGrayColor] set];
   NSRectFill(bounds);
   
   bounds.origin.x+=[isa leftMargin];
   bounds.size.width-=[isa leftMargin]+[isa rightMargin];
   bounds.size.height-=[isa topMargin]+[isa bottomMargin];
   bounds.origin.y+=[isa bottomMargin];
   [[NSColor whiteColor] set];
   NSRectFill(bounds);

   CGContextSaveGState(context);

   CGAffineTransform xform=CGPDFPageGetDrawingTransform(page,kCGPDFMediaBox,bounds,0,NO);
   
   CGContextConcatCTM(context,xform);

   [_selection drawForPage:_page withBox:kCGPDFMediaBox active:YES];

   CGContextDrawPDFPage(context,page);
      
   CGContextRestoreGState(context);
}

@end
