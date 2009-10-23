#ifdef CF_ENABLED
#define COREFOUNDATION_INSIDE_BUILD 1
#import <CoreFoundation/CFData.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSCFTypeID.h>

CFTypeID CFDataGetTypeID(void){
   return kNSCFTypeData;
}

CFDataRef CFDataCreate(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length){
   NSUnimplementedFunction();
   return 0;
}

CFDataRef CFDataCreateWithBytesNoCopy(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFAllocatorRef bytesAllocator){
   NSUnimplementedFunction();
   return 0;
}

CFDataRef CFDataCreateCopy(CFAllocatorRef allocator,CFDataRef self){
   NSUnimplementedFunction();
   return 0;
}

CFIndex CFDataGetLength(CFDataRef self){
   NSUnimplementedFunction();
   return 0;
}

const uint8_t *CFDataGetBytePtr(CFDataRef self){
   NSUnimplementedFunction();
   return 0;
}

void CFDataGetBytes(CFDataRef self,CFRange range,uint8_t *bytes){
   NSUnimplementedFunction();
}

// mutable

CFMutableDataRef CFDataCreateMutable(CFAllocatorRef allocator,CFIndex capacity){
   NSUnimplementedFunction();
   return 0;
}

CFMutableDataRef CFDataCreateMutableCopy(CFAllocatorRef allocator,CFIndex capacity,CFDataRef self){
   NSUnimplementedFunction();
   return 0;
}

uint8_t *CFDataGetMutableBytePtr(CFMutableDataRef self){
   NSUnimplementedFunction();
   return 0;
}

void CFDataSetLength(CFMutableDataRef self,CFIndex length){
   NSUnimplementedFunction();
}

void CFDataAppendBytes(CFMutableDataRef self,const uint8_t *bytes,CFIndex length){
   NSUnimplementedFunction();
}

void CFDataDeleteBytes(CFMutableDataRef self,CFRange range){
   NSUnimplementedFunction();
}

void CFDataIncreaseLength(CFMutableDataRef self,CFIndex delta){
   NSUnimplementedFunction();
}

void CFDataReplaceBytes(CFMutableDataRef self,CFRange range,const uint8_t *bytes,CFIndex length){
   NSUnimplementedFunction();
}
#endif
