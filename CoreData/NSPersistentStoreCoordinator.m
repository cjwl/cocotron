/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSPersistentStoreCoordinator.h"

@implementation NSPersistentStoreCoordinator

+ (NSDictionary *) registeredStoreTypes {
    NSUnimplementedMethod();
    return nil;
}


+ (void) registerStoreClass: (Class) storeClass forStoreType: (NSString *) storeType {
    NSUnimplementedMethod();
}


- (id) initWithManagedObjectModel: (NSManagedObjectModel *) model {
    self = [super init];
    if(self) {
	_model = [model retain];
    }
    return self;
}


- (NSManagedObjectModel *) managedObjectModel {
    return _model;
}


- (NSPersistentStore *) addPersistentStoreWithType: (NSString *) storeType
				     configuration: (NSString *) configuration
					       URL: (NSURL *) storeURL
					   options: (NSDictionary *) options
					     error: (NSError **) error
{
    NSUnimplementedMethod();
    return nil;
}


- (BOOL) setURL: (NSURL *) url forPersistentStore: (NSPersistentStore *) store {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) removePersistentStore: (NSPersistentStore *) store error: (NSError **) error {
    NSUnimplementedMethod();
    return NO;
}


- (NSPersistentStore *) migratePersistentStore: (NSPersistentStore *) store
					 toURL: (NSURL *) URL
				       options: (NSDictionary *) options
				      withType: (NSString *) storeType
					 error: (NSError **) error
{
    NSUnimplementedMethod();
    return nil;
}


- (NSArray *) persistentStores {
    NSUnimplementedMethod();
    return nil;
}


- (NSPersistentStore *) persistentStoreForURL: (NSURL *) URL {
    NSUnimplementedMethod();
    return nil;
}


- (NSURL *) URLForPersistentStore: (NSPersistentStore *) store {
    NSUnimplementedMethod();
    return nil;
}


- (void) lock {
    NSUnimplementedMethod();
}


- (BOOL) tryLock {
    NSUnimplementedMethod();
    return NO;
}


- (void) unlock {
    NSUnimplementedMethod();
}


- (NSDictionary *) metadataForPersistentStore: (NSPersistentStore *) store {
    NSUnimplementedMethod();
    return nil;
}


- (void) setMetadata: (NSDictionary *) metadata
  forPersistentStore: (NSPersistentStore *) store
{
    NSUnimplementedMethod();
}


+ (BOOL)       setMetadata: (NSDictionary *) metadata
  forPersistentStoreOfType: (NSString *) storeType
		       URL: (NSURL *) url
		     error: (NSError **) error
{
    NSUnimplementedMethod();
    return NO;
}


+ (NSDictionary *) metadataForPersistentStoreOfType: (NSString *) storeType
						URL: (NSURL *) url
					      error: (NSError **) error
{
    NSUnimplementedMethod();
    return nil;
}


- (NSManagedObjectID *) managedObjectIDForURIRepresentation: (NSURL *) URL {
    NSUnimplementedMethod();
    return nil;
}

@end
