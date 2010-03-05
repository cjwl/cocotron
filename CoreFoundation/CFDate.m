#import <CoreFoundation/CFDate.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>

CFAbsoluteTime CFAbsoluteTimeGetCurrent() {
   return NSPlatformTimeIntervalSinceReferenceDate();
}

