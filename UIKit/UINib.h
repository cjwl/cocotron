#import <Foundation/NSObject.h>

@class NSData,NSBundle,NSArray,NSDictionary;

#define IBOutlet

@interface UINib : NSObject {
}

+(UINib *)nibWithData:(NSData *)data bundle:(NSBundle *)bundle;
+(UINib *)nibWithNibName:(NSString *)name bundle:(NSBundle *)bundle;

-(NSArray *)instantiateWithOwner:owner options:(NSDictionary *)options;

@end
