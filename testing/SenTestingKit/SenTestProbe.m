/*$Id: SenTestProbe.m,v 1.23 2005/04/02 03:21:04 phink Exp $*/

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

/*" The purpose of this class is to run the tests and exit when the TestingKit
    is loaded and testing is on (SenTest default is "All" or "Self")

    This class is a bit of hack, to make testing as transparent as possible,
    (i.e. without modification to the client code to set testing on or off).
"*/


#import "SenTestProbe.h"
#import "SenTestSuite.h"
#import "SenTestRun.h"
#import "SenTestObserver.h"

#import "SenTestingUtilities.h"

NSString *SenTestedUnitPath = @"SenTestedUnitPath";
NSString *SenTestScopeKey = @"SenTest";
NSString *SenTestScopeAll = @"All";
NSString *SenTestScopeNone = @"None";
NSString *SenTestScopeSelf = @"Self";


@interface SenTestProbe(SenTestProbe_Private)
+ (void) runTestsAtUnitPath:(NSString *)path scope:(NSString *)scope;
+ (void) runTests:(id) ignored;
@end


@implementation SenTestProbe

+ (BOOL) isLoadedFromApplication
{
    BOOL result = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSBundle *mainBundle = [NSBundle mainBundle];

    if (mainBundle != nil) {
        // -mainBundle returns a value even when we are not running from an .app

        // And even ([NSBundle bundleWithPath:[mainBundle bundlePath]] != nil) is not a sufficient test!
        // so we have to resort to this:
        NSString *extension = [[mainBundle bundlePath] pathExtension];
        if (extension != nil) {
            NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"ApplicationWrapperExtensions" ofType:@"plist"];
            result = [[[NSString stringWithContentsOfFile:path] propertyList] containsObject:extension];
        }
    }
    [pool release];
    return result;
}


+ (BOOL) isLoadedFromTool
{
    BOOL result = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSBundle *mainBundle = [NSBundle mainBundle];

    if (mainBundle != nil && (![[[NSProcessInfo processInfo] processName] isEqualToString: @"otest"])) {
        result = [[NSFileManager defaultManager] fileExistsAtPathOrLink: [[mainBundle bundlePath] stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]]];
    }
    [pool release];
    return result;
}


+ (NSString *) testScope
{
    static NSString *testScope = nil;
    if (testScope == nil) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        testScope = [[[NSUserDefaults standardUserDefaults] stringForKey:SenTestScopeKey] copy];
        [pool release];
    }
    return testScope;
}


+ (BOOL) isTesting
{
    NSString *testScope = [self testScope];
    return (testScope != nil) && (![testScope isEqualToString:@""]) && (![testScope isEqualToString:SenTestScopeNone]);
}


+ (NSString *) testedBundlePath
{
    static NSString *testedBundlePath = nil;
    if (testedBundlePath == nil) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        if ([self isLoadedFromApplication] || [self isLoadedFromTool]) {
            testedBundlePath = [[[NSBundle mainBundle] bundlePath] copy];
        }
        else {
            testedBundlePath = [[[NSUserDefaults standardUserDefaults] stringForKey:SenTestedUnitPath] copy];
        }
        [pool release];
    }
    return testedBundlePath;
}


+ (SenTestSuite *) specifiedTestSuite
{
    static SenTestSuite *specifiedTestSuite = nil;
    if (specifiedTestSuite == nil) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *testScope = [self testScope];
        if ([testScope isEqualToString:SenTestScopeAll]) {
            ASSIGN (specifiedTestSuite, [SenTestSuite defaultTestSuite]);
        }
        else if ([testScope isEqualToString:SenTestScopeSelf]) {
            ASSIGN (specifiedTestSuite, [SenTestSuite testSuiteForBundlePath:[self testedBundlePath]]);
        }
        else if (![testScope isEqualToString:SenTestScopeNone]) {
            ASSIGN (specifiedTestSuite, [SenTestSuite testSuiteForTestCaseWithName:testScope]);
        }
        [pool release];
    }
    return specifiedTestSuite;
}


+ (void) runTestsAtUnitPath:(NSString *)path scope:(NSString *)scope
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:path forKey:SenTestedUnitPath];
    [defaults setObject:SenTestScopeSelf forKey:SenTestScopeKey];
    [self runTests:nil];
}


+ (void) runTests:(id) ignored
{
    BOOL hasFailed  = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [[NSBundle allFrameworks] makeObjectsPerformSelector:@selector (principalClass)];
    [SenTestObserver class];          // make sure an observer is loaded
    hasFailed = ![[[self specifiedTestSuite] run] hasSucceeded];
    [pool release];
    exit ((int) hasFailed);
}


+ (void) initialize
{
    if ([self isTesting]) {
        if ([self isLoadedFromApplication]) {
            // wait for the application to complete its own loading
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            [self performSelector:@selector(runTests:) withObject:nil afterDelay:0.0];
            [pool release];
        }
        else if (![[[NSProcessInfo processInfo] processName] isEqualToString: @"otest"]) {
#ifndef WIN32
            [self runTests:nil];
            // hangs on Windows. otest loads tests differently.
#endif
        }
    }
}


#if !defined(GNUSTEP) || (GNUSTEP && !GS_FAKE_MAIN)
// hangs on GNUstep with fake main defined. You should send a msg
// to initialize SenTestProbe in your main()

+ (void) load
{
	[NSObject self];
    [self class];
}
#endif
@end

int SenSelfTestMain()
/*" Call this function from your tool project's main() function "*/
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *path;

    path = [[NSBundle mainBundle] bundlePath];
    [SenTestProbe runTestsAtUnitPath:path scope:SenTestScopeSelf];

    [pool release];
    return 0;
}
