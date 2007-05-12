/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArray_placeholder.h>
#import <Foundation/NSArray_concrete.h>
#import <Foundation/NSEnumerator_array.h>
#import <Foundation/NSEnumerator_arrayReverse.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSPropertyListReader.h>
#import <Foundation/NSPropertyListWriter_vintage.h>
#import <Foundation/NSKeyedUnarchiver.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSIndexSet.h>

#import <malloc.h>

@implementation NSArray 

+allocWithZone:(NSZone *)zone {
   if(self==OBJCClassFromString("NSArray"))
    return NSAllocateObject([NSArray_placeholder class],0,NULL);

   return NSAllocateObject(self,0,zone);
}

-initWithArray:(NSArray *)array {
   unsigned count=[array count];
   id      *objects=alloca(sizeof(id)*count);

   [array getObjects:objects];

   return [self initWithObjects:objects count:count];
}

-initWithContentsOfFile:(NSString *)path {
   NSUnimplementedMethod();
   return nil;
}


-initWithObjects:(id *)objects count:(unsigned)count {
   NSInvalidAbstractInvocation();
   return nil;
}


-initWithObjects:object,... {
   va_list  arguments;
   unsigned i,count;
   id      *objects;

   va_start(arguments,object);
   count=1;
   while(va_arg(arguments,id)!=nil)
    count++;
   va_end(arguments);

   objects=alloca(sizeof(id)*count);

   va_start(arguments,object);
   objects[0]=object;
   for(i=1;i<count;i++)
    objects[i]=va_arg(arguments,id);
   va_end(arguments);

   return [self initWithObjects:objects count:count];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}


-mutableCopyWithZone:(NSZone *)zone {
   return [[NSMutableArray allocWithZone:zone] initWithArray:self];
}


-(Class)classForCoder {
   return OBJCClassFromString("NSArray");
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

    [coder decodeValueOfObjCType:@encode(int) at:&count];

    objects=alloca(count*sizeof(id));

    for(i=0;i<count;i++)
     objects[i]=[coder decodeObject];

    return [self initWithObjects:objects count:count];
   }
}


-(void)encodeWithCoder:(NSCoder *)coder {
   unsigned i,count=[self count];

   [coder encodeValueOfObjCType:@encode(int) at:&count];
   for(i=0;i<count;i++)
    [coder encodeObject:[self objectAtIndex:i]];
}

+array {
   if(self==OBJCClassFromString("NSArray"))
    return NSAutorelease(NSArray_concreteNew(NULL,NULL,0));

   return [[[self allocWithZone:NULL] init] autorelease];
}


+arrayWithContentsOfFile:(NSString *)path {
   return [[[self allocWithZone:NULL] initWithContentsOfFile:path] autorelease];
}


+arrayWithObject:object {
   if(self==OBJCClassFromString("NSArray"))
    return NSAutorelease(NSArray_concreteNew(NULL,&object,1));

   return [[[self allocWithZone:NULL]
      initWithObjects:&object count:1] autorelease];
}


+arrayWithObjects:object,... {
   va_list  arguments;
   unsigned i,count; 
   id      *objects;

   va_start(arguments,object);
   count=1; // include object
   while(va_arg(arguments,id)!=nil)
    count++;
   va_end(arguments);

   objects=alloca(sizeof(id)*count);

   va_start(arguments,object);
   objects[0]=object;
   for(i=1;i<count;i++)
    objects[i]=va_arg(arguments,id);
   va_end(arguments);

   if(self==OBJCClassFromString("NSArray"))
    return NSAutorelease(NSArray_concreteNew(NULL,objects,count));

   return [[[self allocWithZone:NULL]
     initWithObjects:objects count:count] autorelease];
}


+arrayWithArray:(NSArray *)array {
   return [[[self allocWithZone:NULL] initWithArray:array] autorelease];
}


+arrayWithObjects:(id *)objects count:(unsigned)count {
   return [[[self allocWithZone:NULL] initWithObjects:objects count:count] autorelease];
}


-(unsigned)count {
   NSInvalidAbstractInvocation();
   return 0;
}


-objectAtIndex:(unsigned)index {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)getObjects:(id *)objects {
   unsigned i,count=[self count];

   for(i=0;i<count;i++)
    objects[i]=[self objectAtIndex:i];
}


-(void)getObjects:(id *)objects range:(NSRange)range {
   unsigned i,count=[self count],loc=range.location;

   if(NSMaxRange(range)>count)
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",
     NSStringFromRange(range),[self count]);

   for(i=0;i<range.length;i++)
    objects[i]=[self objectAtIndex:loc+i];
}

-(NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
   unsigned i,count=[indexes count];
   unsigned buffer[count];
   id       objects[count];

   count=[indexes getIndexes:buffer maxCount:count inIndexRange:NULL];
//  getObjects:range: would make more sense
   for(i=0;i<count;i++)
    objects[i]=[self objectAtIndex:buffer[i]];
   
   return [NSArray arrayWithObjects:objects count:count];
}

-(NSArray *)subarrayWithRange:(NSRange)range {
   if(NSMaxRange(range)>[self count])
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",
     NSStringFromRange(range),[self count]);

   return NSAutorelease(NSArray_concreteWithArrayRange(self,range));
}

-(unsigned)hash {
   return [self count];
}

-(BOOL)isEqual:array {
   if(self==array)
    return YES;

   if(![array isKindOfClass:OBJCClassFromString("NSArray")])
    return NO;

   return [self isEqualToArray:array];
}


-(BOOL)isEqualToArray:(NSArray *)array {
   int i,count;

   if(self==array)
    return YES;

   count=[self count];
   if(count!=[array count])
    return NO;

   for(i=0;i<count;i++)
    if(![[self objectAtIndex:i] isEqual:[array objectAtIndex:i]])
     return NO;

   return YES;
}

-(unsigned)indexOfObject:object {
   int i,count=[self count];

   for(i=0;i<count;i++)
    if([[self objectAtIndex:i] isEqual:object])
     return i;

   return NSNotFound;
}


-(unsigned)indexOfObject:object inRange:(NSRange)range {
   int i,count=[self count],loc=range.location;

   if(NSMaxRange(range)>count)
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",
     NSStringFromRange(range),[self count]);

   for(i=0;i<range.length;i++)
    if([[self objectAtIndex:loc+i] isEqual:object])
     return i;

   return NSNotFound;
}


-(unsigned)indexOfObjectIdenticalTo:object {
   int i,count=[self count];

   for(i=0;i<count;i++)
    if([self objectAtIndex:i]==object)
     return i;

   return NSNotFound;
}


-(unsigned)indexOfObjectIdenticalTo:object inRange:(NSRange)range {
   int i,count=[self count],loc=range.location;

   if(NSMaxRange(range)>count)
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond count %d",
     NSStringFromRange(range),[self count]);

   for(i=0;i<range.length;i++)
    if([self objectAtIndex:loc+i]==object)
     return i;

   return NSNotFound;
}

-(NSEnumerator *)objectEnumerator {
   return NSAutorelease(NSEnumerator_arrayNew(self));
}


-(NSEnumerator *)reverseObjectEnumerator {
   return NSAutorelease(NSEnumerator_arrayReverseNew(self));
}


-(NSArray *)arrayByAddingObject:object {
   return NSAutorelease(NSArray_concreteWithArrayAndObject(self,object));
}


-(NSArray *)arrayByAddingObjectsFromArray:(NSArray *)array {
   return NSAutorelease(NSArray_concreteWithArrayAndArray(self,array));
}

-(NSString *)componentsJoinedByString:(NSString *)separator {
   NSMutableString *string=[NSMutableString stringWithCapacity:256];
   int i,count=[self count];

   for(i=0;i<count;i++){
    [string appendString:[[self objectAtIndex:i] description]];
    if(i+1<count)
     [string appendString:separator];
   }
   return string;
}


-(BOOL)containsObject:object {
   return ([self indexOfObject:object]!=NSNotFound)?YES:NO;
}


-firstObjectCommonWithArray:(NSArray *)array {
   int i,count=[self count];

   for(i=0;i<count;i++){
    id object=[self objectAtIndex:i];

    if([array indexOfObject:object]!=NSNotFound)
     return object;
   }

   return nil;
}



-lastObject {
   int count=[self count];

   if(count==0)
    return nil;

   return [self objectAtIndex:count-1];
}

-(NSArray *)sortedArrayUsingSelector:(SEL)selector {
   NSMutableArray *array=[NSMutableArray arrayWithArray:self];

   [array sortUsingSelector:selector];

   return array;
}

-(NSArray *)sortedArrayUsingFunction:(int (*)(id, id, void *))function
   context:(void *)context {
   NSMutableArray *array=[NSMutableArray arrayWithArray:self];

   [array sortUsingFunction:function context:context];

   return array;
}

-(BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically {
   return [NSPropertyListWriter_vintage writePropertyList:self toFile:path atomically:atomically];
}


-(void)makeObjectsPerformSelector:(SEL)selector {
   int count=[self count];

   while(--count>=0)
    [[self objectAtIndex:count] performSelector:selector];
}


-(void)makeObjectsPerformSelector:(SEL)selector withObject:object {
   int count=[self count];

   while(--count>=0)
    [[self objectAtIndex:count] performSelector:selector withObject:object];
}

-(NSString *)description {
   return [NSPropertyListWriter_vintage stringWithPropertyList:self];
}

-(NSString *)descriptionWithLocale:(NSDictionary *)locale {
   NSUnimplementedMethod();
   return nil;
}

-(NSString *)descriptionWithLocale:(NSDictionary *)locale
   indent:(unsigned)level {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)filteredArrayUsingPredicate:(NSPredicate *)predicate {
   int             i,count=[self count];
   NSMutableArray *result=[NSMutableArray arrayWithCapacity:count];
   
   for(i=0;i<count;i++){
    id check=[self objectAtIndex:i];
    
    if([predicate evaluateWithObject:check])
     [result addObject:check];
   }
    
   return result;
}

-(NSArray *)sortedArrayUsingDescriptors:(NSArray *)descriptors {
   NSMutableArray *result=[NSMutableArray arrayWithArray:self];
   
   [result sortUsingDescriptors:descriptors];
   
   return result;
}


@end

