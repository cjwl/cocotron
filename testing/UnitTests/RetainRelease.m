//
//  RetainRelease.m
//  UnitTests
//
//  Created by Johannes Fortmann on 20.09.08.
//  Copyright 2008 -. All rights reserved.
//

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
