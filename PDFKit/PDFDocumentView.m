#import "PDFDocumentView.h"
#import "PDFDocument.h"
#import "PDFPageView.h"
#import "PDFPage.h"
#import <AppKit/NSClipView.h>

@implementation PDFDocumentView

-initWithFrame:(NSRect)rect {
   [super initWithFrame:rect];
   _pageViews=[[NSMutableArray alloc] init];
   return self;
}

-(BOOL)isFlipped {
   return YES;
}

-(void)setDocument:(PDFDocument *)document {
   document=[document retain];
   [_document release];
   _document=document;
}

-(void)layoutDocumentView {
  NSInteger i,count=[_document pageCount];

  for(i=0;i<count;i++){
   PDFPage *page=[_document pageAtIndex:i];
   
   if(i>=[_pageViews count]){
    PDFPageView *view=[[PDFPageView alloc] init];
    [_pageViews addObject:view];
    [self addSubview:view];
   }
   [[_pageViews objectAtIndex:i] setPage:page];
  }
  
  while([_pageViews count]>count){
   PDFPageView *view=[_pageViews lastObject];
   [view removeFromSuperview];
   [_pageViews removeLastObject];
  }

// autoscale
  
  float maxPageWidth=0;
  
  for(i=0;i<count;i++){
   PDFPageView *view=[_pageViews objectAtIndex:i];
   PDFPage     *page=[view page];
   NSRect       pageBounds=[page boundsForBox:kPDFDisplayBoxMediaBox];
      
   maxPageWidth=MAX(pageBounds.size.width,maxPageWidth);
  }
  
  
  // clipview bounds, this is wrong, need to translate 
  float availableWidth=[[self superview] bounds].size.width-([PDFPageView leftMargin]+[PDFPageView rightMargin]);
    
  _scaleFactor=availableWidth/maxPageWidth;
  
  CGFloat currentY=[PDFPageView topMargin];
  
  for(i=0;i<count;i++){
   PDFPageView *view=[_pageViews objectAtIndex:i];
   PDFPage     *page=[view page];
   NSRect       pageBounds=[page boundsForBox:kPDFDisplayBoxMediaBox];
   NSRect       viewFrame;
   
   viewFrame.origin.x=[PDFPageView leftMargin];
   viewFrame.origin.y=currentY;
   viewFrame.size.width=pageBounds.size.width*_scaleFactor;
   viewFrame.size.height=pageBounds.size.height*_scaleFactor;
   
   [view setFrame:viewFrame];
   
   currentY+=viewFrame.size.height;
   currentY+=[PDFPageView bottomMargin];
  }
  
  NSSize frameSize=[self frame].size;
  
  NSPoint scrollTo=[[self superview] bounds].origin;
  float percentage=scrollTo.y/frameSize.height;

  frameSize.width=[[self superview] bounds].size.width;
  frameSize.height=currentY;

  scrollTo.y=frameSize.height*percentage;
    
  [self setFrameSize:frameSize];
  [(NSClipView *)[self superview] scrollToPoint:scrollTo];
  
  [self setNeedsDisplay:YES];
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldSize {
   [self layoutDocumentView];
}

-(BOOL)acceptsFirstResponder {
   return YES;
}

-(BOOL)becomeFirstResponder {
   return YES;
}

-(void)keyDown:(NSEvent *)event {
   [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

-(void)pageUp:sender {
   NSRect rect = [self visibleRect];

   rect.origin.y -= rect.size.height;
   [self scrollPoint:rect.origin];
}

-(void)pageDown:sender {
   NSRect rect = [self visibleRect];

   rect.origin.y += rect.size.height;
   [self scrollPoint:rect.origin];
}

-(void)goToPageAtIndex:(NSUInteger)pageIndex {
   NSView *pageView=[_pageViews objectAtIndex:pageIndex];
   NSRect  frame=[pageView frame];
   
   [self scrollRectToVisible:frame];
   
}

-(void)setCurrentSelection:(PDFSelection *)selection {
   [_pageViews makeObjectsPerformSelector:_cmd withObject:selection];
}

-(void)drawRect:(NSRect)rect {
}

@end
