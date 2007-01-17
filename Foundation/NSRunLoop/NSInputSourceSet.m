/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSInputSourceSet.h>
#import <Foundation/NSInputSource.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSMutableSet.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDate.h>

@implementation NSInputSourceSet

-init {
   _inputSources=[NSMutableSet new];
   return self;
}

-(void)dealloc {
   [_inputSources release];
   [super dealloc];
}

-(BOOL)recognizesInputSource:(NSInputSource *)source {
   return NO;
}

-(void)addInputSource:(NSInputSource *)source {
   [_inputSources addObject:source];
}

-(void)removeInputSource:(NSInputSource *)source {
   [_inputSources removeObject:source];
}

-(void)changingIntoMode:(NSString *)mode {
  // do nothing
}

-(NSDate *)limitDateForMode:(NSString *)mode {
   NSDate        *result=nil;
   NSEnumerator  *state=[_inputSources objectEnumerator];
   NSInputSource *check;

   while((check=[state nextObject])!=nil){
    NSDate *limit=[check limitDateForMode:mode];

    if(limit!=nil){
     if(result==nil)
      result=limit;
     else
      result=[limit earlierDate:result];
    }
   }

   return result;
}

-(BOOL)immediateInputInMode:(NSString *)mode {
   NSEnumerator  *state=[_inputSources objectEnumerator];
   NSInputSource *check;

   while((check=[state nextObject])!=nil){
    if([check processInputImmediately])
     return YES;
   }

   return NO;
}

-(void)waitInBackground {
   NSInvalidAbstractInvocation();
}

-(BOOL)waitForInputInMode:(NSString *)mode beforeDate:(NSDate *)date {
   NSInvalidAbstractInvocation();
   return NO;
}

@end
