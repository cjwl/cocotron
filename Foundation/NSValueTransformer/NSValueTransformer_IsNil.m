#import "NSValueTransformer_IsNil.h"
#import <Foundation/NSNumber.h>

@implementation NSValueTransformer_IsNil

+(Class)transformedValueClass {
   return [NSNumber class];
}

-transformedValue:value {
   BOOL result=(value==nil)?YES:NO;
   
   return [NSNumber numberWithBool:result];
}

@end
