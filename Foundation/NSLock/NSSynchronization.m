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

static NSLock *lockChainLock=nil;

struct LockChain;
typedef struct LockChain
	{
		id lock;
		id object;
		struct LockChain *next;
	} LockChain;

LockChain *allLocks=NULL;

void _NSInitializeSynchronizedDirective()
{
	if(!lockChainLock)
	{
		lockChainLock=[NSLock new];
		allLocks=NSZoneMalloc(NULL, sizeof(LockChain));

		allLocks->object=0;
		allLocks->next=0;
		allLocks->lock=[NSRecursiveLock new];
	}
}

enum {
	OBJC_SYNC_SUCCESS                 = 0,
	OBJC_SYNC_NOT_OWNING_THREAD_ERROR = -1,
	OBJC_SYNC_TIMED_OUT               = -2,
	OBJC_SYNC_NOT_INITIALIZED         = -3		
};

LockChain* lockForObject(id object)
{
	LockChain *result=NULL;
	LockChain *firstFree=NULL;
	[lockChainLock lock];

	for(result=allLocks; result; result=result->next)
	{
		if(result->object==object)
			goto done;
		if(result->object==NULL)
			firstFree=result;
	}

	if(firstFree)
	{
		firstFree->object=object;
		result=firstFree;
		goto done;
	}

	result=NSZoneMalloc(NULL, sizeof(LockChain));
	result->object=object;
	result->next=allLocks;
	result->lock=[NSRecursiveLock new];
	allLocks=result;

done:

	[lockChainLock unlock];
	return result;
}

FOUNDATION_EXPORT int objc_sync_enter(id obj)
{
	if(!obj)
		return OBJC_SYNC_SUCCESS;
	if(!allLocks)
		return OBJC_SYNC_NOT_INITIALIZED;

	LockChain *result=lockForObject(obj);

	[result->lock lock];
	return OBJC_SYNC_SUCCESS;
}


FOUNDATION_EXPORT int objc_sync_exit(id obj)
{
	if(!obj)
		return OBJC_SYNC_SUCCESS;
	if(!allLocks)
		return OBJC_SYNC_NOT_INITIALIZED;

	LockChain *result=lockForObject(obj);

	result->object=NULL;
	[result->lock unlock];

	return OBJC_SYNC_SUCCESS;
}
