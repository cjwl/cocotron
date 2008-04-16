/*$Id: SenTestFail.m,v 1.11 2005/04/02 03:18:23 phink Exp $*/

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

#import "SenTestFail.h"


@implementation SenTestFailTested
- (void) pass
{
}


- (void) fail
{
    STFail (nil);
    STFail (@"I fail...");
    STAssertNotNil(nil, @"This should fail since nil is nil.");
}


+ (unsigned int) failFailureCount
{
    return 3;
}
@end


@implementation SenTestFailTesting
- (Class) testedClass
{
    return [SenTestFailTested class];
}


- (void) testPass
{
    STAssertTrue ([passedRun failureCount] == 0,
            @"The failure count should be zero, instead it is %d.",
            [passedRun failureCount]);
    STAssertTrue ([passedRun unexpectedExceptionCount] == 0,
            @"The unexpected exception count should be zero, instead it is %d.",
            [passedRun unexpectedExceptionCount]);
    STAssertTrue ([passedRun hasSucceeded],
            @"This test should succeed, but is has not.");
}


- (void) testFail
{
    STAssertTrue ([failedRun failureCount] == [[self testedClass] failFailureCount],
            @"The failed run failure count of %d does not equal the expected failure count of %d.", 
            [failedRun failureCount], [[self testedClass] failFailureCount]);
    STAssertTrue ([failedRun unexpectedExceptionCount] == 0,
            @"Should be no unexpected exceptions, but there were %d exceptions(s).",
            [failedRun unexpectedExceptionCount]);
    STAssertFalse ([failedRun hasSucceeded], @"But this test has not failed.");
}
@end
