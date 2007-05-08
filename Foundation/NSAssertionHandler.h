/* Copyright (c) 2007 Dirk Theisen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

// Just Log the assertion failure for now. Should throw exception.
#define _CTFailAssert(format, val1, val2, val3, val4, val5) NSLog([NSString stringWithFormat: @"NSAssert failed in method '%@': %@", NSStringFromSelector(_cmd), format], val1, val2, val3, val4, val5);

// Just Log the assertion failure for now. Should throw exception.
#define _CTCFailAssert(format, val1, val2, val3, val4, val5) NSLog([NSString stringWithFormat: @"NSCAssert failed: %@", format], val1, val2, val3, val4, val5);


/*
 * Asserts to use in Objective-C methods:
 */

#define NSAssert5(condition, desc, val1, val2, val3, val4, val5) {if (!(condition)) _CTFailAssert((desc), (val1), (val2), (val3), (val4), (val5))}

#define NSAssert4(condition, desc, val1, val2, val3, val4) {if (!(condition)) _CTFailAssert((desc), (val1), (val2), (val3), (val4), 0)}

#define NSAssert3(condition, desc, val1, val2, val3) {if (!(condition)) _CTFailAssert((desc), (val1), (val2), (val3), 0, 0)}

#define NSAssert2(condition, desc, val1, val2) {if (!(condition)) _CTFailAssert((desc), (val1), (val2), 0, 0, 0)}

#define NSAssert1(condition, desc, val1) {if (!(condition)) _CTFailAssert((desc), (val1), 0, 0, 0, 0)}


#define NSAssert(condition, desc) {if (!(condition)) _CTFailAssert((desc), 0, 0, 0, 0, 0)}


#define NSParameterAssert(condition)			\
NSAssert1((condition), @"Invalid parameter not satisfying: %s", #condition)


/*
 * Asserts to use in C function calls:
 */

#define NSCAssert5(condition, desc, val1, val2, val3, val4, val5) {if (!(condition)) _CTCFailAssert((desc), (val1), (val2), (val3), (val4), (val5))}

#define NSCAssert4(condition, desc, val1, val2, val3, val4) {if (!(condition)) _CTCFailAssert((desc), (val1), (val2), (val3), (val4), 0)}

#define NSCAssert3(condition, desc, val1, val2, val3) {if (!(condition)) _CTCFailAssert((desc), (val1), (val2), (val3), 0, 0)}

#define NSCAssert2(condition, desc, val1, val2) {if (!(condition)) _CTCFailAssert((desc), (val1), (val2), 0, 0, 0)}

#define NSCAssert1(condition, desc, val1) {if (!(condition)) _CTCFailAssert((desc), (val1), 0, 0, 0, 0)}


#define NSCAssert(condition, desc) {if (!(condition)) _CTCFailAssert((desc), 0, 0, 0, 0, 0)}


#define NSCParameterAssert(condition)			\
NSCAssert1((condition), @"Invalid parameter not satisfying: %s", #condition)
