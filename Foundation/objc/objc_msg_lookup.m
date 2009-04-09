/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/objc_forward_ffi.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "objc_cache.h"
#import "objc_class.h"
#import <Foundation/ObjCException.h>

extern void *objc_forwardHandler;
extern void *objc_forwardHandler_stret;

static int msg_tracing=0;

void OBJCEnableMsgTracing(){
  msg_tracing=1;
  OBJCLog("OBJC msg tracing ENABLED");
}
void OBJCDisableMsgTracing(){
  msg_tracing=0;
  OBJCLog("OBJC msg tracing DISABLED");
}

static id nil_message(id object,SEL message,...){
   return nil;
}

IMP objc_msg_lookup(id object,SEL selector) {
   if(object==nil)
      return nil_message;
   
   if(msg_tracing){
    OBJCPartialLog("objc_msg_lookup %x %s",selector,sel_getName(selector));
    OBJCFinishLog(" isa %x name %s",(object!=nil)?object->isa:Nil,(object!=nil)?object->isa->name:"");
   }
   {
    OBJCMethodCache      *cache=object->isa->cache;
    unsigned              index=(unsigned)selector&OBJCMethodCacheMask;
    OBJCMethodCacheEntry *checkEntry=((void *)cache->table)+index; 

    do{
     struct objc_method *check=checkEntry->method;
     
     if(((SEL)check->method_name)==selector)
      return check->method_imp;

     checkEntry=((void *)checkEntry)+checkEntry->offsetToNextEntry;
    }while(checkEntry!=NULL);
   }

   IMP ret = OBJCInitializeLookupAndCacheUniqueIdForObject(object,selector);
	if(!ret)
   {
#ifdef HAVE_LIBFFI
		ret=objc_forward_ffi(object, selector);
#else
      ret=objc_forwardHandler;
#endif
   }
	return ret;
}

IMP objc_msg_lookup_super(struct objc_super *super,SEL selector) {
    unsigned              index=(unsigned)selector&OBJCMethodCacheMask;
    OBJCMethodCacheEntry *checkEntry=((void *)super->super_class->cache->table)+index; 

   do{
     struct objc_method *check=checkEntry->method;
     
     if(((SEL)check->method_name)==selector)
      return check->method_imp;

     checkEntry=((void *)checkEntry)+checkEntry->offsetToNextEntry;
    }while(checkEntry!=NULL);

   IMP ret = OBJCLookupAndCacheUniqueIdInClass(super->super_class,selector);
   if(!ret)
   {
#ifdef HAVE_LIBFFI
		ret=objc_forward_ffi(super->receiver, selector);
#else
      ret=objc_forwardHandler;
#endif
   }
   return ret;
}
