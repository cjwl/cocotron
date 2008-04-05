//
//  NSRecursiveLock.h
//  Foundation
//
//  Created by Johannes Fortmann on 05.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSLock.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSString.h>

@interface NSRecursiveLock : NSObject <NSLocking> {
	NSLock *_lock;
	NSThread *_lockingThread;
	int _numberOfLocks;
	NSString *_name;
}
-(NSString *)name;
-(void)setName:(NSString *)value;

-(BOOL)tryLock;
-(BOOL)lockBeforeDate:(NSDate *)value;
@end



@interface NSRecursiveLock (Private)
-(BOOL)isLocked;
@end
