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


@implementation _NSTableColumnBinder
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


-(void)applyToCell:(id)cell inRow:(int)row
{
	[cell setValue:[rowValues objectAtIndex:row] forKey:bindingPath];
}



-(void)dealloc
{
	[self setRowValues:nil];
	[super dealloc];
}

-(void)startObservingChanges
{
	//NSLog(@"%@: observing path %@ on %@", [self className], keyPath, destination);
	NS_DURING

	//[destination addObserver:self forKeyPath:keyPath options:0 context:destination];
	NS_HANDLER
	NS_ENDHANDLER

}

-(void)stopObservingChanges
{
	NS_DURING
	//	[destination removeObserver:self forKeyPath:keyPath];
	NS_HANDLER
	NS_ENDHANDLER
}

-(void)syncUp
{
	[self updateRowValues];
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self stopObservingChanges];
	
	if(object==source)
	{
		NSLog(@"bind event from %@.%@ alias %@ to %@.%@ (%@)", [source className], binding, bindingPath, [destination className], keyPath, self);
	}		
	else if(context==destination)
	{
		NSLog(@"bind event from %@.%@ to %@.%@ alias %@ (%@)", [destination className], keyPath, [source className], binding, bindingPath, self);

		[self updateRowValues];
		
		if([source respondsToSelector:@selector(reloadData)])
			[source reloadData];
		if([source respondsToSelector:@selector(tableView)])
			[[source tableView] reloadData];
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

-(int)count
{
	return [rowValues count];
}

-(id)objectAtIndex:(unsigned)row
{
	return [rowValues objectAtIndex:row];
}

-(id)description
{
	return [NSString stringWithFormat:@"%@ %@", [super description], [self rowValues]];
	
}

-(void)updateRowValues
{
	[self setRowValues:[destination valueForKeyPath:keyPath]];
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
				 afterDelay:1.0];
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
