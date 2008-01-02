/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSObject.h>

@class NSRunLoop,NSNetService,NSDictionary;

@interface NSNetServiceBrowser : NSObject {
}

-init;

-delegate;
-(void)setDelegate:delegate;

-(void)removeFromRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
-(void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;

-(void)searchForBrowsableDomains;
-(void)searchForRegistrationDomains;
-(void)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;

-(void)stop;

@end

@interface NSObject(NSNetServiceBrowserDelegate)
-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser;
-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domain moreComing:(BOOL)moreComing;
-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing;
-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)dictionary;
-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser;

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreComing;
-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing;
@end
