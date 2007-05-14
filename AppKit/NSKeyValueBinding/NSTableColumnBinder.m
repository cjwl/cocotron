/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSTableColumnBinder.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSArrayController.h>
#import <AppKit/NSObject+BindingSupport.h>


@implementation _NSTableColumnBinder
- (NSMutableArray *)rowValues 
{
    return [[rowValues retain] autorelease];
}

- (void)setRowValues:(NSArray *)value 
{
    if (rowValues != value)
	{
        [rowValues release];
        rowValues = [value retain];
    }
}


-(void)applyToCell:(id)cell inRow:(int)row
{
	if(!arrayKeyPath)
		[self cacheArrayKeyPath];
	[cell setValue:[[rowValues objectAtIndex:row] valueForKey:valueKeyPath] forKey:bindingPath];
}

-(void)applyFromCell:(id)cell inRow:(int)row
{
	[[rowValues objectAtIndex:row] setValue:[cell valueForKeyPath:bindingPath] 
								 forKeyPath:valueKeyPath];
}

-(void)cacheArrayKeyPath
{
	// find content binding
	id tableViewContentBinder=[[source tableView] _binderForBinding:@"content"];
	if(!tableViewContentBinder)
		return;

	// this should be something like "arrangedObjects"
	arrayKeyPath=[[tableViewContentBinder keyPath] copy];

	if(![keyPath hasPrefix:arrayKeyPath])
		[NSException raise:NSInvalidArgumentException
					format:@"content binding %@ of table view %@ doesn't fit value binding %@ on column %@",
			arrayKeyPath,
			[source tableView],
			keyPath,
			source];

	// get rest of key path ("value" from "arrangedObjects.value")
	valueKeyPath=[[keyPath substringFromIndex:[arrayKeyPath length]+1] retain];
}

-(BOOL)allowsEditingForRow:(int)row
{
	return YES;
}

-(void)dealloc
{
	[arrayKeyPath release];
	[valueKeyPath release];
	[self setRowValues:nil];
	[super dealloc];
}

-(void)startObservingChanges
{
	NS_DURING
	[destination addObserver:self forKeyPath:arrayKeyPath options:0 context:destination];
	[rowValues addObserver:self
		toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rowValues count])]
				forKeyPath:valueKeyPath 
				   options:0
				   context:nil];
	NS_HANDLER
	NS_ENDHANDLER
}

-(void)stopObservingChanges
{
	NS_DURING
	[destination removeObserver:self forKeyPath:arrayKeyPath];
	[rowValues removeObserver:self
		 fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rowValues count])]
				   forKeyPath:valueKeyPath];
	NS_HANDLER
	NS_ENDHANDLER
}

-(void)syncUp
{
	[self updateRowValues];
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object==source)
	{
		//NSLog(@"bind event from %@.%@ alias %@ to %@.%@ (%@)", [source className], binding, bindingPath, [destination className], keyPath, self);
	}
	else if(context==destination)
	{
		[self stopObservingChanges];

		//NSLog(@"bind event from %@.%@ to %@.%@ alias %@ (%@)", [destination className], keyPath, [source className], binding, bindingPath, self);

		[self updateRowValues];
		
		if([source respondsToSelector:@selector(reloadData)])
			[source reloadData];
		if([source respondsToSelector:@selector(tableView)])
			[[source tableView] reloadData];

		[self startObservingChanges];
	}
	else if(context==nil)
	{
		if([source respondsToSelector:@selector(reloadData)])
			[source reloadData];
		if([source respondsToSelector:@selector(tableView)])
			[[source tableView] reloadData];
		
		if([destination respondsToSelector:@selector(_selectionMayHaveChanged)])
			[destination _selectionMayHaveChanged];

	}
}

-(void)finishBind
{
	[self cacheArrayKeyPath];

	[self syncUp];
	[self startObservingChanges];
}

-(void)bind
{
	[self cacheArrayKeyPath];	

	// At the time of binding, the binders for the table view may not yet be initialized.
	// In that case, we cannot determine which part of our key path is the array and
	// which is the value key. In that case, we defer the finishing steps.
	if(!arrayKeyPath)
		[self performSelector:@selector(finishBind) withObject:nil afterDelay:0.0];
	else
		[self finishBind];
}



-(void)unbind
{
	[self stopObservingChanges];
}

-(int)count
{
	return [rowValues count];
}

-(id)objectAtIndex:(unsigned)row
{
	return [[rowValues objectAtIndex:row] valueForKey:valueKeyPath];
}

-(id)description
{
	return [NSString stringWithFormat:@"%@ %@", [super description], [self rowValues]];
}

-(void)updateRowValues
{
	[self setRowValues:[destination valueForKeyPath:arrayKeyPath]];
}
@end





@class NSTableView;

@implementation _NSTableViewContentBinder
-(void)startObservingChanges
{
	NSParameterAssert([source isKindOfClass:[NSTableView class]]);
	[destination addObserver:self 
				  forKeyPath:keyPath 
					 options:NSKeyValueObservingOptionNew
					 context:nil];
}

-(void)stopObservingChanges
{
	NS_DURING
		[destination removeObserver:self forKeyPath:keyPath];
	NS_HANDLER
	NS_ENDHANDLER
}

-(void)syncUp
{
	[source performSelector:@selector(reloadData) 
				 withObject:nil
				 afterDelay:0.0];
	[source reloadData];
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self stopObservingChanges];

	if(object==destination)
	{
		[source _boundValuesChanged];
	}	
	
	[self startObservingChanges];
}

-(void)bind
{
	[self syncUp];
	[self startObservingChanges];
}

-(void)unbind
{
	[self stopObservingChanges];
}
@end
