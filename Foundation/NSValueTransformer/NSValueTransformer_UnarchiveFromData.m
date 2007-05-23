#import "NSValueTransformer_UnarchiveFromData.h"
#import <Foundation/NSArchiver.h>

@implementation NSValueTransformer_UnarchiveFromData

+(Class)transformedValueClass {
   return nil;
}

+(BOOL)allowsReverseTransformation {
   return YES;
}

-transformedValue:value {
   return [NSUnarchiver unarchiveObjectWithData:value];
}

-reverseTransformedValue:value {
   return [NSArchiver archivedDataWithRootObject:value];
}

@end
