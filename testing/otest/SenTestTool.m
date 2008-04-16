//*$Id: SenTestTool.m,v 1.11 2005/04/02 03:18:24 phink Exp $*/
// Copyright (c) 1997-2003 Sente SA.  All rights reserved.
//
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

#import "SenTestTool.h"


static NSString *SenTestedUnitPath = @"SenTestedUnitPath";
static NSString *SenTestScopeKey = @"SenTest";
static NSString *SenTestDefaultScope = @"Self";


// Copied from SenFoundation to make otest independant of SenFoundation.
@interface NSMutableArray (OtestAddition)
- (void) setValue:(NSString *) aValue forArgumentName:(NSString *) aKey;
@end


@implementation NSMutableArray (SenTaskAddition)
- (void) setValue:(NSString *) aValue forArgumentName:(NSString *) aKey
{
    NSString *defaultKey = [NSString stringWithFormat:@"-%@", aKey];
    unsigned int anIndex = [self indexOfObject:defaultKey];
    if (anIndex == NSNotFound) {
        [self addObject:defaultKey];
        [self addObject:aValue];
    }
    else {
        [self replaceObjectAtIndex:(anIndex + 1) withObject:aValue];
    }
}
@end


@implementation SenTestTool

+ (void) initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *registeredDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
        SenTestDefaultScope, SenTestScopeKey,
        nil];
    [defaults registerDefaults:registeredDefaults];
}


+ (SenTestTool *) sharedInstance
{
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}


- (void) showUsage
{
    NSLog (@"Usage: %@ [-SenTest Self | All | None | <TestCaseClassName/testMethodName>] <path of unit to be tested>",
           [[NSProcessInfo processInfo] processName]);
}


- (NSBundle *) bundleWithPath:(NSString *) aPath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:aPath]) {
        return [NSBundle bundleWithPath:aPath];
    }
    return nil;
}


- (BOOL) runTestFromBundle:(NSBundle *) aBundle
{
    BOOL result = NO;

    [[NSUserDefaults standardUserDefaults] setObject:[aBundle bundlePath] forKey:SenTestedUnitPath];
    result = [aBundle load];
    if (result) {
        // The bundle has been loaded, and it should be linked against SenTestingKit.
        // so SenTestProbe should be available
        // (but we do not want to link otest with SenTestingKit to be able to test the kit itself.)
        id testProbeClass = NSClassFromString (@"SenTestProbe");
        if (testProbeClass != nil) {
            [testProbeClass performSelector:@selector(runTests:) withObject:nil];
        }
    }
    return result;
}


- (void) launchTaskFromPath:(NSString *) aPath bundle:(NSBundle *) aBundle
{
    NSString *testedUnitPath;
    NSString *launchPath;
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
    [arguments setValue:[[NSUserDefaults standardUserDefaults] stringForKey:SenTestScopeKey] forArgumentName:SenTestScopeKey];

    if (aBundle != nil) {
        testedUnitPath = aPath;
        launchPath = [aBundle executablePath];
    }
    else {
        // FIXME: This is a hack based on the fact that [NSBundle bundleForClass:aClass] returns a bundle with
        // the tool parent folder as its path.
        testedUnitPath = [aPath stringByDeletingLastPathComponent];
        launchPath = aPath;
    }
    [arguments setValue:testedUnitPath forArgumentName:SenTestedUnitPath];
    [[NSTask launchedTaskWithLaunchPath:launchPath arguments:arguments] waitUntilExit];
}


- (void) run
{
    NS_DURING
        if ([[[NSProcessInfo processInfo] arguments] count] < 2) {
            [NSException raise:NSInvalidArgumentException format:@"Missing arguments"]; 
        }
        else {
            NSString *path = [[[NSProcessInfo processInfo] arguments] lastObject];
            NSBundle *bundle = [self bundleWithPath:path];
            if (bundle != nil) {
                if (![self runTestFromBundle:bundle]) {
                    [self launchTaskFromPath:path bundle:bundle];
                }
            }
            else {
                [self launchTaskFromPath:path bundle:nil];
            }
        }
            
    NS_HANDLER
        [self showUsage];
        NSLog (@"%@", localException);
    NS_ENDHANDLER
}


+ (void) run
{
   [[self sharedInstance] run];
}
@end
