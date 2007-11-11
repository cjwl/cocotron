/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSMultipleValueBinder.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSObject+BindingSupport.h>

@interface _NSMultipleValueWrapperArray : NSArray
{
	id object;
}
-(id)initWithObject:(id)obj;
@end



@implementation _NSMultipleValueBinder

#pragma mark -
#pragma mark Outside accessors

- (NSArray *)rowValues 
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

-(void)applyToObject:(id)object inRow:(int)row keyPath:(id)path
{
	[object setValue:[[rowValues objectAtIndex:row] valueForKeyPath:valueKeyPath] forKey:path];
}

-(void)applyToObject:(id)object inRow:(int)row
{
	[self applyToObject:object inRow:row keyPath:bindingPath];
}

-(void)applyToCell:(id)cell inRow:(int)row
{
	[self applyToObject:cell inRow:row keyPath:bindingPath];
}

-(void)applyFromObject:(id)object inRow:(int)row keyPath:(id)keypath
{
	[[rowValues objectAtIndex:row] setValue:[object valueForKeyPath:keypath] 
								 forKeyPath:valueKeyPath];
}

-(void)applyFromObject:(id)object inRow:(int)row
{
	[self applyFromObject:object inRow:row keyPath:bindingPath];
}

-(void)applyFromCell:(id)cell inRow:(int)row
{
	[self applyFromObject:cell inRow:row keyPath:bindingPath];
}


-(unsigned)count
{
	return [rowValues count];
}

-(id)objectAtIndex:(unsigned)row
{
	return [[rowValues objectAtIndex:row] valueForKeyPath:valueKeyPath];
}

#pragma mark -
#pragma mark Internal stuff


-(void)cacheArrayKeyPath
{
	/*
	 Normally, the array path is the key path minus the last component.
	 In case the last component is actually a parameter to an operator,
	 we have to take the last two components.	 
	 */
	id components=[keyPath componentsSeparatedByString:@"."];
	if([components count]==1)
	{
		valueKeyPath=@"self";
		arrayKeyPath=[components lastObject];
	}
	else
	{
		id secondToLast=[components objectAtIndex:[components count]-2];
		
		if([secondToLast hasPrefix:@"@"])
		{
			valueKeyPath=keyPath;
			arrayKeyPath=@"self";
		}
		else
		{
			valueKeyPath=[components lastObject];
			arrayKeyPath= [keyPath substringToIndex:[keyPath length]-[valueKeyPath length]-1];
		}
	}
	[valueKeyPath retain];
	[arrayKeyPath retain];
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
	if(![valueKeyPath hasPrefix:@"@"])
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
	if(![valueKeyPath hasPrefix:@"@"])
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
		
		if([source respondsToSelector:@selector(_boundValuesChanged)])
			[source _boundValuesChanged];

		[self startObservingChanges];
	}
	else if(context==nil)
	{
		if([source respondsToSelector:@selector(reloadData)])
			[source reloadData];
		if([source respondsToSelector:@selector(tableView)])
			[[source tableView] reloadData];
		
		if([destination respondsToSelector:@selector(_selectionMayHaveChanged)])
			[destination performSelector:@selector(_selectionMayHaveChanged)];

	}
}

-(id)defaultBindingOptionsForBinding:(id)thisBinding
{
	return [[source dataCell] _defaultBindingOptionsForBinding:thisBinding];
}

-(void)bind
{
	[self cacheArrayKeyPath];

	[self syncUp];
	[self startObservingChanges];

	if([self createsSortDescriptor] && [binding isEqual:@"value"])
	{
		[source setSortDescriptorPrototype:[[[NSSortDescriptor alloc] initWithKey:valueKeyPath
																		ascending:NO] autorelease]];
	}
	if([source respondsToSelector:@selector(_establishBindingsWithDestinationIfUnbound:)])
	{
		[source performSelector:@selector(_establishBindingsWithDestinationIfUnbound:)
					 withObject:destination
					 afterDelay:0.0];
	}
}



-(void)unbind
{
	[self stopObservingChanges];
}


-(NSString*)description
{
	return [NSString stringWithFormat:@"%@ %@", [super description], [self rowValues]];
}

-(void)updateRowValues
{
	id value=[destination valueForKeyPath:arrayKeyPath];
	if(![value respondsToSelector:@selector(objectAtIndex:)])
		value=[[[_NSMultipleValueWrapperArray alloc] initWithObject:value] autorelease];
	[self setRowValues:value];
}
@end


#pragma mark -
#pragma mark Helper classes



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

-(unsigned)numberOfRows
{
	return [[destination valueForKeyPath:keyPath] count];
}
@end

@implementation _NSMultipleValueWrapperArray
-(id)initWithObject:(id)obj
{
	if(self = [super init])
	{
		object=[obj retain];
	}
	return self;
}

-(void)dealloc
{
	[object release];
	[super dealloc];
}

-(unsigned)count
{
	return 1;
}

-(id)objectAtIndex:(unsigned)idx
{
	return object;
}
@end
