#import <PDFKit/PDFSelection.h>
#import "PDFSelectedRange.h"
#import <AppKit/NSRaise.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <Foundation/NSArray.h>

@implementation PDFSelection

-initWithDocument:(PDFDocument *)document {
   _document=[document retain];
   _color=nil;
   _ranges=nil;
   return self;
}

-(void)dealloc {
   [_document release];
   [_color release];
   [_ranges release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   PDFSelection *result=NSCopyObject(self,0,zone);
   
   result->_document=[_document retain];
   result->_color=[_color copy];
   result->_ranges=[_ranges copy];
   
   return result;
}

-(NSColor *)color {
   return _color;
}

-(void)setColor:(NSColor *)value {
   value=[value copy];
   [_color release];
   _color=value;
}

-(NSArray *)_selectedRanges {
   return _ranges;
}

-(void)_setSelectedRanges:(NSArray *)ranges {
   ranges=[ranges copy];
   [_ranges release];
   _ranges=ranges;
}

-(NSArray *)pages {
   NSMutableArray *result=[NSMutableArray array];
   NSInteger       i,count=[_ranges count];
   
   for(i=0;i<count;i++){
    PDFSelectedRange *selectedRange=[_ranges objectAtIndex:i];
    PDFPage *page=[selectedRange page];
    
    if(![result containsObject:page])
     [result addObject:page];
   }
   
   return result;
}

-(NSString *)string {
   NSMutableString *result=[NSMutableString string];
   NSInteger i,count=[_ranges count];
   
   for(i=0;i<count;i++){
    PDFSelectedRange *selectedRange=[_ranges objectAtIndex:i];
    PDFPage          *page=[selectedRange page];
    NSString         *string=[page string];
    NSRange           range=[selectedRange range];
    
    [result appendString:[string substringWithRange:range]];
   }
   
   return result;
}

-(NSAttributedString *)attributedString {
   return [[[NSAttributedString alloc] initWithString:[self string]] autorelease];
}


-(void)addSelection:(PDFSelection *)selection {
   NSMutableArray *result=[NSMutableArray array];
   
   [result addObjectsFromArray:_ranges];
   [result addObjectsFromArray:[selection _selectedRanges]];
   [self _setSelectedRanges:result];
}

-(void)addSelections:(NSArray *)selections {
   for(PDFSelection *selection in selections)
    [self addSelection:selection];
}

-(NSArray *)selectionsByLine {
}

-(void)extendSelectionAtEnd:(NSInteger)delta {
// FIXME: This method should extend through page boundries, and what do negative deltas mean?
   PDFSelectedRange *lastRange=[_ranges lastObject];
   PDFPage          *page=[lastRange page];
   NSRange           range=[lastRange range];
   
   if(delta>0){
    NSInteger location=NSMaxRange(range);
    NSInteger length=delta;
    
    if(location+length>[page numberOfCharacters])
     length=[page numberOfCharacters]-location;
     
    if(length>0){
     PDFSelectedRange *extendRange=[[[PDFSelectedRange alloc] initWithPage:page range:NSMakeRange(location,length)] autorelease];
     NSMutableArray *changes=[[_ranges mutableCopy] autorelease];
     [changes addObject:extendRange];
     [self _setSelectedRanges:changes];
    }
   }
}

-(void)extendSelectionAtStart:(NSInteger)delta {
// FIXME: This method should extend through page boundries, and what do negative deltas mean?
   PDFSelectedRange *firstRange=[_ranges objectAtIndex:0];
   PDFPage          *page=[firstRange page];
   NSRange           range=[firstRange range];
   
   if(delta>0){
    NSInteger location=range.location;
    location-=delta;
    if(location<0)
     location=0;
    NSInteger length=range.location-location;
    
    PDFSelectedRange *extendRange=[[[PDFSelectedRange alloc] initWithPage:page range:NSMakeRange(location,length)] autorelease];
    NSMutableArray *changes=[[_ranges mutableCopy] autorelease];
    [changes insertObject:extendRange atIndex:0];
    [self _setSelectedRanges:changes];
   }
}

-(NSRect)boundsForPage:(PDFPage *)page {
}

-(void)drawForPage:(PDFPage *)page active:(BOOL)active {
   [self drawForPage:page withBox:kPDFDisplayBoxCropBox active:active];
}

-(void)drawForPage:(PDFPage *)page withBox:(PDFDisplayBox)box active:(BOOL)active {
   if(_color!=nil)
    [_color set];
   else if(active)
    [[NSColor selectedTextBackgroundColor] set];
   else
    [[NSColor secondarySelectedControlColor] set];
   
   NSInteger i,count=[_ranges count];
   
   for(i=0;i<count;i++){
    PDFSelectedRange *selected=[_ranges objectAtIndex:i];
    
    if([selected page]==page){
     NSRange range=[selected range];
     NSRect *rects=malloc(range.length*sizeof(NSRect));
     
     [page _getRects:rects range:range];
     
     NSRectFillList(rects,range.length);
     
     free(rects);
    }
   }
}

@end
