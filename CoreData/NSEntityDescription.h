#import <Foundation/NSObject.h>

@interface NSEntityDescription : NSObject {
}

+(NSEntityDescription *)entityForName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)moc;
+(NSManagedObject *)insertNewObjectForEntityForName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)moc;

-(NSManagedObjectModel *)managedObjectModel;

-(NSString *)name;
-(BOOL)isAbstract;
-(NSString *)managedObjectClassName;
-(NSArray *)properties;
-(NSArray *)subentities;
-(NSDictionary *)userInfo;

-(void)setName:(NSString *)value;
-(void)setAbstract:(BOOL)value;
-(void)setManagedObjectClassName:(NSString *)value;
-(void)setProperties:(NSArray *)value;
-(void)setSubentities:(NSArray *)value;
-(void)setUserInfo:(NSDictionary *)value;

-(NSEntityDescription *)superentity;
-(NSDictionary *)subentitiesByName;
-(NSDictionary *)attributesByName
-(NSDictionary *)propertiesByName;
-(NSDictionary *)relationshipsByName;
-(NSArray *)relationshipsWithDestinationEntity:(NSEntityDescription *)entity;

@end
