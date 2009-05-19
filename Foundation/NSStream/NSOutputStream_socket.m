/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSOutputStream_socket.h>
#import <Foundation/NSSocket.h>
#import <Foundation/NSSelectInputSource.h>
#import <Foundation/NSSelectSet.h>
#import <Foundation/NSError.h>
#import <Foundation/NSRunLoop.h>

@implementation NSOutputStream_socket

-initWithSocket:(NSSocket *)socket streamStatus:(NSStreamStatus)status {
   _delegate=self;
   _error=nil;
   _status=status;
   _socket=[socket retain];
   _inputSource=nil;
   return self;
}

-(void)dealloc {
   [_error release];
   [_socket release];
   [_inputSource setDelegate:nil];
   [_inputSource release];
   [super dealloc];
}

-(int)fileDescriptor {
   return [_socket fileDescriptor];
}

-delegate {
   return _delegate;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
   if(_delegate==nil)
    _delegate=self;
}

-(void)open {
   if(_status==NSStreamStatusNotOpen){
    _status=NSStreamStatusOpening;
   }
}

-(NSError *)streamError {
   return _error;
}

-(NSStreamStatus)streamStatus {
   return _status;
}

-(void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {
   if(_inputSource==nil){
    _inputSource=[[NSSelectInputSource alloc] initWithSocket:_socket];
    [_inputSource setDelegate:self];
    [_inputSource setSelectEventMask:NSSelectWriteEvent];
   }
   
   [runLoop addInputSource:_inputSource forMode:mode];
}

-(void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {
   if(_inputSource!=nil)
    [runLoop removeInputSource:_inputSource forMode:mode];
}

-(void)close {
   [_socket close];
}

-(BOOL)hasSpaceAvailable {
   if(_status==NSStreamStatusOpen){
    NSSelectSet *selectSet=[[[NSSelectSet alloc] init] autorelease];
    NSSelectSet *outputSet;
    
    [selectSet addObjectForWrite:_socket];
    if([selectSet waitForSelectWithOutputSet:&outputSet beforeDate:[NSDate date]]!=nil)
     return [outputSet containsObjectForWrite:_socket];
   }
   return NO;
}

-(NSInteger)write:(const unsigned char *)buffer maxLength:(NSUInteger)length {
   if(_status!=NSStreamStatusOpen && _status!=NSStreamStatusOpening)
    return -1;

   return [_socket write:buffer maxLength:length];
}

-(void)selectInputSource:(NSSelectInputSource *)inputSource selectEvent:(unsigned)selectEvent {
   NSStreamEvent event;

   switch(_status){
   
    case NSStreamStatusOpening:
     _status=NSStreamStatusOpen;
     event=NSStreamEventOpenCompleted;
     break;
    
    case NSStreamStatusOpen:
     event=NSStreamEventHasSpaceAvailable;
     break;

    case NSStreamStatusAtEnd:
     event=NSStreamEventEndEncountered;
     break;
     
    default:
     event=NSStreamEventNone;
     break;
   }
         
   if(event!=NSStreamEventNone && [_delegate respondsToSelector:@selector(stream:handleEvent:)])
    [_delegate stream:self handleEvent:event];
}
@end
