/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSDictionaryController.h>
#import <Foundation/NSString.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSKeyedUnarchiver.h>

@interface NSDictionaryControllerProxy : NSObject
{
   id _key;
   id _dictionary;
   id _controller;
}
@property (copy) id key;
@property (retain) id value;
@property (retain) id dictionary;
@property (assign) id controller;

@end

@implementation NSDictionaryControllerProxy
@synthesize key=_key;

@synthesize dictionary=_dictionary;
@synthesize controller=_controller;

-(id)value {
   return [_dictionary objectForKey:_key];
}

-(void)setValue:(id)newVal {
   [_dictionary setObject:newVal forKey:_key];
}

-(id)description {
   return [NSString stringWithFormat:@"%@ (%@ %p)", [super description], [self key], [self value]];
}

-(void)dealloc {
   [_key release];
   [_dictionary release];
   [super dealloc];
}
@end

@implementation NSDictionaryController
-(id)initWithCoder:(NSCoder*)coder
{
	if((self = [super initWithCoder:coder]))
	{
      _includedKeys=[[coder decodeObjectForKey:@"NSIncludedKeys"] retain];
      _excludedKeys=[[coder decodeObjectForKey:@"NSExcludedKeys"] retain];
      
	}
	return self;
}

-(void)dealloc {
   [_contentDictionary release];
   [_includedKeys release];
   [_excludedKeys release];
   [super dealloc];
}

-(id)contentDictionary {
   return _contentDictionary;
}

-(void)setContentDictionary:(id)dict {
   if(dict!=_contentDictionary) {
      [_contentDictionary release];
      
      if(NSIsControllerMarker(dict)) {
         dict=nil;
      }
      
      _contentDictionary=[dict retain];

      id contentArray=[NSMutableArray array];

      for(id key in [_contentDictionary allKeys]) {
         if(![_excludedKeys containsObject:key]) {
            NSDictionaryControllerProxy* proxy=[NSDictionaryControllerProxy new];
            proxy.key=key;
            proxy.dictionary=_contentDictionary;
            [contentArray addObject:proxy];
            [proxy release];
         }
      }
      
      [self setContent:contentArray];
   }
}
@end
