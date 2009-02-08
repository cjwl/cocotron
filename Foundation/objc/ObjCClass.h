/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/ObjCHashTable.h>
#import <Foundation/ObjCTypes.h>
#import <Foundation/ObjCSelector.h>
#import <objc/objc-class.h>

typedef struct OBJCMethodDescriptionList {
   int                    count;
   OBJCMethodDescription list[1];
} OBJCMethodDescriptionList;

FOUNDATION_EXPORT Class OBJCClassFromString(const char *name);
FOUNDATION_EXPORT id objc_getClass(const char *name);
FOUNDATION_EXPORT id objc_getOrigClass(const char *name);
FOUNDATION_EXPORT Class objc_allocateClassPair(Class super_class, const char *name, size_t extraBytes);
FOUNDATION_EXPORT void objc_registerClassPair(Class new_class);

FOUNDATION_EXPORT void OBJCRegisterClass(Class class);
FOUNDATION_EXPORT void OBJCRegisterCategoryInClass(OBJCCategory *category,Class class);

FOUNDATION_EXPORT inline struct objc_method *OBJCLookupUniqueIdInClass(Class class,SEL uniqueId);
FOUNDATION_EXPORT IMP OBJCLookupAndCacheUniqueIdInClass(Class class,SEL uniqueId);
FOUNDATION_EXPORT IMP OBJCInitializeLookupAndCacheUniqueIdForObject(id object,SEL message);

FOUNDATION_EXPORT void OBJCLinkClassTable(void);

BOOL object_cxxConstruct(id self, Class c);
BOOL object_cxxDestruct(id self, Class c);

