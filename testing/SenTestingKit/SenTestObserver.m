/*$Id: SenTestObserver.m,v 1.7 2005/04/02 03:18:21 phink Exp $*/

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

#import "SenTestObserver.h"
#import "SenTestSuiteRun.h"
#import "SenTestCaseRun.h"
#import "SenTestingUtilities.h"
#import <Foundation/Foundation.h>

@implementation NSNotification (SenTest)
- (SenTestRun *) run
{
    return [self object];
}


- (SenTest *) test
{
    return [[self run] test];
}


- (NSException *) exception
{
    return [[self userInfo] objectForKey:@"exception"];
}
@end


@implementation SenTestObserver

// FIXME. Not very elegant  and only one observer currently possible.
static Class currentObserverClass = Nil;
static BOOL isSuspended = YES;

+ (void) setCurrentObserver:(Class) anObserver
{
    if (currentObserverClass != Nil) {
        [self suspendObservation];
    }
    currentObserverClass = anObserver;
    if (currentObserverClass != Nil) {
        [self resumeObservation];
    }
}


+ (void) resumeObservation
{
    if (isSuspended) {
        [[NSNotificationCenter defaultCenter] addObserver:currentObserverClass
                                                 selector:@selector(testSuiteDidStart:)
                                                     name:SenTestSuiteDidStartNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:currentObserverClass
                                                 selector:@selector(testSuiteDidStop:)
                                                     name:SenTestSuiteDidStopNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:currentObserverClass
                                                 selector:@selector(testCaseDidStart:)
                                                     name:SenTestCaseDidStartNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:currentObserverClass
                                                 selector:@selector(testCaseDidStop:)
                                                     name:SenTestCaseDidStopNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:currentObserverClass
                                                 selector:@selector(testCaseDidFail:)
                                                     name:SenTestCaseDidFailNotification
                                                   object:nil];
        isSuspended = NO;
    }
}


+ (void) suspendObservation
{
    if (!isSuspended) {
        [[NSNotificationCenter defaultCenter] removeObserver:currentObserverClass];
        isSuspended = YES;
    }
}


+ (void) initialize
{
    if ([self class] == [SenTestObserver class]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *registeredDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
            @"SenTestLog" , @"SenTestObserverClass",
            nil];
        [defaults registerDefaults:registeredDefaults];
        [NSClassFromString ([defaults objectForKey:@"SenTestObserverClass"]) class]; // make sure default observer is loaded
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SenTestObserverClass"] isEqualToString:NSStringFromClass(self)]) {
        [self setCurrentObserver:self];
    }
}


+ (void) testSuiteDidStart:(NSNotification *) aNotification
{   
}


+ (void) testSuiteDidStop:(NSNotification *) aNotification
{
}


+ (void) testCaseDidStart:(NSNotification *) aNotification
{
}


+ (void) testCaseDidStop:(NSNotification *) aNotification
{
}


+ (void) testCaseDidFail:(NSNotification *) aNotification
{
}
@end
