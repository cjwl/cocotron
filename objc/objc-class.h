/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/objc-export.h>
#import <objc/objc.h>
#import <stdint.h>

enum {
   _C_ID='@',
   _C_CHR='c',
   _C_UCHR='C',
   _C_INT='i',
   _C_UINT='I',
   _C_FLT='f',
   _C_DBL='d',
   _C_VOID='v',
   _C_UNDEF='?',
   _C_CLASS='#',
   _C_SEL=':',
   _C_CHARPTR='*',
   _C_SHT='s',
   _C_USHT='S',
   _C_LNG='l',
   _C_ULNG='L',
   _C_LNGLNG='q',
   _C_LNG_LNG=_C_LNGLNG,
   _C_ULNGLNG='Q',
   _C_ULNG_LNG=_C_ULNGLNG,
   _C_BFLD='b',
   _C_ARY_B='[',
   _C_STRUCT_B='{',
   _C_UNION_B='(',
   _C_ARY_E=']',
   _C_STRUCT_E='}',
   _C_UNION_E=')',
   _C_PTR='^',
   _C_CONST='r',
   _C_IN='n',
   _C_INOUT='N',
   _C_OUT='o',
   _C_BYCOPY='R',
   _C_ONEWAY='V',
};

struct objc_ivar {
   char *ivar_name;
   char *ivar_type;
   int   ivar_offset;
};

struct objc_ivar_list {
   int              ivar_count;
   struct objc_ivar ivar_list[1];
};

struct objc_method {
   SEL   method_name;
   char *method_types;
   IMP   method_imp;
};

struct objc_method_description {
   SEL   name;
   char *types;
};

struct objc_method_list {
   struct objc_method_list *obsolete;
   int                      method_count;
   struct objc_method       method_list[1]; 
};

@class Protocol;

struct objc_protocol_list {
    struct objc_protocol_list *next;
    int                        count;
    Protocol                  *list[1];
};

struct objc_category {
   const char       *name;
   const char       *className;
   struct objc_method_list   *instanceMethods;
   struct objc_method_list   *classMethods;
   struct objc_protocol_list *protocols;
};

struct objc_property {
   const char * const name;
   const char * const attributes;
};

struct objc_prop_list_t {
   uint32_t size;
   uint32_t prop_count;
   struct objc_property prop_list [1];
};

struct objc_class_extension {
   uint32_t             size;
   const char          *weak_ivar_layout;
   struct objc_prop_list_t *properties;
};

struct objc_class {			
   struct objc_class        *isa;	
   struct objc_class        *super_class;	
   const char               *name;		
   long                      version;
   long                      info;
   long                      instance_size;
   struct objc_ivar_list    *ivars;
   struct objc_method_list **methodLists;
   struct objc_cache        *cache;
   struct objc_protocol_list *protocols;
   const char *ivar_layout;
   struct objc_class_extension  *ext;
};

