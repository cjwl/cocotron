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
	//NSLog(@"binding between %@.%@ alias %@ and %@.%@ (%@)", [_source className], _binding, _bindingPath, [_destination className], _keyPath, self);
   [super startObservingChanges];
	[_destination addObserver:self 
                  forKeyPath:_keyPath 
                     options:0
                     context:nil];
}

-(void)stopObservingChanges {
   [super stopObservingChanges];
   [_destination removeObserver:self forKeyPath:_keyPath];
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
		id pattern=[[[_options objectForKey:@"NSDisplayPattern"] mutableCopy] autorelease];
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
			if([_binding isEqual:@"hidden"])
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
   {
		return [_destination valueForKeyPath:_keyPath];
   }
}

-(id)_realDestinationValue
{
	return [_destination valueForKeyPath:_keyPath];
}

-(void)syncUp
{
	NS_DURING
	if([self destinationValue])
		[_source setValue:[self destinationValue] forKeyPath:_bindingPath];
	NS_HANDLER
		if([self raisesForNotApplicableKeys])
			[localException raise];
	NS_ENDHANDLER
}


- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   //NSLog(@"observeValueForKeyPath %@, %@", kp, object);
   if(object==_destination)
	{
      [self stopObservingChanges];

		//NSLog(@"bind event from %@.%@ to %@.%@ alias %@ (%@)", [_destination className], _keyPath, [_source className], _binding, _bindingPath, self);
		id newValue=[self destinationValue];

		//NSLog(@"new value %@", newValue);

		BOOL editable=YES;
		BOOL isPlaceholder=NO;
		if(newValue==NSMultipleValuesMarker)
		{
			newValue=[self multipleValuesPlaceholder];
			if(![self allowsEditingMultipleValues])
				editable=NO;
			isPlaceholder=YES;
		}
		else if(newValue==NSNoSelectionMarker)
		{
			newValue=[self noSelectionPlaceholder];
			editable=NO;
			isPlaceholder=YES;
		}
		else if(!newValue || newValue==[NSNull null])
		{
			newValue=[self nullPlaceholder];
			isPlaceholder=YES;
		}

		if([self conditionallySetsEditable])
			[_source setEditable:editable];
		if([self conditionallySetsEnabled])
			[_source setEnabled:editable];
		
		[_source setValue:newValue
			  forKeyPath:_bindingPath];

		if(isPlaceholder && [_source respondsToSelector:@selector(_setCurrentValueIsPlaceholder:)])
			[_source _setCurrentValueIsPlaceholder:YES];

      [self startObservingChanges];
	}
	else
      [super observeValueForKeyPath:kp ofObject:object change:change context:context];
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

