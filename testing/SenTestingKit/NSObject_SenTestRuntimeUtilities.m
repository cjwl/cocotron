/*$Id: NSObject_SenTestRuntimeUtilities.m,v 1.4 2005/04/02 03:18:20 phink Exp $*/

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

#import "NSObject_SenTestRuntimeUtilities.h"
#import "SenTestInvocationEnumerator.h"
#import "SenTestClassEnumerator.h"
#import <Foundation/Foundation.h>
#import <objc/objc-class.h>


#if defined (GNUSTEP)
@interface Object (PrivateRuntimeUtilities)
+ (BOOL)respondsToSelector:(SEL)sel;
@end


@implementation Object (PrivateRuntimeUtilities)
+ (BOOL)respondsToSelector:(SEL)sel
{
  return (IMP)class_get_instance_method(self, sel) != (IMP)0;
}
@end
#endif


@implementation NSObject (SenTestRuntimeUtilities)
+ (NSArray *) senAllSuperclasses
{
    static NSMutableDictionary *superclassesClassVar = nil;
    NSString *key = NSStringFromClass (self);

    if (superclassesClassVar == nil) {
        superclassesClassVar = [[NSMutableDictionary alloc] init];
    }
    if ([superclassesClassVar objectForKey:key] == nil) {
        NSMutableArray *superclasses = [NSMutableArray array];
        Class currentClass = self;
        while (currentClass != nil) {
            [superclasses addObject:currentClass];
            currentClass = [currentClass superclass];
        }
        [superclassesClassVar setObject:superclasses forKey:key];
    }
    return [superclassesClassVar objectForKey:key];
}


- (NSArray *) senAllSuperclasses
{
    return [[self class] senAllSuperclasses];
}


+ (BOOL) senIsASuperclassOfClass:(Class) aClass
{
    // Some classes don't inherit from NSObject, nor do they implement <NSObject> protocol, thus probably don't respond to @selector(respondsToSelector:)
    // We check if the class responds to @selector(respondsToSelector:) using Objective-C low-level function calls.
    return  (aClass != self) &&
        (class_getClassMethod(aClass, @selector(respondsToSelector:)) != NULL) &&
        [aClass respondsToSelector:@selector(senAllSuperclasses)] &&
        [[aClass senAllSuperclasses] containsObject:self];
}


+ (NSArray *) senAllSubclasses
{
    NSMutableArray *subclasses = [NSMutableArray array];
    NSEnumerator *classEnumerator = [SenTestClassEnumerator classEnumerator];
    id eachClass = nil;

    while ( (eachClass = [classEnumerator nextObject]) ) {
        @try {
            if ([self senIsASuperclassOfClass:eachClass]) {
                [subclasses addObject:eachClass];
            }
        }
        @catch (NSException *anException) {
            //NSLog (([NSString stringWithFormat:@"Skipping %@ (%@)", NSStringFromClass(eachClass), anException]));
        }
    }
    return [subclasses count] == 0 ? nil : subclasses;
}


- (NSArray *) senAllSubclasses
{
    return [[self class] senAllSubclasses];
}


+ (NSArray *) senInstanceInvocations
{
    return [[SenTestInvocationEnumerator instanceInvocationEnumeratorForClass:self] allObjects];
}


+ (NSArray *) senAllInstanceInvocations
{    
    if ([self superclass] == nil) {
        return [self senInstanceInvocations];
    }
    else {
        NSMutableSet *result = [NSMutableSet setWithArray:[[self superclass] senAllInstanceInvocations]];
        [result addObjectsFromArray: [self senInstanceInvocations]];
        return [result allObjects];
    }
}


- (NSArray *) senInstanceInvocations
{
    return [[self class] senInstanceInvocations];
}


- (NSArray *) senAllInstanceInvocations
{
    return [[self class] senAllInstanceInvocations];
}
@end
