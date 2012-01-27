/*
Original Author: Michael Ash on 11/9/08.
Copyright (c) 2008 Rogue Amoeba Software LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import "NSOperation.h"
#import <Foundation/NSString.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSInvocation.h>

@implementation NSOperation

-(void)main {
	NSLog( @"NSOperation is an abstract class, implement -[%@ %@]", [self class], NSStringFromSelector( _cmd ) );
	[self doesNotRecognizeSelector: _cmd];
}

-(NSArray *)dependencies {
	return dependencies;
}

-(void)addDependency:(NSOperation *)operation {
	if (nil == dependencies) {
		dependencies = [[NSMutableArray alloc] init];
	}
	[dependencies addObject: operation];
}

-(void)removeDependency:(NSOperation *)operation {
	if (nil != dependencies) {
		[dependencies removeObject: operation];
	}
}

-(NSOperationQueuePriority)queuePriority {
	return priority;
}

-(void)setQueuePriority:(NSOperationQueuePriority)newPriority {
	priority = newPriority;
}

-(BOOL)isCancelled {
	return cancelled;
}

-(void)cancel {
	[self willChangeValueForKey: @"isCancelled"];
	cancelled = 1;
	[self didChangeValueForKey: @"isCancelled"];
}

-(BOOL)isConcurrent {
	return NO;
}

-(BOOL)isExecuting {
	return executing;
}

-(BOOL)isFinished {
	return finished;
}

-(BOOL)isReady {
	for (NSOperation *op in dependencies) {
    if (![op isFinished])
     return NO;
	}
	return YES;
}

-(void)start {
	if (!executing && !finished) {
		if (!cancelled) {
			[self willChangeValueForKey: @"isExecuting"];
			executing = 1;
			[self didChangeValueForKey: @"isExecuting"];
			
			[self main];
		}
		
		[self willChangeValueForKey: @"isExecuting"];
		[self willChangeValueForKey: @"isFinished"];
		executing = 0;
		finished = 1;
		[self didChangeValueForKey: @"isFinished"];
		[self didChangeValueForKey: @"isExecuting"];
	}
}

-(void)dealloc {
   [dependencies release];
	[super dealloc];
}

@end

NSString * const NSInvocationOperationVoidResultException = @"NSInvocationOperationVoidResultException";
NSString * const NSInvocationOperationCancelledException = @"NSInvocationOperationCancelledException";


@implementation NSInvocationOperation

-initWithInvocation:(NSInvocation *)invocation {
   if([super init]==nil)
    return nil;
    
   _invocation = [invocation retain];
   [_invocation retainArguments];
   
	return self;
}

-initWithTarget:target selector:(SEL)selector object:argument {
   NSMethodSignature *signature=[target methodSignatureForSelector:selector];
   NSInvocation      *invocation=[NSInvocation invocationWithMethodSignature:signature];
	
   [invocation setTarget:target];
   [invocation setSelector:selector];
	if ([signature numberOfArguments] > 2) {
		[invocation setArgument:&argument atIndex:2];
	}
	return [self initWithInvocation:invocation];
}

-(NSInvocation *)invocation {
	return _invocation;
}

-result {
   if ([self isCancelled])
    [NSException raise: NSInvocationOperationCancelledException format: @"" ];

	id result = 0;
	
   if ([[_invocation methodSignature] methodReturnLength] != sizeof( result ))
    [NSException raise: NSInvocationOperationVoidResultException format: @""];
	
   [_invocation getReturnValue: &result];
	return result;
}

-(void)dealloc {
   [_invocation release];
	[super dealloc];
}

-(void)main {
   [_invocation invoke];
}

@end

