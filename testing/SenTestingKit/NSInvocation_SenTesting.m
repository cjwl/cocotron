/*$Id: NSInvocation_SenTesting.m,v 1.10 2005/04/02 03:18:20 phink Exp $*/

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

#import "NSInvocation_SenTesting.h"
#import "SenTestingUtilities.h"
#ifndef GNU_RUNTIME /* NeXT RUNTIME */
#import <objc/objc-class.h>
#else
#include <objc/objc-api.h>
#endif

@implementation NSInvocation (SenTesting)

NSString *DefaultTestMethodPrefix = @"test";
static NSString *testMethodPrefix = nil;


+ (NSString *) testMethodPrefix
{
    return (testMethodPrefix != nil) ? testMethodPrefix : DefaultTestMethodPrefix;
}


+ (void) setTestMethodPrefix:(NSString *) aPrefix
{
    ASSIGN(testMethodPrefix,aPrefix);
}


- (NSString *) testMethodPrefix
{
    return [[self class] testMethodPrefix];
}


- (BOOL) isReturningVoid
{
    return *[[self methodSignature] methodReturnType] == _C_VOID;
}


- (BOOL) hasTestPrefix
{
    return [NSStringFromSelector([self selector]) hasPrefix:[self testMethodPrefix]];
}


- (unsigned) numberOfParameters
{
    return [[self methodSignature] numberOfArguments] - 2;
}


- (BOOL) hasTestCaseSignature
{
    return ([self numberOfParameters] == 0) && [self isReturningVoid] && [self hasTestPrefix];
}

- (NSComparisonResult)compare:(NSInvocation *)anInvocation
    /*" Returns NSOrderedAscending if the selector of the receiver expressed as
        a string precedes the selector of anInvocation expressed as a string in
        lexical ordering, NSOrderedSame if the selector of the receiver and 
        anInvocation are equivalent in lexical value, and NSOrderedDescending if
        the selector of the receiver follows anInvocation. 
    "*/
{
    NSString *mySelector = nil;
    NSString *theOtherSelector = nil;
    NSComparisonResult theComparisonResult = 0;
    
    mySelector = NSStringFromSelector([self selector]);
    theOtherSelector = NSStringFromSelector([anInvocation selector]);
    theComparisonResult = [mySelector compare:theOtherSelector];
    
    return theComparisonResult;
}

@end
