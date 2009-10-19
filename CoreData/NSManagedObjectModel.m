/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSManagedObjectModel.h"
#import <Foundation/NSKeyedUnarchiver.h>
#import <AppKit/NSRaise.h>

@implementation NSManagedObjectModel


- (id) initWithName: (NSString *) name {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource: name ofType: @"mom"];
    if(!path) return nil;
    NSData *data = [[NSData alloc] initWithContentsOfFile: path];
    if(!data) return nil;
    NSDictionary *nameTable
	= [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
    NSKeyedUnarchiver *unarchiver
	= [[[NSKeyedUnarchiver alloc] initForReadingWithData: data
					 externalNameTable: nameTable] autorelease];
    NSManagedObjectModel *result = [unarchiver decodeObjectForKey: @"root"];
    return result;
}


- (id) initWithCoder: (NSCoder *) coder {
   if([coder isKindOfClass: [NSKeyedUnarchiver class]]) {
       NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *) coder;
       _entities = [[keyed decodeObjectForKey: @"NSEntities"] retain];
       _fetchRequestTemplates
	   = [[keyed decodeObjectForKey: @"NSFetchRequestTemplates"] retain];
       _versionIdentifiers
	   = [[keyed decodeObjectForKey: @"NSVersionIdentifiers"] retain];
       return self;
   } else {
       [NSException raise: NSInvalidArgumentException
		    format: @"%@ can not initWithCoder:%@", isa, [coder class]];
       return nil;
   }
}


+ (NSManagedObjectModel *) mergedModelFromBundles: (NSArray *) bundles {
    NSUnimplementedMethod();
}


+ (NSManagedObjectModel *) modelByMergingModels: (NSArray *) models {
    NSUnimplementedMethod();
}


- (id) initWithContentsOfURL: (NSURL *) url {
    NSUnimplementedMethod();
}


- (NSArray *) configurations {
    NSUnimplementedMethod();
}


- (NSArray *) entities {
    NSUnimplementedMethod();
}


- (NSArray *) entitiesForConfiguration: (NSString *) configuration {
    NSUnimplementedMethod();
}


- (NSDictionary *) localizationDictionary {
    NSUnimplementedMethod();
}


- (NSFetchRequest *) fetchRequestTemplateForName: (NSString *) name {
    NSUnimplementedMethod();
}


- (void) setEntities: (NSArray *) entities {
    NSUnimplementedMethod();
}


- (void) setEntities: (NSArray *) entities forConfiguration: (NSString *) configuration
{
    NSUnimplementedMethod();
}


- (void) setLocalizationDictionary: (NSDictionary *) dictionary {
    NSUnimplementedMethod();
}


- (void) setFetchRequestTemplate: (NSFetchRequest *) fetchRequest
			 forName: (NSString *) name;
{
    NSUnimplementedMethod();
}


- (NSDictionary *) entitiesByName {
    return _entities;
}


- (NSFetchRequest *) fetchRequestFromTemplateWithName: (NSString *) name
				substitutionVariables: (NSDictionary *) variables
{
    NSUnimplementedMethod();
}


@end
