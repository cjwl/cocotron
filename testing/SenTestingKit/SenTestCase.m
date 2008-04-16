/*$Id: SenTestCase.m,v 1.15 2005/04/02 03:25:20 phink Exp $*/

// Copyright (c) 1997-2005, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the following license:
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// (1) Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// 
// (2) Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation 
// and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL Sente SA OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Note: this license is equivalent to the FreeBSD license.
// 
// This notice may not be removed from this file.

#import "SenTestCase.h"
#import "SenTestSuite.h"
#import "SenTestCaseRun.h"
#import "NSException_SenTestFailure.h"
#import "NSInvocation_SenTesting.h"

#import "SenTestingUtilities.h"
#import "NSObject_SenTestRuntimeUtilities.h"
#import <Foundation/Foundation.h>


@implementation SenTestCase
- (id) init
{
    [self initWithInvocation:nil];
    return self;
}


- (id) initWithInvocation:(NSInvocation *) anInvocation
{
    self = [super init];
    [self continueAfterFailure];
    [self setInvocation:anInvocation];
    return self;
}


+ (id) testCaseWithInvocation:(NSInvocation *) anInvocation
{
    return [[[self alloc] initWithInvocation:anInvocation] autorelease];
}


- (id) initWithSelector:(SEL) aSelector
{
    NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
    [anInvocation setSelector:aSelector];
    return [self initWithInvocation:anInvocation];
}


+ (id) testCaseWithSelector:(SEL) aSelector
{
    return [[[self alloc] initWithSelector:aSelector] autorelease];
}


- (Class) classForCoder
{
    return [SenTestCase class];
}


- (id) initWithCoder:(NSCoder *) aCoder
{
    ASSIGN(invocation, [aCoder decodeObject]);
    [aCoder decodeValueOfObjCType:@encode(SEL) at:&failureAction];
    return self;
}


- (void) encodeWithCoder:(NSCoder *) aCoder
{
    [aCoder encodeObject:invocation];
    [aCoder encodeValueOfObjCType:@encode(SEL) at:&failureAction];
}


- (SEL) selector
{
    return [invocation selector];
}


- (unsigned int) testCaseCount
{
    return 1;
}


- (NSString *) name
{
    return [NSString stringWithFormat:@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector([invocation selector])];
}


- (NSString *) description
{
    return [self name];
}


- (void) dealloc
{
    RELEASE (invocation);
    [super dealloc];
}


+ (void) setUp
{
}


+ (void) tearDown
{
}


- (NSInvocation *) invocation
{
    return invocation;
}


- (void) setInvocation:(NSInvocation *) anInvocation
{
    ASSIGN(invocation, anInvocation);
    [invocation setTarget:self];
}


- (SEL) failureAction
{
    return failureAction;
}


- (void) setFailureAction:(SEL) aSelector
{
    failureAction = aSelector;
}


- (void) continueAfterFailure
{
    [self setFailureAction:@selector(logException:)];
}


- (void) raiseAfterFailure
{
    [self setFailureAction:@selector(raiseException:)];
}


- (void) logException:(NSException *) anException
{
    [run addException: anException];
}


- (void) raiseException:(NSException *) anException
{
    [anException raise];    
}


- (void) failWithException:(NSException *) anException
{
    [self performSelector:failureAction withObject:anException];
}


- (Class) testRunClass
{
    return [SenTestCaseRun class];
}


- (void) performTest:(SenTestRun *) aTestRun
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
    NSException *exception = nil;

	
    ASSIGN (run, aTestRun);
    [self setUp];
    [run start];
    @try {
        [invocation invoke];
    }
    @catch (NSException *anException) {
        exception = [[anException retain] autorelease];
    }
    [run stop];
    [self tearDown];

    if (exception != nil) {
        [self logException:exception];
    }
    RELEASE (run);
	[pool release];
}


+ (BOOL) isInheritingTestCases
{
    return YES;
}


+ (NSArray *) testInvocations
{
    NSArray  *instanceInvocations = [self isInheritingTestCases] ? [self senAllInstanceInvocations] : [self senInstanceInvocations];
	NSMutableArray *testInvocations = [NSMutableArray array];
	NSEnumerator *instanceInvocationEnumerator = [instanceInvocations objectEnumerator];
	NSInvocation *each;
	
	while (nil != (each = [instanceInvocationEnumerator nextObject])) {
		if ([each hasTestCaseSignature]) {
			[testInvocations addObject:each];
		}
	}
    [testInvocations sortUsingSelector:@selector(compare:)];

    return testInvocations;
}

@end


@implementation SenTestCase (Suite)
+ (id) defaultTestSuite
{
    SenTestSuite *suite = [SenTestSuite testSuiteForTestCaseClass:self];
    return suite;
}
@end
