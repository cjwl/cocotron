/* Copyright (c) 2007 Johannes Fortmann

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSControllerSelectionProxy.h"
#import <AppKit/NSArrayController.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString+KVCAdditions.h>
#import "NSObservationProxy.h"
#import <Foundation/NSException.h>

@implementation NSControllerSelectionProxy
-(id)initWithController:(id)cont
{
	if((self=[super init]))
	{
		_values=[NSMutableDictionary new];
		_controller = [cont retain];
      _observationProxies = [NSMutableArray new];
	}
	return self;
}

-(void)dealloc
{
   [_keys release];
	[_values release];
	[_controller release];
   
   if([_observationProxies count]>0)
		[NSException raise:NSInvalidArgumentException
                  format:@"NSControllerSelectionProxy still being observed by %@ on %@",
       [[_observationProxies objectAtIndex:0] observer],
       [[_observationProxies objectAtIndex:0] keyPath]];
   
   [_observationProxies release];
	[super dealloc];
}

-(id)valueForKey:(NSString*)key
{
	id val=[_values objectForKey:key];
	if(val)
		return val;
	id allValues=[[_controller selectedObjects] valueForKeyPath:key];
	
	switch([allValues count])
	{
		case 0:
			val=NSNoSelectionMarker;
			break;
		case 1:
			val=[allValues lastObject];
			break;
		default:
		{
			if([_controller alwaysUsesMultipleValuesMarker])
			{
				val=NSMultipleValuesMarker;
			}
			else
			{
				val=[allValues objectAtIndex:0];
				id en=[allValues objectEnumerator];
				id obj;
				while((obj=[en nextObject]) && val!=NSMultipleValuesMarker)
				{
					if(![val isEqual:obj])
						val=NSMultipleValuesMarker;
				}
			}
			break;
		}
	}
	
	[_values setValue:val forKey:key];
   
	return val;
}

-(int)count
{
	return [_values count];
}

-(id)keyEnumerator
{
	return [_values keyEnumerator];
}

-(void)setValue:(id)value forKey:(NSString *)key
{
	[[_controller selectedObjects] setValue:value forKey:key];
}

-(NSString*)description
{
	return [NSString stringWithFormat:
		@"%@ <0x%x>",
		[self className],
		self];
}

-(void)controllerWillChange
{
   [_keys autorelease];
   _keys=[[_values allKeys] retain];
   for(id key in _keys)
   {
      [self willChangeValueForKey:key];
   }
   [_values removeAllObjects];
}

-(void)controllerDidChange
{
   [_values removeAllObjects];
   for(id key in _keys)
   {
      [self didChangeValueForKey:key];
   }
   [_keys autorelease];
   _keys=nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
   [_values removeObjectForKey:keyPath];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
   _NSObservationProxy *proxy=[[_NSObservationProxy alloc] initWithKeyPath:keyPath observer:observer object:self];
   [_observationProxies addObject:proxy];
   
   [[_controller selectedObjects] addObserver:proxy forKeyPath:keyPath options:options context:context];

   [proxy release];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
   _NSObservationProxy *proxy=[[_NSObservationProxy alloc] initWithKeyPath:keyPath observer:observer object:self];
   int idx=[_observationProxies indexOfObject:proxy];
   [proxy release];

   [[_controller selectedObjects] removeObserver:[_observationProxies objectAtIndex:idx] forKeyPath:keyPath];
   
   [_observationProxies removeObjectAtIndex:idx];
}

@end
