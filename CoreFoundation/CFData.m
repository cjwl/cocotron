#import <CoreFoundation/CFData.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCFTypeID.h>

@interface __CFMutableData : NSMutableData
@end

static inline NSRange NSRangeFromCFRange(CFRange range){
   NSRange result={range.location,range.length};
   return result;
}

CFTypeID CFDataGetTypeID(void){
   return kNSCFTypeData;
}

CFDataRef CFDataCreate(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length){
   return [[NSData alloc] initWithBytes:bytes length:length];
}

CFDataRef CFDataCreateWithBytesNoCopy(CFAllocatorRef allocator,const uint8_t *bytes,CFIndex length,CFAllocatorRef bytesAllocator){
   NSUnimplementedFunction();
   return 0;
}

CFDataRef CFDataCreateCopy(CFAllocatorRef allocator,CFDataRef self){
   return [self copy];
}

CFIndex CFDataGetLength(CFDataRef self){
   return [self length];
}

const uint8_t *CFDataGetBytePtr(CFDataRef self){
   return [self bytes];
}

void CFDataGetBytes(CFDataRef self,CFRange range,uint8_t *bytes){
   [self getBytes:bytes range:NSRangeFromCFRange(range)];
}

// mutable

CFMutableDataRef CFDataCreateMutable(CFAllocatorRef allocator,CFIndex capacity){
   return [[NSMutableData alloc] initWithCapacity:capacity];
}

CFMutableDataRef CFDataCreateMutableCopy(CFAllocatorRef allocator,CFIndex capacity,CFDataRef other){
   CFMutableDataRef self=CFDataCreateMutable(allocator,capacity);
   
   [self setData:other];

   return self;
}

uint8_t *CFDataGetMutableBytePtr(CFMutableDataRef self){
   return [self mutableBytes];
}

void CFDataSetLength(CFMutableDataRef self,CFIndex length){
   [self setLength:length];
}

void CFDataAppendBytes(CFMutableDataRef self,const uint8_t *bytes,CFIndex length){
   [self appendBytes:bytes length:length];
}

void CFDataDeleteBytes(CFMutableDataRef self,CFRange range){
   [self replaceBytesInRange:NSRangeFromCFRange(range) withBytes:NULL length:0];
}

void CFDataIncreaseLength(CFMutableDataRef self,CFIndex delta){
   [self increaseLengthBy:delta];
}

void CFDataReplaceBytes(CFMutableDataRef self,CFRange range,const uint8_t *bytes,CFIndex length){
   [self replaceBytesInRange:NSRangeFromCFRange(range) withBytes:bytes length:length];
}
