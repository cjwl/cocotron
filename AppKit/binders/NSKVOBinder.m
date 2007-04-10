/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSKVOBinder.h"
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

@implementation _NSKVOBinder
-(void)startObservingChanges
{
	[source addObserver:self
			 forKeyPath:binding 
				options:NSKeyValueObservingOptionNew
				context:nil];
	[destination addObserver:self 
				  forKeyPath:keyPath 
					 options:NSKeyValueObservingOptionNew
					 context:nil];
}

-(void)stopObservingChanges
{
	NS_DURING
		[source removeObserver:self forKeyPath:binding];
		[destination removeObserver:self forKeyPath:keyPath];
	NS_HANDLER
	NS_ENDHANDLER
}

-(void)syncUp
{
	id value=[destination valueForKeyPath:keyPath];
	
	if(value)
		[source setValue:value forKeyPath:binding];
	else
	{
		value=[source valueForKeyPath:binding];
		if(value)
			[destination setValue:value forKeyPath:keyPath];
	}
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self stopObservingChanges];
	NSLog(@"bind event from %@.%@ to %@.%@ (%@)", [source className], binding, [destination className], keyPath, self);
	
	if(object==source)
	{
		[destination setValue:[change valueForKey:NSKeyValueChangeNewKey]
					   forKey:keyPath];
	}
	else if(object==destination)
	{
		[source setValue:[change valueForKey:NSKeyValueChangeNewKey]
				  forKey:binding];
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

