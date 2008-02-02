#import <CoreData/NSPropertyDescription.h>

@interface NSRelationshipDescription : NSPropertyDescription {
}

-(BOOL)isToMany;
-(int)maxCount;
-(int)minCount;
-(NSDeleteRule)deleteRule;
-(NSEntityDescription *)destinationEntity;
-(NSRelationshipDescription *)inverseRelationship;

-(void)setMaxCount:(int)value;
-(void)setMinCount:(int)value;
-(void)setDeleteRule:(NSDeleteRule)value;
-(void)setDestinationEntity:(NSEntityDescription *)value;
-(void)setInverseRelationship:(NSRelationshipDescription *)value;

@end
