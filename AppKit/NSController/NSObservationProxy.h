#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSKeyValueObserving.h>

@interface _NSObservationProxy : NSObject
{
	id _keyPath;
	id _observer;
	id _object;
   BOOL _notifyObject;
   // only as storage (context for _observer will be the one given in observeValueForKeyPath:)
   // FIXME: write accessors, remove @public
@public 
   void* _context;
   NSKeyValueObservingOptions _options;
}
-(id)initWithKeyPath:(id)keyPath observer:(id)observer object:(id)object;
-(id)observer;
-(id)keyPath;
-(void)setNotifyObject:(BOOL)val;
@end



@interface _NSObservableArray : NSMutableArray
{
	NSMutableArray *_array;
	NSMutableArray *_observationProxies;
}
@end

