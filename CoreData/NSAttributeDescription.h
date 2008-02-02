#import <CoreData/NSPropertyDescription.h>

typedef int NSAttributeType;

@interface NSAttributeDescription : NSPropertyDescription {
}

-(NSString *)attributeValueClassName;

-(NSAttributeType)attributeType;
-defaultValue;

-(void)setAttributeType:(NSAttributeType)value;
-(void)setDefaultValue:value;

@end
