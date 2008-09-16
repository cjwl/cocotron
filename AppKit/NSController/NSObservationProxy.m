#import "NSObservationProxy.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString+KVCAdditions.h>
#import <Foundation/NSKeyValueObserving.h>

@implementation _NSObservationProxy 
-(id)initWithKeyPath:(id)keyPath observer:(id)observer object:(id)object
{
	if((self=[super init]))
	{
		_keyPath=[keyPath retain];
		_observer=observer;
		_object=object;
      if([object respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)])
         _notifyObject=YES;
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
		if(o->_observer==_observer && [o->_keyPath isEqual:_keyPath] && [o->_object isEqual:_object])
			return YES;
	}
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
   if(_notifyObject)
      [_object observeValueForKeyPath:_keyPath
                             ofObject:_object
                               change:change
                              context:context];

	[_observer observeValueForKeyPath:_keyPath
                            ofObject:_object
                              change:change
                             context:context];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"observation proxy for %@ on key path %@", _observer, _keyPath];
}
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
	if((self=[super init]))
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
                                                                     observer:observer
                                                                       object:self];
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
                                                                     observer:observer
                                                                       object:self];
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

