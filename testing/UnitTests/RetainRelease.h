//
//  RetainRelease.h
//  UnitTests
//
//  Created by Johannes Fortmann on 20.09.08.
//  Copyright 2008 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface RetainRelease : SenTestCase {
   BOOL deallocCalled;
}
-(void)testRetainRelease;
-(void)testAutoreleasePool;
-(void)didCallDealloc;
@end
