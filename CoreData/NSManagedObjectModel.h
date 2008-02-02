#import <Foundation/NSObject.h>

@interface NSManagedObjectModel : NSObject {
}

+(NSManagedObjectModel *)mergedModelFromBundles:(NSArray *)bundles;
+(NSManagedObjectModel *)modelByMergingModels:(NSArray *)models;

-initWithContentsOfURL:(NSURL *)url;

-(NSArray *)configurations;

-(NSArray *)entities;
-(NSArray *)entitiesForConfiguration:(NSString *)configuration;
-(NSDictionary *)localizationDictionary;
-(NSFetchRequest *)fetchRequestTemplateForName:(NSString *)name;

-(void)setEntities:(NSArray *)entities;
-(void)setEntities:(NSArray *)entities forConfiguration:(NSString *)configuration;
-(void)setLocalizationDictionary:(NSDictionary *)dictionary;
-(void)setFetchRequestTemplate:(NSFetchRequest *)fetchRequest forName:(NSString *)name;

-(NSDictionary *)entitiesByName;

-(NSFetchRequest *)fetchRequestFromTemplateWithName:(NSString *)name substitutionVariables:(NSDictionary *)variables;

@end
