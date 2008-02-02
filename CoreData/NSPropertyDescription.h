#import <Foundation/NSObject.h>

@interface NSPropertyDescription : NSObject <NSCoding,NSCopying> {
}

-(NSEntityDescription *)entity;

-(NSString *)name;
-(BOOL)isOptional;
-(BOOL)isTransient;
-(NSDictionary *)userInfo;
-(NSArray *)validationPredicates;
-(NSArray *)validationWarnings;

-(void)setName:(NSString *)value;
-(void)setOptional:(BOOL)value;
-(void)setTransient:(BOOL)value;
-(void)setUserInfo:(NSDictionary *)value;
-(void)setValidationPredicates:(NSArray *)predicates withValidationWarnings:(NSArray *)warnings;

@end
