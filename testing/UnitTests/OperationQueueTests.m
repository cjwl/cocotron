//
//  OperationQueueTests.m
//  NSOperationQueueTestCase
//
//  Created by Sven Weidauer on 08.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OperationQueueTests.h"

#ifdef WINDOWS
#include <windows.h>
#define sleep( x ) do { Sleep( 1000 * (x) ); } while (0)
#endif

@interface TestOperation : NSOperation {
	
}

@end

@implementation TestOperation

- (void) main;
{
	sleep( 2 );
}

@end


@implementation OperationQueueTests

- (void) setUp;
{
	[super setUp];
	queue = [[NSOperationQueue alloc] init];
	operation = [[TestOperation alloc] init];
	observationCount = 0;
}

- (void) tearDown;
{
	[operation release], operation = nil;
	[queue release], queue = nil;
	[super tearDown];
}


- (void) testSuspending;
{
	STAssertFalse( [queue isSuspended], @"Queue should not be suspended initially" );
	[queue setSuspended: YES];
	STAssertTrue( [queue isSuspended], @"Queue should be suspended after setSuspended: YES" );
	[queue setSuspended: NO];
	STAssertFalse( [queue isSuspended], @"Queue should not be suspended after setSuspended: NO" );
}

- (void) testMaximumOperationCount;
{
	STAssertEquals( [queue maxConcurrentOperationCount], NSOperationQueueDefaultMaxConcurrentOperationCount, @"Queue should initially have default max conncurrent operation count" );
	int i;
	for (i = 1; i < 32; i++) {
		[queue setMaxConcurrentOperationCount: i];
		STAssertEquals( i, [queue maxConcurrentOperationCount], @"Setting maxConcurrentOperationCount to %d should work", i );
	}
}

- (void) testCancelAll;
{
	[queue addOperation: operation];
	[queue cancelAllOperations];
	STAssertTrue( [operation isCancelled], @"Operation should be cancelled after Queue cancelAllOperations" );
}

- (void) watchRunningOperation;
{
	sleep( 1 );
	STAssertTrue( [operation isExecuting], @"Operation should have been started" );
	sleep( 2 );
	STAssertTrue( [operation isFinished], @"Operation should have been finnished" );
	STAssertFalse( [operation isExecuting], @"Finished operation should not say it is executing" );
	STAssertEquals( (NSUInteger)1, [operation retainCount], @"Operation should have a retain count of 1 after it is done" );	
}

- (void) testRunning;
{
	[queue addOperation: operation];
	[self watchRunningOperation];
}

- (void) testOperationsArray;
{
	NSArray *array = [queue operations];
	STAssertEquals( (NSUInteger)0, [array count], @"Initially there should be 0 operations in the array" );
	[queue addOperation: operation];
	array = [queue operations];
	STAssertEquals( (NSUInteger)1, [array count], @"After adding an operation there should be 1 operation in the array" );
	STAssertEquals( operation, [array objectAtIndex: 0],  @"The object in the array should be my operation object" );
	sleep( 3 );
	array = [queue operations];
	STAssertEquals( (NSUInteger)0, [array count], @"Array should be empty after the operation is finnished" );
}

- (void)testRunningFromArray;
{
	NSArray *array = [[NSArray alloc] initWithObjects: operation, nil];
	[queue addOperations: array waitUntilFinished: NO];
	[array release];
	[self watchRunningOperation];
}

- (void)testRunningFromArrayWaiting;
{
	[queue addOperations: [NSArray arrayWithObject: operation] waitUntilFinished: YES];
	STAssertTrue( [operation isFinished], @"Operation should have been finnished" );
}

- (void) testWaiting;
{
	[queue addOperation: operation];
	[queue waitUntilAllOperationsAreFinished];
	STAssertTrue( [operation isFinished], @"Operation should have been finnished" );
}

static NSString *const MyQueueName = @"MyQueueName";

- (void) testName;
{
	[queue setName: MyQueueName];
	STAssertEqualObjects( MyQueueName, [queue name], @"Queue should return the name that was set" );
}

- (void) testAddingWhileSuspended;
{
	[queue setSuspended: YES];
	[queue addOperation: operation];

	STAssertFalse( [operation isExecuting], @"Operation should not be started while queue is suspended" );
	
	[queue setSuspended: NO];
	[self watchRunningOperation];	
}

- (void) testOperationReady;
{
	STAssertTrue( [operation isReady], @"Operation should be ready" );
}

- (void) testOperationPriority;
{
	STAssertEquals( NSOperationQueuePriorityNormal, [operation queuePriority], @"Standard priority should be NSOperationQueuePriorityNormal" );
}

static NSString * const observationContext = @"observationContext";

static void SleepWithRunloop( NSTimeInterval seconds )
{
	[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: seconds]];
}

- (void) testOperationExecutingKVO;
{
	[operation addObserver: self forKeyPath: @"isExecuting" options: 0 context: observationContext];
	
	[queue addOperation: operation];

	SleepWithRunloop( 1 );
	STAssertEquals( (NSUInteger)1, observationCount, @"Object added to queue, should have received 1 KVO notification" );
	SleepWithRunloop( 2 );
	STAssertEquals( (NSUInteger)2, observationCount, @"Should have received 2 KVO notification after done" );
}

- (void) testOperationFinishedKVO;
{
	[operation addObserver: self forKeyPath: @"isFinished" options: 0 context: observationContext];
	
	[queue addOperation: operation];
	
	SleepWithRunloop( 1 );
	STAssertEquals( (NSUInteger)0, observationCount, @"Should not have received isFinished notification yet" );
	SleepWithRunloop( 2 );
	STAssertEquals( (NSUInteger)1, observationCount, @"Should have received one isFinished notification" );
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context;
{
	if (context == observationContext) {
		++observationCount;
	} else {
		[super observeValueForKeyPath: keyPath ofObject: object change:change context: context];
	}
}

@end
