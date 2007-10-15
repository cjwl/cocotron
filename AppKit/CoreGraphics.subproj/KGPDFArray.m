/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFArray.h"
#import "KGPDFObject_Real.h"
#import <AppKit/KGPDFContext.h>
#import <Foundation/NSString.h>
#import <stddef.h>

@implementation KGPDFArray

+(KGPDFArray *)pdfArray {
   return [[[self alloc] init] autorelease];
}

+(KGPDFArray *)pdfArrayWithRect:(NSRect)rect {
   KGPDFArray *result=[self pdfArray];
   
   [result addNumber:rect.origin.x];
   [result addNumber:rect.origin.y];
   [result addNumber:rect.size.width];
   [result addNumber:rect.size.height];
   
   return result;
}

-init {
   _capacity=1;
   _count=0;
   _objects=NSZoneMalloc(NULL,sizeof(KGPDFObject *)*_capacity);
   return self;
}

-(void)dealloc {
   NSZoneFree(NULL,_objects);
   [super dealloc];
}

-(KGPDFObjectType)objectType { return kKGPDFObjectTypeArray; }

-(BOOL)checkForType:(KGPDFObjectType)type value:(void *)value {
   if(type!=kKGPDFObjectTypeArray)
    return NO;
   
   *((KGPDFArray **)value)=self;
   return YES;
}

-(unsigned)count { return _count; }

-(void)addObject:(KGPDFObject *)object {
   [object retain];

   _count++;
   if(_count>_capacity){
    _capacity=_count*2;
    _objects=NSZoneRealloc([self zone],_objects,sizeof(id)*_capacity);
   }
   _objects[_count-1]=object;
}

-(void)addNumber:(KGPDFReal)value {
   [self addObject:[KGPDFObject_Real pdfObjectWithReal:value]];
}

-(KGPDFObject *)objectAtIndex:(unsigned)index {
   if(index<_count)
    return _objects[index];
   else 
    return nil;
}

-(BOOL)getObjectAtIndex:(unsigned)index value:(KGPDFObject **)objectp {
   *objectp=[[self objectAtIndex:index] realObject];
   
   return YES;
}

-(BOOL)getNullAtIndex:(unsigned)index {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return ([object objectType]==kKGPDFObjectTypeNull)?YES:NO;
}

-(BOOL)getBooleanAtIndex:(unsigned)index value:(KGPDFBoolean *)valuep {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeBoolean value:valuep];
}

-(BOOL)getIntegerAtIndex:(unsigned)index value:(KGPDFInteger *)valuep {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeInteger value:valuep];
}

-(BOOL)getNumberAtIndex:(unsigned)index value:(KGPDFReal *)valuep {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeReal value:valuep];
}

-(BOOL)getNameAtIndex:(unsigned)index value:(char **)namep {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeName value:namep];
}

-(BOOL)getStringAtIndex:(unsigned)index value:(KGPDFString **)stringp {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeString value:stringp];
}

-(BOOL)getArrayAtIndex:(unsigned)index value:(KGPDFArray **)arrayp {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeArray value:arrayp];
}

-(BOOL)getDictionaryAtIndex:(unsigned)index value:(KGPDFDictionary **)dictionaryp {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeDictionary value:dictionaryp];
}

-(BOOL)getStreamAtIndex:(unsigned)index value:(KGPDFStream **)streamp {
   KGPDFObject *object=[self objectAtIndex:index];
   
   return [object checkForType:kKGPDFObjectTypeStream value:streamp];
}

-(BOOL)getNumbers:(KGPDFReal **)numbersp count:(unsigned *)countp {
   unsigned   i,count=[self count];
   KGPDFReal *numbers;
   
   numbers=NSZoneMalloc(NULL,sizeof(KGPDFReal)*count);
   for(i=0;i<count;i++){
    if(![self getNumberAtIndex:i value:numbers+i]){
     NSZoneFree(NULL,numbers);
     *numbersp=NULL;
     *countp=0;
     return NO;
    }
   }
   
   *numbersp=numbers;
   *countp=count;
   return YES;
}


-(NSString *)description {
   NSMutableString *result=[NSMutableString string];
   int              i;
   
   [result appendString:@"[ \n"];
   for(i=0;i<_count;i++)
    [result appendFormat:@"%@ ",_objects[i]];
   [result appendString:@" ]\n"];
   return result;
}

-(void)encodeWithPDFContext:(KGPDFContext *)encoder {
   int i;
   
   [encoder appendString:@"[ "];
   for(i=0;i<_count;i++)
    [encoder encodePDFObject:_objects[i]];
   [encoder appendString:@"]\n"];
}

@end
