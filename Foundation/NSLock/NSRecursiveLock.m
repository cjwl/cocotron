//
//  NSRecursiveLock.m
//  Foundation
//
//  Created by Johannes Fortmann on 05.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSRecursiveLock.h"

@implementation NSRecursiveLock
-(id)init
{
	if(self = [super init])
	{
		_lock=[NSLock new];
	}
	return self;
}

-(void)dealloc
{
	[_lock release];
	[_name release];
	[super dealloc];
}

-(NSString *)name;
{
	return _name;
}

-(void)setName:(NSString *)value;
{
	if(value!=_name)
	{
		[_name release];
		_name=[value retain];
	}
}

-(void)lock
{
	[self lockBeforeDate:[NSDate distantFuture]];
}

-(void)unlock
{
	id currentThread=[NSThread currentThread];
	if(_lockingThread==currentThread)
	{
		_numberOfLocks--;
		if(_numberOfLocks==0)
			[_lock unlock];
	}
	else
		[NSException raise:NSInternalInconsistencyException format:@"tried to unlock lock %@ owned by thread %@ from thread %@", self, _lockingThread, currentThread];
}

-(BOOL)tryLock;
{
	id currentThread=[NSThread currentThread];
	BOOL ret=[_lock tryLock];
	if(ret)
	{
		// got the lock. so it's ours now
		_lockingThread=currentThread;
		_numberOfLocks=1;
		return YES;
	}
	else if(_lockingThread==currentThread)
	{
		// didn't get the lock, but just because our thread already had it
		_numberOfLocks++;
		return YES;
	}
	return NO;
}

-(BOOL)lockBeforeDate:(NSDate *)value;
{
	if([self tryLock])
		return YES;
	// tryLock failed. That means someone else owns the lock. So we wait it out:
	BOOL ret=[_lock lockBeforeDate:value];
	if(ret)
	{
		_lockingThread=[NSThread currentThread];
		_numberOfLocks=1;
	}
	return ret;
}

-(BOOL)isLocked
{
	return _numberOfLocks!=0;
}
@end

