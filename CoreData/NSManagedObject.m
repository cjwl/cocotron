/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSManagedObject.h"
#import "NSManagedObjectContext.h"
#import "NSEntityDescription.h"
#import "NSPropertyDescription.h"

@implementation NSManagedObject

- (id) init {
    NSLog(@"Error - can't initialize an NSManagedObject with [init]");
    return nil;
}


- (id)              initWithEntity: (NSEntityDescription *) entity
    insertIntoManagedObjectContext: (NSManagedObjectContext *) context
{
    _entity = entity;
    _context = context;
    [context insertObject: self];
    _changedValues = [[NSMutableDictionary dictionaryWithCapacity: 10] retain];
    return self;
}


- (NSEntityDescription *) entity {
    return _entity;
}


- (NSManagedObjectID *) objectID {
    NSUnimplementedMethod();
    return nil;
}


- (id) self {
    return self;
}


- (NSManagedObjectContext *) managedObjectContext {
    return _context;
}


- (BOOL) isInserted {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) isUpdated {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) isDeleted {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) isFault {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) hasFaultForRelationshipNamed: (NSString *) key {
    NSUnimplementedMethod();
    return NO;
}


- (void) awakeFromFetch {
    NSUnimplementedMethod();
}


- (void) awakeFromInsert {
    NSUnimplementedMethod();
}


- (NSDictionary *) changedValues {
    return _changedValues;
}


- (NSDictionary *) committedValuesForKeys: (NSArray *) keys {
    NSUnimplementedMethod();
    return nil;
}


- (void) dealloc {
    [_changedValues release];
    [super dealloc];
}


- (void) didSave {
    NSUnimplementedMethod();
}


- (void) willTurnIntoFault {
    NSUnimplementedMethod();
}


- (void) didTurnIntoFault {
    NSUnimplementedMethod();
}


- (void) willSave {
    NSUnimplementedMethod();
}


- (id) valueForKey: (NSString *) key {
    NSPropertyDescription *property
	= [_entity _propertyForSelector: NSSelectorFromString(key)];
    if(property) {
	return [self _valueForProperty: property];
    } else {
	NSLog(@"Attempt to get undefined key %@.%@\n",
	      [_entity name], key);
	return nil;
    }
}


- (void) setValue: (id) value forKey: (NSString *) key {
    NSPropertyDescription *property
	= [_entity _propertyForSelector: NSSelectorFromString(key)];
    if(property) {
	[_context _requestProcessPendingChanges];
	[self _setValue: value forProperty: property];
    } else {
	NSLog(@"Attempt to set undefined key %@.%@\n",
	      [_entity name], key);
    }
}


- (NSMutableSet *) mutableSetValueForKey: (NSString *) key {
    NSUnimplementedMethod();
    return nil;
}


- (id) primitiveValueForKey: (NSString *) key {
    NSUnimplementedMethod();
    return nil;
}


- (void) setPrimitiveValue: (id) value forKey: (NSString *) key {
    NSUnimplementedMethod();
}


- (id) _valueForProperty: (NSPropertyDescription *) property {
    return [_changedValues objectForKey: property];
}


- (void) _setValue: (id) value forProperty: (NSPropertyDescription *) property {
    [self willChangeValueForKey: [property name]];
    [_changedValues setObject: value forKey: property];
    NSLog(@"Set %@.%@ to %@\n", self, [property name], value);
    [self didChangeValueForKey: [property name]];
    [_context _requestProcessPendingChanges];
}


- (BOOL) validateValue: (id *) value forKey: (NSString *) key error: (NSError **) error {
    NSUnimplementedMethod();
    return YES;
}


- (BOOL) validateForDelete: (NSError **) error {
    NSUnimplementedMethod();
    return YES;
}


- (BOOL) validateForInsert: (NSError **) error {
    NSUnimplementedMethod();
    return YES;
}


- (BOOL) validateForUpdate: (NSError **) error {
    NSUnimplementedMethod();
    return YES;
}


+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) key {
    return NO;
}


- (void) didAccessValueForKey: (NSString *) key {
    NSUnimplementedMethod();
}


- (void *) observationInfo {
    return NULL;
}


- (void) setObservationInfo: (void *) value {
    NSUnimplementedMethod();
}


- (void) willAccessValueForKey: (NSString *) key {
    NSUnimplementedMethod();
}


@end

