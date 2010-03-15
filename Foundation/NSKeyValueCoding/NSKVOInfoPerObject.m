#import "NSKVOInfoPerObject.h"

@implementation NSKVOInfoPerObject

-init {
   _lock=(pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
   _dictionary=[[NSMutableDictionary allocWithZone:NULL] init];
   return self;
}

-(void)dealloc {
   [_dictionary release];
   [super dealloc];
}

-objectForKey:key {
   return [_dictionary objectForKey:key];
}

-(void)setObject:value forKey:key {
   [_dictionary setObject:value forKey:key];
}

-(void)removeObjectForKey:key {
   [_dictionary removeObjectForKey:key];
}

-(NSUInteger)count {
   return [_dictionary count];
}

-(NSMutableArray *)observersForKey:(NSString *)key {
   return [_dictionary objectForKey:key];
}

@end
