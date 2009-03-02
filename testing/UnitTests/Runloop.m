/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "Runloop.h"

#define NUM_ITERATIONS 1000

@interface WorkerThread : NSThread
{
   int _loopCount;
   NSConditionLock *_condition;
}

@end

@implementation WorkerThread
-(id)init {
   if(self=[super init]) {
      _condition = [[NSConditionLock alloc] initWithCondition:0];
   }
   return self;
}

-(void)dealloc {
   [_condition release];
   [super dealloc];
}

-(void)main
{
	id pool=[NSAutoreleasePool new];
	NSRunLoop *runLoop=[NSRunLoop currentRunLoop];
   [_condition lockWhenCondition:0];
   [_condition unlockWithCondition:1];
	while(![self isCancelled])
	{
		id pool2=[NSAutoreleasePool new];
		[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
      __sync_add_and_fetch(&_loopCount, 1);
		[pool2 drain];
	}
	[pool drain];
   [_condition lockWhenCondition:1];
   [_condition unlockWithCondition:0];
}

-(void)waitUntilRunning {
   [_condition lockWhenCondition:1];
   [_condition unlock];
}

-(void)waitUntilStopped {
   [_condition lockWhenCondition:0];
   [_condition unlock];
}


-(int)loopCount {
   return _loopCount;
}
@end

@implementation Runloop
-(void)setUp
{
	_workerThread=[WorkerThread new];
	[_workerThread start];
	_jobs=[NSMutableArray new];
	[_workerThread waitUntilRunning];
}

-(void)tearDown
{
	[_workerThread cancel];
   [self performSelector:@selector(self) onThread:_workerThread withObject:nil waitUntilDone:NO];
	[_workerThread waitUntilStopped];
	[_workerThread release];
	[_jobs release];
	_jobs=nil;
}

-(void)doJobOnThread:(id)job
{
	@synchronized(_jobs)
	{
		[_jobs removeObject:job];
	}
	if([NSThread currentThread]!=_workerThread)
		_wrongThread=YES;
}

-(void)doNothing
{
	
}

-(void)testPerformOnThread
{
   STAssertEquals([_workerThread loopCount], 0, nil);
	for(int i=0; i<NUM_ITERATIONS; i++)
	{
		@synchronized(_jobs)
		{
			[_jobs addObject:[NSNumber numberWithInt:i]];
		}
		[self performSelector:@selector(doJobOnThread:) onThread:_workerThread withObject:[NSNumber numberWithInt:i] waitUntilDone:NO];
	}
	
	[self performSelector:@selector(doNothing) onThread:_workerThread withObject:nil waitUntilDone:YES];
   
	STAssertEquals(_wrongThread, NO, nil);
	@synchronized(_jobs)
	{
		STAssertTrue([_jobs count] == 0, nil);
	}
}

-(void)testPerformOnThreadWait
{
	for(int i=0; i<NUM_ITERATIONS; i++)
	{
		@synchronized(_jobs)
		{
			[_jobs addObject:[NSNumber numberWithInt:i]];
		}
		[self performSelector:@selector(doJobOnThread:) onThread:_workerThread withObject:[NSNumber numberWithInt:i] waitUntilDone:YES];
		STAssertTrue([_jobs count] == 0, nil);
	}
	
	[self performSelector:@selector(doNothing) onThread:_workerThread withObject:nil waitUntilDone:YES];
	STAssertEquals(_wrongThread, NO, nil);
	STAssertTrue([_jobs count] == 0, nil);
}

-(void)testRunloopSpinning {
   int countBeforeWait=[_workerThread loopCount];
   
   [self performSelector:@selector(self) onThread:_workerThread withObject:nil waitUntilDone:YES];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
   STAssertEqualsWithAccuracy([_workerThread loopCount], countBeforeWait, 5, nil);   
}

@end
