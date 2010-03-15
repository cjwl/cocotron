#import <Foundation/NSObject.h>
#import <pthread.h>

@class NSMutableDictionary,NSMutableArray;

@interface NSKVOInfoPerObject : NSObject {
   pthread_mutex_t      _lock;
   NSMutableDictionary *_dictionary;
}

-init;
-objectForKey:key;
-(void)setObject:value forKey:key;
-(void)removeObjectForKey:key;
-(NSUInteger)count;
-(NSMutableArray *)observersForKey:(NSString *)key;

@end
