/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSXMLElement.h>
#import <Foundation/NSXMLNode.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>

@implementation NSXMLElement

-initWithName:(NSString *)name {
   return 0;
}

-initWithName:(NSString *)name stringValue:(NSString *)string {
   return 0;
}

-initWithName:(NSString *)name URI:(NSString *)uri {
   return 0;
}

-initWithXMLString:(NSString *)xml error:(NSError **)error {
   return 0;
}

-copyWithZone:(NSZone *)zone {
   return 0;
}

-(NSArray *)attributes {
   return [_attributes allValues];
}

-(NSXMLNode *)attributeForLocalName:(NSString *)name URI:(NSString *)uri {
   return 0;
}

-(NSXMLNode *)attributeForName:(NSString *)name {
   return [_attributes objectForKey:name];
}

-(NSArray *)elementsForLocalName:(NSString *)localName URI:(NSString *)uri {
   return 0;
}

-(NSArray *)elementsForName:(NSString *)name {
   return 0;
}

-(NSArray *)namespaces {
   return 0;
}

-(NSXMLNode *)namespaceForPrefix:(NSString *)prefix {
   return 0;
}

-(void)setAttributes:(NSArray *)attributes {
   NSInteger i,count=[attributes count];
   
   for(i=0;i<count;i++){
    NSXMLNode *add=[attributes objectAtIndex:i];
    
    [_attributes setObject:add forKey:[add name]];
   }
}

-(void)setAttributesAsDictionary:(NSDictionary *)attributes {
   NSEnumerator *state=[attributes keyEnumerator];
   NSString     *name;
   
   while((name=[state nextObject])!=nil){
    NSString  *value=[attributes objectForKey:name];
    NSXMLNode *node=[NSXMLNode attributeWithName:name stringValue:value];
    
    [_attributes setObject:node forKey:name];
   }
}

-(void)setChildren:(NSArray *)children {
   [_children setArray:children];
}

-(void)setNamespaces:(NSArray *)namespaces {
   [_namespaces removeAllObjects];
}

-(void)addChild:(NSXMLNode *)node {
   [_children addObject:node];
}

-(void)insertChild:(NSXMLNode *)child atIndex:(NSUInteger)index {
   [_children insertObject:child atIndex:index];
}

-(void)insertChildren:(NSArray *)children atIndex:(NSUInteger)index {
   NSInteger i,count=[children count];
   
   for(i=0;i<count;i++)
    [_children insertObject:[children objectAtIndex:i] atIndex:index+i];
}

-(void)removeChildAtIndex:(NSUInteger)index {
   [_children removeObjectAtIndex:index];
}

-(void)replaceChildAtIndex:(NSUInteger)index withNode:(NSXMLNode *)node {
   [_children replaceObjectAtIndex:index withObject:node];
}

-(void)addAttribute:(NSXMLNode *)attribute {
   [_attributes setObject:attribute forKey:[attribute name]];
}

-(void)removeAttributeForName:(NSString *)name {
   [_attributes removeObjectForKey:name];
}

-(void)addNamespace:(NSXMLNode *)namespace {
   [_namespaces setObject:namespace forKey:[namespace prefix]];
}

-(void)removeNamespaceForPrefix:(NSString *)prefix {
   [_namespaces removeObjectForKey:prefix];
}

-(void)resolveNamespaceForName:(NSString *)name {
}

-(void)resolvePrefixForNamespaceURI:(NSString *)uri {
}

-(void)normalizeAdjacentTextNodesPreservingCDATA:(BOOL)preserve {
}

@end
