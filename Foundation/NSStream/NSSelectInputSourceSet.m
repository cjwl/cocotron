/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSSelectInputSourceSet.h>
#import <Foundation/NSSelectInputSource.h>
#import <Foundation/NSSelectSet.h>
#import <Foundation/NSMutableSet.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSString.h>

@implementation NSSelectInputSourceSet

-init {
   [super init];
   _outputSources=[NSMutableSet new];
   _outputSet=nil;
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectSetOutputNotification:) name:NSSelectSetOutputNotification object:nil];
   return self;
}

-(void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [_outputSources release];
   [_outputSet release];
   [super dealloc];
}

-(BOOL)recognizesInputSource:(NSInputSource *)source {
   return [source isKindOfClass:[NSSelectInputSource class]];
}

-(NSDate *)limitDateForMode:(NSString *)mode {
   if([_inputSources count]>0)
    return [NSDate distantFuture];

   return [super limitDateForMode:mode];
}

-(void)changingIntoMode:(NSString *)mode {
   [_outputSources removeAllObjects];
   [_outputSet autorelease];
   _outputSet=nil;
}

-(BOOL)immediateInputInMode:(NSString *)mode {
   NSArray *sources=[_outputSources allObjects];
   int      i,count=[sources count];

   for(i=0;i<count;i++){   
    NSSelectInputSource *check=[sources objectAtIndex:i];
    
    [_outputSources removeObject:check];
    
    if([_inputSources containsObject:check]){
     NSSocket *socket=[check socket];
     unsigned  event=0;
    
     if([_outputSet containsObjectForRead:socket])
      event|=NSSelectReadEvent;
     if([_outputSet containsObjectForWrite:socket])
      event|=NSSelectWriteEvent;
     if([_outputSet containsObjectForException:socket])
      event|=NSSelectExceptEvent;
     
     if([check processImmediateEvents:event])
      return YES;
    }
   }
   
   [_outputSources removeAllObjects];
   [_outputSet autorelease];
   _outputSet=nil;
   
   return NO;
}

-(NSSelectSet *)inputSelectSet {
   NSSelectSet         *result=[[[NSSelectSet alloc] init] autorelease];
   NSEnumerator        *state=[_inputSources objectEnumerator];
   NSSelectInputSource *check;
   
   while((check=[state nextObject])!=nil){
    NSSocket *socket=[check socket];
    unsigned  mask=[check selectEventMask];
    
    if(mask&NSSelectReadEvent)
     [result addObjectForRead:socket];
    if(mask&NSSelectWriteEvent)
     [result addObjectForWrite:socket];
    if(mask&NSSelectExceptEvent)
     [result addObjectForException:socket];
   }
   
   return result;
}

-(void)selectSetOutputNotification:(NSNotification *)note {
   NSSelectSet *outputSet=[note object];
 
   [_outputSet autorelease];
   _outputSet=[outputSet copy];
}

-(void)waitInBackgroundInMode:(NSString *)mode {
   NSSelectSet *selectSet=[self inputSelectSet];
   
   [_outputSources setSet:_inputSources];
   [_outputSet autorelease];
   _outputSet=nil;
   
   [selectSet waitInBackgroundInMode:mode];
}

-(BOOL)waitForInputInMode:(NSString *)mode beforeDate:(NSDate *)date {
   NSSelectSet *selectSet=[self inputSelectSet];
   NSError     *error;
      
   [_outputSources setSet:_inputSources];
   [_outputSet autorelease];
   _outputSet=nil;
   
   if([selectSet isEmpty]){
    [NSThread sleepUntilDate:date];
    return NO;
   }
   else if((error=[selectSet waitForSelectWithOutputSet:&_outputSet beforeDate:date])!=nil)
    return NO;
   else {
    [_outputSet retain];
   
    return [self immediateInputInMode:mode];
   }
}

@end
