/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintPanel.h>
#import <AppKit/NSView.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/KGContext.h>
#import <AppKit/KGRenderingContext.h>

@implementation NSPrintOperation

static NSPrintOperation *_currentOperation=nil;

+(NSPrintOperation *)currentOperation {
   return _currentOperation;
}

+(NSPrintOperation *)printOperationWithView:(NSView *)view {
   return [[[self alloc] initWithView:view printInfo:[NSPrintInfo sharedPrintInfo]] autorelease];
}

+(NSPrintOperation *)printOperationWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo {
   return [[[self alloc] initWithView:view printInfo:printInfo] autorelease];
}

-initWithView:(NSView *)view printInfo:(NSPrintInfo *)printInfo {
   _view=[view retain];
   _printInfo=[printInfo retain];
   _printPanel=[[NSPrintPanel printPanel] retain];
   _showsPrintPanel=YES;
   _currentPage=0;
   return self;
}

-(void)dealloc {
   [_view release];
   [_printInfo release];
   [_printPanel release];
   [_context release];
   [super dealloc];
}

-(BOOL)isCopyingOperation {
   return NO;
}

-(void)setAccessoryView:(NSView *)view {
   NSUnimplementedMethod();
}

-(NSView *)view {
   return _view;
}

-(NSPrintInfo *)printInfo {
   return _printInfo;
}

-(NSPrintPanel *)printPanel {
   return _printPanel;
}

-(BOOL)showsPrintPanel {
   return _showsPrintPanel;
}

-(void)setShowsPrintPanel:(BOOL)flag {
   _showsPrintPanel=flag;
}

-(int)currentPage {
   return _currentPage;
}

-(NSGraphicsContext *)createContext {
   return nil;
}

-(void)_autopaginatePageRange:(NSRange)pageRange actualPageRange:(NSRange *)rangep context:(KGContext *)context {
   NSRange result=NSMakeRange(1,0);
   NSRect  bounds=[_view bounds];
   NSRect  imageableRect=[_printInfo imageablePageBounds];
   BOOL    isFlipped=[_view isFlipped];
   float   top=isFlipped?NSMinY(bounds):NSMaxY(bounds);
   NSPrintingOrientation orientation=[_printInfo orientation];
   
   while(YES) {
    float heightAdjustLimit=[_view heightAdjustLimit];
    float widthAdjustLimit=[_view widthAdjustLimit];
    float left=NSMinX(bounds);
    float right=left+imageableRect.size.width;
    float rightLimit=left+imageableRect.size.width*widthAdjustLimit;
    float bottom=isFlipped?top+imageableRect.size.height:top-imageableRect.size.height;
    float bottomLimit=isFlipped?top+imageableRect.size.height*heightAdjustLimit:top-imageableRect.size.height*heightAdjustLimit;
    
    if(orientation==NSLandscapeOrientation){
     // FIX
    }
    
    if(isFlipped){
     if(bottom>NSMaxY(bounds))
      bottom=NSMaxY(bounds);
    }
    else {
     if(bottom<NSMinY(bounds))
      bottom=NSMinY(bounds);
    }

    [_view adjustPageWidthNew:&right left:left right:right limit:rightLimit];
    [_view adjustPageHeightNew:&bottom top:top bottom:bottom limit:bottomLimit];
             
    if(context!=nil && (pageRange.location==NSNotFound || NSLocationInRange(NSMaxRange(result),pageRange))){
     NSRect  rect=NSMakeRect(left,top,right-left,bottom-top);
     NSPoint location=[_view locationOfPrintRect:rect];

     [_view beginPageInRect:rect atPlacement:location];
     [_view drawRect:rect];
     [_view endPage];
     _currentPage++;
    }
    
    result.length++;
    
    top=bottom;
    
    if(isFlipped){
     if(top>=NSMaxY(bounds))
      break;
    }
    else {
     if(top<=NSMinY(bounds))
      break;
    }
   }
   
   *rangep=result;
}

-(BOOL)_paginateWithPageRange:(NSRange)pageRange context:(KGContext *)context {
   int i;

   for(i=0,_currentPage=pageRange.location;i<pageRange.length;i++,_currentPage++){
    NSRect  rect=[_view rectForPage:_currentPage];
    NSPoint location=[_view locationOfPrintRect:rect];

    [_view beginPageInRect:rect atPlacement:location];
    [_view drawRect:rect];
    [_view endPage];
   }
}

-(BOOL)runOperation {
   NSRange            pageRange=NSMakeRange(NSNotFound,NSNotFound);
   BOOL               knowsPageRange;
   NSPrintPanel      *printPanel=[self printPanel];
   int                panelResult;
   KGContext         *context;
   NSGraphicsContext *graphicsContext;
      
   _currentOperation=self;
   
   knowsPageRange=[_view knowsPageRange:&pageRange];

   if(knowsPageRange){
    [[_printInfo dictionary] setObject:[NSNumber numberWithInt:pageRange.location] forKey:NSPrintFirstPage];
    [[_printInfo dictionary] setObject:[NSNumber numberWithInt:NSMaxRange(pageRange)-1] forKey:NSPrintLastPage];
   }
   else {
    [[_printInfo dictionary] setObject:[NSNumber numberWithInt:1] forKey:NSPrintFirstPage];
    [[_printInfo dictionary] setObject:[NSNumber numberWithInt:1] forKey:NSPrintLastPage];
   }
   
   if(_showsPrintPanel){
    [[_printInfo dictionary] setObject:_view forKey:@"_NSView"];
    panelResult=[printPanel runModal];
    [[_printInfo dictionary] removeObjectForKey:@"_NSView"];
   
    if(panelResult!=NSOKButton)
     return NO;
   }
   else {
    NSLog(@"Printing not implemented without print panel yet");
     return NO;
   }
   
   if((context=[[_printInfo dictionary] objectForKey:@"_KGContext"])==nil)
    return NO;

   [_printInfo setUpPrintOperationDefaultValues];

   graphicsContext=[NSGraphicsContext graphicsContextWithPrintingContext:context];

   [NSGraphicsContext saveGraphicsState];
   [NSGraphicsContext setCurrentContext:graphicsContext];
   [[context renderingContext] beginPrintingWithDocumentName:[[_view window] title]];
   [_view beginDocument];
   
   if(knowsPageRange)
    [self _paginateWithPageRange:pageRange context:context];
   else
    [self _autopaginatePageRange:pageRange actualPageRange:&pageRange context:context];
     
   [_view endDocument];
   [[context renderingContext] endPrinting];
   [NSGraphicsContext restoreGraphicsState];
   
   [[_printInfo dictionary] removeObjectForKey:@"_KGContext"];
   
   _currentOperation=nil;

   return YES;
}

@end
