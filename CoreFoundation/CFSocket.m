#ifdef CF_ENABLED
#define COREFOUNDATION_INSIDE_BUILD 1
#import <CoreFoundation/CFSocket.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSSocket.h>

#define NSSocketCast(_) ((NSSocket *)_)

CFTypeID CFSocketGetTypeID() {
   return [NSSocket typeID];
}

CFSocketRef CFSocketCreate(CFAllocatorRef allocator,CFInteger protocolFamily,CFInteger socketType,CFInteger protocol,CFOptionFlags flags,CFSocketCallBack callback,const CFSocketContext *context) {
   return [NSSocket createWithAllocator:allocator protocolFamily:protocolFamily type:socketType protocol:protocol options:flags callback:callback context:context];
}

CFSocketRef CFSocketCreateConnectedToSocketSignature(CFAllocatorRef allocator,const CFSocketSignature *signature,CFOptionFlags flags,CFSocketCallBack callback,const CFSocketContext *context,CFTimeInterval timeout) {
   return [NSSocket createConnectedWithAllocator:allocator signature:signature options:flags callback:callback context:context timeout:timeout];
}

CFSocketRef CFSocketCreateWithNative(CFAllocatorRef allocator,CFSocketNativeHandle native,CFOptionFlags flags,CFSocketCallBack callback,const CFSocketContext *context) {
   return [NSSocket createWithAllocator:allocator native:native options:flags callback:callback context:context];
}

CFSocketRef CFSocketCreateWithSocketSignature(CFAllocatorRef allocator,const CFSocketSignature *signature,CFOptionFlags flags,CFSocketCallBack callback,const CFSocketContext *context) {
   return [NSSocket createWithAllocator:allocator signature:signature options:flags callback:callback context:context];
}

CFSocketError CFSocketConnectToAddress(CFSocketRef self,CFDataRef address,CFTimeInterval timeout) {
   return [NSSocketCast(self) connectToAddress:address timeout:timeout];
}

CFDataRef CFSocketCopyAddress(CFSocketRef self) {
   return [NSSocketCast(self) copyPeerAddress];
}

CFDataRef CFSocketCopyPeerAddress(CFSocketRef self) {
   return [NSSocketCast(self) copyPeerAddress];
}

CFRunLoopSourceRef CFSocketCreateRunLoopSource(CFAllocatorRef allocator,CFSocketRef self,CFIndex order) {
   return [NSSocketCast(self) createRunLoopSourceWithAllocator:allocator order:order];
}

void CFSocketDisableCallBacks(CFSocketRef self,CFOptionFlags flags) {
   [NSSocketCast(self) disableCallBacks:flags];
}

void CFSocketEnableCallBacks(CFSocketRef self,CFOptionFlags flags) {
   [NSSocketCast(self) enableCallBacks:flags];
}

void CFSocketGetContext(CFSocketRef self,CFSocketContext *context) {
   [NSSocketCast(self) getContext:context];
}

CFSocketNativeHandle CFSocketGetNative(CFSocketRef self) {
   return [NSSocketCast(self) native];
}

CFOptionFlags CFSocketGetSocketFlags(CFSocketRef self) {
   return [NSSocketCast(self) socketFlags];
}

void CFSocketInvalidate(CFSocketRef self) {
   [NSSocketCast(self) invalidate];
}

Boolean CFSocketIsValid(CFSocketRef self) {
   return [NSSocketCast(self) isValid];
}

CFSocketError CFSocketSendData(CFSocketRef self,CFDataRef address,CFDataRef data,CFTimeInterval timeout) {
   [NSSocketCast(self) sendToAddress:address data:data timeout:timeout];
}

CFSocketError CFSocketSetAddress(CFSocketRef self,CFDataRef address) {
   [NSSocketCast(self) setAddress:address];
}

void CFSocketSetSocketFlags(CFSocketRef self,CFOptionFlags flags) {
   [NSSocketCast(self) setSocketFlags:flags];
}

#endif
