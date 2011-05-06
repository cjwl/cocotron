#import <Foundation/NSNumber.h>
#import <CoreFoundation/CFNumber.h>

@interface NSNumber_CF : NSNumber {
   CFNumberType _type;
}

@end
