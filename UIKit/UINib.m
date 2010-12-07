#import <UIKit/UINib.h>

@implementation UINib

+(UINib *)nibWithData:(NSData *)data bundle:(NSBundle *)bundle;
+(UINib *)nibWithNibName:(NSString *)name bundle:(NSBundle *)bundle;

-(NSArray *)instantiateWithOwner:owner options:(NSDictionary *)options;

@end
