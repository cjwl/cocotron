/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSTableViewBinder.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSArray.h>


@implementation _NSTableViewBinder
- (NSArray *)rowValues 
{
    return [[rowValues retain] autorelease];
}

- (void)setRowValues:(NSArray *)value 
{
    if (rowValues != value)
	{
        [rowValues release];
        rowValues = [value copy];
    }
}



-(void)dealloc
{
	[self setRowValues:nil];
	[super dealloc];
}

-(void)startObservingChanges
{
	[destination addObserver:self forKeyPath:keyPath options:7 context:nil];
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
	[self setRowValues:[destination valueForKeyPath:keyPath]];
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self stopObservingChanges];

	if(object==destination)
	{
		[self setRowValues:[change valueForKey:NSKeyValueChangeNewKey]];
	}

	[self startObservingChanges];
}

-(void)bind
{
	[self startObservingChanges];
	[self syncUp];
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

@end
