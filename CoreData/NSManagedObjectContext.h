/* Copyright (c) 2008 Dan Knapp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
// -*- mode: objc -*-

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUndoManager.h>
#import <Foundation/NSDate.h>
#import "CoreDataExports.h"

@class NSManagedObject;
@class NSManagedObjectID;
@class NSFetchRequest;
@class NSPersistentStore;
@class NSPersistentStoreCoordinator;
@class NSManagedObjectModel;
@class _NSManagedProxy;
@interface NSManagedObjectContext : NSObject {
    NSPersistentStoreCoordinator *_coordinator;
    NSMutableSet *_insertedObjects;
    NSMutableSet *_activeFetchRequests;
    BOOL _requestedProcessPendingChanges;
}

- (NSManagedObject *) objectRegisteredForID: (NSManagedObjectID *) objectID;
- (NSManagedObject *) objectWithID: (NSManagedObjectID *) objectID;
- (NSArray *) executeFetchRequest: (NSFetchRequest *) request error: (NSError **) error;
- (NSUInteger) countForFetchRequest: (NSFetchRequest *) request error: (NSError **) error;
- (NSSet *) registeredObjects;

- (void) _addFetchRequest: (NSFetchRequest *) fetchRequest;
- (void) _removeFetchRequest: (NSFetchRequest *) fetchRequest;
- (void) insertObject: (NSManagedObject *) object;
- (void) deleteObject: (NSManagedObject *) object;
- (void) assignObject: (id) object toPersistentStore: (NSPersistentStore *) store;
- (BOOL) obtainPermanentIDsForObjects: (NSArray *) objects error: (NSError **) error;
- (void) detectConflictsForObject: (NSManagedObject *) object;
- (void) refreshObject: (NSManagedObject *) object mergeChanges: (BOOL) flag;
- (void) _requestProcessPendingChanges;
- (void) processPendingChanges;
- (void) _processPendingChanges;
- (void) _processPendingChanges;
- (NSSet *) insertedObjects;
- (NSSet *) updatedObjects;
- (NSSet *) deletedObjects;

- (void) mergeChangesFromContextDidSaveNotification: (NSNotification *) notification;

- (NSUndoManager *) undoManager;
- (void) setUndoManager: (NSUndoManager *) undoManager;
- (void) undo;
- (void) redo;
- (void) reset;
- (void) rollback;
- (BOOL) save: (NSError **) error;
- (BOOL) hasChanges;

- (void) lock;
- (void) unlock;
- (BOOL) tryLock;

- (BOOL) propagatesDeletesAtEndOfEvent;
- (void) setPropagatesDeletesAtEndOfEvent: (BOOL) flag;

- (BOOL) retainsRegisteredObjects;
- (void) setRetainsRegisteredObjects: (BOOL) flag;

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
- (void) setPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator;

- (NSTimeInterval)stalenessInterval;
- (void) setStalenessInterval: (NSTimeInterval)expiration;

- (id) mergePolicy;
- (void) setMergePolicy: (id) mergePolicy;

- (BOOL) commitEditing;
- (void) commitEditingWithDelegate: (id) delegate
		 didCommitSelector: (SEL)didCommitSelector
		       contextInfo: (void *) contextInfo;
- (void) discardEditing;
- (void) objectDidBeginEditing: (id) editor;
- (void) objectDidEndEditing: (id) editor;

@end

COREDATA_EXPORT NSString * const NSManagedObjectContextDidSaveNotification;
