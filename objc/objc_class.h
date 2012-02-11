/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "ObjCHashTable.h"
#import <objc/objc.h>
#import "objc_sel.h"
#import <objc/runtime.h>
#import <objc/message.h>

enum {
   CLASS_INFO_CLASS=0x001,
   CLS_CLASS=CLASS_INFO_CLASS,
   CLASS_INFO_META=0x002,
   CLS_META=CLASS_INFO_META,
   CLASS_INFO_INITIALIZED=0x004,
   CLASS_INFO_POSING=0x008,
   CLASS_INFO_LINKED=0x100,
   CLASS_HAS_CXX_STRUCTORS=0x2000,
   CLASS_NO_METHOD_ARRAY=0x4000
};

typedef struct OBJCMethodDescriptionList {
   int                    count;
   struct objc_method_description list[1];
} OBJCMethodDescriptionList;

OBJC_EXPORT void OBJCRegisterClass(Class class);
OBJC_EXPORT void OBJCRegisterCategoryInClass(Category category,Class class);

struct objc_method *OBJCLookupUniqueIdInOnlyThisClass(Class class,SEL uniqueId);
OBJC_EXPORT IMP OBJCInitializeLookupAndCacheUniqueIdForObject(id object,SEL message);
OBJC_EXPORT IMP OBJCLookupAndCacheUniqueIdForSuper(struct objc_super *super,SEL selector);

OBJC_EXPORT void OBJCLinkClassTable(void);

BOOL object_cxxConstruct(id self, Class c);
BOOL object_cxxDestruct(id self, Class c);

