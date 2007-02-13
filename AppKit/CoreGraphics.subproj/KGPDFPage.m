/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFPage.h"
#import "KGPDFContentStream.h"
#import "KGPDFOperatorTable.h"
#import "KGPDFScanner.h"
#import "KGPDFDocument.h"
#import "KGPDFDictionary.h"

@implementation KGPDFPage

-initWithDocument:(KGPDFDocument *)document pageNumber:(int)pageNumber dictionary:(KGPDFDictionary *)dictionary {
   _document=[document retain];
   _pageNumber=pageNumber;
   _dictionary=[dictionary retain];
   return self;
}

-(void)dealloc {
   [_document release];
   [_dictionary release];
   [super dealloc];
}

+(KGPDFPage *)pdfPageWithDocument:(KGPDFDocument *)document pageNumber:(int)pageNumber dictionary:(KGPDFDictionary *)dictionary {
   return [[[self alloc] initWithDocument:document pageNumber:pageNumber dictionary:dictionary] autorelease];
}

-(KGPDFDocument *)document {
   return _document;
}

-(int)pageNumber {
   return _pageNumber;
}

-(KGPDFDictionary *)dictionary {
   return _dictionary;
}

-(void)drawInContext:(KGContext *)context {
   KGPDFContentStream *contentStream=[[[KGPDFContentStream alloc] initWithPage:self] autorelease];
   KGPDFOperatorTable *operatorTable=[KGPDFOperatorTable renderingOperatorTable];
   KGPDFScanner       *scanner=[[[KGPDFScanner alloc] initWithContentStream:contentStream operatorTable:operatorTable info:context] autorelease];
   
   [scanner scan];
}

@end
