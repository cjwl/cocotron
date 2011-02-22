/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/objc.h>
#import <stdarg.h>
#import <stdint.h>
#import <limits.h>

#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(FOUNDATION_INSIDE_BUILD)
#define FOUNDATION_EXPORT extern "C" __declspec(dllexport)
#else
#define FOUNDATION_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define FOUNDATION_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(FOUNDATION_INSIDE_BUILD)
#define FOUNDATION_EXPORT __declspec(dllexport) extern
#else
#define FOUNDATION_EXPORT __declspec(dllimport) extern
#endif
#else
#define FOUNDATION_EXPORT extern
#endif

#endif

#define NS_INLINE static inline

@class NSString;

#define NSINTEGER_DEFINED 1

#if defined(__LP64__)
    typedef long          NSInteger;
    typedef unsigned long NSUInteger;
    #define NSIntegerMax  LONG_MAX
    #define NSIntegerMin  LONG_MIN
    #define NSUIntegerMax ULONG_MAX
#else
    typedef int           NSInteger;
    typedef unsigned int  NSUInteger;
    #define NSIntegerMax  INT_MAX
    #define NSIntegerMin  INT_MIN
    #define NSUIntegerMax UINT_MAX
#endif

enum {
   NSOrderedAscending=-1,
   NSOrderedSame=0,
   NSOrderedDescending=1
};

typedef NSInteger NSComparisonResult;

#define NSNotFound NSIntegerMax

#ifndef MIN
#define MIN(a,b) ({__typeof__(a) _a = (a); __typeof__(b) _b = (b); (_a < _b) ? _a : _b; })
#else
#warning MIN is already defined, MIN(a, b) may not behave as expected.
#endif
  
#ifndef MAX
#define MAX(a,b) ({__typeof__(a) _a = (a); __typeof__(b) _b = (b); (_a > _b) ? _a : _b; })
#else
#warning MAX is already defined, MAX(a, b) may not not behave as expected.
#endif

#ifndef ABS
#define ABS(a) ({__typeof__(a) _a = (a); (_a < 0) ? -_a : _a; })
#else
#warning ABS is already defined, ABS(a) may not behave as expected.
#endif

FOUNDATION_EXPORT void NSLog(NSString *format,...);
FOUNDATION_EXPORT void NSLogv(NSString *format,va_list args);

FOUNDATION_EXPORT const char *NSGetSizeAndAlignment(const char *type,NSUInteger *size,NSUInteger *alignment);

FOUNDATION_EXPORT SEL NSSelectorFromString(NSString *selectorName);
FOUNDATION_EXPORT NSString *NSStringFromSelector(SEL selector);

FOUNDATION_EXPORT Class NSClassFromString(NSString *className);
FOUNDATION_EXPORT NSString *NSStringFromClass(Class aClass);




