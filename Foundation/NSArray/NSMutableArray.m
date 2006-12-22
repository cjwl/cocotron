/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSArray.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSMutableArray_concrete.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSPropertyListReader.h>

#import <malloc.h>

@implementation NSMutableArray

+allocWithZone:(NSZone *)zone {
   if(self==[NSMutableArray class])
    return NSAllocateObject([NSMutableArray_concrete class],0,zone);

   return NSAllocateObject(self,0,zone);
}

-initWithObjects:(id *)objects count:(unsigned)count {
   unsigned i;

   if((self=[self initWithCapacity:count])==nil)
    return nil;

   for(i=0;i<count;i++)
    [self addObject:objects[i]];

   return self;
}


-initWithCapacity:(unsigned)capacity {
   NSInvalidAbstractInvocation();
   return nil;
}

-copy {
   return [[NSArray allocWithZone:NULL] initWithArray:self];
}

-copyWithZone:(NSZone *)zone {
   return [[NSArray allocWithZone:zone] initWithArray:self];
}


-(Class)classForCoder {
   return [NSMutableArray class];
}

+array {
   if(self==[NSMutableArray class])
    return NSAutorelease(NSMutableArray_concreteNewWithCapacity(NULL,0));

   return [[[self allocWithZone:NULL] init] autorelease];
}


+arrayWithContentsOfFile:(NSString *)path {
   return [NSPropertyListReader arrayWithContentsOfFile:path];
}


+arrayWithObject:object {
   if(self==[NSMutableArray class])
    return NSAutorelease(NSMutableArray_concreteNew(NULL,&object,1));

   return [[[self allocWithZone:NULL]
      initWithObjects:&object count:1] autorelease];
}


+arrayWithCapacity:(unsigned)capacity {
   if(self==[NSMutableArray class])
    return NSAutorelease(NSMutableArray_concreteNewWithCapacity(NULL,capacity));

   return [[[self allocWithZone:NULL] initWithCapacity:capacity] autorelease];
}


+arrayWithObjects:first,... {
   va_list  arguments;
   unsigned i,count;
   id      *objects;

   va_start(arguments,first);
   count=1;
   while(va_arg(arguments,id)!=nil)
    count++;
   va_end(arguments);

   objects=alloca(sizeof(id)*count);

   va_start(arguments,first);
   objects[0]=first;
   for(i=1;i<count;i++)
    objects[i]=va_arg(arguments,id);
   va_end(arguments);

   if(self==[NSMutableArray class])
    return NSAutorelease(NSMutableArray_concreteNew(NULL,objects,count));

   return [[[self allocWithZone:NULL]
     initWithObjects:objects count:count] autorelease];
}



-(void)addObject:object {
   NSInvalidAbstractInvocation();
}

-(void)addObjectsFromArray:(NSArray *)other {
   unsigned i,count=[other count];

   for(i=0;i<count;i++)
    [self addObject:[other objectAtIndex:i]];
}

-(void)removeObjectAtIndex:(unsigned)index {
   NSInvalidAbstractInvocation();
}

-(void)removeAllObjects {
   int count=[self count];

   while(--count>=0)
    [self removeObjectAtIndex:count];
}

-(void)removeLastObject {
   [self removeObjectAtIndex:[self count]-1];
}

-(void)removeObject:object {
   int count=[self count];

   while(--count>=0){
    id check=[self objectAtIndex:count];

    if([check isEqual:object])
     [self removeObjectAtIndex:count];
   }
}

-(void)removeObject:object inRange:(NSRange)range {
   int pos=NSMaxRange(range);

   if(pos>[self count])
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",
     NSStringFromRange(range),[self count]);

   while(--pos>=range.location){
    id check=[self objectAtIndex:pos];

    if([check isEqual:object])
     [self removeObjectAtIndex:pos];
   }
}

-(void)removeObjectIdenticalTo:object {
   int count=[self count];

   while(--count>=0){
    id check=[self objectAtIndex:count];

    if(check==object)
     [self removeObjectAtIndex:count];
   }
}

-(void)removeObjectIdenticalTo:object inRange:(NSRange)range {
   int pos=NSMaxRange(range);

   if(pos>[self count])
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",
     NSStringFromRange(range),[self count]);


   while(--pos>=range.location){
    id check=[self objectAtIndex:pos];

    if(check==object)
     [self removeObjectAtIndex:pos];
   }
}

-(void)removeObjectsInRange:(NSRange)range {
   int pos=NSMaxRange(range);

   if(range.length==0)
    return;

   if(pos>[self count])
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",NSStringFromRange(range),[self count]);

   while(--pos>=range.location && pos>=0)
    [self removeObjectAtIndex:pos];
}

-(void)removeObjectsFromIndices:(unsigned *)indices
                     numIndices:(unsigned)count {
   NSUnimplementedMethod();
}

-(void)removeObjectsInArray:(NSArray *)other {
   int count=[other count];

   while(--count>=0){
    id object=[other objectAtIndex:count];
    [self removeObject:object];
   }
}


-(void)insertObject:object atIndex:(unsigned)index {
   NSInvalidAbstractInvocation();
}

-(void)setArray:(NSArray *)other {
   [self removeAllObjects];
   [self addObjectsFromArray:other];
}

-(void)replaceObjectAtIndex:(unsigned)index withObject:object {
   NSInvalidAbstractInvocation();
}


-(void)replaceObjectsInRange:(NSRange)range
        withObjectsFromArray:(NSArray *)array {
   NSUnimplementedMethod();
}

-(void)replaceObjectsInRange:(NSRange)range
        withObjectsFromArray:(NSArray *)array range:(NSRange)otherRange {
   NSUnimplementedMethod();
}


static int selectorCompare(id object1,id object2,void *userData){
   SEL selector=userData;

   return (NSComparisonResult)[object1 performSelector:selector withObject:object2];
}


-(void)sortUsingSelector:(SEL)selector {
   [self sortUsingFunction:selectorCompare context:selector];
}

// shellsort
-(void)sortUsingFunction:(int (*)(id, id, void *))compare
                 context:(void *)context {
   int strideFactor=3; // magic number
   int c,d,stride,count=[self count];
   BOOL found=NO;

   stride=1;
   while(stride<=count)
    stride=stride*strideFactor+1;

   while(stride>(strideFactor-1)){
    stride=stride/strideFactor;
    for(c=stride;c<count;c++){
     found=NO;
     d=c-stride;
     while((d>=0) && !found){
      id dstrideObject=[self objectAtIndex:d+stride];
      id dObject=[self objectAtIndex:d];

      if(compare(dstrideObject,dObject,context)>=0)
       found=YES;
      else{
       [dstrideObject retain];
       [self replaceObjectAtIndex:d+stride withObject:dObject];
       [self replaceObjectAtIndex:d withObject:dstrideObject];
       [dstrideObject release];
       d-=stride;
      }
     }
    }
   }
}


@end
