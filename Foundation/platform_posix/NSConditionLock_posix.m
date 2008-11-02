/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSConditionLock_posix.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <pthread.h>
#import <time.h>

@implementation NSConditionLock_posix
-(id)init {
   return [self initWithCondition:0];
}

-(id)initWithCondition:(NSInteger)value {
   if(self = [super init]) {
      pthread_cond_init(&_cond, NULL);
      pthread_mutex_init(&_mutex, NULL);
      _value=value;
   }
   return self;
}

-(void)dealloc {
   pthread_mutex_destroy(&_mutex);
   pthread_cond_destroy(&_cond);
   [super dealloc];
}

-(NSInteger)condition {
   return _value;
}

-(void)lock {
   pthread_mutex_lock(&_mutex);
   _lockingThread=NSCurrentThread();
}

-(void)unlock {
   if(_lockingThread!=NSCurrentThread()) {
      [NSException raise:NSInvalidArgumentException format:@"trying to unlock %@ from thread %@, was locked from %@", self, NSCurrentThread(), _lockingThread];
   }
   
   _lockingThread=nil;
   pthread_mutex_unlock(&_mutex);
}

-(BOOL)tryLock {
   if(pthread_mutex_trylock(&_mutex))
      return NO;
   _lockingThread=NSCurrentThread();
   return YES;
}

-(BOOL)tryLockWhenCondition:(NSInteger)condition {
   if([self tryLock]) {
      return NO;
   }
   
   if(_value==condition) {
      return YES;
   }
   [self unlock];
   return NO;
}

-(void)lockWhenCondition:(NSInteger)condition {
   pthread_mutex_lock(&_mutex);
   
   while(_value!=condition) {
      pthread_cond_wait(&_cond, &_mutex);
   }
   _lockingThread=NSCurrentThread();
}

-(void)unlockWithCondition:(NSInteger)condition {
   if(_lockingThread!=NSCurrentThread()) {
      [NSException raise:NSInvalidArgumentException format:@"trying to unlock %@ from thread %@, was locked from %@", self, NSCurrentThread(), _lockingThread];
   }

   _lockingThread=nil;
   _value=condition;
   pthread_cond_broadcast(&_cond);
   pthread_mutex_unlock(&_mutex);
}

-(BOOL)lockBeforeDate:(NSDate *)date; {
   pthread_mutex_lock(&_mutex);
   struct timespec t={0};
   NSTimeInterval d=[date timeIntervalSinceReferenceDate];
   double frac;
   t.tv_sec=fmodd(d, &frac);
   t.tv_nsec=frac*1000000.0;
   
   if(pthread_cond_timedwait(&_cond, &_mutex, &t)<0) {
      return NO;
   }
   _lockingThread=NSCurrentThread();
   return YES;
}

-(BOOL)lockWhenCondition:(NSInteger)condition beforeDate:(NSDate *)date; {
   pthread_mutex_lock(&_mutex);
   struct timespec t={0};
   NSTimeInterval d=[date timeIntervalSinceReferenceDate];
   double frac;
   t.tv_sec=fmodd(d, &frac);
   t.tv_nsec=frac*1000000.0;
   
   while(_value!=condition) {
      if(pthread_cond_timedwait(&_cond, &_mutex, &t)<0)
         return NO;
   }
   _lockingThread=NSCurrentThread();
   return YES;
}

@end
