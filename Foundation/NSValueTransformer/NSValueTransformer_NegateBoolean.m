#import "NSValueTransformer_NegateBoolean.h"
#import <Foundation/NSNumber.h>

@implementation NSValueTransformer_NegateBoolean

+(Class)transformedValueClass {
   return [NSNumber class];
}

+(BOOL)allowsReverseTransformation {
   return YES;
}

-transformedValue:value {
   BOOL result=![value boolValue];
   
   return [NSNumber numberWithBool:result];
}

@end
