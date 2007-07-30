/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/ObjectiveC.h>
#import <stdarg.h>

@class NSString;

typedef enum {
   NSOrderedAscending=-1,
   NSOrderedSame=0,
   NSOrderedDescending=1
} NSComparisonResult;

FOUNDATION_EXPORT const unsigned NSNotFound;

#define MIN(a,b) ((a)<(b)?(a):(b))
#define MAX(a,b) ((a)>(b)?(a):(b))
#define ABS(a)   ((a)<0?(-(a)):(a))

FOUNDATION_EXPORT void NSLog(NSString *format,...);
FOUNDATION_EXPORT void NSLogv(NSString *format,va_list args);

FOUNDATION_EXPORT const char *NSGetSizeAndAlignment(const char *type,unsigned *size,
  unsigned *alignment);

FOUNDATION_EXPORT SEL NSSelectorFromString(NSString *selectorName);
FOUNDATION_EXPORT NSString *NSStringFromSelector(SEL selector);

FOUNDATION_EXPORT Class NSClassFromString(NSString *className);
FOUNDATION_EXPORT NSString *NSStringFromClass(Class aClass);




