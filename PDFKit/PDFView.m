#import <PDFKit/PDFView.h>
#import <PDFKit/PDFDocument.h>
#import "PDFDocumentView.h"
#import <AppKit/NSRaise.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSScrollView.h>

@implementation PDFView

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];
   
   if([coder allowsKeyedCoding]){
    _displayMode=[coder decodeIntegerForKey:@"DisplayMode"];
    _pageBreaks=[coder decodeBoolForKey:@"PageBreaks"];
    _scaleFactor=[coder decodeFloatForKey:@"ScaleFactor"];
    _autoScale=[coder decodeBoolForKey:@"AutoScale"];
   }
   else
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] only implements keyed coding",isa,_cmd];
   
   _scrollView=[[NSScrollView alloc] initWithFrame:[self bounds]];
   [_scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
   [_scrollView setAutohidesScrollers:YES];
   [_scrollView setHasVerticalScroller:YES];
   [_scrollView setDrawsBackground:YES];
   [_scrollView setBackgroundColor:[NSColor lightGrayColor]];
   [_scrollView setBorderType:NSNoBorder];
      
   NSRect documentRect;
   documentRect.size=[_scrollView contentSize];
   _documentView=[[PDFDocumentView alloc] initWithFrame:documentRect];
   [_documentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
   [_scrollView setDocumentView:_documentView];
   
   [self addSubview:_scrollView];
   
   return self;
}

-(PDFDocument *)document {
   return _document;
}

-(void)setDocument:(PDFDocument *)document {
   document=[document retain];
   [_document release];
   _document=document;
   [_documentView setDocument:document];
   [self layoutDocumentView];
   [self setNeedsDisplay:YES];
}

-(void)layoutDocumentView {
   [_documentView layoutDocumentView];
}

-(PDFSelection *)currentSelection {
   return _currentSelection;
}

-(void)setCurrentSelection:(PDFSelection *)selection {
   selection=[selection retain];
   [_currentSelection release];
   _currentSelection=selection;
   
   [_documentView setCurrentSelection:_currentSelection];
}

-(void)pageDown:sender {
   [_documentView pageDown:sender];
}

-(void)pageUp:sender {
   [_documentView pageUp:sender];
}

-(void)scrollSelectionToVisible:sender {
   NSUnimplementedMethod();
}

-(void)goToPage:(PDFPage *)page {
   NSUInteger pageIndex=[_document indexForPage:page];
   
   [_documentView goToPageAtIndex:pageIndex];
}

-(BOOL)isOpaque {
   return YES;
}

-(void)drawRect:(NSRect)rect {
}

@end
