#import <CoreFoundation/CFNumber.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSCFTypeID.h>
#import <Foundation/NSNumber.h>

struct __CFBoolean {
};

#define ToNSNumber(object) ((NSNumber *)object)

CFTypeID CFBooleanGetTypeID(void) {
   return kNSCFTypeBoolean;
}

Boolean CFBooleanGetValue(CFBooleanRef self) {
   return [ToNSNumber(self) boolValue];
}
