#import "NSObservationProxy.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString+KVCAdditions.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSIndexSet.h>

@implementation _NSObservationProxy 
-(id)initWithKeyPath:(id)keyPath observer:(id)observer object:(id)object
{
	if((self=[super init]))
	{
		_keyPath=[keyPath retain];
		_observer=observer;
		_object=object;
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

-(void*)context
{
   return _context;
}

-(NSKeyValueObservingOptions)options
{
   return _options;
}

-(void)setNotifyObject:(BOOL)val
{
   _notifyObject=val;
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
   {
      [_object observeValueForKeyPath:_keyPath
                             ofObject:_object
                               change:change
                              context:context];
   }

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

-(id)init {
   return [self initWithObjects:NULL count:0];
}

-initWithObjects:(id *)objects count:(unsigned)count;
{
	if((self=[super init]))
	{
		_array=[[NSMutableArray alloc] initWithObjects:objects count:count];
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
   _NSObservationProxy *proxy=[[_NSObservationProxy alloc] initWithKeyPath:keyPath
                                                                  observer:observer
                                                                    object:self];
   proxy->_options=options;
   proxy->_context=context;
   
   [_observationProxies addObject:proxy];
   [proxy release];
   
   
	if([keyPath hasPrefix:@"@"])
	{
		NSString* firstPart, *rest;
		[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];
      
      [super addObserver:observer
              forKeyPath:keyPath
                 options:options
                 context:context];      
		
      if(rest) {
         [self addObserver:proxy
                  forKeyPath:rest
                     options:options
                     context:context];
      }
	}
	else
	{
      if([_array count]) {
         id idxs=_roi ? _roi : [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])];
         [_array addObserver:proxy
          toObjectsAtIndexes:idxs
                  forKeyPath:keyPath
                     options:options
                     context:context];
      }
   }
}

-(void)removeObserver:(id)observer forKeyPath:(NSString*)keyPath;
{
   _NSObservationProxy *proxy=[[_NSObservationProxy alloc] initWithKeyPath:keyPath
                                                                  observer:observer
                                                                    object:self];
   int idx=[_observationProxies indexOfObject:proxy];
   [proxy release];
   proxy=[_observationProxies objectAtIndex:idx];
   
	if([keyPath hasPrefix:@"@"])
	{
		NSString* firstPart, *rest;
		[keyPath _KVC_partBeforeDot:&firstPart afterDot:&rest];

      [super removeObserver:observer
              forKeyPath:keyPath];      
      
      if(rest) {
         [self removeObserver:proxy		 
                   forKeyPath:rest];
		}
	}
	else
	{
      if([_array count]) {
         id idxs=_roi ? _roi : [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_array count])];
         [_array removeObserver:proxy
           fromObjectsAtIndexes:idxs
                     forKeyPath:keyPath];
      }
	}
   [_observationProxies removeObjectAtIndex:idx];
}

-(void)insertObject:(id)obj atIndex:(NSUInteger)idx
{
   for(_NSObservationProxy *proxy in _observationProxies)
   {
      id keyPath=[proxy keyPath];
      
      if([keyPath hasPrefix:@"@"])
         [self willChangeValueForKey:keyPath];
      else
         if(!_roi) {
            [obj addObserver:proxy
                  forKeyPath:keyPath
                     options:[proxy options]
                     context:[proxy context]];
         }
   }
   
   [_array insertObject:obj atIndex:idx];
   [_roi shiftIndexesStartingAtIndex:idx by:1];
   
   for(_NSObservationProxy *proxy in _observationProxies)
   {
      id keyPath=[proxy keyPath];
      
      if([keyPath hasPrefix:@"@"])
         [self didChangeValueForKey:keyPath];
   }
}

-(void)removeObjectAtIndex:(NSUInteger)idx
{
   id obj=[_array objectAtIndex:idx];
   for(_NSObservationProxy *proxy in _observationProxies)
   {
      id keyPath=[proxy keyPath];

      if([keyPath hasPrefix:@"@"])
         [self willChangeValueForKey:keyPath];
      else {
         if(!_roi || [_roi containsIndex:idx]) {
            [obj removeObserver:proxy
                     forKeyPath:keyPath];
         }
      }
   }
   [_array removeObjectAtIndex:idx];
   
   if([_roi containsIndex:idx])
      [_roi shiftIndexesStartingAtIndex:idx+1 by:-1];
   
   for(_NSObservationProxy *proxy in _observationProxies)
   {
      id keyPath=[proxy keyPath];
      
      if([keyPath hasPrefix:@"@"])
         [self didChangeValueForKey:keyPath];
   }   
}

-(void)addObject:(id)obj
{
   [self insertObject:obj atIndex:[self count]];
}

-(void)removeLastObject
{
   [self removeObjectAtIndex:[self count]-1];
}

-(void)replaceObjectAtIndex:(NSUInteger)idx withObject:(id)obj
{
   id old=[_array objectAtIndex:idx];
   for(_NSObservationProxy *proxy in _observationProxies)
   {
      id keyPath=[proxy keyPath];
      
      if([keyPath hasPrefix:@"@"])
         [self willChangeValueForKey:keyPath];
      else {
         if(!_roi || [_roi containsIndex:idx]) {
            [old removeObserver:proxy
                     forKeyPath:[proxy keyPath]];
            
            [obj addObserver:proxy
                  forKeyPath:[proxy keyPath]
                     options:[proxy options]
                     context:[proxy context]];
         }
      }
   }
   [_array replaceObjectAtIndex:idx withObject:obj];
   
   for(_NSObservationProxy *proxy in _observationProxies)
   {
      id keyPath=[proxy keyPath];
      
      if([keyPath hasPrefix:@"@"])
         [self didChangeValueForKey:keyPath];
   }   
}

-(void)setROI:(NSIndexSet*)newROI {
   if(newROI != _roi) {
      id proxies=[_observationProxies copy];
      
      for(_NSObservationProxy *proxy in proxies) {
         [self removeObserver:[proxy observer] forKeyPath:[proxy keyPath]];
      }
      
      [_roi release];
      _roi=[newROI mutableCopy];
      
      for(_NSObservationProxy *proxy in proxies) {
         [self addObserver:[proxy observer] forKeyPath:[proxy keyPath] options:[proxy options] context:[proxy context]];
      }
      
      [proxies release];
   }   
}
@end

