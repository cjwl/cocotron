#import <CoreFoundation/CFUUID.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSCFTypeID.h>


CFTypeID CFUUIDGetTypeID(void){
   return kNSCFTypeUUID;
}

CFUUIDRef CFUUIDCreate(CFAllocatorRef alloc){
   NSUnimplementedFunction();
   return 0;
}

CFUUIDRef CFUUIDCreateFromString(CFAllocatorRef allocator,CFStringRef string){
   NSUnimplementedFunction();
   return 0;
}

CFUUIDRef CFUUIDCreateFromUUIDBytes(CFAllocatorRef allocator,CFUUIDBytes bytes){
   NSUnimplementedFunction();
   return 0;
}

CFUUIDRef CFUUIDCreateWithBytes(CFAllocatorRef allocator,uint8_t byte0,uint8_t byte1,uint8_t byte2,uint8_t byte3,uint8_t byte4,uint8_t byte5,uint8_t byte6,uint8_t byte7,uint8_t byte8,uint8_t byte9,uint8_t byte10,uint8_t byte11,uint8_t byte12,uint8_t byte13,uint8_t byte14,uint8_t byte15){
   NSUnimplementedFunction();
   return 0;
}

CFUUIDRef CFUUIDGetConstantUUIDWithBytes(CFAllocatorRef allocator,uint8_t byte0,uint8_t byte1,uint8_t byte2,uint8_t byte3,uint8_t byte4,uint8_t byte5,uint8_t byte6,uint8_t byte7,uint8_t byte8,uint8_t byte9,uint8_t byte10,uint8_t byte11,uint8_t byte12,uint8_t byte13,uint8_t byte14,uint8_t byte15){
   NSUnimplementedFunction();
   return 0;
}

CFUUIDBytes CFUUIDGetUUIDBytes(CFUUIDRef self){
   NSUnimplementedFunction();
   CFUUIDBytes result;
   return result;
}

CFStringRef CFUUIDCreateString(CFAllocatorRef allocator,CFUUIDRef self){
   NSUnimplementedFunction();
   return 0;
}
