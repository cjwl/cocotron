/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSRaise.h>

@implementation NSURLRequest

-initWithURL:(NSURL *)url {
   return [self initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
}

-initWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeout {
   _url=[url copy];
   _cachePolicy=cachePolicy;
   _timeoutInterval=timeout;
   return self;
}

-(void)dealloc {
   [_url release];
   [super dealloc];
}

+requestWithURL:(NSURL *)url {
   return [[[self alloc] initWithURL:url] autorelease];
}

+requestWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeout {
   return [[[self alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:timeout] autorelease];
}

-copyWithZone:(NSZone *)zone {
   NSUnimplementedMethod();
   return nil;
}

-mutableCopyWithZone:(NSZone *)zone {
   NSUnimplementedMethod();
   return nil;
}

-(NSURL *)URL {
   return _url;
}

-(NSURLRequestCachePolicy)cachePolicy {
   return _cachePolicy;
}

-(NSTimeInterval)timeoutInterval {
   return _timeoutInterval;
}

-(NSInputStream *)HTTPBodyStream {
   NSUnimplementedMethod();
   return nil;
}

-(NSDictionary *)allHTTPHeaderFields {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)valueForHTTPHeaderField:(NSString *)field {
   NSUnimplementedMethod();
   return nil;
}

-(NSData *)HTTPBody {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)HTTPMethod {
   NSUnimplementedMethod();
   return nil;
}

-(NSURL *)mainDocumentURL {
   NSUnimplementedMethod();
   return nil;
}

-(BOOL)HTTPShouldHandleCookies {
   NSUnimplementedMethod();
   return NO;
}

@end
