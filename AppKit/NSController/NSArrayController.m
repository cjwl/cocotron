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

@implementation NSArrayController

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObjects:@"contentArray", @"selectionIndexes", nil]
 triggerChangeNotificationsForDependentKey:@"selection"];
}

-(id)initWithCoder:(id)coder
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
	// FIX: cocotron nib loading seems not to retain top-level objects. _dirtiest_ possible hack: retain
	return [self retain];
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
	[self willChangeValueForKey:@"selection"];
	_selection=[[NSArrayControllerSelectionProxy alloc] initWithArrayController:self];
	[self didChangeValueForKey:@"selection"];
}

- (id)contentArray {
    return [[contentArray retain] autorelease];
}

- (void)setArrangedObjects:(id)value {
    if (arrangedObjects != value) 
	{
		[arrangedObjects release];
        arrangedObjects = [[NSArray alloc] initWithArray:value];
    }
}

- (void)setContentArray:(id)value {
    if (contentArray != value) {
        [contentArray release];
        contentArray = [value copy];
		
		if([self filterPredicate])
			value=[value filteredArrayUsingPredicate:[self filterPredicate]];
		if([self sortDescriptors])
			value=[value sortedArrayUsingDescriptors:[self sortDescriptors]];
		[self setArrangedObjects:value];
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
		NSLog(@"selectionIndexes changed to %@", value);

		[self willChangeValueForKey:@"selection"];

		[_selection release];
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
    }
}

- (NSPredicate *)filterPredicate {
    return [[filterPredicate retain] autorelease];
}

- (void)setFilterPredicate:(NSPredicate *)value {
    if (filterPredicate != value) {
        [filterPredicate release];
        filterPredicate = [value copy];
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
		return [[self arrangedObjects] objectsAtIndexes:idxs];
	return nil;
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
