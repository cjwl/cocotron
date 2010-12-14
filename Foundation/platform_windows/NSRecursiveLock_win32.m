/* Copyright (c) 2010 Matt Gallagher
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSRecursiveLock_win32.h"
#import <Foundation/NSRaiseException.h>

@implementation NSRecursiveLock(win32)
+allocWithZone:(NSZone *)zone {
   if(self==[NSRecursiveLock class])
    return NSAllocateObject([NSRecursiveLock_win32 class],0,zone);
   else
    return NSAllocateObject(self,0,zone);
}

@end

@implementation NSRecursiveLock_win32

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        InitializeCriticalSection( &_lock );
    }
    return self;
}

- (void)dealloc
{
    DeleteCriticalSection(&_lock);
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

-(void) lock {
    EnterCriticalSection(&_lock);
}

-(BOOL) tryLock {
    return TryEnterCriticalSection(&_lock);
}

-(void) unlock {
    LeaveCriticalSection(&_lock);
}


-(BOOL)lockBeforeDate:(NSDate *)value
{
   BOOL haveLock;
   while (!(haveLock = [self tryLock]) && [value timeIntervalSinceNow] > 0)
   {
      [NSThread sleepForTimeInterval:0.001];
   }
   return haveLock;
}

@end
