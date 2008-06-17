/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSManagedObjectContext.h"
#import "NSManagedObjectModel.h"
#import "NSFetchRequest.h"
#import "_NSManagedProxy.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSApplication.h>

@implementation NSManagedObjectContext


- (id) init {
    self = [super init];
    if(self) {
	_coordinator = nil;
	_insertedObjects = [[NSMutableSet setWithCapacity: 100] retain];
	_activeFetchRequests = [[NSMutableSet setWithCapacity: 10] retain];
	_requestedProcessPendingChanges = NO;
    }
    return self;
}


- (void) dealloc {
    if(_coordinator) [_coordinator release];
    [super dealloc];
}


- (NSManagedObject *) objectRegisteredForID: (NSManagedObjectID *) objectID {
    NSUnimplementedMethod();
    return nil;
}


- (NSManagedObject *) objectWithID: (NSManagedObjectID *) objectID {
    NSUnimplementedMethod();
    return nil;
}


- (NSArray *) executeFetchRequest: (NSFetchRequest *) request
			    error: (NSError **) error {
    NSArray *result = [request _resultsInContext: self];
    return result;
}


- (NSUInteger)countForFetchRequest: (NSFetchRequest *) request
			     error: (NSError **) error {
    NSUInteger result = [request _countInContext: self];
    return result;
}


- (NSSet *) registeredObjects {
    NSUnimplementedMethod();
    return nil;
}


- (void) _addFetchRequest: (NSFetchRequest *) fetchRequest {
    [_activeFetchRequests addObject: fetchRequest];
}


- (void) _removeFetchRequest: (NSFetchRequest *) fetchRequest {
    [_activeFetchRequests removeObject: fetchRequest];
}


- (void) insertObject: (NSManagedObject *) object {
    [self _requestProcessPendingChanges];
    [_insertedObjects addObject: object];
}


- (void) deleteObject: (NSManagedObject *) object {
    NSUnimplementedMethod();
}


- (void) assignObject: (id) object toPersistentStore: (NSPersistentStore *) store {
    NSUnimplementedMethod();
}


- (BOOL) obtainPermanentIDsForObjects: (NSArray *) objects error: (NSError **) error {
    NSUnimplementedMethod();
    return NO;
}


- (void) detectConflictsForObject: (NSManagedObject *) object {
    NSUnimplementedMethod();
}


- (void) refreshObject: (NSManagedObject *) object mergeChanges: (BOOL) flag {
    NSUnimplementedMethod();
}


- (void) _requestProcessPendingChanges {
    if(!_requestedProcessPendingChanges) {
	NSLog(@"%@ queuing for refresh", self);
	NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
	[runLoop performSelector: @selector(_processPendingChangesForRequest)
		 target: self
		 argument: nil
		 order: 0
		 modes: [NSArray arrayWithObjects:
				     NSDefaultRunLoopMode,
				     NSModalPanelRunLoopMode,
				     nil]];
	_requestedProcessPendingChanges = YES;
    }
}


- (void) processPendingChanges {
    if(_requestedProcessPendingChanges) {
	NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
	[runLoop cancelPerformSelector: @selector(_processPendingChangesForRequest)
		 target: self
		 argument: nil];
    }
    [self _processPendingChanges];
}


- (void) _processPendingChangesForRequest {
    [self _processPendingChanges];
}


- (void) _processPendingChanges {
    NSLog(@"%@ processing", self);
    _requestedProcessPendingChanges = NO;
    for(NSFetchRequest *request in _activeFetchRequests) {
	[request _refresh];
    }
}


- (NSSet *) insertedObjects {
    return _insertedObjects;
}


- (NSSet *) updatedObjects {
    NSUnimplementedMethod();
    return nil;
}


- (NSSet *) deletedObjects {
    NSUnimplementedMethod();
    return nil;
}


- (void) mergeChangesFromContextDidSaveNotification: (NSNotification *) notification {
    NSUnimplementedMethod();
}


- (NSUndoManager *) undoManager {
    NSUnimplementedMethod();
    return nil;
}


- (void) setUndoManager: (NSUndoManager *) undoManager {
    NSUnimplementedMethod();
}


- (void) undo {
    NSUnimplementedMethod();
}


- (void) redo {
    NSUnimplementedMethod();
}


- (void) reset {
    NSUnimplementedMethod();
}


- (void) rollback {
    NSUnimplementedMethod();
}


- (BOOL) save: (NSError **) error {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) hasChanges {
    NSUnimplementedMethod();
    return NO;
}


- (void) lock {
    NSUnimplementedMethod();
}


- (void) unlock {
    NSUnimplementedMethod();
}


- (BOOL) tryLock {
    NSUnimplementedMethod();
    return NO;
}


- (BOOL) propagatesDeletesAtEndOfEvent {
    NSUnimplementedMethod();
    return NO;
}


- (void) setPropagatesDeletesAtEndOfEvent: (BOOL) flag {
    NSUnimplementedMethod();
}


- (BOOL) retainsRegisteredObjects {
    NSUnimplementedMethod();
    return YES;
}


- (void) setRetainsRegisteredObjects: (BOOL) flag {
    NSUnimplementedMethod();
}


- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    return _coordinator;
}


- (void) setPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator {
    if(coordinator == _coordinator) return;
    if(_coordinator) [_coordinator release];
    if(coordinator) [coordinator retain];
    _coordinator = coordinator;
}


- (NSTimeInterval) stalenessInterval {
    NSUnimplementedMethod();
    return 0;
}


- (void) setStalenessInterval: (NSTimeInterval) expiration {
    NSUnimplementedMethod();
}


- (id) mergePolicy {
    NSUnimplementedMethod();
    return nil;
}


- (void) setMergePolicy: (id) mergePolicy {
    NSUnimplementedMethod();
}


- (BOOL) commitEditing {
    NSUnimplementedMethod();
    return NO;
}


- (void) commitEditingWithDelegate: (id) delegate
		 didCommitSelector: (SEL)didCommitSelector
		       contextInfo: (void *) contextInfo
{
    NSUnimplementedMethod();
}


- (void) discardEditing {
    NSUnimplementedMethod();
}


- (void) objectDidBeginEditing: (id) editor {
    NSUnimplementedMethod();
}


- (void) objectDidEndEditing: (id) editor {
    NSUnimplementedMethod();
}

@end

NSString *NSManagedObjectContextDidSaveNotification=@"NSManagedObjectContextDidSaveNotification";
