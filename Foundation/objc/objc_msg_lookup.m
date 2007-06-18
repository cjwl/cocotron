/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/ObjCClass.h>
#import <Foundation/ObjectiveC.h>
#import "objc_cache.h"

static int msg_tracing=0;

void OBJCEnableMsgTracing(){
  msg_tracing=1;
  OBJCLog("OBJC msg tracing ENABLED");
}
void OBJCDisableMsgTracing(){
  msg_tracing=0;
  OBJCLog("OBJC msg tracing DISABLED");
}

IMP objc_msg_lookup(id object,SEL selector) {
   
   if(msg_tracing)
    OBJCLog("objc_msg_lookup %x %s isa %x name %s",selector,sel_getName(selector),(object!=nil)?object->isa:Nil,(object!=nil)?object->isa->name:"");

   if(object!=nil){
    OBJCMethodCache      *cache=object->isa->cache;
    unsigned              index=(unsigned)selector&OBJCMethodCacheMask;
    OBJCMethodCacheEntry *checkEntry=((void *)cache->table)+index; 

    do{
     OBJCMethod *check=checkEntry->method;
     
     if(((SEL)check->method_name)==selector)
      return check->method_imp;

     checkEntry=((void *)checkEntry)+checkEntry->offsetToNextEntry;
    }while(checkEntry!=NULL);
   }

   return OBJCInitializeLookupAndCacheUniqueIdForObject(object,selector);
}

IMP objc_msg_lookup_super(struct objc_super *super,SEL selector) {
    unsigned              index=(unsigned)selector&OBJCMethodCacheMask;
    OBJCMethodCacheEntry *checkEntry=((void *)super->class->cache->table)+index; 

   do{
     OBJCMethod *check=checkEntry->method;
     
     if(((SEL)check->method_name)==selector)
      return check->method_imp;

     checkEntry=((void *)checkEntry)+checkEntry->offsetToNextEntry;
    }while(checkEntry!=NULL);

   return OBJCLookupAndCacheUniqueIdInClass(super->class,selector);
}
