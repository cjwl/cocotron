/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSSet.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSKeyedUnarchiver.h>
#import <Foundation/NSSet_placeholder.h>
#import <Foundation/NSSet_concrete.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <malloc.h>

@implementation NSSet

+allocWithZone:(NSZone *)zone {
   if(self==[NSSet class])
    return NSAllocateObject([NSSet_placeholder class],0,NULL);

   return NSAllocateObject(self,0,zone);
}

-init {
   return [self initWithObjects:NULL count:0];
}

-initWithObjects:(id *)objects count:(unsigned)count {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithArray:(NSArray *)array {
   unsigned count=[array count];
   id       objects[count];

   [array getObjects:objects];

   return [self initWithObjects:objects count:count];
}

-initWithSet:(NSSet *)set {
   NSEnumerator *state=[set objectEnumerator];
   unsigned      i,count=[set count];
   id            objects[count],object;

   for(i=0;(object=[state nextObject])!=nil;i++)
    objects[i]=object;

   return [self initWithObjects:objects count:count];
}

-initWithSet:(NSSet *)set copyItems:(BOOL)copyItems {
   NSEnumerator *state=[set objectEnumerator];
   unsigned      i,count=[set count];
   id            objects[count],object;

   for(i=0;(object=[state nextObject])!=nil;i++)
    objects[i]=object;

   if(copyItems){
    for(i=0;i<count;i++)
     objects[i]=[objects[i] copyWithZone:NULL];
   }

   self=[self initWithObjects:objects count:count];

   if(copyItems){
    for(i=0;i<count;i++)
     [objects[i] release];
   }

   return self;
}

-initWithObjects:first,... {
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

   return [self initWithObjects:objects count:count];
}

+set {
   return NSAutorelease(NSSet_concreteNew(NULL,NULL,0));
}

+setWithArray:(NSArray *)array {
   unsigned count=[array count];
   id       objects[count];

   [array getObjects:objects];

   return NSAutorelease(NSSet_concreteNew(NULL,objects,count));
}

+setWithSet:(NSSet *)set {
   return [self setWithArray:[set allObjects]];
}

+setWithObject:object {
   return NSAutorelease(NSSet_concreteNew(NULL,&object,1));
}

+setWithObjects:first,... {
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

   return NSAutorelease(NSSet_concreteNew(NULL,objects,count));
}


-(Class)classForCoder {
   return OBJCClassFromString("NSSet");
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSKeyedUnarchiver class]]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    NSArray           *array=[keyed decodeObjectForKey:@"NS.objects"];
    
    return [self initWithArray:array];
   }
   else {
    unsigned i,count;
    id      *objects;

    [coder decodeValueOfObjCType:@encode(unsigned) at:&count];

    objects=alloca(count*sizeof(id));

    for(i=0;i<count;i++)
     objects[i]=[coder decodeObject];

    return [self initWithObjects:objects count:count];
   }
}

-(void)encodeWithCoder:(NSCoder *)coder {
   unsigned      count=[self count];
   NSEnumerator *state=[self objectEnumerator];
   id            object;

   [coder encodeValueOfObjCType:@encode(unsigned) at:&count];

   while((object=[state nextObject])!=nil)
    [coder encodeObject:object];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [[NSMutableSet allocWithZone:zone] initWithSet:self];
}

-member:object {
   NSInvalidAbstractInvocation();
   return nil;
}

-(unsigned)count {
   NSInvalidAbstractInvocation();
   return 0;
}

-(NSEnumerator *)objectEnumerator {
   NSInvalidAbstractInvocation();
   return nil;
}

-(BOOL)isEqual:other {
   if(self==other)
    return YES;

   if(![other isKindOfClass:[NSSet class]])
    return NO;

   return [self isEqualToSet:other];
}

-(BOOL)isEqualToSet:(NSSet *)other {
   NSEnumerator *state;
   id            object;

   if(self==other)
    return YES;

   if([self count]!=[other count])
    return NO;

   state=[self objectEnumerator];
   while((object=[state nextObject])!=nil)
    if([other member:object]==nil)
     return NO;

   return YES;
}

-(NSArray *)allObjects {
   return [[self objectEnumerator] allObjects];
}

-(BOOL)containsObject:object {
   return ([self member:object]!=nil);
}

-(BOOL)isSubsetOfSet:(NSSet *)other {
   NSEnumerator *state=[self objectEnumerator];
   id            object;

   while((object=[state nextObject])!=nil)
    if([other member:object]==nil)
     return NO;

   return YES;
}

-(BOOL)intersectsSet:(NSSet *)set {
   NSEnumerator *state=[self objectEnumerator];
   id            object;

   while((object=[state nextObject])!=nil)
    if([set member:object]!=nil)
     return YES;

   return NO;
}

-(void)makeObjectsPerformSelector:(SEL)selector {
   NSEnumerator *state=[self objectEnumerator];
   id            object;

   while((object=[state nextObject])!=nil)
    [object performSelector:selector];
}

-(void)makeObjectsPerformSelector:(SEL)selector withObject:argument {
   NSEnumerator *state=[self objectEnumerator];
   id            object;

   while((object=[state nextObject])!=nil)
    [object performSelector:selector withObject:argument];
}

-anyObject {
   return [[self objectEnumerator] nextObject];
}

-(NSString *)description {
   NSMutableString *result=[NSMutableString string];
   id objects=[self objectEnumerator];
   id next;
   int i,count=[self count];

   [result appendFormat:@"<%@: 0x%x> (",self];
   for(i=0;(next=[objects nextObject])!=nil;i++){
    [result appendFormat:@"%@",next];
    if(i+1<count)
     [result appendFormat:@", "];
   }

   [result appendFormat:@"<%@: 0x%x> )",self];

   return result;
}

-(NSString *)descriptionWithLocale:(NSDictionary *)locale {
   return nil;
}

@end
