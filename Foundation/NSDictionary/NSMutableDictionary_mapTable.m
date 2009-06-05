/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSMutableDictionary_mapTable.h>

#import <Foundation/NSEnumerator_dictionaryKeys.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSRaiseException.h>

@implementation NSMutableDictionary_mapTable

-(NSUInteger)count {
   return NSCountMapTable(_table);
}

-objectForKey:key {
   id object=NSMapGet(_table,key);

   return object;
}

-(NSEnumerator *)keyEnumerator {
   return NSAutorelease(NSEnumerator_dictionaryKeysNew(_table));
}

static inline void setObjectForKey(NSMutableDictionary_mapTable *self,id object,id key){
   if (key==nil)
    NSRaiseException(NSInvalidArgumentException,self,@selector(setObject:forKey:),@"Attempt to insert object with nil key");
   else if(object==nil)
    NSRaiseException(NSInvalidArgumentException,self,@selector(setObject:forKey:),@"Attempt to insert nil object for key %@", key);


   key=[key copy];
   NSMapInsert(self->_table,key,object);
   [key release];
}

-(void)setObject:object forKey:key {
   setObjectForKey(self,object,key);
}

-(void)removeObjectForKey:key {
   NSMapRemove(_table,key);
}

-initWithCapacity:(NSUInteger)capacity {
   _table=NSCreateMapTableWithZone(NSObjectMapKeyCallBacks,
     NSObjectMapValueCallBacks,capacity,NULL);
   return self;
}

-(void)dealloc {
   if(_table!=NULL)
    NSFreeMapTable(_table);
   NSDeallocateObject(self);
   return;
   [super dealloc];
}

-(void)addEntriesFromDictionary:(NSDictionary *)dictionary {
   NSEnumerator *keyEnum=[dictionary keyEnumerator];
   id            key;

   while((key=[keyEnum nextObject])!=nil)
    setObjectForKey(self,[dictionary objectForKey:key],key);
}

@end
