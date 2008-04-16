/*$Id: SenTestShouldBeEqual.m,v 1.12 2005/04/02 03:18:24 phink Exp $*/

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

#import "SenTestShouldBeEqual.h"

@implementation SenTestShouldBeEqualTested
- (void) pass
{
    STAssertEqualObjects (nil, nil, @"nil should equal nil.");
    STAssertEqualObjects (@"a", @"a", @"a should equal a.");
    STAssertEqualObjects (@"a", @"a", @"ok");
    STAssertEqualObjects ([NSNumber numberWithInt:20], [NSNumber numberWithInt:20], @"20 should equal 20");
}


- (void) fail
{
	char B = 'B';
	char d = 'd';
    short aShortA = 2;
    short aShortB = 3;
	
	STAssertEquals(aShortA,aShortB,@"Basic shorts equals.");
	STAssertEquals(12,2ULL,@"shorts equals.");
	STAssertEquals(B,d,@"Basic char equals.");
	STAssertEquals('a','b',@"Basic char not equals.");
	STAssertEquals(20,0,@"Basic integer equals.");
    STAssertEquals(21.99,(float)22.0,@"Basic float equals.");
    STAssertEquals(21.999999,22.0,@"Basic float equals.");
	STAssertEqualsWithAccuracy(21,22,0,@"Basic float equals.");

	STAssertEquals(20,0,@"Basic integer equals.");
    STAssertEquals(21.999999,22.0,@"Basic float equals.");
    STAssertEqualObjects (@"a", @"b", @"a should not equal b. This test should fail.");
    STAssertEqualObjects (nil, @"", @"nil should not equal an empty string. This test should fail.");
    STAssertEqualObjects (@"x", nil, @"x should not equal nil. This test should fail.");
    STAssertEqualObjects (@"x", nil, @"not ok");
	STAssertEqualObjects ([NSNumber numberWithInt:20], [NSNumber numberWithInt:30], @"20 should not equal 30. This test should fail.");

}

+ (unsigned int) failFailureCount
{
    return 15;
}

@end


@implementation SenTestShouldBeEqualTesting
- (Class) testedClass
{
    return [SenTestShouldBeEqualTested class];
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
