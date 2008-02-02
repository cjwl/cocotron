#import <Foundation/NSObject.h>

@interface NSFetchRequest : NSObject <NSCoding,NSCopying> {
}

-(NSEntityDescription *)entity;
-(NSPredicate *)predicate;
-(NSArray *)sortDescriptors;
-(NSArray *)affectedStores;
-(unsigned)fetchLimit;

-(void)setEntity:(NSEntityDescription *)value;
-(void)setPredicate:(NSPredicate *)value;
-(void)setSortDescriptors:(NSArray *)value;
-(void)setAffectedStores:(NSArray *)value;
-(void)setFetchLimit:(unsigned)value;

@end
