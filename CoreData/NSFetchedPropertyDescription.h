#import <CoreData/NSPropertyDescription.h>

@interface NSFetchedPropertyDescription : NSPropertyDescription {
}

-(NSFetchRequest *)fetchRequest;

-(void)setFetchRequest:(NSFetchRequest *)value;

@end
