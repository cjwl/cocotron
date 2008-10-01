/* Copyright (c) 2007-2008 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSArrayController.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString+KVCAdditions.h>
#import "NSObservationProxy.h"

@interface NSObjectController(private)
-(id)_defaultNewObject;
-(void)_selectionWillChange;
-(void)_selectionDidChange;
@end

@interface NSArrayController(forwardRefs)
-(void)prepareContent;
- (void)_setArrangedObjects:(id)value;
- (void)_setContentArray:(id)value;
@end

@implementation NSArrayController

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObjects:@"contentArray", @"selectionIndexes", nil]
 triggerChangeNotificationsForDependentKey:@"selection"];
	[self setKeys:[NSArray arrayWithObjects:@"contentArray", @"selectionIndexes", @"selection", nil]
triggerChangeNotificationsForDependentKey:@"selectionIndex"];
	[self setKeys:[NSArray arrayWithObjects:@"contentArray", @"selectionIndexes", @"selection", nil]
 triggerChangeNotificationsForDependentKey:@"selectedObjects"];
	
	[self setKeys:[NSArray arrayWithObjects:@"selectionIndexes", nil]
 triggerChangeNotificationsForDependentKey:@"canRemove"];
	[self setKeys:[NSArray arrayWithObjects:@"selectionIndexes", nil]
 triggerChangeNotificationsForDependentKey:@"canSelectNext"];
	[self setKeys:[NSArray arrayWithObjects:@"selectionIndexes", nil]
 triggerChangeNotificationsForDependentKey:@"canSelectPrevious"];
}

-(id)initWithCoder:(NSCoder*)coder
{
	if((self = [super initWithCoder:coder]))
	{
		_flags.avoidsEmptySelection = [coder decodeBoolForKey:@"NSAvoidsEmptySelection"];
		_flags.clearsFilterPredicateOnInsertion = [coder decodeBoolForKey:@"NSClearsFilterPredicateOnInsertion"];
		_flags.filterRestrictsInsertion = [coder decodeBoolForKey:@"NSFilterRestrictsInsertion"];
		_flags.preservesSelection = [coder decodeBoolForKey:@"NSPreservesSelection"];
		_flags.selectsInsertedObjects = [coder decodeBoolForKey:@"NSSelectsInsertedObjects"];
		_flags.alwaysUsesMultipleValuesMarker = [coder decodeBoolForKey:@"NSAlwaysUsesMultipleValuesMarker"];

		id declaredKeys=[coder decodeObjectForKey:@"NSDeclaredKeys"];
		
		if([self automaticallyPreparesContent])
			[self prepareContent];
		else
			[self _setContentArray:[NSMutableArray array]];

	}
	return self;
}

-(void)prepareContent
{
	id array=[NSMutableArray array];
	[array addObject:[[self newObject] autorelease]];
	[self _setContentArray:array];
}

-(void)dealloc
{
	[_selectionIndexes release];
	[_sortDescriptors release];
	[_filterPredicate release];
	[_arrangedObjects release];
	[super dealloc];
}

-(void)awakeFromNib
{
   [self _selectionWillChange];
   [self _selectionDidChange];
}

- (BOOL)preservesSelection
{
	return _flags.preservesSelection;
}

-(void)setPreservesSelection:(BOOL)value
{
	_flags.preservesSelection=value;
}

- (void)_setContentArray:(id)value 
{
	id oldSelection=nil; 
	id oldSelectionIndexes=[[[self selectionIndexes] copy] autorelease];
	if([self preservesSelection])
		oldSelection=[self selectedObjects];

	[self setContent:value];
	[self rearrangeObjects];


	if(oldSelection)
	{
		[self setSelectedObjects:oldSelection];
	}
	else	
	{
		[self setSelectionIndexes:oldSelectionIndexes];
	}
}

- (id)contentArray {
    return [self content];
}

-(NSArray*)arrangeObjects:(NSArray*)objects
{
	id sortedObjects=objects;
	if([self filterPredicate])
		sortedObjects=[sortedObjects filteredArrayUsingPredicate:[self filterPredicate]];
	if([self sortDescriptors])
		sortedObjects=[sortedObjects sortedArrayUsingDescriptors:[self sortDescriptors]];
	return sortedObjects;
}

- (void)rearrangeObjects
{
	[self _setArrangedObjects:[self arrangeObjects:[self contentArray]]];
}

- (void)_setArrangedObjects:(id)value {
    if (_arrangedObjects != value) 
	{
		[_arrangedObjects release];
        _arrangedObjects = [[_NSObservableArray alloc] initWithArray:value];
    }
}

-(id)arrangedObjects
{
	return _arrangedObjects;
}


- (NSArray *)sortDescriptors {
    return [[_sortDescriptors retain] autorelease];
}

- (void)setSortDescriptors:(NSArray *)value {
    if (_sortDescriptors != value) {
        [_sortDescriptors release];
        _sortDescriptors = [value copy];
		[self rearrangeObjects];
    }
}

- (NSPredicate *)filterPredicate {
    return [[_filterPredicate retain] autorelease];
}

- (void)setFilterPredicate:(NSPredicate *)value {
    if (_filterPredicate != value) {
        [_filterPredicate release];
        _filterPredicate = [value copy];
		[self rearrangeObjects];
    }
}

-(BOOL)alwaysUsesMultipleValuesMarker
{
	return _flags.alwaysUsesMultipleValuesMarker;
}

#pragma mark -
#pragma mark Selection

-(NSUInteger)selectionIndex
{
	return [_selectionIndexes firstIndex];
}

-(BOOL)setSelectionIndex:(unsigned)index {
	return [self setSelectionIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (NSIndexSet *)selectionIndexes {
    return [[_selectionIndexes retain] autorelease];
}

- (BOOL)setSelectionIndexes:(NSIndexSet *)value {
	if(![value count] && _flags.avoidsEmptySelection && [[self arrangedObjects] count])
		value=[NSIndexSet indexSetWithIndex:0];
	
	value=[[value mutableCopy] autorelease];
	[(NSMutableIndexSet *)value removeIndexesInRange:NSMakeRange([[self arrangedObjects] count]+1, NSNotFound)];
	
	// use isEqualToIndexSet: ?	
    if (_selectionIndexes != value) {
		[self willChangeValueForKey:@"selectionIndexes"];
       [self _selectionWillChange];
       
        [_selectionIndexes release];
        _selectionIndexes = [value copy];
       [self _selectionDidChange];
       
		[self didChangeValueForKey:@"selectionIndexes"];
		return YES;
    }
    return NO;
}

-(NSArray *)selectedObjects
{
	id idxs=[self selectionIndexes];
	if(idxs)
		return [_NSObservableArray arrayWithArray:[[self arrangedObjects] objectsAtIndexes:idxs]];
	return [_NSObservableArray array];
}

- (BOOL)setSelectedObjects:(NSArray *)objects
{
	id set=[NSMutableIndexSet indexSet];
	int i, count=[objects count];
	for(i=0; i<[objects count]; i++)
	{
		unsigned idx=[[self arrangedObjects] indexOfObject:[objects objectAtIndex:i]];
		if(idx!=NSNotFound)
			[set addIndex:idx];
	}
	[self setSelectionIndexes:set];
	return YES;
}

#pragma mark -
#pragma mark Moving selection

-(BOOL)canSelectPrevious
{
	id idxs=[[[self selectionIndexes] mutableCopy] autorelease];
	
	if(idxs && [idxs firstIndex]>0)
	{
		return YES;
	}
	return NO;
}

-(BOOL)canSelectNext
{
	id idxs=[[[self selectionIndexes] mutableCopy] autorelease];
	
	if(idxs && [idxs lastIndex]<[[self arrangedObjects] count]-1)
		return YES;
	return NO;
}

-(void)selectNext:(id)sender
{
	id idxs=[[[self selectionIndexes] mutableCopy] autorelease];
	if(!idxs){
		[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
        return;
    }
	[idxs shiftIndexesStartingAtIndex:0 by:1];
	
	if([idxs lastIndex]<[[self arrangedObjects] count])
		[self setSelectionIndexes:idxs];
}

-(void)selectPrevious:(id)sender
{
	id idxs=[[[self selectionIndexes] mutableCopy] autorelease];
	if(!idxs){
		[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
        return;
	}
	if([idxs firstIndex]>0)
	{
		[idxs shiftIndexesStartingAtIndex:0 by:-1];
		
		[self setSelectionIndexes:idxs];
	}
}

#pragma mark -
#pragma mark NSSet support

-(id)_contentSet
{
   return [NSSet setWithArray:_content];
}

-(void)_setContentSet:(NSSet*)set
{
   [self _setContentArray:[set allObjects]];
}

#pragma mark -
#pragma mark Add/Remove

- (void)addObject:(id)object
{
	if(![self canAdd])
		return;
	[[self mutableArrayValueForKey:@"contentArray"] addObject:object];
}


- (void)removeObject:(id)object
{
	if(![self canRemove])
		return;	
	[[self mutableArrayValueForKey:@"contentArray"] removeObject:object];
}

-(void)add:(id)sender
{
	if(![self canAdd])
		return;
	[self insert:sender];
}

-(void)insert:(id)sender
{
	if(![self canInsert])
		return;
	id toAdd=nil;
	if([self automaticallyPreparesContent])
		toAdd=[[self newObject] autorelease];
	else
		toAdd=[[self _defaultNewObject] autorelease];
	[self addObject:toAdd];
}

-(void)remove:(id)sender
{
	[self removeObjectsAtArrangedObjectIndexes:[self selectionIndexes]];
}

-(void)removeObjectsAtArrangedObjectIndexes:(NSIndexSet*)indexes
{
	[self removeObjects:[[self contentArray] objectsAtIndexes:indexes]];
}

- (void)addObjects:(NSArray *)objects
{
	if(![self canAdd])
		return;
	id contentArray=[[[self contentArray] mutableCopy] autorelease];
	int count=[objects count];
	int i;
	for(i=0; i<count; i++)
		[contentArray addObject:[objects objectAtIndex:i]];
	[self _setContentArray:contentArray];
}


- (void)removeObjects:(NSArray *)objects
{
	if(![self canRemove])
		return;	

	id contentArray=[[[self contentArray] mutableCopy] autorelease];
	int count=[objects count];
	int i;

	for(i=0; i<count; i++)
		[contentArray removeObject:[objects objectAtIndex:i]];
	[self _setContentArray:contentArray];
}

-(BOOL)canInsert;
{
	return [self isEditable];
}
@end


