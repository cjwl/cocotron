/*$Id: SenTestInvocationEnumerator.m,v 1.3 2005/04/02 03:18:21 phink Exp $*/

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

#import "SenTestInvocationEnumerator.h"

@implementation SenTestInvocationEnumerator

+ (id) instanceInvocationEnumeratorForClass:(Class) aClass
{
    return [[[self alloc] initForClass:aClass] autorelease];
}


- (void) goNextMethodList
{
#if defined (GNUSTEP)
   if (iterator == NULL)
     mlist = iterator = class->methods;
   else
     mlist = iterator = mlist->method_next;
#else
    mlist = class_nextMethodList (class, &iterator);
#endif
    count = (mlist != NULL) ? mlist->method_count - 1 : -1;
}


- (id) initForClass:(Class) aClass
{
    self = [super init];
    class = aClass;
    iterator = NULL;
    [self goNextMethodList];
    return self;
}


- (id) nextObject
{
    if (mlist == NULL) {
        return nil;
    }
    else {
        SEL nextSelector = mlist->method_list[count].method_name;
        count--;
        if (count == -1) {
            [self goNextMethodList];
        }
#if defined (GNUSTEP)
        if (sel_is_mapped(nextSelector)) {
#else
        if (sel_isMapped(nextSelector)) {
#endif
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[class instanceMethodSignatureForSelector:nextSelector]];
            [invocation setSelector:nextSelector];
            return invocation;
        }
        else {
            return [self nextObject];
        }
    }
}

- (NSArray *) allObjects
{
    NSMutableArray *array = [NSMutableArray array];
    id each;

    while ( (each = [self nextObject]) ) {
        [array addObject:each];
    }
    return array;
}

@end
