/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
// -*- mode: objc -*-
#import <Foundation/Foundation.h>

@class NSFetchRequest;
@interface NSManagedObjectModel : NSObject {
    NSMutableDictionary *_entities;
    id _fetchRequestTemplates;
    NSSet *_versionIdentifiers;
}

+ (NSManagedObjectModel *) mergedModelFromBundles: (NSArray *) bundles;
+ (NSManagedObjectModel *) modelByMergingModels: (NSArray *) models;

- (id) initWithContentsOfURL: (NSURL *) url;

- (NSArray *) configurations;

- (NSArray *) entities;
- (NSArray *) entitiesForConfiguration: (NSString *) configuration;
- (NSDictionary *) localizationDictionary;
- (NSFetchRequest *) fetchRequestTemplateForName: (NSString *) name;

- (void) setEntities: (NSArray *) entities;
- (void) setEntities: (NSArray *) entities forConfiguration: (NSString *) configuration;
- (void) setLocalizationDictionary: (NSDictionary *) dictionary;
- (void) setFetchRequestTemplate: (NSFetchRequest *) fetchRequest
			 forName: (NSString *) name;

- (NSDictionary *) entitiesByName;

- (NSFetchRequest *) fetchRequestFromTemplateWithName: (NSString *) name
				substitutionVariables: (NSDictionary *) variables;

@end
