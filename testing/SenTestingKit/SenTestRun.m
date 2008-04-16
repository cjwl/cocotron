/*$Id: SenTestRun.m,v 1.10 2005/04/02 03:18:22 phink Exp $*/

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

#import "SenTestRun.h"
#import "SenTestingUtilities.h"

@implementation SenTestRun
+ (id) testRunWithTest:(SenTest *) aTest
{
    return [[[self alloc] initWithTest:aTest] autorelease];
}


- (id) initWithTest:(SenTest *) aTest
{
    self = [super init];
    ASSIGN(test, aTest);
    return self;
}


- (void) dealloc
{
    RELEASE(test);
    [super dealloc];
}


- (id) initWithCoder:(NSCoder *) aCoder
{
    ASSIGN(test, [aCoder decodeObject]);
    [aCoder decodeValueOfObjCType:@encode(NSTimeInterval) at:&startDate];
    [aCoder decodeValueOfObjCType:@encode(NSTimeInterval) at:&stopDate];
    return self;
}


- (void) encodeWithCoder:(NSCoder *) aCoder
{
    [aCoder encodeObject:test];
    [aCoder encodeValueOfObjCType:@encode(NSTimeInterval) at:&startDate];
    [aCoder encodeValueOfObjCType:@encode(NSTimeInterval) at:&stopDate];
}


- (SenTest *) test
{
    return test;
}


- (NSTimeInterval) totalDuration
/*" Total elapsed time "*/
{
    return stopDate - startDate;
}


- (NSTimeInterval) testDuration
/*" Time spent in test cases "*/
{
    return [self totalDuration];
}


- (NSDate *) startDate
{
    return [NSDate dateWithTimeIntervalSinceReferenceDate:startDate];
}


- (NSDate *) stopDate
{
    return [NSDate dateWithTimeIntervalSinceReferenceDate:stopDate];
}


- (void) start
{
    startDate = [NSDate timeIntervalSinceReferenceDate];
}


- (void) stop
{
    stopDate = [NSDate timeIntervalSinceReferenceDate];
}


- (unsigned int) totalFailureCount
{
    return [self failureCount] + [self unexpectedExceptionCount];
}


- (unsigned int) failureCount
{
    return 0;
}


- (unsigned int) unexpectedExceptionCount
{
    return 0;
}


- (unsigned int) testCaseCount
{
    return [test testCaseCount];
}


- (BOOL) hasSucceeded
{
    return ([self totalFailureCount] == 0);
}



- (NSString *)description
{
    return [NSString stringWithFormat:@"Test:%@ started:%@ stopped:%@", [self test], [self startDate], [self stopDate]];
}
@end
