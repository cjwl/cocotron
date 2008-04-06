//
//  NSSynchronization.m
//  Foundation
//
//  Created by Johannes Fortmann on 05.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSRecursiveLock.h>
#import <Foundation/NSValue.h>

// TODO: These are all horribly expensive. The Apple implementation uses a per-thread 
// list of already acquired locks, a cache of unused preallocated locks and a hash table
// for this. They also use pthreads directly. Maybe making this platform-specific
// is the way to go?

static NSMutableDictionary *synchronizationLocks=nil;
static NSLock *syncLocksLock=nil;

void _NSInitializeSynchronizedDirective()
{
	return;
	if(!synchronizationLocks)
	{
		synchronizationLocks=[NSMutableDictionary new];
		syncLocksLock=[NSLock new];
	}
}

enum {
	OBJC_SYNC_SUCCESS                 = 0,
	OBJC_SYNC_NOT_OWNING_THREAD_ERROR = -1,
	OBJC_SYNC_TIMED_OUT               = -2,
	OBJC_SYNC_NOT_INITIALIZED         = -3		
};

FOUNDATION_EXPORT int objc_sync_enter(id obj)
{
	if(!obj)
		return OBJC_SYNC_SUCCESS;
	if(!synchronizationLocks)
		return OBJC_SYNC_NOT_INITIALIZED;
	id key=[[NSValue alloc] initWithBytes:&obj objCType:@encode(id)];

	[syncLocksLock lock];
	
	id lock=[synchronizationLocks objectForKey:key];
	if(!lock)
	{
		lock=[NSRecursiveLock new];
		[synchronizationLocks setObject:lock forKey:key];
		[lock release];
	}
	
	[syncLocksLock unlock];
	[key release];

	[lock lock];
	return OBJC_SYNC_SUCCESS;
}


FOUNDATION_EXPORT int objc_sync_exit(id obj)
{
	if(!obj)
		return OBJC_SYNC_SUCCESS;
	if(!synchronizationLocks)
		return OBJC_SYNC_NOT_INITIALIZED;
	id key=[[NSValue alloc] initWithBytes:&obj objCType:@encode(id)];
	
	[syncLocksLock lock];
	
	id lock=[synchronizationLocks objectForKey:key];
	if(lock)
	{
		[lock unlock];
	}
	
	[syncLocksLock unlock];
	
	[key release];
	
	return OBJC_SYNC_SUCCESS;
}
