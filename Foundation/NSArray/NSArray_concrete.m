/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSArray_concrete.h"
#import <Foundation/NSRaise.h>

@implementation NSArray_concrete

static inline NSArray_concrete *newWithCount(NSZone *zone,unsigned count){
   return NSAllocateObject([NSArray_concrete class],sizeof(id)*count,zone);
}

NSArray *NSArray_concreteNewWithCount(NSZone *zone,id **objects,
  unsigned count){
   NSArray_concrete *self=newWithCount(zone,count);

   self->_count=count;
   *objects=self->_objects;

   return self;
}

NSArray *NSArray_concreteNew(NSZone *zone,id *objects,unsigned count) {
   NSArray_concrete *self=newWithCount(zone,count);
   unsigned         i;

   self->_count=count;
   for(i=0;i<count;i++)
    self->_objects[i]=[objects[i] retain];

   return self;
}

NSArray *NSArray_concreteWithArrayAndObject(NSArray *array,id object) {
   unsigned         i,count=[array count];
   NSArray_concrete *self=newWithCount(NULL,count+1);

   self->_count=count+1;

   [array getObjects:self->_objects];
   for(i=0;i<count;i++)
    [self->_objects[i] retain];

   self->_objects[count]=[object retain];

   return self;
}

NSArray *NSArray_concreteWithArrayAndArray(NSArray *array1,NSArray *array2) {
   unsigned         i,count1=[array1 count],total=count1+[array2 count];
   NSArray_concrete *self=newWithCount(NULL,total);

   self->_count=total;

   [array1 getObjects:self->_objects];
   [array2 getObjects:self->_objects+count1];
   for(i=0;i<total;i++)
    [self->_objects[i] retain];

   return self;
}

NSArray *NSArray_concreteWithArrayRange(NSArray *array,NSRange range) {
   NSArray_concrete *self=newWithCount(NULL,range.length);
   unsigned         i;

   self->_count=range.length;

   [array getObjects:self->_objects range:range];

   for(i=0;i<range.length;i++)
    [self->_objects[i] retain];

   return self;
}

-(void)dealloc {
   int count=_count;

   while(--count>=0)
    [_objects[count] release];

   NSDeallocateObject(self);
}

-(unsigned)count { return _count; }

-objectAtIndex:(unsigned)index {
   if(index>=_count)
    NSRaiseException(NSRangeException,self,_cmd,@"index %d beyond count %d",
     index,_count);

   return _objects[index];
}

@end
