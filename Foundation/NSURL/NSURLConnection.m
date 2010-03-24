/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURLProtocol.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSURL.h>
#import "NSURLConnectionState.h"

@interface NSURLProtocol(private)
+(Class)_URLProtocolClassForRequest:(NSURLRequest *)request;
@end;

@interface NSURLConnection(private) <NSURLProtocolClient>
@end

@implementation NSURLConnection

+(BOOL)canHandleRequest:(NSURLRequest *)request {
   return ([NSURLProtocol _URLProtocolClassForRequest:request]!=nil)?YES:NO;
}

+(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)responsep error:(NSError **)errorp {
	NSLog(@"sendSynchronousRequest");
//	NSURLConnectionState *state=[[[NSURLConnectionState alloc] init] autorelease];
	NSURLConnectionState *state=[[NSURLConnectionState alloc] init];
	NSLog(@"state: %@",state);
   NSURLConnection      *connection=[[self alloc] initWithRequest:request delegate:state];
   NSString *mode=@"NSURLConnectionRequestMode";
   
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    
	NSLog(@"will receive data");
	[state receiveAllDataInMode:mode];
    [connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
	NSLog(@"did receive data");


    [connection cancel];
    [connection release];
    
   if(errorp!=NULL)
    *errorp=[state error];
   if(responsep!=NULL)
    *responsep=[state response];
    
   return [state data];
}

+(NSURLConnection *)connectionWithRequest:(NSURLRequest *)request delegate:delegate {
   return [[[self alloc] initWithRequest:request delegate:delegate] autorelease];
}

-initWithRequest:(NSURLRequest *)request delegate:delegate startImmediately:(BOOL)startLoading {
   _request=[request copy];
   Class cls=[NSURLProtocol _URLProtocolClassForRequest:request];
   _protocol=[[cls alloc] initWithRequest:_request cachedResponse:nil client:self];
   _delegate=delegate;
   _modes=[[NSMutableArray arrayWithObject:NSDefaultRunLoopMode] retain];
   if(startLoading)
    [self start];
   return self;
}

-initWithRequest:(NSURLRequest *)request delegate:delegate {
   return [self initWithRequest:request delegate:delegate startImmediately:YES];
}

-(void)dealloc {
   [_request release];
   [_protocol release];
   _delegate=nil;
   [_modes release];
   [_inputStream release];
   [_outputStream release];
   [super dealloc];
}

-(void)start {
   NSURL    *url=[_request URL];
   NSString *hostName=[url host];
   NSNumber *portNumber=[url port];
//	NSLog(@"startloading");
   
   if(portNumber==nil)
    portNumber=[NSNumber numberWithInt:80];
    
   NSHost *host=[NSHost hostWithName:hostName];
   
   [NSStream getStreamsToHost:host port:[portNumber intValue] inputStream:&_inputStream outputStream:&_outputStream];
   [_inputStream setDelegate:_protocol];
   [_outputStream setDelegate:_protocol];
	
   for(NSString *mode in _modes){
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
   }
    
	[_inputStream retain];
	[_outputStream retain];
	[_inputStream open];
	[_outputStream open];
//	NSLog(@"input stream %@",_inputStream);

	NSLog(@"start -> startLoading");
   [_protocol startLoading];
}

-(void)cancel {
   [_protocol stopLoading];
   
   [_inputStream setDelegate:nil];
   [_outputStream setDelegate:nil];
   for(NSString *mode in _modes){
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:mode];
   }
}

-(void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {
   [_inputStream scheduleInRunLoop:runLoop forMode:mode];
   [_outputStream scheduleInRunLoop:runLoop forMode:mode];
}

-(void)unscheduleFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode {
   [_inputStream removeFromRunLoop:runLoop forMode:mode];
   [_outputStream removeFromRunLoop:runLoop forMode:mode];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol wasRedirectedToRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirect {
   [_delegate connection:self willSendRequest:request redirectResponse:redirect];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  // [_delegate connection:self didReceiveAuthenticationChallenge];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  // [_delegate connection:self didCancelAuthenticationChallenge];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didReceiveResponse:(NSURLResponse *)response cacheStoragePolicy:(NSURLCacheStoragePolicy)policy {
  // [_delegate connection:self ];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol cachedResponseIsValid:(NSCachedURLResponse *)response {
  // [_delegate connection:self];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didLoadData:(NSData *)data {
	NSLog(@"URLProtocol:didLoadData:");
   [_delegate connection:self didReceiveData:data];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didFailWithError:(NSError *)error {
   [_delegate connection:self didFailWithError:error];
}

-(void)URLProtocolDidFinishLoading:(NSURLProtocol *)urlProtocol {
	NSLog(@"URLProtocolDidFinishLoading:");
	if([_delegate respondsToSelector:@selector(connectionDidFinishLoading:)])
		[_delegate performSelector:@selector(connectionDidFinishLoading:) withObject:self];
}


@end
