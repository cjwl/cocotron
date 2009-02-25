/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSEntityDescription.h"
#import "NSManagedObjectContext.h"
#import "NSManagedObjectModel.h"
#import "NSPersistentStoreCoordinator.h"
#import "NSPropertyDescription.h"
#import "NSAttributeDescription.h"
#import "NSRelationshipDescription.h"
#import "NSManagedObject.h"
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <Foundation/ObjCSelector.h>
#import <objc/objc-class.h>
#import <ctype.h>
#import <string.h>
#import <stdint.h>


@implementation NSEntityDescription
@synthesize _selectorPropertyMap;

- (id) initWithCoder: (NSCoder *) coder {
   if([coder isKindOfClass: [NSNibKeyedUnarchiver class]]) {
       NSNibKeyedUnarchiver *keyed = (NSNibKeyedUnarchiver *) coder;
       _className = [[keyed decodeObjectForKey: @"NSClassNameForEntity"] retain];
       _name = [[keyed decodeObjectForKey: @"NSEntityName"] retain];
       _model = [keyed decodeObjectForKey: @"NSManagedObjectModel"];
       _properties = [[keyed decodeObjectForKey: @"NSProperties"] retain];
       _subentities = [[keyed decodeObjectForKey: @"NSSubentities"] retain];
       _superentity = [[keyed decodeObjectForKey: @"NSSuperentity"] retain];
       _userInfo = [[keyed decodeObjectForKey: @"NSUserInfo"] retain];
       _versionHashModifier
	   = [[keyed decodeObjectForKey: @"NSVersionHashModifier"] retain];

       _selectorPropertyMap = [[NSMutableDictionary dictionaryWithCapacity: 20] retain];

       _hasBeenInstantiated = NO;

       if(_className) {
	   Class class = NSClassFromString(_className);
	   NSMutableArray *newMethods = [NSMutableArray arrayWithCapacity: 10];
	   
	   for(NSPropertyDescription *property in [_properties allValues]) {
	       if([property isMemberOfClass: [NSAttributeDescription class]]) {
		   NSAttributeDescription *attribute
		       = (NSAttributeDescription *) property;

		   NSString *propertyName = [property name];
		   
		   NSString *getSelectorName = propertyName;
		   SEL getSelector = NSSelectorFromString(getSelectorName);
		   NSString *getTypes = @"@@:";

		   NSMutableString *setSelectorName
		       = [NSMutableString stringWithFormat: @"set%c%@:",
					  toupper([propertyName characterAtIndex: 0]),
					  [propertyName substringFromIndex: 1]];
		   SEL setSelector = NSSelectorFromString(setSelectorName);
		   NSString *setTypes = @"v@:@";
		   
		   [_selectorPropertyMap
		       setObject: property
		       forKey: [NSEntityDescription _selectorKey: getSelector]];
		   [_selectorPropertyMap
		       setObject: property
		       forKey: [NSEntityDescription _selectorKey: setSelector]];
		   
		   struct objc_method *method = malloc(sizeof(struct objc_method));
		   method->method_name = getSelector;
		   method->method_types = strdup([getTypes UTF8String]);
		   method->method_imp = (IMP) getValue;
		   [newMethods addObject: [NSValue valueWithPointer: method]];
		   
		   method = malloc(sizeof(struct objc_method));
		   method->method_name = setSelector;
		   method->method_types = strdup([setTypes UTF8String]);
		   method->method_imp = (IMP) setValue;
		   [newMethods addObject: [NSValue valueWithPointer: method]];
	       } else if([property isMemberOfClass: [NSRelationshipDescription class]]) {
		   NSRelationshipDescription *relationship
		       = (NSRelationshipDescription *) property;

		   if(![relationship isToMany]) {
		       NSString *propertyName = [property name];
		       
		       NSString *getSelectorName = propertyName;
		       SEL getSelector = NSSelectorFromString(getSelectorName);
		       NSString *getTypes = @"@@:";

		       NSMutableString *setSelectorName
			   = [NSMutableString stringWithFormat: @"set%c%@:",
					      toupper([propertyName characterAtIndex: 0]),
					      [propertyName substringFromIndex: 1]];
		       SEL setSelector = NSSelectorFromString(setSelectorName);
		       NSString *setTypes = @"v@:@";
		   
		       [_selectorPropertyMap
			   setObject: property
			   forKey: [NSEntityDescription _selectorKey: getSelector]];
		       [_selectorPropertyMap
			   setObject: property
			   forKey: [NSEntityDescription _selectorKey: setSelector]];
		   
		       struct objc_method *method = malloc(sizeof(struct objc_method));
		       method->method_name = getSelector;
		       method->method_types = strdup([getTypes UTF8String]);
		       method->method_imp = (IMP) getValue;
		       [newMethods addObject: [NSValue valueWithPointer: method]];
		   
		       method = malloc(sizeof(struct objc_method));
		       method->method_name = setSelector;
		       method->method_types = strdup([setTypes UTF8String]);
		       method->method_imp = (IMP) setValue;
		       [newMethods addObject: [NSValue valueWithPointer: method]];
		   } else {
		       NSLog(@"Not adding accessors for to-many relationship %@.%@",
			     [self name],
			     [relationship name]);
		   }
	       }
	   }
	   
	   struct objc_method_list *newMethodList
	       = malloc(sizeof(struct objc_method_list)
			+ [newMethods count] * sizeof(struct objc_method));
	   newMethodList->method_count = [newMethods count];
	   NSInteger i = 0;
	   for(NSValue *methodValue in newMethods) {
	       struct objc_method *method = [methodValue pointerValue];
	       memcpy(&(newMethodList->method_list[i]), method,
		      sizeof(struct objc_method));
	       i++;
	   }
	   class_addMethods(class, newMethodList);
       }
       
       return self;
   } else {
       [NSException raise: NSInvalidArgumentException
		    format: @"%@ can not initWithCoder:%@", isa, [coder class]];
       return nil;
   }
}


- (NSString *) description {
    return [NSString stringWithFormat: @"<NSEntityDescription %@>", _name];
}


+ (id) _selectorKey: (SEL) selector {
    return [NSNumber numberWithInteger: (NSInteger) OBJCSelectorUniqueId(selector)];
}


- (NSPropertyDescription *) _propertyForSelector: (SEL) selector {
    NSEntityDescription *entity;
    for(entity = self; entity; entity = [entity superentity]) {
	NSPropertyDescription *result
	    = [[entity _selectorPropertyMap] objectForKey:
					[NSEntityDescription _selectorKey: selector]];
	if(result) return result;
    }
    return nil;
}


- (BOOL) _hasBeenInstantiated {
    return _hasBeenInstantiated;
}

/*
- (BOOL) _computeAttribute: (NSAttributeDescription *) attribute
                          getter: (IMP *) getter
                          setter: (IMP *) setter
{
    switch([attribute attributeType]) {
    case NSUndefinedAttributeType:
	NSLog(@"Undefined-type attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSInteger16AttributeType:
	NSLog(@"Integer 16 attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSInteger32AttributeType:
	*getter = (IMP) getInt32;
	*setter = (IMP) setInt32;
	return [NSString stringWithUTF8String: @encode(int32_t)];
		       
    case NSInteger64AttributeType:
	NSLog(@"Integer 64 attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSDecimalAttributeType:
	NSLog(@"Decimal attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSDoubleAttributeType:
	NSLog(@"Double attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSFloatAttributeType:
	NSLog(@"Float attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSStringAttributeType:
	*getter = (IMP) getString;
	*setter = (IMP) setString;
	return [NSString stringWithUTF8String: @encode(NSString *)];
		       
    case NSBooleanAttributeType:
	*getter = (IMP) getBool;
	*setter = (IMP) setBool;
	return [NSString stringWithUTF8String: @encode(BOOL)];
		       
    case NSDateAttributeType:
	NSLog(@"Date attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSBinaryDataAttributeType:
	NSLog(@"Binary data attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
		       
    case NSTransformableAttributeType:
	NSLog(@"Transformable attributes not implemented for %@.%@",
	      _className, [attribute name]);
	return NO;
	
    default:
	NSLog(@"Unknown attribute type for %@.%@",
	      _className, [attribute name]);
	return NO;
    }
}
*/

+ (NSEntityDescription *) entityForName: (NSString *) entityName
		 inManagedObjectContext: (NSManagedObjectContext *) context
{
    NSDictionary *entities = [[[context persistentStoreCoordinator]
				  managedObjectModel]
				 entitiesByName];
    return [entities objectForKey: entityName];
}


+ (NSManagedObject *) insertNewObjectForEntityForName: (NSString *) entityName
			       inManagedObjectContext: (NSManagedObjectContext *) context
{
    NSEntityDescription *entity = [self entityForName: entityName
					inManagedObjectContext: context];
    NSString *className = [entity managedObjectClassName];
    Class class;
    if(className)
	class = NSClassFromString(className);
    else
	class = [NSManagedObject class];
    NSManagedObject *result = [class alloc];
    [result initWithEntity: entity
	    insertIntoManagedObjectContext: context];
    return result;
}


- (NSManagedObjectModel *) managedObjectModel {
    NSUnimplementedMethod();
    return nil;
}


- (NSString *) name {
    return _name;
}


- (BOOL) isAbstract {
    NSUnimplementedMethod();
    return NO;
}


- (NSString *) managedObjectClassName {
    return _className;
}


- (NSArray *) properties {
    NSUnimplementedMethod();
    return nil;
}


- (NSArray *) subentities {
    NSUnimplementedMethod();
    return nil;
}


- (NSDictionary *) userInfo {
    NSUnimplementedMethod();
    return nil;
}


- (void) setName: (NSString *) value {
    if(_hasBeenInstantiated) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    NSUnimplementedMethod();
}


- (void) setAbstract: (BOOL) value {
    if(_hasBeenInstantiated) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    NSUnimplementedMethod();
}


- (void) setManagedObjectClassName: (NSString *) value {
    if(_hasBeenInstantiated) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    NSUnimplementedMethod();
}


- (void) setProperties: (NSArray *) value {
    if(_hasBeenInstantiated) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    NSUnimplementedMethod();
}


- (void) setSubentities: (NSArray *) value {
    if(_hasBeenInstantiated) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    NSUnimplementedMethod();
}


- (void) setUserInfo: (NSDictionary *) value {
    if(_hasBeenInstantiated) {
	NSLog(@"Attempt to modify entity after instantiating it.");
	return;
    }
    
    NSUnimplementedMethod();
}


- (NSEntityDescription *) superentity {
    return _superentity;
}


- (NSDictionary *) subentitiesByName {
    NSUnimplementedMethod();
    return nil;
}


- (NSDictionary *) attributesByName {
    NSUnimplementedMethod();
    return nil;
}


- (NSDictionary *) propertiesByName {
    NSUnimplementedMethod();
    return nil;
}


- (NSDictionary *) relationshipsByName {
    NSUnimplementedMethod();
    return nil;
}


- (NSArray *) relationshipsWithDestinationEntity: (NSEntityDescription *) entity {
    NSUnimplementedMethod();
    return nil;
}

@end


id getValue(id self, SEL selector) {
    NSPropertyDescription *property = [[self entity] _propertyForSelector: selector];
    return [self _valueForProperty: property];
}


void setValue(id self, SEL selector, id newValue) {
    NSPropertyDescription *property = [[self entity] _propertyForSelector: selector];
    [self _setValue: newValue forProperty: property];
}
