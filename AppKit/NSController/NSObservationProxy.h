#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSMutableArray.h>

@interface _NSObservationProxy : NSObject
{
	id _keyPath;
	id _observer;
	id _object;
   BOOL _notifyObject;
}
-(id)initWithKeyPath:(id)keyPath observer:(id)observer object:(id)object;
-(id)observer;
-(id)keyPath;
@end



@interface _NSObservableArray : NSArray
{
	NSArray *_array;
	NSMutableArray *_observationProxies;
}
-initWithObjects:(id *)objects count:(unsigned)count;
@end

