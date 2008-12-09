/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "RetainRelease.h"

@interface RetainReleaseTestHelperObject : NSObject
{
@public
   RetainRelease* delegate;
}
@end


@implementation RetainReleaseTestHelperObject
-(void)dealloc
{
   [delegate didCallDealloc];
   [super dealloc];
}
@end

@implementation RetainRelease
-(void)testRetainRelease;
{
   deallocCalled=NO;
   RetainReleaseTestHelperObject *helper=[RetainReleaseTestHelperObject new];
   
   helper->delegate=self;

   [helper release];   
   
   STAssertTrue(deallocCalled, nil);
}

-(void)didCallDealloc
{
   deallocCalled=YES;
}

-(void)testAutoreleasePool;
{
   deallocCalled=NO;
   RetainReleaseTestHelperObject *helper=[RetainReleaseTestHelperObject new];
   
   helper->delegate=self;

   id pool=[NSAutoreleasePool new];
   [helper autorelease];   
   
   STAssertFalse(deallocCalled, nil);
   [pool drain];
   STAssertTrue(deallocCalled, nil);

}
@end
