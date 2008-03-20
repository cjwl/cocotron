/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSArrayController.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString+KVCAdditions.h>

@interface NSObjectController(private)
-(id)_defaultNewObject;
-(void)_selectionMayHaveChanged;
@end

@interface NSArrayController(forwardRefs)
-(void)prepareContent;
- (void)setArrangedObjects:(id)value;
- (void)setContentArray:(id)value;
@end


@interface _NSObservableArray : NSArray
{
	NSArray *_array;
	NSMutableArray *_observationProxies;
}
-initWithObjects:(id *)objects count:(unsigned)count;
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
	if(self = [super initWithCoder:coder])
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
			[self setContentArray:[NSMutableArray array]];

	}
	return self;
}

-(void)prepareContent
{
	id array=[NSMutableArray array];
	[array addObject:[[self newObject] autorelease]];
	[self setContentArray:array];
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
	[self _selectionMayHaveChanged];
}

- (BOOL)preservesSelection
{
	return _flags.preservesSelection;
}

-(void)setPreservesSelection:(BOOL)value
{
	_flags.preservesSelection=value;
}

- (void)setContentArray:(id)value 
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
	
	[self _selectionMayHaveChanged];
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
	[self setArrangedObjects:[self arrangeObjects:[self contentArray]]];
}

- (void)setArrangedObjects:(id)value {
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

        [_selectionIndexes release];
        _selectionIndexes = [value copy];
		[self _selectionMayHaveChanged];

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
	[self setContentArray:contentArray];
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
	[self setContentArray:contentArray];
}

@end


#pragma mark -
#pragma mark -
#pragma mark Helper classes


@interface _NSObservationProxy : NSObject
{
	id _keyPath;
	id _observer;
	id _object;
}
-(id)initWithKeyPath:(id)keyPath observer:(id)observer;
-(id)observer;
-(id)keyPath;
@end

@implementation _NSObservableArray 

-(id)objectAtIndex:(unsigned)idx
{
	return [_array objectAtIndex:idx];
}

-(unsigned)count
{
	return [_array count];
}

-initWithObjects:(id *)objects count:(unsigned)count;
{
	if(self=[super init])
	{
		_array=[[NSArray alloc] initWithObjects:objects count:count];
		_observationProxies=[NSMutableArray new];
	}
	return self;
}

-(void)dealloc
{
	if([_observationProxies count]>0)
		[NSException raise:NSInvalidArgumentException
					format:@"_NSObservableArray still being observed by %@ on %@",
			[[_observationProxies objectAtIndex:0] observer],
			[[_observationProxies objectAtIndex:0] keyPath]];
	[_observationProxies release];
	[_array release];
	[super dealloc];
}

-(void)addObserver:(id)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context;
{
	if([keyPath hasPrefix:@"@"])
	{
		// count never changes (immutable array)
		if([keyPath isEqualToString:@"@count"])
			return;

		_NSObservationProxy *proxy=[[_NSObservationProxy alloc] initWithKeyPath:keyPath
																	   observer:observer
																		 object:self];
		[_observationProxies addObject:proxy];
		[proxy release];

		NSString* firstPart, *rest;
		[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];
		
		[_array addObserver:proxy
		 toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])]
				 forKeyPath:rest
					options:options
					context:context];
	}
	else
	{
		[_array addObserver:observer
		 toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])]
				 forKeyPath:keyPath
					options:options
					context:context];
	}
}

-(void)removeObserver:(id)observer forKeyPath:(NSString*)keyPath;
{
	if([keyPath hasPrefix:@"@"])
	{
		// count never changes (immutable array)
		if([keyPath isEqualToString:@"@count"])
			return;
		
		_NSObservationProxy *proxy=[[_NSObservationProxy alloc] initWithKeyPath:keyPath
																	   observer:observer
																		 object:self];
		int idx=[_observationProxies indexOfObject:proxy];
		[proxy release];
		proxy=[_observationProxies objectAtIndex:idx];
		
		NSString* firstPart, *rest;
		[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];

		[_array removeObserver:proxy		 
		  fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])]
					forKeyPath:rest];
		
		[_observationProxies removeObjectAtIndex:idx];
	}
	else
	{
		[_array removeObserver:observer
		  fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])]
				 forKeyPath:keyPath];
	}
}
@end

@implementation _NSObservationProxy 
-(id)initWithKeyPath:(id)keyPath observer:(id)observer object:(id)object
{
	if(self=[super init])
	{
		_keyPath=[keyPath retain];
		_observer=observer;
		_object=object;
	}
	return self;
}

-(void)dealloc
{
	[_keyPath release];
	[super dealloc];
}

-(id)observer
{
	return _observer;
}

-(id)keyPath
{
	return _keyPath;
}

- (BOOL)isEqual:(id)other
{
	if([other isMemberOfClass:isa])
	{
		_NSObservationProxy *o=other;
		if(o->_observer==_observer && [o->_keyPath isEqual:_keyPath] && [o->_object isEqual:_object])
			return YES;
	}
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change
					   context:(void *)context
{
	[_observer observeValueForKeyPath:_keyPath
							ofObject:_object
							  change:change
							 context:context];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"observation proxy for %@ on key path %@", _observer, _keyPath];
}
@end
