/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSArrayController.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import "NSArrayControllerSelectionProxy.h"
#import <Foundation/NSIndexSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSString+KVCAdditions.h>

@interface NSArrayController(forwardRefs)
-(void)_selectionMayHaveChanged;
- (void)setArrangedObjects:(id)value;
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
	[self setKeys:[NSArray arrayWithObjects:@"contentArray", @"selectionIndexes", nil]
 triggerChangeNotificationsForDependentKey:@"selectedObjects"];

}

-(id)initWithCoder:(NSCoder*)coder
{
	self=[super init];
	if(self)
	{
		flags.avoidsEmptySelection = [coder decodeBoolForKey:@"NSAvoidsEmptySelection"];
		flags.clearsFilterPredicateOnInsertion = [coder decodeBoolForKey:@"NSClearsFilterPredicateOnInsertion"];
		flags.editable = [coder decodeBoolForKey:@"NSEditable"];
		flags.filterRestrictsInsertion = [coder decodeBoolForKey:@"NSFilterRestrictsInsertion"];
		flags.preservesSelection = [coder decodeBoolForKey:@"NSPreservesSelection"];
		flags.selectsInsertedObjects = [coder decodeBoolForKey:@"NSSelectsInsertedObjects"];
		flags.alwaysUsesMultipleValuesMarker = [coder decodeBoolForKey:@"NSAlwaysUsesMultipleValuesMarker"];

		id declaredKeys=[coder decodeObjectForKey:@"NSDeclaredKeys"];
	}
	return self;
}

-(void)dealloc
{
	[_selection release];
	[contentArray release];
	[selectionIndexes release];
	[super dealloc];
}

-(id)awakeFromNib
{
	[self _selectionMayHaveChanged];
}

-(void)_selectionMayHaveChanged
{
	[self willChangeValueForKey:@"selection"];
	_selection=[[NSArrayControllerSelectionProxy alloc] initWithArrayController:self];
	[self didChangeValueForKey:@"selection"];	
}

- (id)contentArray {
    return [[contentArray retain] autorelease];
}

-(void)arrangeObjects
{
	id sortedObjects=contentArray;
	if([self filterPredicate])
		sortedObjects=[sortedObjects filteredArrayUsingPredicate:[self filterPredicate]];
	if([self sortDescriptors])
		sortedObjects=[sortedObjects sortedArrayUsingDescriptors:[self sortDescriptors]];
	[self setArrangedObjects:sortedObjects];
	
}

- (void)setContentArray:(id)value {
    if (contentArray != value) {
        [contentArray release];
        contentArray = [value copy];
		[self arrangeObjects];
    }
}

- (void)setArrangedObjects:(id)value {
    if (arrangedObjects != value) 
	{
		[arrangedObjects release];
        arrangedObjects = [[_NSObservableArray alloc] initWithArray:value];
    }
}

-(id)arrangedObjects
{
	return arrangedObjects;
}

-(id)selection
{
	return _selection;
}

- (NSIndexSet *)selectionIndexes {
    return [[selectionIndexes retain] autorelease];
}

-(BOOL)setSelectionIndex:(unsigned)index {
   return [self setSelectionIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (BOOL)setSelectionIndexes:(NSIndexSet *)value {
	if(!value && flags.avoidsEmptySelection && [[self arrangedObjects] count])
		value=[NSIndexSet indexSetWithIndex:0];

// use isEqualToIndexSet: ?	
    if (selectionIndexes != value) {
        [selectionIndexes release];
        selectionIndexes = [value copy];
		//NSLog(@"selectionIndexes changed to %@", value);

		[self willChangeValueForKey:@"selection"];

		[_selection autorelease];
		_selection = nil;
		_selection=[[NSArrayControllerSelectionProxy alloc] initWithArrayController:self];

		[self didChangeValueForKey:@"selection"];		
     return YES;
    }
    return NO;
}

- (NSArray *)sortDescriptors {
    return [[sortDescriptors retain] autorelease];
}

- (void)setSortDescriptors:(NSArray *)value {
    if (sortDescriptors != value) {
        [sortDescriptors release];
        sortDescriptors = [value copy];
		[self arrangeObjects];
    }
}

- (NSPredicate *)filterPredicate {
    return [[filterPredicate retain] autorelease];
}

- (void)setFilterPredicate:(NSPredicate *)value {
    if (filterPredicate != value) {
        [filterPredicate release];
        filterPredicate = [value copy];
		[self arrangeObjects];
    }
}

-(BOOL)alwaysUsesMultipleValuesMarker
{
	return flags.alwaysUsesMultipleValuesMarker;
}

-(NSArray *)selectedObjects
{
	id idxs=[self selectionIndexes];
	if(idxs)
		return [_NSObservableArray arrayWithArray:[[self arrangedObjects] objectsAtIndexes:idxs]];
	return [_NSObservableArray array];
}


-(void)add:(id)sender
{
	
}

-(void)remove:(id)sender
{
	
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


@end


@interface _NSObservationProxy : NSObject
{
	id _keyPath;
	id _observer;
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
																	   observer:observer];
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
																	   observer:observer];
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
-(id)initWithKeyPath:(id)keyPath observer:(id)observer
{
	if(self=[super init])
	{
		_keyPath=[keyPath retain];
		_observer=observer;
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
		if(o->_observer==_observer && [o->_keyPath isEqual:_keyPath])
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
							ofObject:object
							  change:change
							 context:context];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"observation proxy for %@ on key path %@", _observer, _keyPath];
}
@end
