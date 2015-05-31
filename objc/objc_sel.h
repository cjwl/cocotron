/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/objc.h>
#import <objc/objc-class.h>

OBJC_EXPORT const char *sel_registerNameNoCopy(const char *name);

OBJC_EXPORT SEL sel_registerSelectorNoCopyName(const char *name);

#ifdef OBJC_TYPED_SELECTORS

typedef struct {
    const char *name;
    const char *types;
} objc_selector_internal;

static inline const char *objc_getSelectorReferenceName(objc_selector_internal *ref) {
    return ref->name;
}

static inline void objc_setSelectorReferenceName(objc_selector_internal **ref, const char *name) {
    (*ref)->name = name;
}

static inline SEL sel_getSelector(SEL selector) {
    if(selector == NULL)
        return selector;

    struct {
        SEL selector;
    } *typed = (void *)selector;

    return typed->selector;
}

#else

typedef SEL objc_selector_internal;

static inline const char *objc_getSelectorReferenceName(objc_selector_internal *ref) {
    return (const char *)(*ref);
}

static inline void objc_setSelectorReferenceName(objc_selector_internal **ref, const char *name) {
    **ref = (objc_selector_internal)name;
}

static inline SEL sel_getSelector(SEL selector) {
    return selector;
}

#endif
