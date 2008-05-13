//
//  Runloop.h
//  UnitTests
//
//  Created by Johannes Fortmann on 07.05.08.
//  Copyright 2008 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface Runloop : SenTestCase {
	NSThread *workerThread;
	NSMutableArray *jobs;
	BOOL wrongThread;
}

@end
