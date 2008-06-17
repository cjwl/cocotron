/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSFetchRequest.h"
#import "NSManagedObject.h"
#import "NSManagedObjectContext.h"
#import "NSEntityDescription.h"

@implementation NSFetchRequest

- (id) init {
    _entity = nil;
    _predicate = nil;
    _sortDescriptors = [[NSMutableArray arrayWithCapacity: 1] retain];
    _affectedStores = [[NSMutableArray arrayWithCapacity: 1] retain];
    _fetchLimit = 0;
    _owner = nil;
    return self;
}


- (id) initWithCoder: (NSCoder *) coder {
    NSUnimplementedMethod();
    return nil;
}


- (void) encodeWithCoder: (NSCoder *) coder {
    NSUnimplementedMethod();
}


- (id) copyWithZone: (NSZone *) zone {
    return [self retain];
}


- (void) dealloc {
    if(_cachedContext)
	[_cachedContext _removeFetchRequest: self];
    [super dealloc];
}


- (void) _refresh {
    [self _invalidateCache];
    if(_owner) [_owner performSelector: @selector(_refresh)];
}


- (void) _setOwner: (id) owner {
    _owner = owner;
}


- (void) _invalidateCache {
    if(_cachedContext)
	[_cachedContext _removeFetchRequest: self];
    _cachedContext = nil;
    if(_cachedResults) {
	[_cachedResults release];
	_cachedResults = nil;
    }
}


- (BOOL) _cacheIsValidForContext: (NSManagedObjectContext *) context {
    if((_cachedContext == context) && _cachedResults)
	return YES;
    else
	return NO;
}


- (void) _performInContext: (NSManagedObjectContext *) context {
    [self _invalidateCache];
    [context _addFetchRequest: self];
    _cachedContext = context;
    _cachedResults = [[NSMutableArray arrayWithCapacity: 10] retain];
    NSSet *objects = [context insertedObjects];
    for(NSManagedObject *object in [objects allObjects]) {
	NSEntityDescription *entity;
	for(entity = [object entity]; entity; entity = [entity superentity]) {
	    if(entity == _entity) {
		[_cachedResults addObject: object];
		break;
	    }
	}
    }
}


- (NSUInteger) _countInContext: (NSManagedObjectContext *) context {
    if(![self _cacheIsValidForContext: context])
	[self _performInContext: context];
    return [_cachedResults count];
}


- (NSArray *) _resultsInContext: (NSManagedObjectContext *) context {
    if(![self _cacheIsValidForContext: context])
	[self _performInContext: context];
    return _cachedResults;
}


- (NSEntityDescription *) entity {
    return _entity;
}


- (NSPredicate *) predicate {
    return _predicate;
}


- (NSArray *) sortDescriptors {
    return _sortDescriptors;
}


- (NSArray *) affectedStores {
    return _affectedStores;
}


- (unsigned) fetchLimit {
    return _fetchLimit;
}


- (void) setEntity: (NSEntityDescription *) value {
    _entity = value;
}


- (void) setPredicate: (NSPredicate *) value {
    if(_predicate == value) return;
    if(_predicate) [_predicate release];
    if(value) [value retain];
    _predicate = value;
}


- (void) setSortDescriptors: (NSArray *) value {
    [_sortDescriptors removeAllObjects];
    [_sortDescriptors addObjectsFromArray: value];
}


- (void) setAffectedStores: (NSArray *) value {
    [_affectedStores removeAllObjects];
    [_affectedStores addObjectsFromArray: value];
}


- (void) setFetchLimit: (unsigned) value {
    _fetchLimit = value;
}


@end
