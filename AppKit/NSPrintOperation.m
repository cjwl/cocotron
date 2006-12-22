/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSGraphicsContext.h>

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
   _currentPage=0;
   return self;
}

-(void)dealloc {
   [_view release];
   [_printInfo release];
   [_context release];
   [super dealloc];
}

-(BOOL)isCopyingOperation {
   return NO;
}

-(NSRect)nextPageRectAfterPageRect:(NSRect)lastRect {
   return lastRect;
}

-(BOOL)_viewKnowsPageRange:(NSRange *)range {
   if([_view knowsPageRange:range])
    return YES;

   *range=NSMakeRange(1,1000);
   return NO;
}

-(BOOL)runOperation {
   NSRange            pageRange;
   BOOL               knowsPageRange=[self _viewKnowsPageRange:&pageRange];
   CGContext *graphicsPort=[[NSDisplay currentDisplay] graphicsPortForPrintOperationWithView:_view printInfo:_printInfo pageRange:pageRange];
   NSGraphicsContext *context;

   if(graphicsPort==nil)
    return NO;

   context=[NSGraphicsContext graphicsContextWithPrintingContext:graphicsPort];

   _currentOperation=self;
   [NSGraphicsContext saveGraphicsState];
   [NSGraphicsContext setCurrentContext:context];
   [_view beginDocument];

   if(knowsPageRange){
    int i;

    for(i=0,_currentPage=pageRange.location;i<pageRange.length;i++,_currentPage++){
     NSRect  rect=[_view rectForPage:_currentPage];
     NSPoint location=[_view locationOfPrintRect:rect];

//NSLog(@"rect=%f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
//NSLog(@"location=%f %f",location.x,location.y);

     [_view beginPageInRect:rect atPlacement:location];

     [_view drawRect:rect];

     [_view endPage];
    }
   }
   else {
    NSRect lastRect=NSZeroRect;

    for(_currentPage=0;;_currentPage++){
     NSRect  rect=[self nextPageRectAfterPageRect:lastRect];
     NSPoint location=[_view locationOfPrintRect:rect];

     [_view beginPageInRect:rect atPlacement:location];
     [_view endPage];
    }
   }
 
   [_view endDocument];
   [NSGraphicsContext restoreGraphicsState];
   _currentOperation=nil;

   return YES;
}

-(void)setAccessoryView:(NSView *)view {
   NSUnimplementedMethod();
}

-(NSPrintInfo *)printInfo {
   return _printInfo;
}

-(NSView *)view {
   return _view;
}

-(int)currentPage {
   return _currentPage;
}

-(NSGraphicsContext *)createContext {
 //  _context=[[NSGraphicsContext graphicsContextWithPrinterName:@"HP DeskJet 970Cse"] retain];

   return nil;//_context;
}

@end
