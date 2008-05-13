//
//  Runloop.m
//  UnitTests
//
//  Created by Johannes Fortmann on 07.05.08.
//  Copyright 2008 -. All rights reserved.
//

#import "Runloop.h"

#define NUM_ITERATIONS 1000

@interface WorkerThread : NSThread
@end

@implementation WorkerThread
-(void)main
{
	id pool=[NSAutoreleasePool new];
	NSRunLoop *runLoop=[NSRunLoop currentRunLoop];
	while(![self isCancelled])
	{
		id pool2=[NSAutoreleasePool new];
		[runLoop runUntilDate:[NSDate date]];
		[pool2 drain];
	}
	[pool drain];
}
@end

@implementation Runloop
-(void)setUp
{
	workerThread=[WorkerThread new];
	[workerThread start];
	jobs=[NSMutableArray new];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
}

-(void)tearDown
{
	[workerThread cancel];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	[workerThread release];
	[jobs release];
	jobs=nil;
}

-(void)doJobOnThread:(id)job
{
	@synchronized(jobs)
	{
		[jobs removeObject:job];
	}
	if([NSThread currentThread]!=workerThread)
		wrongThread=YES;
}

-(void)doNothing
{
	
}

-(void)testPerformOnThread
{
	for(int i=0; i<NUM_ITERATIONS; i++)
	{
		@synchronized(jobs)
		{
			[jobs addObject:[NSNumber numberWithInt:i]];
		}
		[self performSelector:@selector(doJobOnThread:) onThread:workerThread withObject:[NSNumber numberWithInt:i] waitUntilDone:NO];
	}
	
	[self performSelector:@selector(doNothing) onThread:workerThread withObject:nil waitUntilDone:YES];

	STAssertEquals(wrongThread, NO, nil);
	@synchronized(jobs)
	{
		STAssertTrue([jobs count] == 0, nil);
	}
}

-(void)testPerformOnThreadWait
{
	for(int i=0; i<NUM_ITERATIONS; i++)
	{
		@synchronized(jobs)
		{
			[jobs addObject:[NSNumber numberWithInt:i]];
		}
		[self performSelector:@selector(doJobOnThread:) onThread:workerThread withObject:[NSNumber numberWithInt:i] waitUntilDone:YES];
		STAssertTrue([jobs count] == 0, nil);
	}
	
	[self performSelector:@selector(doNothing) onThread:workerThread withObject:nil waitUntilDone:YES];
	STAssertEquals(wrongThread, NO, nil);
	STAssertTrue([jobs count] == 0, nil);
}

@end
