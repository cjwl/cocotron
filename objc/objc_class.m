/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "objc_class.h"
#import "objc_sel.h"
#import "objc_protocol.h"
#import "objc_malloc.h"
#import "ObjCException.h"
#import "ObjCModule.h"
#import <Foundation/NSRaiseException.h>
#import <stdio.h>
#import "objc_cache.h"
#import <objc/deprecated.h>
#import <objc/message.h>

#ifdef WIN32
#import <windows.h>
#endif
#ifdef SOLARIS
#import <stdarg.h>
#endif

#import <pthread.h>

static pthread_mutex_t classTableLock=PTHREAD_MUTEX_INITIALIZER;

#define INITIAL_CLASS_HASHTABLE_SIZE	256

static inline OBJCHashTable *OBJCClassTable(void) {
   static OBJCHashTable *allClasses=NULL;

   if(allClasses==NULL)
    allClasses=OBJCCreateHashTable(INITIAL_CLASS_HASHTABLE_SIZE);

   return allClasses;
}

static inline OBJCHashTable *OBJCFutureClassTable(void) {
   static OBJCHashTable *allFutureClasses=NULL;
   
   if(allFutureClasses==NULL)
      allFutureClasses=OBJCCreateHashTable(INITIAL_CLASS_HASHTABLE_SIZE);
   
   return allFutureClasses;
}

id objc_lookUpClass(const char *className) {
   id result;
   
   pthread_mutex_lock(&classTableLock);
   result=OBJCHashValueForKey(OBJCClassTable(),className);
   pthread_mutex_unlock(&classTableLock);
   
   return result;
}

id objc_getClass(const char *name) {
   id result;
   
   // technically, this should call a class lookup callback if class not found (unlike objc_lookUpClass)
   pthread_mutex_lock(&classTableLock);
   result=OBJCHashValueForKey(OBJCClassTable(),name);
   pthread_mutex_unlock(&classTableLock);
   
   return result;
}

int objc_getClassList(Class *buffer,int bufferLen) {
   pthread_mutex_lock(&classTableLock);
   OBJCHashEnumerator classes=OBJCEnumerateHashTable(OBJCClassTable());
   int i=0;
    
   if(buffer!=NULL){
    Class entry;
    
    for(;i<bufferLen && (entry=(Class)OBJCNextHashEnumeratorValue(&classes))!=Nil;i++)
     buffer[i]=entry;
   }
   
   for(;OBJCNextHashEnumeratorValue(&classes)!=0; i++)
    ;
   pthread_mutex_unlock(&classTableLock);
   return i;
}

Class objc_getFutureClass(const char *name) {
   // first find if class is already defined
   struct objc_class* ret=OBJCHashValueForKey(OBJCClassTable(), name);

   // maybe there's a future class
   if(!ret) {
      ret=OBJCHashValueForKey(OBJCFutureClassTable(), name);
   }
   if(!ret) {
      // no future class; build one
      ret=objc_calloc( 1, sizeof(struct objc_class));
      ret->name=strdup(name);
      OBJCHashInsertValueForKey(OBJCFutureClassTable(), ret->name, ret);
   }
   return ret;
}

id objc_getMetaClass(const char *name) {
   Class c=objc_getClass(name);
   return c->isa;
}

id objc_getRequiredClass(const char *name) {
   id result=objc_getClass(name);
   
   if(result==Nil)
    exit(1);
   
   return result;
}

Protocol *objc_getProtocol(const char *name) {
   // UNIMPLEMENTED
   return NULL;
}

Protocol **objc_copyProtocolList(unsigned int *countp) {
   // UNIMPLEMENTED
   return NULL;
}

void objc_addClass(Class class) {
   OBJCRegisterClass(class);
}

void objc_registerClassPair(Class new_class)
{
   objc_addClass( new_class ); 
}

void objc_setFutureClass(Class cls, const char *name) {
   OBJCHashInsertValueForKey(OBJCFutureClassTable(), strdup(name), cls);
}

Class objc_allocateClassPair(Class super_class, const char *name, size_t extraBytes)
{
   struct objc_class * meta_class;
   struct objc_class * new_class;
   struct objc_class * root_class;
	
   // Ensure that the superclass exists and that someone
   // hasn't already implemented a class with the same name
   //
   if (super_class == Nil)
   {
      return Nil;
   }
	
   if (objc_lookUpClass (name) != Nil) 
   {
      return Nil;
   }
	
   // Find the root class
   //
   root_class = super_class;
   while( root_class->super_class != nil )
   {
      root_class = root_class->super_class;
   }
	
   // Allocate space for the class and its metaclass
   //
   new_class = calloc( 2, sizeof(struct objc_class) + extraBytes);
   meta_class = &new_class[1];
	
   // setup class
   new_class->isa      = meta_class;
   new_class->info     = CLS_CLASS;
   meta_class->info    = CLS_META;
	
   // Create a copy of the class name.
   // For efficiency, we have the metaclass and the class itself 
   // to share this copy of the name, but this is not a requirement
   // imposed by the runtime.
   //
   new_class->name = malloc (strlen (name) + 1);
   strcpy ((char*)new_class->name, name);
   meta_class->name = new_class->name;
	
   // Connect the class definition to the class hierarchy:
   // Connect the class to the superclass.
   // Connect the metaclass to the metaclass of the superclass.
   // Connect the metaclass of the metaclass to the metaclass of  the root class.
   //
   new_class->super_class  = super_class;
   meta_class->super_class = super_class->isa;
   meta_class->isa         = (void *)root_class->isa;
	
   // Set the sizes of the class and the metaclass.
   //
   new_class->instance_size = super_class->instance_size;
   meta_class->instance_size = meta_class->super_class->instance_size;

   // Finally, register the class with the runtime.
   //
   return new_class;
}

const char *class_getName(Class cls) {
   return cls->name;
}

BOOL class_isMetaClass(Class class) {
   return (class->info&CLASS_INFO_META)?YES:NO;
}

Class class_getSuperclass(Class class) {
   struct objc_class *cls=class;
   return cls->super_class;
}

int class_getVersion(Class class) {
   struct objc_class *cls=class;
   return (int)(cls->version); // FIXME: NSObject uses NSInteger (long), object format uses log, API is int. wtf. am I missing something?
}

Method class_getClassMethod(Class class, SEL selector)
{
	if (class == Nil) {
     return NULL;   
    }
	return class_getInstanceMethod(class->isa, selector);
}

Ivar class_getClassVariable(Class cls,const char *name) {
   // UNIMPLEMENTED
   return NULL;
}


static inline struct objc_method *OBJCLookupUniqueIdInMethodList(struct objc_method_list *list,SEL uniqueId){
   int i;

   for(i=0;i<list->method_count;i++){
    if(((SEL)list->method_list[i].method_name)==uniqueId)
     return list->method_list+i;
   }

   return NULL;
}

struct objc_method *OBJCLookupUniqueIdInOnlyThisClass(Class class,SEL uniqueId){
   void *iterator=0;
   struct objc_method_list *check;
   struct objc_method     *result=NULL;
   
   while((check = class_nextMethodList(class, &iterator))) {
      if((result=OBJCLookupUniqueIdInMethodList(check,uniqueId))) {
         return result;
      }
   }
   return NULL;
}

struct objc_method *class_getInstanceMethod(Class class,SEL uniqueId) {
   struct objc_method *result=NULL;

   for(;class!=NULL;class=class->super_class){     
    if((result=OBJCLookupUniqueIdInOnlyThisClass(class,uniqueId))!=NULL)
     break;
   }
   return result;
}

size_t class_getInstanceSize(Class class) {
   struct objc_class *cls=class;
   return cls->instance_size;
}

Ivar class_getInstanceVariable(Class class,const char *variableName) {
   for(;;class=class->super_class){
    if(class==Nil)
           break;
    struct objc_ivar_list *ivarList=class->ivars;
    int i;

    for(i=0;ivarList!=NULL && i<ivarList->ivar_count;i++){
     if(strcmp(ivarList->ivar_list[i].ivar_name,variableName)==0)
      return &(ivarList->ivar_list[i]);
    }
   }

   return NULL;
}

const char *class_getIvarLayout(Class cls) {
   // UNIMPLEMENTED
   return NULL;
}

static inline void OBJCInitializeCacheEntryOffset(OBJCMethodCacheEntry *entry){
   entry->offsetToNextEntry=-((intptr_t)entry);
}

// FIXME, better allocator
static inline OBJCMethodCacheEntry *allocateCacheEntry(){
   OBJCMethodCacheEntry *result=objc_malloc(sizeof(OBJCMethodCacheEntry));
   
   OBJCInitializeCacheEntryOffset(result);
   
   return result;
}

static inline void OBJCCacheMethodInClass(Class class,struct objc_method *method) {
   SEL          uniqueId=method->method_name;
   uintptr_t             index=(uintptr_t)uniqueId&OBJCMethodCacheMask;
   OBJCMethodCacheEntry *check=((void *)class->cache->table)+index;

   if(check->method->method_name==NULL)
    check->method=method;
   else {    
      BOOL success=NO;
      while(!success)
      {
         intptr_t offset=0;
          do {
              check=((void *)check)+offset;
              if (method == check->method) {
                  // already cached
                  return;
              }
          } while (offset=check->offsetToNextEntry, ((void *)check)+offset!=NULL);

          OBJCMethodCacheEntry *entry=allocateCacheEntry();
          
          entry->method=method;

         success=__sync_bool_compare_and_swap(&check->offsetToNextEntry, offset, ((void *)entry)-((void *)check));
      }
   }
}

static struct objc_method empty_method={
 0,NULL,NULL
};

static int msg_tracing=0;
static int msgLoggingCount=0;

OBJC_EXPORT void objc_enableMessageLoggingWithCount(int count) {
   msg_tracing=1;
   msgLoggingCount=count;
   
   int   i,capacity=objc_getClassList(NULL,0);
   Class list[capacity];
   
   objc_getClassList(list,capacity);
   
   for(i=0;i<capacity;i++){
    OBJCMethodCache *cache=list[i]->cache;
    int              j;
    
    // FIXME: this leaks because it does not free entries in the linked list
    
    for(j=0;j<OBJCMethodCacheNumberOfEntries;j++){
     OBJCInitializeCacheEntryOffset(cache->table+j);
     cache->table[j].method=&empty_method;
    }
   }

   NSCLog("OBJC msg tracing ENABLED count=%d",count);
}

void OBJCEnableMsgTracing(){
   objc_enableMessageLoggingWithCount(0x7FFFFFFF);
}

void OBJCDisableMsgTracing(){
   msg_tracing=0;
   NSCLog("OBJC msg tracing DISABLED");
}

void objc_logMsgSend(id object,SEL selector){
   msgLoggingCount--;
   if(msgLoggingCount<0)
    msg_tracing=0;
    
   NSCLogThreadId();
   NSCLogFormat("objc_msgSend %x %s self=%p",selector,sel_getName(selector),object);
   NSCLogFormat(" isa %x name %s",(object!=nil)?object->isa:Nil,(object!=nil)?object->isa->name:"");
   NSCLogNewline();
}

void objc_logMsgSendSuper(struct objc_super *super,SEL selector){
   msgLoggingCount--;
   if(msgLoggingCount<0)
    msg_tracing=0;
    
   NSCLogThreadId();
   NSCLogFormat("objc_msgSendSuper %x %s",selector,sel_getName(selector));
   id object=super->receiver;
   NSCLogFormat("self=%p isa %x name %s",object,(object!=nil)?object->isa:Nil,(object!=nil)?object->isa->name:"");
   NSCLogNewline();
}

static inline IMP OBJCLookupAndCacheUniqueIdInClass(Class class,SEL selector){
   struct objc_method *method;

   if((method=class_getInstanceMethod(class,selector))!=NULL){

    // When msg_tracing is on we don't cache the result so there is always a cache miss
    // and we always get the chance to log the msg

    if(!msg_tracing)
     OBJCCacheMethodInClass(class,method);
    
    return method->method_imp;
   }

   return NULL;
}

IMP class_getMethodImplementation(Class cls, SEL selector) {
   return OBJCLookupAndCacheUniqueIdInClass(cls,selector);
}

IMP class_getMethodImplementation_stret(Class cls, SEL selector) {
   return OBJCLookupAndCacheUniqueIdInClass(cls,selector);
}

objc_property_t class_getProperty(Class cls,const char *name) {
   // UNIMPLEMENTED
   return NULL;
}

const char *class_getWeakIvarLayout(Class cls) {
   // UNIMPLEMENTED
   return NULL;
}

Ivar *class_copyIvarList(Class cls,unsigned int *countp) {
    Ivar *result = NULL;
    struct objc_ivar_list *ivars=cls->ivars;
    
    if(countp != NULL) {
        if (ivars != NULL) {
            *countp = ivars->ivar_count;
        }
        else {
            *countp = 0;
        }
    }
    
    if (ivars != NULL) {
        result=malloc(sizeof(Ivar)*ivars->ivar_count);
        
        for(int i=0;i<ivars->ivar_count;i++){
            result[i] = &ivars->ivar_list[i];
        }
    }
    
    return result;
}

Method *class_copyMethodList(Class cls,unsigned int *countp) {
    int methodCount = 0;
    void *iterator = 0;
    struct objc_method_list *list;
    Method *result = NULL;
    int j = 0;
    
    while((list = class_nextMethodList(cls, &iterator)) != NULL)
    {
        methodCount += list->method_count;
    }
    
    if(countp != NULL) {
        *countp = methodCount;
    }
    
    result=malloc(sizeof(Method)*methodCount);
    iterator = 0;
    
    while((list = class_nextMethodList(cls, &iterator)) != NULL)
    {
        int mCount = list->method_count;
        for(int i = 0;i < mCount; i++) {
            result[j] = &list->method_list[i];
            j++;
        }
    }
    
    return result;
}

objc_property_t *class_copyPropertyList(Class cls,unsigned int *countp) {
   struct objc_class_extension *ext=cls->ext;
   
   if(ext==NULL){
    *countp=0;
   return NULL;
}
   if(ext->properties==NULL){
    *countp=0;
    return NULL;
   }

   uint32_t i,propertyCount=ext->properties->prop_count;
   
   if(propertyCount==0){
    *countp=0;
    return NULL;
   }
   
   objc_property_t *result=malloc(sizeof(struct objc_property)*propertyCount);
      
   for(i=0;i<propertyCount;i++){
    result[i]=&(ext->properties->prop_list[i]);
   }
 
   *countp=propertyCount;
   
   return result;
}

Protocol **class_copyProtocolList(Class cls,unsigned int *countp) {
   *countp=0;
   NSCLog("class_copyProtocolList unimplemented");
   // UNIMPLEMENTED
   return NULL;
}

Class class_setSuperclass(Class cls,Class parent) {
   Class result=cls->super_class;
   cls->super_class=parent;
   return result;
}

void class_setVersion(Class class,int version) {
   struct objc_class *cls=class;
   cls->version=version;
}

void class_setIvarLayout(Class cls,const char *layout) {
   // UNIMPLEMENTED
}

void class_setWeakIvarLayout(Class cls,const char *layout) {
   // UNIMPLEMENTED
}

BOOL class_addIvar(Class cls,const char *name,size_t size,uint8_t alignment,const char *type) {
   struct objc_ivar_list *ivars;
   struct objc_ivar *ivar;
   Class class;
   int i, mask;
   char *namecopy, *typecopy;

   if(cls->info&CLS_META) {
     return NO;
   }
   if(objc_lookUpClass(cls->name) != Nil) {
     return NO;
   }
   for(class=cls;(class!=Nil);class=class->super_class){
     ivars=class->ivars;
     if(ivars){
       for(i=0;i<ivars->ivar_count;i++){
         if(strcmp(ivars->ivar_list[i].ivar_name,name)==0){
           return NO;           // name exists
         }
       }
     }
   }
    
   namecopy=malloc(strlen(name)+1);
   if(namecopy==NULL) {
     return NO;
   }
   strcpy(namecopy,name);
   typecopy=malloc(strlen(type)+1);
   if (typecopy==NULL){
     free(namecopy);
     return NO;
   }
   ivars=cls->ivars;

   if(ivars==NULL){
     ivars=(struct objc_ivar_list *)malloc(sizeof(struct objc_ivar_list));
     if(ivars==NULL){
       free(namecopy);
       free(typecopy);
       return NO;
     }
     ivars->ivar_count=1;
     ivar=&(ivars->ivar_list[0]);
   } else {
     i = ivars->ivar_count;
     ivars=(struct objc_ivar_list *)realloc(ivars,sizeof(struct objc_ivar_list)
                                            +(i*sizeof(struct objc_ivar)));
     if(ivars==NULL) {
       free(namecopy);
       free(typecopy);
       return NO;
     }
     ivars->ivar_count=i+1;
     ivar=&(ivars->ivar_list[i]);
   }
   ivar->ivar_name=namecopy;
   ivar->ivar_type=typecopy;
   mask=(1<<alignment)-1;
   i=(cls->instance_size+mask)&~mask;
   ivar->ivar_offset=i;
   cls->instance_size=i+size;
   cls->ivars=ivars;

   return YES;
}

void class_addMethods(Class class,struct objc_method_list *methodList) {
   struct objc_method_list **methodLists=class->methodLists;
   struct objc_method_list **newLists=NULL;
   int i;

   if(!methodLists) {
      // no method list yet: create one
      newLists=calloc(sizeof(struct objc_method_list*), 2);
      newLists[0]=methodList;
   } else {
      // we have a method list: measure it out
      for(i=0; methodLists[i]!=NULL; i++) {
      }
      // allocate new method list array
      newLists=calloc(sizeof(struct objc_method_list*), i+2);
      // copy over
      newLists[0]=methodList;
      for(i=0; methodLists[i]!=NULL; i++) {
         newLists[i+1]=methodLists[i];
      }
   }
   // set new lists
   class->methodLists=newLists;
   // free old ones (FIXME: thread safety)
   if(methodLists)
      free(methodLists);
}

BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types) {
	struct objc_method *newMethod = calloc(sizeof(struct objc_method), 1);
	struct objc_method_list *methodList = calloc(sizeof(struct objc_method_list)+sizeof(struct objc_method), 1);
        char *typescopy = (char *)malloc(strlen(types)+1);
	
	newMethod->method_name = name;
        strcpy(typescopy,(char *)types);
	newMethod->method_types = typescopy;
	newMethod->method_imp = imp;

	methodList->method_count = 1;
	memcpy(methodList->method_list, newMethod, sizeof(struct objc_method));
	free(newMethod);
	class_addMethods(cls, methodList);
	return YES; // TODO: check if method exists
}

BOOL class_addProtocol(Class cls,Protocol *protocol) {
	//TODO: check if protocol already exists
	
	struct objc_protocol_list *protocolList = malloc(sizeof(struct objc_protocol_list));
	protocolList->next = 0;
	protocolList->list[0] = protocol;
    protocolList->count = 1;
	struct objc_protocol_list *protoList = cls->protocols;
	struct objc_protocol_list *lastList = protoList;
	while((protoList=protoList->next) != NULL) {
		lastList = protoList;
	}
	lastList->next = protocolList;
	return YES;
}

BOOL class_conformsToProtocol(Class class,Protocol *protocol) {

   if (class == Nil) {
        return NO;
   }
   for(;;class=class->super_class){
       if(class==Nil)
           break;

    struct objc_protocol_list *protoList=class->protocols;

    for(;protoList!=NULL;protoList=protoList->next){
     int i;

     for(i=0;i<protoList->count;i++){
      if([protoList->list[i] conformsTo:protocol])
       return YES;
     }
    }
   }

   return NO;
}

id class_createInstance(Class cls,size_t extraBytes) {
   // UNIMPLEMENTED
   return NULL;
}

IMP class_replaceMethod(Class cls,SEL selector,IMP imp,const char *types) {
   // UNIMPLEMENTED
   return NULL;
}

BOOL class_respondsToSelector(Class cls,SEL selector) {
   return (class_getInstanceMethod(cls,selector)!=NULL)?YES:NO;
}

static SEL OBJCRegisterMethod(struct objc_method *method) {
   return sel_registerNameNoCopy((const char *)method->method_name);
}

static void OBJCRegisterSelectorsInMethodList(struct objc_method_list *list){
  int i;

  for (i=0;i<list->method_count;i++)
    list->method_list[i].method_name=OBJCRegisterMethod(list->method_list+i);
}

static void OBJCRegisterSelectorsInClass(Class class) {
   struct objc_method_list *cur=NULL;
   
   if(class->info & CLASS_NO_METHOD_ARRAY) {
      // we have been called by via OBJCSymbolTableRegisterClasses; the methodLists pointer really
      // points to a single method list.

      // remember direct-style method lists
      struct objc_method_list *methodLists=(struct objc_method_list *)class->methodLists;
   
      class->methodLists=NULL;
      // just in case this is really an old-style method list setup with a linked list, walk it.
      for(cur=methodLists; cur; cur=cur->obsolete) {
         OBJCRegisterSelectorsInMethodList(cur);
         class_addMethods(class, cur);
      }
      class->info&=~CLASS_NO_METHOD_ARRAY;
   } else {
      // this is a properly setup class; just walk through all method lists and register the selectors
      void *iterator=0;
      while((cur = class_nextMethodList(class, &iterator))) {
         OBJCRegisterSelectorsInMethodList(cur);
      }
      
   }
}

static void OBJCCreateCacheForClass(Class class){
   if(class->cache==NULL){
    int i;
    
    class->cache=objc_calloc(1,sizeof(OBJCMethodCache));
    
    for(i=0;i<OBJCMethodCacheNumberOfEntries;i++){
     OBJCMethodCacheEntry *entry=class->cache->table+i;
     OBJCInitializeCacheEntryOffset(entry);
     entry->method=&empty_method;
    }
   }
}

void OBJCRegisterClass(Class class) {

   {
      struct objc_class* futureClass=OBJCHashValueForKey(OBJCFutureClassTable(), class->name);

      if(futureClass) {
         memcpy(futureClass, class, sizeof(struct objc_class));
         class=futureClass;
      }
   }
   
   pthread_mutex_lock(&classTableLock);
   OBJCHashInsertValueForKey(OBJCClassTable(), class->name, class);
   pthread_mutex_unlock(&classTableLock);
   
   OBJCRegisterSelectorsInClass(class);
   OBJCRegisterSelectorsInClass(class->isa);

   {
    struct objc_protocol_list *protocols;

    for(protocols=class->protocols;protocols!=NULL;protocols=protocols->next){
     unsigned i;

     for(i=0;i<protocols->count;i++){
      OBJCProtocolTemplate *template=(OBJCProtocolTemplate *)protocols->list[i];

      OBJCRegisterProtocol(template);
     }
    }
   }

   OBJCCreateCacheForClass(class);
   OBJCCreateCacheForClass(class->isa);

   if(class->super_class==NULL){
     // Root class
    class->isa->isa=class->isa;
    class->isa->super_class=class;
    class->info|=CLASS_INFO_LINKED;
   }
}

static void OBJCAppendMethodListToClass(Class class, struct objc_method_list *methodList) {
   OBJCRegisterSelectorsInMethodList(methodList);
   class_addMethods(class, methodList);
}

void OBJCRegisterCategoryInClass(Category category,Class class) {
   struct objc_protocol_list *protos;

   if(category->instanceMethods!=NULL)
    OBJCAppendMethodListToClass(class,category->instanceMethods);
   if(category->classMethods!=NULL)
    OBJCAppendMethodListToClass(class->isa,category->classMethods);

   for(protos=category->protocols;protos!=NULL;protos=protos->next){
    unsigned i;
	   
	   for (i=0;i<protos->count;i++) {
		   OBJCRegisterProtocol((OBJCProtocolTemplate *)protos->list[i]);
		   //add protocols from category to class
		   class_addProtocol(class, protos->list[i]);
	   }
   }
}

static void OBJCLinkClass(Class class) {
   if(!(class->info&CLASS_INFO_LINKED)){
    Class superClass=objc_lookUpClass((const char *)class->super_class);
    Class metaRoot=objc_lookUpClass((const char *)class->isa->isa);
	
    if(superClass!=NULL && metaRoot!= NULL){
     class->super_class=superClass;
     class->info|=CLASS_INFO_LINKED;
     class->isa->super_class=class->super_class->isa;
     class->isa->info|=CLASS_INFO_LINKED;
     class->isa->isa=metaRoot->isa;
	}
   }
}

void OBJCLinkClassTable(void) {
   OBJCHashTable *hashTable=OBJCClassTable();
   Class          class;
   OBJCHashEnumerator  state=OBJCEnumerateHashTable(hashTable);

   while((class=OBJCNextHashEnumeratorValue(&state))!=Nil)
    OBJCLinkClass(class);
}

void OBJCInitializeClass(Class class) {
   if(!(class->info&CLASS_INFO_INITIALIZED)){
    if(class->super_class!=NULL)
     OBJCInitializeClass(class->super_class);

    if(!(class->info&CLASS_INFO_INITIALIZED)) {
     SEL         selector=@selector(initialize);
		/* "If a particular class does not implement initialize, the initialize
		 method of its superclass is invoked twice, once for the superclass and 
		 once for the non-implementing subclass." */
     struct objc_method *method=class_getClassMethod(class,selector);

     class->info|=CLASS_INFO_INITIALIZED;
     class->isa->info|=CLASS_INFO_INITIALIZED;

     if(method!=NULL)
      method->method_imp(class,selector);
    }
   }
}

void *objc_forwardHandler=NULL;
void *objc_forwardHandler_stret=NULL;

void objc_setForwardHandler(void *handler,void *handler_stret){
   objc_forwardHandler=handler;
   objc_forwardHandler_stret=handler_stret;
}

IMP OBJCLookupAndCacheUniqueIdForSuper(struct objc_super *super,SEL selector){
   if(msg_tracing)
    objc_logMsgSendSuper(super,selector);

   IMP result = class_getMethodImplementation(super->super_class,selector);

   if(result==NULL){
    result=objc_forwardHandler;
   }
   return result;
}

IMP OBJCInitializeLookupAndCacheUniqueIdForObject(id object,SEL selector){
   if(msg_tracing)
    objc_logMsgSend(object,selector);

   Class class=object->isa;

   if(!(class->info&CLASS_INFO_INITIALIZED)){
    Class checkInit=(class->info&CLASS_INFO_META)?(Class)object:class;
    OBJCInitializeClass(checkInit);
   }
   
   IMP result=class_getMethodImplementation(class,selector);
   
   if(result==NULL){
    result=objc_forwardHandler;
   }
   return result;
}

struct objc_method_list *class_nextMethodList(Class class,void **iterator) {
   int *it=(int*)iterator;
   struct objc_method_list *ret=NULL;
   if(!class->methodLists)
      return NULL;
   
   ret=class->methodLists[*it];
   *it=*it+1;
   
   return ret;
}
