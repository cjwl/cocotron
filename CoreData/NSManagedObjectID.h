#import <Foundation/NSObject.h>

@interface NSManagedObjectID : NSObject <NSCopying> {
}

-(NSEntityDescription *)entity;

-(BOOL)isTemporaryID;
-(NSURL *)URIRepresentation;

-persistentStore;

@end
