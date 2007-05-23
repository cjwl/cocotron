#import "NSValueTransformer_IsNotNil.h"
#import <Foundation/NSNumber.h>

@implementation NSValueTransformer_IsNotNil

+(Class)transformedValueClass {
   return [NSNumber class];
}

-transformedValue:value {
   BOOL result=(value!=nil)?YES:NO;
   
   return [NSNumber numberWithBool:result];
}

@end
