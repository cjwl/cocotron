/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
// -*- mode: objc -*-
#import <Foundation/Foundation.h>
#import <stdint.h>

@class NSManagedObject;
@class NSManagedObjectContext;
@class NSManagedObjectModel;
@class NSPropertyDescription;
@class NSAttributeDescription;
@interface NSEntityDescription : NSObject {
    NSString *_className;
    NSString *_name;
    NSManagedObjectModel *_model;
    NSMutableDictionary *_properties;
    NSMutableDictionary *_subentities;
    NSEntityDescription *_superentity;
    NSDictionary *_userInfo;
    id _versionHashModifier;
    NSMutableDictionary *_selectorPropertyMap;
    BOOL _hasBeenInstantiated;
}

@property (readonly) NSMutableDictionary *_selectorPropertyMap;

+ (id) _selectorKey: (SEL) selector;
- (NSPropertyDescription *) _propertyForSelector: (SEL) selector;
- (BOOL) _hasBeenInstantiated;

+ (NSEntityDescription *) entityForName: (NSString *) entityName
		inManagedObjectContext: (NSManagedObjectContext *) moc;
+ (NSManagedObject *) insertNewObjectForEntityForName: (NSString *) entityName
			       inManagedObjectContext: (NSManagedObjectContext *) moc;

- (NSManagedObjectModel *) managedObjectModel;

- (NSString *) name;
- (BOOL) isAbstract;
- (NSString *) managedObjectClassName;
- (NSArray *) properties;
- (NSArray *) subentities;
- (NSDictionary *) userInfo;

- (void) setName: (NSString *) value;
- (void) setAbstract: (BOOL) value;
- (void) setManagedObjectClassName: (NSString *) value;
- (void) setProperties: (NSArray *) value;
- (void) setSubentities: (NSArray *) value;
- (void) setUserInfo: (NSDictionary *) value;

- (NSEntityDescription *) superentity;
- (NSDictionary *) subentitiesByName;
- (NSDictionary *) attributesByName;
- (NSDictionary *) propertiesByName;
- (NSDictionary *) relationshipsByName;
- (NSArray *) relationshipsWithDestinationEntity: (NSEntityDescription *) entity;

@end


extern id getValue(id self, SEL selector);
extern void setValue(id self, SEL selector, id newValue);

