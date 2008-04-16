/*$Id: SenTestShouldRaise.m,v 1.13 2005/04/02 03:18:24 phink Exp $*/

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

#import "SenTestShouldRaise.h"

@implementation SenTestShouldRaiseTested
- (void) pass
{
    STAssertThrows ([NSException raise:NSGenericException format:@"A voluntary error"],nil);
    STAssertNoThrow ([[NSMutableArray array] addObject:@"a"], nil);
    STAssertThrows ([NSException raise:NSGenericException format:@"A voluntary error"], @"ok");
    STAssertNoThrow ([[NSMutableArray array] addObject:@"a"], @"ok");
    STAssertTrueNoThrow(([[NSArray arrayWithObject:@"a"] count] == 1), @"Should be true and should not raise.");
    STAssertFalseNoThrow(([[NSArray arrayWithObject:@"a"] count] == 0), @"Should be false and should not raise.");
}


- (void) fail
{
    STAssertThrows ([[NSMutableArray array] addObject:@"a"], nil);
    STAssertNoThrow ([NSException raise:NSGenericException format:@"A voluntary error"],nil);
    STAssertThrows ([[NSMutableArray array] addObject:@"a"], @"Not ok %@ %d", self, 12);
    STAssertNoThrow ([NSException raise:NSGenericException format:@"A voluntary error"], @"Not ok %@ %d", self, 12);
    STAssertTrueNoThrow(([[NSArray arrayWithObject:nil] count] == 0), @"Should be true and should raise.");
    STAssertFalseNoThrow(([[NSArray arrayWithObject:nil] count] == 1), @"Should be false and should raise.");

}


+ (unsigned int) failFailureCount
{
    return 6;
}
@end


@implementation SenTestShouldRaiseTesting
- (Class) testedClass
{
    return [SenTestShouldRaiseTested class];
}


- (void) testPass
{
    STAssertTrue ([passedRun failureCount] == 0, 
            @"Should be no failures, but there were %d failure(s).", 
            [passedRun failureCount]);
    STAssertTrue ([passedRun unexpectedExceptionCount] == 0,
            @"Should be no unexpected exceptions, but there were %d exceptions(s).", 
            [passedRun unexpectedExceptionCount]);
    STAssertTrue ([passedRun hasSucceeded], @"But this test has failed.");        
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
