/*$Id: SenTestDistributedNotifier.m,v 1.8 2005/04/02 03:18:21 phink Exp $*/

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

#import "SenTestDistributedNotifier.h"
#import "SenTestSuite.h"
#import "SenTestCase.h"
#import "SenTestRun.h"
#import "SenTestingUtilities.h"


@implementation SenTestDistributedNotifier
+ (NSString *) notificationIdentifier
{
    static NSString *notificationIdentifier = nil;
    if (notificationIdentifier == nil) {
        notificationIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"SenTestNotificationIdentifier"];
    }
    return notificationIdentifier;
}


- (void) postNotificationName:(NSString *) aName userInfo:(NSDictionary *) userInfo
{
	NSUnimplementedMethod();
	/*
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:aName
                                                                   object:[[self class] notificationIdentifier]
                                                                 userInfo:userInfo
                                                       deliverImmediately:NO];*/
}


+ (NSDictionary *) userInfoForObject:(id) anObject userInfo:(NSDictionary *) userInfo
{
    NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionary];
    [newUserInfo setObject:[NSArchiver archivedDataWithRootObject:anObject] forKey:@"object"];
    if ([userInfo objectForKey:@"exception"] != nil) {
        [newUserInfo setObject:[NSArchiver archivedDataWithRootObject:[userInfo objectForKey:@"exception"]] forKey:@"exception"];
    }
    return newUserInfo;
}


+ (void) postNotificationName:(NSString *) aNotificationName object:(id) anObject userInfo:(NSDictionary *) userInfo
{
	NSUnimplementedMethod();
/*    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:aNotificationName
                                                                   object:[self notificationIdentifier]
                                                                 userInfo:[self userInfoForObject:anObject userInfo:userInfo]
                                                       deliverImmediately:NO];*/
}


+ (void) testSuiteDidStart:(NSNotification *) aNotification
{
    [self postNotificationName:[aNotification name] object:[aNotification object] userInfo:[aNotification userInfo]];
}


+ (void) testSuiteDidStop:(NSNotification *) aNotification
{
    [self postNotificationName:[aNotification name] object:[aNotification object] userInfo:[aNotification userInfo]];
}


+ (void) testCaseDidStart:(NSNotification *) aNotification
{
    [self postNotificationName:[aNotification name] object:[aNotification object] userInfo:[aNotification userInfo]];
}


+ (void) testCaseDidStop:(NSNotification *) aNotification
{
    [self postNotificationName:[aNotification name] object:[aNotification object] userInfo:[aNotification userInfo]];
}


+ (void) testCaseDidFail:(NSNotification *) aNotification
{
    [self postNotificationName:[aNotification name] object:[aNotification object] userInfo:[aNotification userInfo]];
}
@end
