/*$Id: SenTest.m,v 1.10 2005/04/02 03:18:20 phink Exp $*/

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

#import "SenTest.h"
#import "SenTestRun.h"


@implementation SenTest

- (BOOL) isEmpty
/*"Returns YES if testCaseCount is 0."*/
{
    return [self testCaseCount] == 0;
}


- (unsigned int) testCaseCount
/*"Must be overridden by subclasses."*/
{
    return 0;
}


- (Class) testRunClass
/*"The SenTestRun subclass that will be created when a test is run to hold the test's results. Must be overridden by subclasses."*/
{
    return nil;
}

- (NSString *) name
/*"Must be overridden by subclasses."*/
{
    return nil;
}


- (void) performTest:(SenTestRun *) aRun
/*"The method through which tests are executed. Must be overridden by subclasses. "*/
{
}


- (void) setUp
/*"Sets up the fixture. This method is called before a test is executed."*/
{
}


- (void) tearDown
/*"Tears down the fixture. This method is called after a test is executed."*/
{
}


- (SenTestRun *) run
/*"Creates a SenTestRun of the testRunClass and passes it as a parameter to the performTest method. "*/
{
    SenTestRun *testRun = [[self testRunClass] testRunWithTest:self];
    [self performTest:testRun];
    return testRun;
}
@end
