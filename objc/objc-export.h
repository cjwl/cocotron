/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <stdlib.h>

#ifdef __clang__
#define OBJC_DLLEXPORT
#define OBJC_DLLIMPORT

#ifndef __APPLE__
#define OBJC_TYPED_SELECTORS 1
#endif

#else
#define OBJC_DLLEXPORT __declspec(dllexport)
#define OBJC_DLLIMPORT __declspec(dllimport)
#endif

#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(OBJC_INSIDE_BUILD)
#define OBJC_EXPORT extern "C" OBJC_DLLEXPORT
#else
#define OBJC_EXPORT extern "C" OBJC_DLLEXPORT
#endif
#else
#define OBJC_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(OBJC_INSIDE_BUILD)
#define OBJC_EXPORT OBJC_DLLEXPORT extern
#else
#define OBJC_EXPORT OBJC_DLLIMPORT extern
#endif
#else
#define OBJC_EXPORT extern
#endif

#endif
