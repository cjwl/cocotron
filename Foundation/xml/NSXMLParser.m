/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSXMLParser.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRaise.h>

@implementation NSXMLParser

-initWithData:(NSData *)data {
   _data=[data retain];
   return self;
}

-initWithContentsofURL:(NSURL *)url {
   NSUnimplementedMethod();
   return self;
}

-(void)dealloc {
   [_data release];
   [super dealloc];
}

-delegate {
   return _delegate;
}

-(BOOL)shouldProcessNamespaces {
   return _shouldProcessNamespaces;
}

-(BOOL)shouldReportNamespacePrefixes {
   return _shouldReportNamespacePrefixes;
}

-(BOOL)shouldResolveExternalEntities {
   return _shouldResolveExternalEntities;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setShouldProcessNamespaces:(BOOL)flag {
   _shouldProcessNamespaces=flag;
}

-(void)setShouldReportNamespacePrefixes:(BOOL)flag {
   _shouldReportNamespacePrefixes=flag;
}

-(void)setShouldResolveExternalEntities:(BOOL)flag {
   _shouldResolveExternalEntities=flag;
}


-(BOOL)parse {
   NSUnimplementedMethod();
   return NO;
}

-(void)abortParsing {
   NSUnimplementedMethod();
}

-(NSError *)parserError {
   return _parserError;
}

-(NSString *)systemID {
   return _systemID;
}

-(NSString *)publicID {
   return _publicID;
}

-(NSInteger)columnNumber {
   return _columnNumber;
}

-(NSInteger)lineNumber {
   return _lineNumber;
}

@end
