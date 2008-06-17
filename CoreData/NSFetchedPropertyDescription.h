#import "NSPropertyDescription.h"

@class NSFetchRequest;
@interface NSFetchedPropertyDescription : NSPropertyDescription {
}

-(NSFetchRequest *)fetchRequest;

-(void)setFetchRequest:(NSFetchRequest *)value;

@end
