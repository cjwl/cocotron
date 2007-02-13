/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFContentStream.h"
#import "KGPDFPage.h"
#import "KGPDFArray.h"
#import "KGPDFDictionary.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

@implementation KGPDFContentStream

-initWithStreams:(NSArray *)streams resources:(KGPDFDictionary *)resources parent:(KGPDFContentStream *)parent {
   _streams=[streams retain];
   _resources=[resources retain];
   _parent=[parent retain];
   return self;
}

-initWithPage:(KGPDFPage *)page {
   KGPDFDictionary *dictionary=[page dictionary];
   KGPDFDictionary *resources;
   KGPDFObject     *contents;
   NSMutableArray  *streams=[[[NSMutableArray alloc] init] autorelease];
   
   if(![dictionary getDictionaryForKey:"Resources" value:&resources])
    resources=nil;
   if(![dictionary getObjectForKey:"Contents" value:&contents])
    contents=nil;
   else if([contents objectType]==kKGPDFObjectTypeArray){
    KGPDFArray *array=(KGPDFArray *)contents;
    int         i,count=[array count];
    
    for(i=0;i<count;i++)
     [streams addObject:[array objectAtIndex:i]];
   }
   else if([contents objectType]==kKGPDFObjectTypeStream)
    [streams addObject:contents];
   else {
    NSLog(@"contents is not an array or stream, got %@",contents);
   }
   
   return [self initWithStreams:streams resources:resources parent:nil];
}

-initWithStream:(KGPDFStream *)stream resources:(KGPDFDictionary *)resources parent:(KGPDFContentStream *)parent {
   NSArray *array=[NSArray arrayWithObject:stream];
      
   return [self initWithStreams:array resources:resources parent:parent];
}

-(void)dealloc {
   [_streams release];
   [_resources release];
   [_parent release];
   [super dealloc];
}

-(NSArray *)streams {
   return _streams;
}

-(KGPDFObject *)resourceForCategory:(const char *)category name:(const char *)name {
   KGPDFObject     *result;
   KGPDFDictionary *sub;
   
   if([_resources getDictionaryForKey:category value:&sub])
    if([sub getObjectForKey:name value:&result])
     return result;
   
   return [_parent resourceForCategory:category name:name];
}

@end
