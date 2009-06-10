#ifdef CF_ENABLED
#define COREFOUNDATION_INSIDE_BUILD 1
#import <CoreFoundation/CFDictionary.h>
#import <Foundation/NSRaise.h>

CFTypeID CFDictionaryGetTypeID(void){
   NSUnimplementedFunction();
   return 0;
}

CFDictionaryRef CFDictionaryCreate(CFAllocatorRef allocator,const void **keys,const void **values,CFIndex count,const CFDictionaryKeyCallBacks *keyCallbacks,const CFDictionaryValueCallBacks *valueCallbacks){
   NSUnimplementedFunction();
   return 0;
}

CFDictionaryRef CFDictionaryCreateCopy(CFAllocatorRef allocator,CFDictionaryRef self){
   NSUnimplementedFunction();
   return 0;
}

void CFDictionaryApplyFunction(CFDictionaryRef self,CFDictionaryApplierFunction function,void *context){
   NSUnimplementedFunction();
}

Boolean CFDictionaryContainsKey(CFDictionaryRef self,const void *key){
   NSUnimplementedFunction();
   return 0;
}

Boolean CFDictionaryContainsValue(CFDictionaryRef self,const void *value){
   NSUnimplementedFunction();
   return 0;
}

CFIndex CFDictionaryGetCount(CFDictionaryRef self){
   NSUnimplementedFunction();
   return 0;
}

CFIndex CFDictionaryGetCountOfKey(CFDictionaryRef self,const void *key){
   NSUnimplementedFunction();
   return 0;
}

CFIndex CFDictionaryGetCountOfValue(CFDictionaryRef self,const void *value){
   NSUnimplementedFunction();
   return 0;
}

void CFDictionaryGetKeysAndValues(CFDictionaryRef self,const void **keys,const void **values){
   NSUnimplementedFunction();
}

const void *CFDictionaryGetValue(CFDictionaryRef self,const void *key){
   NSUnimplementedFunction();
   return 0;
}

Boolean CFDictionaryGetValueIfPresent(CFDictionaryRef self,const void *key,const void **value){
   NSUnimplementedFunction();
   return 0;
}

CFMutableDictionaryRef CFDictionaryCreateMutable(CFAllocatorRef allocator,CFIndex capacity,const CFDictionaryKeyCallBacks *keyCallbacks,const CFDictionaryValueCallBacks *valueCallbacks){
   NSUnimplementedFunction();
   return 0;
}

CFMutableDictionaryRef CFDictionaryCreateMutableCopy(CFAllocatorRef allocator,CFIndex capacity,CFDictionaryRef self){
   NSUnimplementedFunction();
   return 0;
}

void CFDictionaryAddValue(CFMutableDictionaryRef self,const void *key,const void *value){
   NSUnimplementedFunction();
}

void CFDictionaryRemoveAllValues(CFMutableDictionaryRef self){
   NSUnimplementedFunction();
}

void CFDictionaryRemoveValue(CFMutableDictionaryRef self,const void *key){
   NSUnimplementedFunction();
}

void CFDictionaryReplaceValue(CFMutableDictionaryRef self,const void *key,const void *value){
   NSUnimplementedFunction();
}

void CFDictionarySetValue(CFMutableDictionaryRef self,const void *key,const void *value){
   NSUnimplementedFunction();
}
#endif
