/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSXMLDocument.h>
#import <Foundation/NSXMLElement.h>
#import <Foundation/NSXMLDTD.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRaise.h>

@implementation NSXMLDocument

+(Class)replacementClassForClass:(Class)class {
   return class;
}

-initWithRootElement:(NSXMLElement *)element {
   NSUnimplementedMethod();
   return nil;
}

-initWithXMLString:(NSString *)string options:(unsigned)options error:(NSError **)error {
   NSUnimplementedMethod();
   return nil;
}

-initWithData:(NSData *)data options:(unsigned)options error:(NSError **)error {
   NSUnimplementedMethod();
   return nil;
}

-initWithContentsOfURL:(NSURL *)url options:(unsigned)options error:(NSError **)error {
   NSUnimplementedMethod();
   return nil;
}

-(NSXMLDocumentContentKind)documentContentKind {
   return _contentKind;
}

-(NSString *)version {
   return _version;
}

-(NSString *)characterEncoding {
   return _characterEncoding;
}

-(NSString *)MIMEType {
   return _mimeType;
}

-(BOOL)isStandalone {
   return _isStandalone;
}

-(NSXMLElement *)rootElement {
   return _rootElement;
}

-(NSXMLDTD *)DTD {
   return _dtd;
}

-(NSString *)URI {
   return _uri;
}

-(void)setDocumentContentKind:(NSXMLDocumentContentKind)kind {
   _contentKind=kind;
}

-(void)setCharacterEncoding:(NSString *)encoding {
   encoding=[encoding copy];
   [_characterEncoding release];
   _characterEncoding=encoding;
}

-(void)setVersion:(NSString *)version {
   version=[version copy];
   [_version release];
   _version=version;
}

-(void)setMIMEType:(NSString *)mimeType {
   mimeType=[mimeType copy];
   [_mimeType release];
   _mimeType=mimeType;
}

-(void)setStandalone:(BOOL)flag {
   _isStandalone=flag;
}

-(void)setRootElement:(NSXMLNode *)element {
   element=[element retain];
   [_rootElement release];
   _rootElement=(NSXMLElement *)element;
}

-(void)setDTD:(NSXMLDTD *)dtd {
   dtd=[dtd retain];
   [_dtd release];
   _dtd=dtd;
}

-(void)setURI:(NSString *)uri {
   uri=[uri copy];
   [_uri release];
   _uri=uri;
}

-(void)setChildren:(NSArray *)children {
   [_children setArray:children];
}

-(void)addChild:(NSXMLNode *)node {
   [_children addObject:node];
}

-(void)insertChild:(NSXMLNode *)child atIndex:(unsigned)index {
   [_children insertObject:child atIndex:index];
}

-(void)insertChildren:(NSArray *)children atIndex:(unsigned)index {
   int i,count=[children count];
   
   for(i=0;i<count;i++)
    [_children insertObject:[children objectAtIndex:i] atIndex:index+i];
}

-(void)removeChildAtIndex:(unsigned)index {
   [_children removeObjectAtIndex:index];
}

-(void)replaceChildAtIndex:(unsigned)index withNode:(NSXMLNode *)node {
   [_children replaceObjectAtIndex:index withObject:node];
}

-(BOOL)validateAndReturnError:(NSError **)error {
   NSUnimplementedMethod();
   return NO;
}

-(NSData *)XMLData {
   return [self XMLDataWithOptions:NSXMLNodeOptionsNone];
}

-(NSData *)XMLDataWithOptions:(unsigned)options {
   NSUnimplementedMethod();
   return nil;
}

-objectByApplyingXSLT:(NSData *)xslt arguments:(NSDictionary *)arguments error:(NSError *)error {
   NSUnimplementedMethod();
   return nil;
}
-objectByApplyingXSLTAtURL:(NSURL *)url arguments:(NSDictionary *)arguments error:(NSError *)error {
   NSUnimplementedMethod();
   return nil;
}
-objectByApplyingXSLTString:(NSString *)string arguments:(NSDictionary *)arguments error:(NSError *)error {
   NSUnimplementedMethod();
   return nil;
}

@end
