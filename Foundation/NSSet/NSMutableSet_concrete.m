/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSMutableSet_concrete.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator_set.h>
#import <Foundation/NSAutoreleasePool-private.h>

@implementation NSMutableSet_concrete

NSSet *NSMutableSet_concreteNew(NSZone *zone,unsigned capacity) {
   NSMutableSet_concrete *self=NSAllocateObject([NSMutableSet_concrete class],0,zone);

   NSSetTableInit(&(self->_table),capacity,zone);

   return self;
}

NSSet *NSMutableSet_concreteNewWithObjects(NSZone *zone,id *objects,
  unsigned count) {
   NSMutableSet_concrete *self=NSAllocateObject([NSMutableSet_concrete class],0,zone);
   unsigned i;

   NSSetTableInit(&(self->_table),count,zone);
   for(i=0;i<count;i++)
    NSSetTableAddObjectNoGrow(&(self->_table),objects[i]);

   return self;
}

NSSet *NSMutableSet_concreteNewWithArray(NSZone *zone,NSArray *array) {
   unsigned count=[array count];
   id       objects[count];

   [array getObjects:objects];

   return NSMutableSet_concreteNewWithObjects(zone,objects,count);
}

-initWithCapacity:(unsigned)capacity {
   NSSetTableInit(&_table,capacity,[self zone]);
   return self;
}

-(void)dealloc {
   NSSetTableFreeObjects(&_table);
   NSSetTableFreeBuckets(&_table);
   NSDeallocateObject(self);
}

-(unsigned)count {
   return _table.count;
}

-member:object {
   return NSSetTableMember(&_table,object);
}

-(NSEnumerator *)objectEnumerator {
   return NSAutorelease(NSEnumerator_setNew(NULL,self,&_table));
}

-(void)addObject:object {
   NSSetTableAddObject(&_table,object);
}

-(void)removeObject:object {
   NSSetTableRemoveObject(&_table,object);
}

@end
