#ifdef CF_ENABLED
#define COREFOUNDATION_INSIDE_BUILD 1
#import <CoreFoundation/CFBinaryHeap.h>
#import <Foundation/NSRaise.h>

const CFBinaryHeapCallBacks kCFStringBinaryHeapCallBacks={
};

CFTypeID CFBinaryHeapGetTypeID(void){
   NSUnimplementedFunction();
   return 0;
}

void CFBinaryHeapAddValue(CFBinaryHeapRef self,const void *value){
   NSUnimplementedFunction();
}

void CFBinaryHeapApplyFunction(CFBinaryHeapRef self,CFBinaryHeapApplierFunction function,void *context){
   NSUnimplementedFunction();
}

Boolean CFBinaryHeapContainsValue(CFBinaryHeapRef self,const void *value){
   NSUnimplementedFunction();
   return 0;
}

CFBinaryHeapRef CFBinaryHeapCreate(CFAllocatorRef allocator,CFIndex capacity,const CFBinaryHeapCallBacks *callbacks,const CFBinaryHeapCompareContext *context){
   NSUnimplementedFunction();
   return 0;
}

CFBinaryHeapRef CFBinaryHeapCreateCopy(CFAllocatorRef allocator,CFIndex capacity,CFBinaryHeapRef self){
   NSUnimplementedFunction();
   return 0;
}

CFIndex CFBinaryHeapGetCount(CFBinaryHeapRef self){
   NSUnimplementedFunction();
   return 0;
}

CFIndex CFBinaryHeapGetCountOfValue(CFBinaryHeapRef self,const void *value){
   NSUnimplementedFunction();
   return 0;
}

const void *CFBinaryHeapGetMinimum(CFBinaryHeapRef self){
   NSUnimplementedFunction();
   return 0;
}

Boolean CFBinaryHeapGetMinimumIfPresent(CFBinaryHeapRef self,const void **valuep){
   NSUnimplementedFunction();
   return 0;
}

void CFBinaryHeapGetValues(CFBinaryHeapRef self,const void **values){
   NSUnimplementedFunction();
}

void CFBinaryHeapRemoveAllValues(CFBinaryHeapRef self){
   NSUnimplementedFunction();
}

void CFBinaryHeapRemoveMinimumValue(CFBinaryHeapRef self){
   NSUnimplementedFunction();
}
#endif
