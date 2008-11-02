/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

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
		[runLoop run];
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
