/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSRecursiveLock.h>
#import <Foundation/NSValue.h>


// lock to serialize accesses to the lock chain; also serves as a marker if we 
// are currently locking (locking is disabled as long as there's no multithreading)
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
		allLocks=NSZoneMalloc(NULL, sizeof(LockChain));

		allLocks->object=0;
		allLocks->next=0;
		allLocks->lock=[NSRecursiveLock new];
        
        // this needs to be initialized last: it also serves as a marker that the locking
        // mechanism is actually initialized.
        lockChainLock=[NSLock new];
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
	if(!lockChainLock)
		return OBJC_SYNC_NOT_INITIALIZED;

	LockChain *result=lockForObject(obj);

	[result->lock lock];
	return OBJC_SYNC_SUCCESS;
}


FOUNDATION_EXPORT int objc_sync_exit(id obj)
{
	if(!obj)
		return OBJC_SYNC_SUCCESS;
	if(!lockChainLock)
		return OBJC_SYNC_NOT_INITIALIZED;

	LockChain *result=lockForObject(obj);

	result->object=NULL;
	[result->lock unlock];

	return OBJC_SYNC_SUCCESS;
}
