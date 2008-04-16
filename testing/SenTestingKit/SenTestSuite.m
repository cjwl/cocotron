/*$Id: SenTestSuite.m,v 1.17 2005/04/02 03:18:22 phink Exp $*/

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

#import "SenTestSuite.h"
#import "SenTestCase.h"
#import "SenTestSuiteRun.h"
#import "SenTestingUtilities.h"
#import "NSObject_SenTestRuntimeUtilities.h"
#import <Foundation/Foundation.h>

static NSMutableDictionary *suiteForBundleCache = nil;


@interface NSObject (NSBundle)
+ (NSBundle *) bundle;
@end


@implementation NSObject (NSBundle)
+ (NSBundle *) bundle
{
    return [NSBundle bundleForClass:self];
}
@end


@interface SenTestCaseSuite : SenTestSuite
{
    @private
    Class testCaseClass;
}
+ (id) emptyTestSuiteForTestCaseClass:(Class) aClass;
@end


@implementation SenTestSuite

+ (id) testSuiteWithName:(NSString *) aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}


+ (id) emptyTestSuiteNamedFromPath:(NSString *) aPath
{
    return [self testSuiteWithName:[NSString stringWithFormat:@"%@(Tests)", aPath]];
}


+ (void) updateCache
{
    NSEnumerator *testCaseEnumerator = [[SenTestCase senAllSubclasses] objectEnumerator];
    id each = nil;
    while (nil != (each = [testCaseEnumerator nextObject])) {
        NSString *path = [[each bundle] bundlePath];
		SenTestSuite *suite = [suiteForBundleCache objectForKey:path];
		if (suite == nil) {
			suite = [self emptyTestSuiteNamedFromPath:path];
			[suiteForBundleCache setObject:suite forKey:path];
		}
		[suite addTest:[each defaultTestSuite]];
	}
}


+ (void) invalidateCache
{
    RELEASE (suiteForBundleCache);
}


+ (NSDictionary *) suiteForBundleCache
{
    if (suiteForBundleCache == nil) {
        suiteForBundleCache = [[NSMutableDictionary alloc] init];
        [self updateCache];
    }
    return suiteForBundleCache;
}



+ (id) testSuiteForBundlePath:(NSString *) bundlePath
{
    if ((bundlePath == nil) || [bundlePath isEqualToString:@""]) {
        return [self defaultTestSuite];
    }
    else {
        SenTestSuite *suite = [[self suiteForBundleCache] objectForKey:bundlePath];
        return (suite != nil) ? suite : [self emptyTestSuiteNamedFromPath:bundlePath];
    }
}


+ (id) testSuiteForTestCaseWithName:(NSString *) aName
{
    SenTestSuite *suite;
    NSArray *components = [aName pathComponents];
    if ([components count] > 0) {
        Class testCaseClass = NSClassFromString([components objectAtIndex:0]);
        suite = [SenTestCaseSuite emptyTestSuiteForTestCaseClass:testCaseClass];
        if ([components count] == 2) {
            if ([testCaseClass respondsToSelector:@selector (testCaseWithSelector:)]) {
                [suite addTest:[testCaseClass testCaseWithSelector:NSSelectorFromString([components lastObject])]];
            }
        }
        else {
            if ([testCaseClass respondsToSelector:@selector (defaultTestSuite)]) {
                suite = [testCaseClass defaultTestSuite];
            }
        }
        return suite;
    }
    return [self testSuiteWithName:aName];
}


+ (id) testSuiteForTestCaseClass:(Class) aClass
{
    SenTestSuite *suite = [SenTestCaseSuite emptyTestSuiteForTestCaseClass:aClass];
    NSEnumerator *invocationEnumerator = [[aClass testInvocations] objectEnumerator];
    NSMutableArray *testCollection = [NSMutableArray array];
    NSInvocation *eachInvocation = nil;
    while (nil != (eachInvocation = [invocationEnumerator nextObject])) {
        id eachTestCase = [aClass testCaseWithInvocation:eachInvocation];
        if (eachTestCase != nil) {
            [testCollection addObject:eachTestCase];
        }
    }
    [suite addTestsEnumeratedBy:[testCollection objectEnumerator]];

    return suite;
}


+ (NSDictionary *) structuredTests
{
    return [self suiteForBundleCache];   
}


+ (id) allTests
{
    SenTestSuite *fullTestSuite = [self testSuiteWithName:@"All tests"];

    [fullTestSuite addTestsEnumeratedBy:[[self structuredTests] objectEnumerator]];
    return fullTestSuite;   
}


+ (id) defaultTestSuite
{
    return [self allTests];
}


- (id) initWithName:(NSString *) aName
{
    self = [super init];
    name = [aName copy];
    tests = [[NSMutableArray alloc] init];
    return self;
}


- (id) initWithCoder:(NSCoder *) aCoder
{
    ASSIGN(name, [aCoder decodeObject]);
    ASSIGN(tests, [aCoder decodeObject]);
    return self;
}


- (void) encodeWithCoder:(NSCoder *) aCoder
{
    [aCoder encodeObject:name];
    [aCoder encodeObject:tests];
}


- (void) dealloc
{
    RELEASE (name);
    RELEASE (tests);
    [super dealloc];
}


- (NSString *) name
{
    return name;
}


- (NSString *) description
{
    return [self name];
}


- (void) addTest:(SenTest *) aTest
{
    if (aTest != nil) {
        [tests addObject:aTest];   
    }
}


- (void) addTestsEnumeratedBy:(NSEnumerator *) anEnumerator;
{
	id each;
	while (nil != (each = [anEnumerator nextObject])) {
		[self addTest:each];
	}
}


- (unsigned int) testCaseCount
{
	
	unsigned int testCaseCount = 0;
	NSEnumerator *testEnumerator = [tests objectEnumerator];
	SenTest *eachTest;
	
	while (nil != (eachTest = [testEnumerator nextObject])) {
		testCaseCount += [eachTest testCaseCount];
	}
	
    return testCaseCount;
}


- (Class) testRunClass
{
    return [SenTestSuiteRun class];
}


- (void) performTest:(SenTestRun *) aTestRun
{
    [self setUp];
    [aTestRun start];
	{
		NSEnumerator *testEnumerator = [tests objectEnumerator];
		SenTest *eachTest;
		while (nil != (eachTest = [testEnumerator nextObject])) {
			[(SenTestSuiteRun *) aTestRun addTestRun:[eachTest run]];
		}
	}
    [aTestRun stop];
    [self tearDown];
}
@end


@implementation SenTestCase (SenTestSuiteExtensions)
+ (void) setUp
{
}

+ (void) tearDown
{
}
@end


@implementation SenTestCaseSuite
- (id) initWithTestCaseClass:(Class) aClass
{
    testCaseClass = aClass;
    [super initWithName:NSStringFromClass(testCaseClass)];
    return self;
}


+ (id) emptyTestSuiteForTestCaseClass:(Class) aClass
{
    return [[[self alloc] initWithTestCaseClass:aClass] autorelease];
}


- (void) setUp
{
    [testCaseClass setUp];
}


- (void) tearDown
{
    [testCaseClass tearDown];
}
@end
