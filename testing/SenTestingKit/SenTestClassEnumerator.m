/*$Id: SenTestClassEnumerator.m,v 1.3 2005/04/02 03:18:20 phink Exp $*/

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

#import "SenTestClassEnumerator.h"

#ifndef RHAPSODY
#import <objc/objc-runtime.h>
#endif

@implementation SenTestClassEnumerator

+ (NSEnumerator *) classEnumerator
{
    return [[[self alloc] init] autorelease];
}


#if defined (GNUSTEP)
- (id) init
{
    self = [super init];
    state = NULL;
    isAtEnd = NO;
    return self;
}


- (id) nextObject
{
    if (isAtEnd) {
        return nil;
    } 
	else {
        Class nextClass = objc_next_class(&state);
		if (nextClass == Nil) {
			isAtEnd = YES;
		}
		return isAtEnd ? nil : nextClass;
    }
}


#elif defined (RHAPSODY)
- (id) init
{
    [super init];
    class_hash = objc_getClasses();
    state = NXInitHashState(class_hash);
    isAtEnd = NO;
    return self;
}


- (id) nextObject
{
    if (isAtEnd) {
        return nil;
    } 
	else {
        Class nextClass = Nil;
		isAtEnd = !NXNextHashState(class_hash, &state, (void **) &nextClass);
		return isAtEnd ? nil : nextClass;
    }
}

#else  
// Mac OS X
- (NSSet *) rejectedClassNames
{
	static NSSet *rejectedClassNames = nil;
	if (rejectedClassNames == nil) {
		rejectedClassNames = [[NSSet setWithObjects:@"WOResourceManager", @"Object", @"List", @"Protocol", nil] retain];
	}
	return rejectedClassNames;
}


- (BOOL) isValidClass:(Class) aClass
{
	return (class_getClassMethod (aClass, @selector(description)) != NULL) 
	&& (class_getClassMethod (aClass, @selector(conformsToProtocol:)) != NULL)
	&& (class_getClassMethod (aClass, @selector(superclass)) != NULL)
	&& (class_getClassMethod (aClass, @selector(isKindOfClass:)) != NULL)
	&& ![[self rejectedClassNames] containsObject:NSStringFromClass (aClass)];
}


- (id) init
{
    int	numberOfClasses = objc_getClassList (NULL, 0);
	currentIndex = 0;
	[super init];
	
	if (numberOfClasses > 0) {
		Class *classList = malloc (sizeof (Class) * numberOfClasses);
		(void) objc_getClassList (classList, numberOfClasses);
		
		classes = [[NSMutableArray alloc] initWithCapacity:numberOfClasses];
		while (numberOfClasses--) {
			Class eachClass = classList[numberOfClasses];
			if ([self isValidClass:eachClass]) {
				[classes addObject:eachClass];
			} 
		}
		free (classList);
		isAtEnd = [classes count] == 0;
	} 
	else {
		isAtEnd = YES;
	}
	
    return self;
}


- (id) nextObject
{
    if (isAtEnd) {
        return nil;
    } 
	else {
        Class nextClass = Nil;
		isAtEnd = (currentIndex >= [classes count]);
		if(!isAtEnd) {
			nextClass = [classes objectAtIndex:currentIndex++];
		}
		return isAtEnd ? nil : nextClass;
    }
}


- (void) dealloc
{
	[classes release];
    [super dealloc];
}
#endif    

@end
