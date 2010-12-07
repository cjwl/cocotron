#import <Foundation/Foundation.h>

@interface SBObject : NSObject {
   NSDictionary *_properties;
}

-initWithProperties:(NSDictionary *)properties;

@end
