#ifdef CF_ENABLED
#define COREFOUNDATION_INSIDE_BUILD 1
#import <CoreFoundation/CFBase.h>
#import <Foundation/NSRaise.h>

const CFAllocatorRef kCFAllocatorDefault;
const CFAllocatorRef kCFAllocatorSystemDefault;
const CFAllocatorRef kCFAllocatorMalloc;
const CFAllocatorRef kCFAllocatorMallocZone;
const CFAllocatorRef kCFAllocatorNull;
const CFAllocatorRef kCFAllocatorUseContext;

CFAllocatorRef CFAllocatorGetDefault(void){
   NSUnimplementedFunction();
   return 0;
}

void CFAllocatorSetDefault(CFAllocatorRef self){
}

CFTypeID CFAllocatorGetTypeID(void){
   NSUnimplementedFunction();
   return 0;
}

CFAllocatorRef CFAllocatorCreate(CFAllocatorRef self,CFAllocatorContext *context){
   NSUnimplementedFunction();
   return 0;
}

void CFAllocatorGetContext(CFAllocatorRef self,CFAllocatorContext *context){
}
CFIndex CFAllocatorGetPreferredSizeForSize(CFAllocatorRef self,CFIndex size,CFOptionFlags hint){
   NSUnimplementedFunction();
   return 0;
}

void *CFAllocatorAllocate(CFAllocatorRef self,CFIndex size,CFOptionFlags hint){
   NSUnimplementedFunction();
   return 0;
}
void CFAllocatorDeallocate(CFAllocatorRef self,void *ptr){
   NSUnimplementedFunction();
}
void *CFAllocatorReallocate(CFAllocatorRef self,void *ptr,CFIndex size,CFOptionFlags hint){
   NSUnimplementedFunction();
   return 0;
}


CFTypeID CFGetTypeID(CFTypeRef self){
   NSUnimplementedFunction();
   return 0;
}

CFTypeRef CFRetain(CFTypeRef self){
	return (CFTypeRef)[(id) self retain];
}

void CFRelease(CFTypeRef self){
	return [(id) self release];
}
CFIndex CFGetRetainCount(CFTypeRef self){
   return [(id) self retainCount];
   return 0;
}

CFAllocatorRef CFGetAllocator(CFTypeRef self){
   NSUnimplementedFunction();
   return 0;
}

CFHashCode CFHash(CFTypeRef self){
	return [(id)self hash];
}

Boolean CFEqual(CFTypeRef self,CFTypeRef other){
	return [(id) self isEqual:(id)other];
}

CFStringRef CFCopyTypeIDDescription(CFTypeID typeID){
	NSUnimplementedFunction();
	return 0;
}

CFStringRef CFCopyDescription(CFTypeRef self){
   return (CFStringRef)[(id) self description];
}

CFTypeRef CFMakeCollectable(CFTypeRef self){
   //does nothing on cocotron
   return 0;
}
#endif
