/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/runtime.h>
#import <objc/message.h>
#import "objc_cache.h"
#import "objc_class.h"
#import "ObjCException.h"

//we must return a 64 bit type for clearing both registers (32 bit systems)
static unsigned long long nil_message(id object,SEL message,...) {
   return 0;
}

IMP objc_msg_lookup(id object,SEL selector) {
   if(object==nil)
    return (IMP)nil_message;
   else {
    OBJCMethodCache      *cache=object->isa->cache;
    uintptr_t              index=(uintptr_t)selector&OBJCMethodCacheMask;
    OBJCMethodCacheEntry *checkEntry=((void *)cache->table)+index; 

    do{
     struct objc_method *check=checkEntry->method;
     
     if(((SEL)check->method_name)==selector)
      return check->method_imp;

     checkEntry=((void *)checkEntry)+checkEntry->offsetToNextEntry;
    }while(checkEntry!=NULL);
   }

   return OBJCInitializeLookupAndCacheUniqueIdForObject(object,selector);
}

IMP objc_msg_lookup_super(struct objc_super *super,SEL selector) {
    uintptr_t              index=(uintptr_t)selector&OBJCMethodCacheMask;
    OBJCMethodCacheEntry *checkEntry=((void *)super->super_class->cache->table)+index; 

   do{
     struct objc_method *check=checkEntry->method;
     
     if(((SEL)check->method_name)==selector)
      return check->method_imp;

     checkEntry=((void *)checkEntry)+checkEntry->offsetToNextEntry;
    }while(checkEntry!=NULL);

   return OBJCLookupAndCacheUniqueIdForSuper(super,selector);
}
