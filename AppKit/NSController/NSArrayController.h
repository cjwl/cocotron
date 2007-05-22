/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
   Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSObjectController.h>

@class NSPredicate,NSIndexSet;

@interface NSArrayController : NSObjectController {
	struct
	{
		long avoidsEmptySelection:1;
		long clearsFilterPredicateOnInsertion:1;
		long editable:1;
		long filterRestrictsInsertion:1;
		long preservesSelection:1;
		long selectsInsertedObjects:1;
		long alwaysUsesMultipleValuesMarker:1;
	} flags;
	id _contentArray;
	id _selectionIndexes;
	id _sortDescriptors;
	id _filterPredicate;
	id _selection;
	id _arrangedObjects;
}

-(NSArray *)sortDescriptors;
-(NSPredicate *)filterPredicate;
-(BOOL)alwaysUsesMultipleValuesMarker;
//-(BOOL)clearsFilterPredicateOnInsertion;
//-(BOOL)automaticallyPreparesContent;
//-(BOOL)avoidsEmptySelection;
//-(BOOL)selectsInsertedObjects;
//-(BOOL)preservesSelection;

-(void)setSortDescriptors:(NSArray *)descriptors;
-(void)setFilterPredicate:(NSPredicate *)predicate;
//-(void)setAlwaysUsesMultipleValuesMarker:(BOOL)flag;
//-(void)setClearsFilterPredicateOnInsertion:(BOOL)flag;
//-(void)setAutomaticallyPreparesContent:(BOOL)flag;
//-(void)setAvoidsEmptySelection:(BOOL)flag;
//-(void)setSelectsInsertedObjects:(BOOL)flag;
//-(void)setPreservesSelection:(BOOL)flag;

#if 0
-(void)addObject:object;
-(void)addObjects:(NSArray *)objects;
-(void)insertObject:object atArrangedObjectIndex:(unsigned)index;
-(void)insertObjects:(NSArray *)objects atArrangedObjectIndexes:(NSIndexSet *)indices;
-(void)removeObject:object;
-(void)removeObjectAtArrangedObjectIndex:(unsigned)index;
-(void)removeObjects:(NSArray *)objects;
-(void)removeObjectsAtArrangedObjectIndexes:(NSIndexSet *)indices;
#endif

-(NSIndexSet *)selectionIndexes;
//-(unsigned)selectionIndex;
-(NSArray *)selectedObjects;

//-(BOOL)canInsert;
//-(BOOL)canSelectNext;
//-(BOOL)canSelectPrevious;

//-(void)insert:sender;
-(void)remove:sender;
-(void)selectNext:sender;
-(void)selectPrevious:sender;

//-(void)setSelectedObjects:(NSArray *)objects;
-(BOOL)setSelectionIndex:(unsigned)index;
-(BOOL)setSelectionIndexes:(NSIndexSet *)indices;

//-(BOOL)addSelectedObjects:(NSArray *)objects;
//-(BOOL)addSelectionIndexes:(NSIndexSet *)indices;

//-(BOOL)removeSelectedObjects:(NSArray *)objects;
//-(BOOL)removeSelectionIndexes:(NSIndexSet *)indices;

-arrangedObjects;
//-(NSArray *)arrangeObjects:(NSArray *)objects;
//-(void)rearrangeObjects;

// private 
-(void)_selectionMayHaveChanged;

@end
