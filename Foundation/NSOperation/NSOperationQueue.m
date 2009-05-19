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

#import "NSAtomicList.h"
#import "NSLatchTrigger.h"


@interface NSOperationQueueImpl : NSObject
{
	NSThread*		_thread;
	
	NSLatchTrigger*	_trigger;
	
	// NOTE: operations in lists are explicitly retained, must be released when popping
	NSAtomicListRef	_operationList;
	NSAtomicListRef	_highPriorityOperationList;
}

- (void)addOperation: (NSOperation *)op;
- (void)addHighPriorityOperation: (NSOperation *)op;
- (void)stop;

@end

@implementation NSOperationQueueImpl

- (id)init
{
	if( (self = [super init]) )
	{
		_trigger = [[NSLatchTrigger alloc] init];
		
		_thread = [[NSThread alloc] initWithTarget: self selector: @selector( _workThread ) object: nil];
		[_thread start];
	}
	return self;
}

- (NSOperation *)_popOperation: (NSAtomicListRef *)listPtr
{
	return [(id)NSAtomicListPop( listPtr ) autorelease];
}

- (void)dealloc
{
	[_thread release];
	[_trigger release];
	
	while( [self _popOperation: &_operationList] )
		;
	while( [self _popOperation: &_highPriorityOperationList] )
		;
	
	[super dealloc];
}

- (void)_addOperation: (NSOperation *)op toList: (NSAtomicListRef *)listPtr
{
	NSAtomicListInsert( listPtr, [op retain] );
	[_trigger signal];
}

- (void)addOperation: (NSOperation *)op
{
	[self _addOperation: op toList: &_operationList];
}

- (void)addHighPriorityOperation: (NSOperation *)op
{
	[self _addOperation: op toList: &_highPriorityOperationList];
}

- (void)stop
{
	[_thread cancel];
	[_trigger signal];
}

#pragma mark -

// pop an operation from the given list and run it
// if the list is empty, steal the source list into the given list and run an operation from it
// if both are empty, do nothing
// returns YES if an operation was executed, NO otherwise
- (BOOL)_runOperationFromList: (NSAtomicListRef *)listPtr sourceList: (NSAtomicListRef *)sourceListPtr
{
	NSOperation *op = [self _popOperation: listPtr];
	if( !op )
	{
		*listPtr = NSAtomicListSteal( sourceListPtr );
		// source lists are in LIFO order, but we want to execute operations in the order they were enqueued
		// so we reverse the list before we do anything with it
		NSAtomicListReverse( listPtr );
		op = [self _popOperation: listPtr];
	}
	
	if( op )
		[op run];
	
	return op != nil;
}

- (void)_workThread
{
	NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	NSAtomicListRef operations = NULL;
	NSAtomicListRef highPriorityOperations = NULL;
	
	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	BOOL didRun = NO;
	while( ![thread isCancelled] )
	{
		if( !didRun )
			[_trigger wait];
		
		// first attempt to run a high-priority operation
		didRun = [self _runOperationFromList: &highPriorityOperations
									   sourceList: &_highPriorityOperationList];
		// if no high priority operation could be run, then attempt to run a low-priority operation
		if( !didRun )
			didRun = [self _runOperationFromList: &operations
									  sourceList: &_operationList];
		
		[innerPool release];
		innerPool = [[NSAutoreleasePool alloc] init];
		
	}
	
	[innerPool release];
	
	while( [self _popOperation: &operations] )
		;
	while( [self _popOperation: &highPriorityOperations] )
		;
	
	[outerPool release];
}

@end


@implementation NSOperationQueue

- (id)init
{
	if( (self = [super init]) )
	{
		_impl = [[NSOperationQueueImpl alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_impl stop];
	[_impl release];
	
	[super dealloc];
}

- (void)addOperation: (NSOperation *)op
{
	[_impl addOperation: op];
}

- (void)addHighPriorityOperation: (NSOperation *)op
{
	[_impl addHighPriorityOperation: op];
}

@end
