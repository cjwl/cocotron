/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSXMLNode.h>
#import <Foundation/NSXMLDTDNode.h>
#import <Foundation/NSXMLElement.h>
#import <Foundation/NSXMLDocument.h>
#import <Foundation/NSRaise.h>

@implementation NSXMLNode

+document {
   return [[[NSXMLDocument alloc] init] autorelease];
}

+documentWithRootElement:(NSXMLElement *)element {
   return [[[NSXMLDocument alloc] initWithRootElement:element] autorelease];
}


+elementWithName:(NSString *)name {
   return [[[NSXMLElement alloc] initWithName:name] autorelease];
}

+elementWithName:(NSString *)name children:(NSArray *)children attributes:(NSArray *)attributes {
   NSXMLElement *result=[[[NSXMLElement alloc] initWithName:name] autorelease];
   
   [result setChildren:children];
   [result setAttributes:attributes];
   
   return result;
}

+elementWithName:(NSString *)name stringValue:(NSString *)string {
   return [[[NSXMLElement alloc] initWithName:name stringValue:string] autorelease];
}

+attributeWithName:(NSString *)name stringValue:(NSString *)string {
   NSXMLNode *result=[[[self alloc] initWithKind:NSXMLAttributeKind] autorelease];

   [result setName:name];
   [result setStringValue:string];

   return result;
}

+commentWithStringValue:(NSString *)string {
   NSXMLNode *result=[[[self alloc] initWithKind:NSXMLCommentKind] autorelease];

   [result setStringValue:string];

   return result;
}

+textWithStringValue:(NSString *)string {
   NSXMLNode *result=[[[self alloc] initWithKind:NSXMLTextKind] autorelease];

   [result setStringValue:string];

   return result;
}

+processingInstructionWithName:(NSString *)name stringValue:(NSString *)string {
   NSXMLNode *result=[[[self alloc] initWithKind:NSXMLProcessingInstructionKind] autorelease];

   [result setName:name];
   [result setStringValue:string];

   return result;
}

+DTDNodeWithXMLString:(NSString *)string {
   return [[[NSXMLDTDNode alloc] initWithXMLString:string] autorelease];
}

+namespaceWithName:(NSString *)name stringValue:(NSString *)string {
   NSXMLNode *result=[[[self alloc] initWithKind:NSXMLNamespaceKind] autorelease];

   [result setName:name];
   [result setStringValue:string];

   return result;
}

+(NSXMLNode *)predefinedNamespaceForPrefix:(NSString *)prefix {
   NSUnimplementedMethod();
   return nil;
}

+(NSString *)prefixForName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

+(NSString *)localNameForName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}


-initWithKind:(NSXMLNodeKind)kind {
   _parent=nil;
   _index=0;
   _kind=kind;
   _options=NSXMLNodeOptionsNone;
   _name=nil;
   _value=nil;
   return self;
}

-initWithKind:(NSXMLNodeKind)kind options:(unsigned)options {
   _parent=nil;
   _index=0;
   _kind=kind;
   _options=options;
   _name=nil;
   _value=nil;
   return self;
}

-(void)dealloc {
   _parent=nil;
   [_name release];
   [_value release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   NSXMLNode *copy=NSCopyObject(self,0,zone);
   
   copy->_name=[_name copy];
   copy->_value=[_value copy];
   
   return copy;
}

-(unsigned)index {
   return _index;
}

-(NSXMLNodeKind)kind {
   return _kind;
}

-(unsigned)level {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)localName {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)name {
   return _name;
}

-(NSXMLNode *)nextNode {
   NSUnimplementedMethod();
   return nil;
}

-(NSXMLNode *)nextSibling {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)stringValue {
   return _value;
}

-(NSString *)URI {
   NSUnimplementedMethod();
   return nil;
}

-objectValue {
   return _value;
}

-(NSXMLNode *)parent {
   return _parent;
}

-(NSString *)prefix {
   NSUnimplementedMethod();
   return nil;
}

-(NSXMLNode *)previousNode {
   NSUnimplementedMethod();
   return nil;
}

-(NSXMLNode *)previousSibling {
   NSUnimplementedMethod();
   return nil;
}

-(NSXMLDocument *)rootDocument {
   NSUnimplementedMethod();
   return nil;
}

-(unsigned)childCount {
   return 0;
}

-(NSArray *)children {
   return nil;
}

-(NSXMLNode *)childAtIndex:(unsigned)index {
   return nil;
}

-(void)setName:(NSString *)name {
   name=[name copy];
   [_name release];
   _name=name;
}

-(void)setObjectValue:object {
   object=[object retain];
   [_value release];
   _value=object;
}

-(void)setStringValue:(NSString *)string {
   string=[string copy];
   [_value release];
   _value=string;
}

-(void)setStringValue:(NSString *)string resolvingEntities:(BOOL)resolveEntities {
   NSUnimplementedMethod();
}

-(void)detach {
//   [_parent removeChild:self];
   _parent=nil;
}

-(NSArray *)nodesForXPath:(NSString *)xpath error:(NSError **)error {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)objectsForXQuery:(NSString *)xquery constants:(NSDictionary *)constants error:(NSError **)error {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)objectsForXQuery:(NSString *)xquery error:(NSError **)error {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)XMLString {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)XMLStringWithOptions:(unsigned)options {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)XPath {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)canonicalXMLStringPreservingComments:(BOOL)comments {
   NSUnimplementedMethod();
   return nil;
}

@end
