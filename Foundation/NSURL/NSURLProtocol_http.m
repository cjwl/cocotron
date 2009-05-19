/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSURLProtocol_http.h"
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSHost.h>
#import <string.h>

enum {
 STATE_waitingForStatusCR,
 STATE_waitingForStatusLF,
 STATE_waitingForHeader,
 STATE_waitingForContinuationCR,
 STATE_waitingForContinuationLF,
 STATE_waitingForHeaderColon,
 STATE_waitingForSpaceAfterHeaderColon,
 STATE_waitingForHeaderCR,
 STATE_waitingForHeaderLF,
 STATE_waitingForLastLF,
 STATE_waitingForChunkSize,
 STATE_waitingForChunkSizeLF,
 STATE_waitingForChunkCompletion,
 STATE_waitingForChunkCompletionLF,
 STATE_entity_body,
 STATE_done,
};

@implementation NSURLProtocol_http

-(void)status:(NSString *)status {
   NSLog(@"status=[%@]",status);
}

-(void)headers:(NSDictionary *)headers {
   NSLog(@"headers=%@",headers);
}

-(void)entityChunk:(NSData *)data {
  // NSLog(@"entity chunk %@",[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	[_client URLProtocol:self didLoadData:data];
}

-(void)entity:(NSData *)data {
  // NSLog(@"entity %@",[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	[_client URLProtocol:self didLoadData:data];
	[_client URLProtocolDidFinishLoading:self];
}

-(void)_headerKey {
   [_currentKey autorelease];
   _currentKey=[[NSString alloc] initWithCString:(char*)_bytes+_range.location length:_range.length];
}

-(void)_headerValue {
   NSString *value=[NSString stringWithCString:(char*)_bytes+_range.location length:_range.length-1];
   NSString *oldValue;

   if((oldValue=[_headers objectForKey:_currentKey])!=nil)
    value=[[oldValue stringByAppendingString:@" "] stringByAppendingString:value];

   [_headers setObject:value forKey:_currentKey];
}

-(void)_continuation {
   NSString *value=[NSString stringWithCString:(char*)_bytes+_range.location length:_range.length-1];
   NSString *oldValue=[_headers objectForKey:_currentKey];

   value=[[oldValue stringByAppendingString:@" "] stringByAppendingString:value];

   [_headers setObject:value forKey:_currentKey];
}

-(void)_entity {
   [self entity:[NSData dataWithBytes:_bytes+_range.location length:_range.length]];
}

-(void)_entityChunk {
   [self entityChunk:[NSData dataWithBytes:_bytes+_range.location length:_range.length]];
}

-(BOOL)contentIsChunked {
   return [[_headers objectForKey:@"Transfer-Encoding"] isEqual:@"chunked"];
}

-(unsigned)contentLength {
   return [[_headers objectForKey:@"Content-Length"] intValue];
}

-(BOOL)advanceIsEndOfReply {
   while(NSMaxRange(_range)<_length){
    unsigned char code=_bytes[NSMaxRange(_range)];
    enum  {
     extendLength,
     advanceLocationToNext,
     advanceLocationToCurrent,
    } rangeAction=extendLength;

    switch(_state){

     case STATE_waitingForStatusCR:
       if(code=='\015')
       _state=STATE_waitingForStatusLF;
       break;

     case STATE_waitingForStatusLF:
      if(code!='\012')
       _state=STATE_waitingForStatusCR;
      else {
       [self status:[NSString stringWithCString:(char*)_bytes+_range.location length:_range.length-1]];
       _state=STATE_waitingForHeader;
       rangeAction=advanceLocationToNext;
      }
      break;

     case STATE_waitingForHeader:
      if(code==' ' || code=='\t')
       _state=STATE_waitingForContinuationCR;
      else if(code=='\015')
       _state=STATE_waitingForLastLF;
      else
       _state=STATE_waitingForHeaderColon;
      break;

     case STATE_waitingForContinuationCR:
      if(code=='\015')
       _state=STATE_waitingForContinuationLF;
      break;

     case STATE_waitingForContinuationLF:
      if(code!='\012')
       _state=STATE_waitingForContinuationCR;
      else {
       [self _continuation];
       _state=STATE_waitingForHeader;
       rangeAction=advanceLocationToNext;
      }
      break;

     case STATE_waitingForHeaderColon:
      if(code==':'){
       [self _headerKey];
       _state=STATE_waitingForSpaceAfterHeaderColon;
       rangeAction=advanceLocationToNext;
      }
      break;

     case STATE_waitingForSpaceAfterHeaderColon:
      if(code==' '){
       rangeAction=advanceLocationToNext;
       break;
      }
      _state=STATE_waitingForHeaderCR;
      // fallthru

     case STATE_waitingForHeaderCR:
      if(code=='\015')
       _state=STATE_waitingForHeaderLF;
      break;

     case STATE_waitingForHeaderLF:
      if(code!='\012')
       _state=STATE_waitingForHeaderCR;
      else {
       [self _headerValue];
       _state=STATE_waitingForHeader;
       rangeAction=advanceLocationToNext;
      }
      break;

     case STATE_waitingForLastLF:
      [self headers:_headers];
      if([self contentIsChunked]){
       _state=STATE_waitingForChunkSize;
       _chunkSize=0;
       rangeAction=advanceLocationToNext;
       break;
      }
      else if([self contentLength]==0){
       _state=STATE_done;
       return YES;
      }
      else {
       _state=STATE_entity_body;
       rangeAction=advanceLocationToCurrent;
      }
      break;

     case STATE_waitingForChunkSize:
      if(code>='0' && code<='9')
       _chunkSize=_chunkSize*16+(code-'0');
      else if(code>='a' && code<='f')
       _chunkSize=_chunkSize*16+(code-'a')+10;
      else if(code>='A' && code<='F')
       _chunkSize=_chunkSize*16+(code-'A')+10;
      else if(code=='\015')
       _state=STATE_waitingForChunkSizeLF;
      else{
NSLog(@"parse error %d %o",__LINE__,code);
      }
      break;

     case STATE_waitingForChunkSizeLF:
      if(code=='\012'){
       if(_chunkSize==0){
        _state=STATE_done;
        return YES;
NSLog(@"zero chunk");
       }
       else {
NSLog(@"chunk=%d",_chunkSize);
        _state=STATE_waitingForChunkCompletion;
        rangeAction=advanceLocationToNext;
       }
      }
      else {
NSLog(@"parse error %d",__LINE__);
      }
      break;

     case STATE_waitingForChunkCompletion:
      if(_range.length==_chunkSize){
       _state=STATE_waitingForChunkCompletionLF;
       _chunkSize=0;
       if(code=='\015')
        NSLog(@"got cr");
NSLog(@"chunk done");
       [self _entityChunk];
      }
      break;

     case STATE_waitingForChunkCompletionLF:
       if(code=='\012')
        NSLog(@"got lf");
      _state=STATE_waitingForChunkSize;
      break;

     case STATE_entity_body:
      if(_range.length>=[self contentLength]){
NSLog(@"transfer completed");
       [self _entity];
       _state=STATE_done;
       return YES;
      }
      break;

     case STATE_done:
      return YES;
    }

    switch(rangeAction){
     case extendLength:
      _range.length++;
      break;

     case advanceLocationToNext:
      _range.location=NSMaxRange(_range)+1;
      _range.length=0;
      break;

     case advanceLocationToCurrent:
      _range.location=NSMaxRange(_range);
      _range.length=0;
      break;
    }
   }

   return NO;
}

-(void)appendData:(NSData *)data {
   [_data appendData:data];
   _bytes=[_data bytes];
   _length=[_data length];
   NSLog(@"length=%d",_length);
}

-(void)startLoading {
   NSURL    *url=[_request URL];
   NSString *hostName=[url host];
   NSNumber *portNumber=[url port];
	NSLog(@"startloading");
	sentrequest=NO;
   
   if(portNumber==nil)
    portNumber=[NSNumber numberWithInt:80];
    
   NSHost *host=[NSHost hostWithName:hostName];
   
   [NSStream getStreamsToHost:host port:[portNumber intValue] inputStream:&_inputStream outputStream:&_outputStream];
   [_inputStream setDelegate:self];
   [_outputStream setDelegate:self];
	
   [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
   [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream retain];
	[_outputStream retain];
	[_inputStream open];
	[_outputStream open];
	NSLog(@"input stream %@",_inputStream);

   _data=[NSMutableData new];
   _range=NSMakeRange(0,0);
   _headers=[NSMutableDictionary new];
}

-(void)stopLoading {
   [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
   [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)inputStream:(NSInputStream *)stream handleEvent:(NSStreamEvent)streamEvent 
{
	char buffer[1024];
	NSInteger size=[stream read:(unsigned char*)buffer maxLength:sizeof(buffer)];
	if (size>0)
	{
		[self appendData:[NSData dataWithBytes:buffer length:size]];
		if ([self advanceIsEndOfReply])
		{
			//[_client URLProtocol:self didLoadData: ]
		}
		else
		{
			//[_client URLProtocol:didLoadData:];
			[_client URLProtocolDidFinishLoading:self];
		}
	}
	
		
}

-(void)outputStream:(NSOutputStream *)stream handleEvent:(NSStreamEvent)streamEvent 
{
	if(streamEvent==NSStreamEventHasSpaceAvailable && sentrequest==NO)
	{
		NSURL* url=[_request URL];
		NSString* path=[url relativeString];
		NSString* host=[url host];
		NSMutableString* httprequest=[NSMutableString string];
		[httprequest appendFormat:@"GET %@ HTTP/1.1\r\n",path];
		[httprequest appendFormat:@"Host: %@\r\n",host];
		[httprequest appendString:@"\r\n"];
		NSLog(@"request %@ ",httprequest);
		const char* crequest=[httprequest UTF8String];
		[stream write:(unsigned char*)crequest maxLength:strlen(crequest)];
		sentrequest=YES;
		
	}
	
}

-(void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent {
   if(stream==_inputStream)
    [self inputStream:(NSInputStream *)stream handleEvent:streamEvent];
   else if(stream==_outputStream)
    [self outputStream:(NSOutputStream *)stream handleEvent:streamEvent];
}

+(BOOL)canInitWithRequest:(NSURLRequest *)request {
	if( [[[request URL]scheme] isEqual:@"http"]) return YES;
	return 0;
}
-initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)response client:(id <NSURLProtocolClient>)client {
	_request=[request retain];
	_response=[response retain];
	_client=[(id)client retain];
	return self;
}

@end
