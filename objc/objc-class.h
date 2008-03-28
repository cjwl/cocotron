/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/objc-export.h>
#import <objc/objc.h>

enum {
   CLASS_INFO_CLASS=0x001,
   CLS_CLASS=CLASS_INFO_CLASS,
   CLASS_INFO_META=0x002,
   CLS_META=CLASS_INFO_META,
   CLASS_INFO_INITIALIZED=0x004,
   CLASS_INFO_POSING=0x008,
   CLASS_INFO_LINKED=0x100,
   CLASS_HAS_CXX_STRUCTORS=0x2000
};

enum {
 _C_ID='@',
 _C_CHR='c',
 _C_UCHR='C',
 _C_INT='i',
 _C_UINT='I',
 _C_FLT='f',
 _C_DBL='d',
};

typedef struct objc_ivar {
   char *ivar_name;
   char *ivar_type;
   int   ivar_offset;
} *Ivar, OBJCInstanceVariable;

struct objc_ivar_list {
   int              ivar_count;
   struct objc_ivar ivar_list[1];
};

typedef struct objc_method {
   SEL   method_name;
   char *method_types;
   IMP   method_imp;
} *Method;

struct objc_method_list {
   struct objc_method_list *method_next;
   int                      method_count;
   struct objc_method       method_list[1]; 
};

@class Protocol;

typedef struct OBJCProtocolList {
    struct OBJCProtocolList *next;
    int                      count;
    Protocol                *list[1];
} OBJCProtocolList;

typedef struct {
   const char       *name;
   const char       *className;
   struct objc_method_list   *instanceMethods;
   struct objc_method_list   *classMethods;
   OBJCProtocolList *protocols;
} OBJCCategory;

typedef struct objc_class {			
   struct objc_class        *isa;	
   struct objc_class        *super_class;	
   const char               *name;		
   long                      version;
   long                      info;
   long                      instance_size;
   struct objc_ivar_list    *ivars;
   struct objc_method_list           *methodLists;
   struct objc_cache        *cache;
   OBJCProtocolList         *protocols;
   void                     *privateData;
} OBJCClassTemplate;

OBJC_EXPORT Ivar class_getInstanceVariable(Class class,const char *variableName);
OBJC_EXPORT void class_addMethods(Class class,struct objc_method_list *methodList);

OBJC_EXPORT struct objc_method_list *class_nextMethodList(Class class,void **iterator);
