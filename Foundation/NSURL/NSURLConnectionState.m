/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSURLConnectionState.h"
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURLAuthenticationChallenge.h>
#import <Foundation/NSError.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

@implementation NSURLConnectionState

-init {
   _isRunning=YES;
   _response=nil;
   _error=nil;
   _data=[[NSMutableData alloc] init];
   return self;
}

-(void)dealloc {
   [_response release];
   [_error release];
   [_data release];
   [super dealloc];
}

-(BOOL)isRunning {
   return _isRunning;
}

-(void)receiveAllData
{
	while (  [self isRunning] ) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//		NSLog(@"loop did run");
	}
	NSLog(@"done %d",_isRunning);
	
}

-(NSURLResponse *)response {
   return _response;
}

-(NSError *)error {
   return _error;
}

-(NSMutableData *)data {
   return _data;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"connection didFailWithError: %@",error);
	_isRunning=NO;
	_error=[error retain];
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

-(void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"connection didReceiveData: %d",[data length]);
	[_data appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"connection didReceiveResponse: %@",response);
}

-(void)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)response {
}

-(void)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"connection connectionDidFinishLoading");

	_isRunning=NO;
}

@end
