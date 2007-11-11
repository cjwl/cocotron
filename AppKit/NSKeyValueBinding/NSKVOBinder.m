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
#import <AppKit/NSController.h>
#import <AppKit/NSControl.h>
#import "NSObject+BindingSupport.h"

@implementation _NSKVOBinder
-(void)startObservingChanges
{
	//NSLog(@"binding between %@.%@ alias %@ and %@.%@ (%@)", [source className], binding, bindingPath, [destination className], keyPath, self);

	[source addObserver:self
			 forKeyPath:bindingPath 
				options:0
				context:nil];
	[destination addObserver:self 
				  forKeyPath:keyPath 
					 options:0
					 context:nil];
}

-(void)stopObservingChanges
{
	NS_DURING
		[source removeObserver:self forKeyPath:bindingPath];
		[destination removeObserver:self forKeyPath:keyPath];
	NS_HANDLER
	NS_ENDHANDLER
}

-(id)destinationValue
{
	id peers=[self peerBinders];
	if([peers count])
	{
		// Support for pattern binders
		// FIX: maybe this should be in subclasses.
		// however, as long as there's just booleans (enabled, hidden etc.)
		// and strings (%{value1}@...
		peers=[peers sortedArrayUsingSelector:@selector(compare:)];
		id values=[peers valueForKeyPath:@"realDestinationValue"];
		int i;
		id pattern=[[[options objectForKey:@"NSDisplayPattern"] mutableCopy] autorelease];
		if(pattern)
		{
			for(i=0; i<[peers count]; i++)
			{
				id token=[NSString stringWithFormat:@"%%{value%i}@", i+1];
				[pattern replaceCharactersInRange:[pattern rangeOfString:token]
									   withString:[[values objectAtIndex:i] description]];
			}
			return pattern;
		}
		else if([[values lastObject] isKindOfClass:[NSNumber class]])
		{
			BOOL ret;
			if([binding isEqual:@"hidden"])
			{
				ret=NO;
				for(i=0; i<[peers count]; i++)
				{
					id value=[values objectAtIndex:i];
					if([value respondsToSelector:@selector(boolValue)])
						ret|=[value boolValue];
					else
						ret=YES;
				}
			}
			else
			{
				ret=YES;
				for(i=0; i<[peers count]; i++)
				{
					id value=[values objectAtIndex:i];
					if([value respondsToSelector:@selector(boolValue)])
						ret&=[value boolValue];
					else
						ret=NO;
				}				
			}
			return [NSNumber numberWithBool:ret];
		}
		return pattern;
	}
	else
		return [destination valueForKeyPath:keyPath];
}

-(id)_realDestinationValue
{
	return [destination valueForKeyPath:keyPath];
}

-(void)syncUp
{
	NS_DURING
	if([self destinationValue])
		[source setValue:[self destinationValue] forKeyPath:bindingPath];
	NS_HANDLER
		if([self raisesForNotApplicableKeys])
			[localException raise];
	NS_ENDHANDLER
}


- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self stopObservingChanges];

	if(object==source)
	{
		//NSLog(@"bind event from %@.%@ alias %@ to %@.%@ (%@)", [source className], binding, bindingPath, [destination className], keyPath, self);

		[destination setValue:[source valueForKeyPath:bindingPath]
				   forKeyPath:keyPath];
	}
	else if(object==destination)
	{
		//NSLog(@"bind event from %@.%@ to %@.%@ alias %@ (%@)", [destination className], keyPath, [source className], binding, bindingPath, self);
		id newValue=[self destinationValue];

		BOOL editable=YES;
		if(newValue==NSMultipleValuesMarker)
		{
			newValue=[self multipleValuesPlaceholder];
			if(![self allowsEditingMultipleValues])
				editable=NO;
		}
		else if(newValue==NSNoSelectionMarker)
		{
			newValue=[self noSelectionPlaceholder];
			editable=NO;
		}

		if([self conditionallySetsEditable])
			[source setEditable:editable];
		if([self conditionallySetsEnabled])
			[source setEnabled:editable];
		
		[source setValue:newValue
			  forKeyPath:bindingPath];
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

