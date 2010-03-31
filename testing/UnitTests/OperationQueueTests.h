//
//  OperationQueueTests.h
//  NSOperationQueueTestCase
//
//  Created by Sven Weidauer on 08.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class TestOperation;

@interface OperationQueueTests : SenTestCase {
	NSOperationQueue *queue;
	TestOperation *operation;
	NSUInteger observationCount;
}

@end
