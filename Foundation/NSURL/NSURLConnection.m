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
#import "NSURLConnectionState.h"

@interface NSURLProtocol(private)
+(NSArray *)_registeredClasses;
@end;

@interface NSURLConnection(private) <NSURLProtocolClient>
@end

@implementation NSURLConnection

+(Class)_URLProtocolClassForRequest:(NSURLRequest *)request {
   NSArray *classes=[NSURLProtocol _registeredClasses];
   int      count=[classes count];
   
   while(--count>=0){
    Class check=[classes objectAtIndex:count];
    
    if([check canInitWithRequest:request])
     return check;
   }
   return nil;
}

+(BOOL)canHandleRequest:(NSURLRequest *)request {
   return ([self _URLProtocolClassForRequest:request]!=nil)?YES:NO;
}

+(NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)responsep error:(NSError **)errorp {
   NSURLConnectionState *state=[[[NSURLConnectionState alloc] init] autorelease];
   NSURLConnection      *connection=[[NSURLConnection alloc] initWithRequest:request delegate:state];
   
   
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
   Class cls=[isa _URLProtocolClassForRequest:request];
   _protocol=[[cls alloc] initWithRequest:_request cachedResponse:nil client:self];
   _delegate=delegate;
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
   [super dealloc];
}

-(void)start {
   [_protocol startLoading];
}

-(void)cancel {
   [_protocol stopLoading];
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
  // [_delegate connection:self ];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didLoadData:(NSData *)data {
   [_delegate connection:self didReceiveData:data];
}

-(void)URLProtocol:(NSURLProtocol *)urlProtocol didFailWithError:(NSError *)error {
   [_delegate connection:self didFailWithError:error];
}

-(void)URLProtocolDidFinishLoading:(NSURLProtocol *)urlProtocol {
	if([_delegate respondsToSelector:@selector(connectionDidFinishLoading:)])
		[_delegate performSelector:@selector(connectionDidFinishLoading:) withObject:self];
}


@end
