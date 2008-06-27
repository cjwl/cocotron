/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSPDFImageRep.h>
#import <AppKit/NSGraphicsContext.h>
#import <ApplicationServices/CGContext.h>
#import <AppKit/KGPDFPage.h>

@implementation NSPDFImageRep

+(NSArray *)imageUnfilteredFileTypes {
   return [NSArray arrayWithObjects:@"pdf",nil];
}

+(NSArray *)imageRepsWithContentsOfFile:(NSString *)path {
   NSMutableArray *result=[NSMutableArray array];
   NSData         *data=[NSData dataWithContentsOfFile:path];
   NSPDFImageRep  *pdf;
   
   if(data==nil)
    return nil;
   if((pdf=[[[self alloc] initWithData:data] autorelease])==nil)
    return nil;
   
   [result addObject:pdf];
   
   return result;
}

-initWithData:(NSData *)data {
   _pdf=[data retain];
   _currentPage=0;
   CGDataProviderRef provider=CGDataProviderCreateWithCFData(_pdf);
   _document=CGPDFDocumentCreateWithProvider(provider);
   CGDataProviderRelease(provider);
   return self;
}

-(void)dealloc {
   [_pdf release];
   CGPDFDocumentRelease(_document);
   [super dealloc];
}

+imageRepWithData:(NSData *)data {
   return [[[self alloc] initWithData:data] autorelease];
}

-(NSData *)PDFRepresentation {
   return _pdf;
}

-(int)pageCount {
   return CGPDFDocumentGetNumberOfPages(_document);
}

-(int)currentPage {
   return _currentPage;
}

-(void)setCurrentPage:(int)page {
   _currentPage=page;
}

-(NSSize)size {
   CGPDFPageRef page=CGPDFDocumentGetPage(_document,_currentPage);
   NSRect     mediaBox;
      
   if(![page getRect:&mediaBox forBox:kCGPDFMediaBox])
    return NSMakeSize(0,0);

   return mediaBox.size;
}

-(BOOL)drawInRect:(NSRect)rect {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];
   CGPDFPageRef page=CGPDFDocumentGetPage(_document,_currentPage);

   if(page==nil)
    return NO;
   
   CGContextSaveGState(context);
   CGContextConcatCTM(context,[page drawingTransformForBox:kCGPDFMediaBox inRect:rect rotate:0 preserveAspectRatio:NO]);
   CGContextDrawPDFPage(context,page);
   CGContextRestoreGState(context);
   return YES;
}

@end
