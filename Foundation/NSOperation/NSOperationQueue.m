/*
Original Author: Michael Ash on 11/9/08
Copyright (c) 2008 Rogue Amoeba Software LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import "NSOperationQueue.h"
#import "NSOperation.h"
#import <Foundation/NSThread.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSDebug.h>

#import "NSAtomicList.h"
#import <Foundation/NSRaise.h>
#include <string.h>

// The @synchronized on the lists heads kind of kill the use of atomic list but we need to protect
// the list walking done in "operations" from the changes done by the worker thread

@implementation NSOperationQueue

static id PopOperation( NSAtomicListRef *listPtr )
{
	return [(id)NSAtomicListPop( listPtr ) autorelease];
}
	
static void ClearList( NSAtomicListRef *listPtr )
{
	for (int i = 0; i < NSOperationQueuePriority_Count; i++) {
		while (PopOperation( &listPtr[i] )) ;	
	}
}


-init {
		workAvailable = [[NSCondition alloc] init];
		suspendedCondition = [[NSCondition alloc] init];
   allWorkDone = [[NSCondition alloc] init];
		isSuspended = NO;
		
		_thread = [[NSThread alloc] initWithTarget: self selector: @selector( _workThread ) object: nil];
		[_thread start];

	return self;
}

-(void) resume {
   [suspendedCondition lock];
	if (isSuspended) {
		isSuspended = NO;
		[suspendedCondition broadcast];
}
	[suspendedCondition unlock];
}

-(void) suspend {
	[suspendedCondition lock];
	isSuspended = YES;
	[suspendedCondition unlock];
}


- (void)stop
{
	[_thread cancel];
	[self resume];
	[workAvailable broadcast];
	}


- (void)dealloc
{
	[self stop];
	
	[_thread release];
	[workAvailable release];
	[suspendedCondition release];
	
	ClearList((NSAtomicListRef *) queues );
	
	[super dealloc];
}

- (void)addOperation: (NSOperation *)op
{
	unsigned priority = 1;
	if ([op queuePriority] < NSOperationQueuePriorityNormal) priority = 2;
	else if ([op queuePriority] > NSOperationQueuePriorityNormal) priority = 0;
	NSAtomicListInsert( (NSAtomicListRef *)(&queues[priority]), [op retain] );
	[workAvailable signal];
}

- (void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait {
	NSUnimplementedMethod();
	}

- (void)cancelAllOperations {
	[[self operations] makeObjectsPerformSelector:@selector(cancel)];
}

- (NSInteger)maxConcurrentOperationCount {
	NSUnimplementedMethod();
	return NSOperationQueueDefaultMaxConcurrentOperationCount;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)count {
// FIXME: implement but dont warn
//	NSUnimplementedMethod();
}

- (NSString *)name {
	return _name;
}

-(void)setName:(NSString *)newName {
	if (_name != newName) {
		[_name release];
		_name = [newName copy];
	}
}

- (NSArray *)operations {
	NSMutableArray *operations = [NSMutableArray arrayWithCapacity:NSOperationQueuePriority_Count];
	@synchronized(self) {
		for (int i = 0; i < NSOperationQueuePriority_Count; i++) {
			if (0 != queues[i]) {
				NSAtomicListAddToArray(queues[i], operations);
			}
		}
	}
	return operations;
}

- (BOOL)isSuspended {
	[suspendedCondition lock];
	BOOL result = isSuspended;
	[suspendedCondition unlock];
	return result;
}

-(void)setSuspended:(BOOL)suspend {
	if (suspend)
     [self suspend];
	else
     [self resume];
}

-(BOOL) hasMoreWork {
	for (int i = 0; i < NSOperationQueuePriority_Count; i++)
     if (0 != queues[i])
      return YES;
     
	return NO;
}

-(void)waitUntilAllOperationsAreFinished {
   BOOL isWorking;

   [workAvailable lock];
   isWorking=[self hasMoreWork];
   [workAvailable unlock];

   if(isWorking){
    [allWorkDone lock];
    [allWorkDone wait];
    [allWorkDone unlock];
   }
}

// pop an operation from the given list and run it
// if the list is empty, steal the source list into the given list and run an operation from it
// if both are empty, do nothing
// returns YES if an operation was executed, NO otherwise
// - (BOOL)_runOperationFromList: (NSAtomicListRef *)listPtr sourceList: (NSAtomicListRef *)sourceListPtr
static BOOL RunOperationFromLists( NSAtomicListRef *listPtr, NSAtomicListRef *sourceListPtr, NSOperationQueue *opqueue )
{
	NSOperation *op = nil;
	@synchronized(opqueue) {
		op = PopOperation( listPtr );
		if( !op ) {
			*listPtr = NSAtomicListSteal( sourceListPtr );
			// source lists are in LIFO order, but we want to execute operations in the order they were enqueued
			// so we reverse the list before we do anything with it
			NSAtomicListReverse( listPtr );
			op = PopOperation( listPtr );
		}	
	}
	if (op) {
		if ([op isReady]) {
			[op start];
		} else {
			@synchronized(opqueue) {
				NSAtomicListInsert( sourceListPtr, [op retain] );
			}
		}
	}
	
	return op != nil;
}

- (void)_workThread
{
	NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	NSAtomicListRef myQueues[NSOperationQueuePriority_Count];
	memset( myQueues, 0, sizeof( myQueues ) );
	
	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	BOOL didRun = NO;
	while( ![thread isCancelled] )
	{
        
		[suspendedCondition lock];
        
		while (isSuspended)
         [suspendedCondition wait];
         
		[suspendedCondition unlock];
		
		if( !didRun ) {
			[workAvailable lock];
            
            if(![self hasMoreWork]){
             [allWorkDone signal];
            }
            
			while (![self hasMoreWork] && ![thread isCancelled])
             [workAvailable wait];

			[workAvailable unlock];
		}
		
		for (int i = 0; i < NSOperationQueuePriority_Count; i++) {
			didRun = RunOperationFromLists( &myQueues[i], ( NSAtomicListRef *)(&queues[i] ), self);
			if (didRun)
              break;
		}
		
		[innerPool release];
		innerPool = [[NSAutoreleasePool alloc] init];
	}
	
	[innerPool release];
	
	// This thread got cancelled, so insert all of its operations back into the main queue.
	// The thread pool could have been reduced and then other threads should do this thread's work.
	@synchronized(self) {
		for (int i = 0; i < NSOperationQueuePriority_Count; i++) {
			id op = 0;
			while ((op = (id)NSAtomicListPop( &myQueues[i] ))) {
				NSAtomicListInsert((NSAtomicListRef *)( &queues[i]), op );
			}
		}
		ClearList( myQueues );
	}
	[outerPool release];
}


@end
