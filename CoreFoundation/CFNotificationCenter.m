#import <CoreFoundation/CFNotificationCenter.h>
#import <Foundation/NSRaise.h>

CFTypeID CFNotificationCenterGetTypeID(void){
   NSUnimplementedFunction();
   return 0;
}

CFNotificationCenterRef CFNotificationCenterGetLocalCenter(void){
   NSUnimplementedFunction();
   return 0;
}

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void){
   NSUnimplementedFunction();
   return 0;
}

void CFNotificationCenterAddObserver(CFNotificationCenterRef self,const void *observer,CFNotificationCallback callback,CFStringRef name,const void *object,CFNotificationSuspensionBehavior suspensionBehavior){
   NSUnimplementedFunction();
}

void CFNotificationCenterPostNotification(CFNotificationCenterRef self,CFStringRef name,const void *object,CFDictionaryRef userInfo,Boolean immediate){
   NSUnimplementedFunction();
}

void CFNotificationCenterPostNotificationWithOptions(CFNotificationCenterRef self,CFStringRef name,const void *object,CFDictionaryRef userInfo,CFOptionFlags options){
   NSUnimplementedFunction();
}

void CFNotificationCenterRemoveEveryObserver(CFNotificationCenterRef self,const void *observer){
   NSUnimplementedFunction();
}

void CFNotificationCenterRemoveObserver(CFNotificationCenterRef self,const void *observer,CFStringRef name,const void *object){
   NSUnimplementedFunction();
}
