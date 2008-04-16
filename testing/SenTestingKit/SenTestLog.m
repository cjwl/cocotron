/*$Id: SenTestLog.m,v 1.10 2005/04/02 03:18:21 phink Exp $*/

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

#import "SenTestLog.h"
#import "SenTestSuite.h"
#import "SenTestCase.h"
#import "SenTestRun.h"
#import "NSException_SenTestFailure.h"
#import "SenTestingUtilities.h"

@implementation SenTestLog
static void testlog (NSString *message)
{
	NSString *line = [NSString stringWithFormat:@"%@\n", message];
	[(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
}

#ifdef GNU_RUNTIME
// unlike the NeXT runtime, the GNU runtime doesn't call super automatically
+ (void) initialize
{
    [super initialize];
}
#endif

+ (void) testCaseDidStop:(NSNotification *) aNotification
{
    SenTestRun *run = [aNotification run];
    testlog ([NSString stringWithFormat:@"Test Case '%@' %s (%.3f seconds).", [run test], ([run hasSucceeded] ? "passed" : "failed"), [run totalDuration]]);
}


+ (void) testSuiteDidStart:(NSNotification *) aNotification
{
    SenTestRun *run = [aNotification run];
    testlog ([NSString stringWithFormat:@"Test Suite '%@' started at %@", [run test], [run startDate]]);
}


+ (void) testSuiteDidStop:(NSNotification *) aNotification
{
    SenTestRun *run = [aNotification run];
    testlog ([NSString stringWithFormat:@"Test Suite '%@' finished at %@.\nPassed %d test%s, with %d failure%s (%d unexpected) in %.3f (%.3f) seconds\n",
        [run test],
        [run stopDate],
        [run testCaseCount], ([run testCaseCount] != 1 ? "s" : ""),
        [run totalFailureCount], ([run totalFailureCount] != 1 ? "s" : ""),
        [run unexpectedExceptionCount],
        [run testDuration],
        [run totalDuration]]);
}


+ (void) testCaseDidFail:(NSNotification *) aNotification
{
    NSException *exception = [aNotification exception];
    testlog ([NSString stringWithFormat:@"%@:%@: error: %@ : %@",
        [exception filePathInProject],
        [exception lineNumber],
        [aNotification test],
        [exception reason]]);
}
@end
