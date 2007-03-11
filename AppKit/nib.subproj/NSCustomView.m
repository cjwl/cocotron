/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSCustomView.h"
#import <Foundation/NSString.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSCustomView

- (id)initWithCoder:(NSCoder *)coder {
   self = [super initWithCoder:coder];

   if (self && [coder isKindOfClass:[NSNibKeyedUnarchiver class]])
      _className = [[(NSNibKeyedUnarchiver *)coder decodeObjectForKey:@"NSClassName"] retain];
   else 
      [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] does not handle %@",isa,SELNAME(_cmd),[coder class]];

   return self;
}

-(void)dealloc {
   [_className release];
   [super dealloc];
}

- (id)awakeAfterUsingCoder:(NSCoder *)coder {
   if ([_className isEqualToString:@"NSView"])
      return [super awakeAfterUsingCoder:coder];
   else
   {
      id    result = nil;
      Class class  = NSClassFromString(_className);

      if (class == nil)
         NSLog(@"NSCustomView unknown class %@", _className);

      result = [[[class alloc] initWithFrame:_frame] autorelease];
      [result setAutoresizingMask:_autoresizingMask];
      [result setTag:_tag];
      [(NSMutableArray *)[result subviews] addObjectsFromArray:_subviews];
      [[result subviews] makeObjectsPerformSelector:@selector(_setSuperview:) withObject:result];

      return result;
   }
}

@end
