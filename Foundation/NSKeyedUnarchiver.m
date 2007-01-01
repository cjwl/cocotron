/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSKeyedUnarchiver.h>
#import <Foundation/NSPropertyListReader.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>

@interface NSObject(NSKeyedUnarchiverPrivate)
+(id)allocWithKeyedUnarchiver:(NSKeyedUnarchiver *)keyed;
@end

@implementation NSObject(NSKeyedUnarchiverPrivate)

+(id)allocWithKeyedUnarchiver:(NSKeyedUnarchiver *)keyed {
   return [self allocWithZone:NULL];
}

@end

@implementation NSKeyedUnarchiver

-initForReadingWithData:(NSData *)data {
   _nameToReplacementClass=[NSMutableDictionary new];
   _propertyList=[[NSPropertyListReader propertyListFromData:data] retain];
   _objects=[[_propertyList objectForKey:@"$objects"] retain];
   _plistStack=[NSMutableArray new];
   [_plistStack addObject:[_propertyList objectForKey:@"$top"]];
   _uidToObject=NSCreateMapTable(NSIntMapKeyCallBacks,NSNonRetainedObjectMapValueCallBacks,0);
   return self;
}

-(void)dealloc {
   [_nameToReplacementClass release];
   [_propertyList release];
   [_objects release];
   [_plistStack release];
   if(_uidToObject!=NULL)
    NSFreeMapTable(_uidToObject);
   [super dealloc];
}

-(BOOL)allowsKeyedCoding {
   return YES;
}

-(Class)decodeClassFromDictionary:(NSDictionary *)classReference {
   Class         result;
   NSDictionary *plist=[classReference objectForKey:@"$class"];
   NSNumber     *uid=[plist objectForKey:@"CF$UID"];
   NSDictionary *profile=[_objects objectAtIndex:[uid intValue]];
   NSDictionary *classes=[profile objectForKey:@"$classes"];
   NSString     *className=[profile objectForKey:@"$classname"];
   
   if((result=[_nameToReplacementClass objectForKey:className])==Nil)
    if((result=NSClassFromString(className))==Nil)
     [NSException raise:NSInvalidArgumentException format:@"Unable to find class named %@",className];
    
   return result;
}

-decodeObjectForUID:(NSNumber *)uid {
   int uidIntValue=[uid intValue];
   id result=NSMapGet(_uidToObject,(void *)uidIntValue);
            
   if(result==nil){
    id plist=[_objects objectAtIndex:uidIntValue];
    
    if([plist isKindOfClass:[NSString class]]){
     if([plist isEqualToString:@"$null"])
      result=nil;
     else {
      result=plist;
      NSMapInsert(_uidToObject,(void *)uidIntValue,result);
     }
    }
    else if([plist isKindOfClass:[NSDictionary class]]){
     Class class=[self decodeClassFromDictionary:plist];
   
     [_plistStack addObject:plist];
     result=[class allocWithKeyedUnarchiver:self];
     NSMapInsert(_uidToObject,(void *)uidIntValue,result);
     result=[[result initWithCoder:self] autorelease];
     NSMapInsert(_uidToObject,(void *)uidIntValue,result);
     result=[result awakeAfterUsingCoder:self];
     NSMapInsert(_uidToObject,(void *)uidIntValue,result);
     [_plistStack removeLastObject];
    }
    else if([plist isKindOfClass:[NSNumber class]]){
     result=plist;
     NSMapInsert(_uidToObject,(void *)uidIntValue,result);
    }
    else
     NSLog(@"plist of class %@",[plist class]);
   }
   
   return result;  
}

-decodeRootObject {
   NSDictionary *top=[_propertyList objectForKey:@"$top"];
   NSArray      *values=[top allValues];

   if([values count]!=1){
    NSLog(@"multiple values=%@",values);
    return nil;
   }
   else {
    NSDictionary *object=[values objectAtIndex:0];
    NSNumber     *uid=[object objectForKey:@"CF$UID"];
    
    return [self decodeObjectForUID:uid];
   }
}

+unarchiveObjectWithData:(NSData *)data {
   NSKeyedUnarchiver *unarchiver=[[[self alloc] initForReadingWithData:data] autorelease];
   
   return [unarchiver decodeRootObject];
}

+unarchiveObjectWithFile:(NSString *)path {
   NSData *data=[NSData dataWithContentsOfFile:path];
   
   return [self unarchiveObjectWithData:data];
}

-(BOOL)containsValueForKey:(NSString *)key {
   return ([[_plistStack lastObject] objectForKey:key]!=nil)?YES:NO;
}

-(const void *)decodeBytesForKey:(NSString *)key returnedLength:(unsigned *)lengthp {
   NSData *data=[[_plistStack lastObject] objectForKey:key];

   *lengthp=[data length];
   
   return [data bytes];
}

-(NSNumber *)_numberForKey:(NSString *)key {
   NSNumber *result=[[_plistStack lastObject] objectForKey:key];

   if(result==nil || [result isKindOfClass:[NSNumber class]])
    return result;
   
   [NSException raise:@"NSKeyedUnarchiverException" format:@"Expecting number, got %@",result];
   return nil;
}

-(BOOL)decodeBoolForKey:(NSString *)key {
   NSNumber *number=[self _numberForKey:key];
   
   return [number boolValue];
}

-(double)decodeDoubleForKey:(NSString *)key {
   NSNumber *number=[self _numberForKey:key];
   
   return [number doubleValue];
}

-(float)decodeFloatForKey:(NSString *)key {
   NSNumber *number=[self _numberForKey:key];
   
   return [number floatValue];
}

-(int)decodeIntForKey:(NSString *)key {
   NSNumber *number=[self _numberForKey:key];
   
   return [number intValue];
}

-(int)decodeInt32ForKey:(NSString *)key {
   NSNumber *number=[self _numberForKey:key];
   
   return [number intValue];
}

-(int)decodeInt64ForKey:(NSString *)key {
   NSNumber *number=[self _numberForKey:key];
   
   return [number intValue];
}

// not a lot of validation
-(unsigned)decodeArrayOfFloats:(float *)result forKey:(NSString *)key {
   NSString *string=[self decodeObjectForKey:key];
   unsigned i,length=[string length],resultLength=0;
   unichar  buffer[length];
   double   multiplier=0.10,sign=1;
   enum {
    expectingBraceOrSpace,
    expectingBraceSpaceOrInteger,
    expectingSpaceOrInteger,
    expectingInteger,
    expectingFraction,
    expectingCommaBraceOrSpace,
    expectingSpace
   } state=expectingBraceOrSpace;
  
   if(string==nil)
    return NSNotFound;
    
   [string getCharacters:buffer];
    
   for(i=0;i<length;i++){
    unichar code=buffer[i];
     
    switch(state){
     
     case expectingBraceOrSpace:
      if(code=='{')
       state=expectingBraceSpaceOrInteger;
      else if(code>' ')
       [NSException raise:NSInvalidArgumentException format:@"Unable to parse geometry %@, state=%d",string,state];
      break;
      
     case expectingBraceSpaceOrInteger:
      if(code=='{'){
       state=expectingSpaceOrInteger;
       break;
      }
      // fallthru     
     case expectingSpaceOrInteger:
      if(code<=' ')
       break;
      // fallthru
     case expectingInteger:
      state=expectingInteger;
      if(code=='-')
       sign=-1;
      else if(code>='0' && code<='9')
       result[resultLength]=result[resultLength]*10+(code-'0');
      else if(code=='.'){
       multiplier=0.10;
       state=expectingFraction;
      }
      else if(code==','){
       result[resultLength++]*=sign;
       sign=1;
       state=expectingSpaceOrInteger;
      }
      else if(code=='}'){
       result[resultLength++]*=sign;
       sign=1;
       state=expectingCommaBraceOrSpace;
      }
      else if(code<=' '){
       result[resultLength++]*=sign;
       sign=1;
       state=expectingCommaBraceOrSpace;
      }
      else
       [NSException raise:NSInvalidArgumentException format:@"Unable to parse geometry %@, state=%d",string,state];
      break;
       
     case expectingFraction:
      if(code>='0' && code<='9'){
       result[resultLength]=result[resultLength]+multiplier*(code-'0');
       multiplier/=10;
      }
      else if(code==','){
       result[resultLength++]*=sign;
       sign=1;
       state=expectingSpaceOrInteger;
      }
      else if(code=='}'){
       result[resultLength++]*=sign;
       sign=1;
       state=expectingBraceSpaceOrInteger;
      }
      else
       [NSException raise:NSInvalidArgumentException format:@"Unable to parse geometry %@, state=%d",string,state];
      break;
     
     case expectingCommaBraceOrSpace:
      if(code==',')
       state=expectingBraceSpaceOrInteger;
      else if(code=='}')
       state=expectingSpace;
      else if(code>=' ')
       [NSException raise:NSInvalidArgumentException format:@"Unable to parse geometry %@, state=%d",string,state];
      break;
      
     case expectingSpace:
      if(code>=' ')
       [NSException raise:NSInvalidArgumentException format:@"Unable to parse geometry %@, state=%d",string,state];
      break;
    }
   }
   
   return resultLength; 
}

-(NSPoint)decodePointForKey:(NSString *)key {
   float    array[4]={ 0,0,0,0 };
   unsigned length=[self decodeArrayOfFloats:array forKey:key];
   
   return NSMakePoint(array[0],array[1]);
}

-(NSSize)decodeSizeForKey:(NSString *)key {
   float     array[4]={ 0,0,0,0 };
   unsigned length=[self decodeArrayOfFloats:array forKey:key];
   
   return NSMakeSize(array[0],array[1]);
}

-(NSRect)decodeRectForKey:(NSString *)key {
   float    array[4]={ 0,0,0,0 };
   unsigned length=[self decodeArrayOfFloats:array forKey:key];
   
   return NSMakeRect(array[0],array[1],array[2],array[3]);
}

-_decodeObjectWithPropertyList:plist {

   if([plist isKindOfClass:[NSString class]])
    return plist;
   if([plist isKindOfClass:[NSDictionary class]]){
    NSNumber *uid=[plist objectForKey:@"CF$UID"];

    return [self decodeObjectForUID:uid];
   }
   else if([plist isKindOfClass:[NSArray class]]){
    NSMutableArray *result=[NSMutableArray array];
    int             i,count=[plist count];
    
    for(i=0;i<count;i++){
     id sibling=[plist objectAtIndex:i];
     
     [result addObject:[self _decodeObjectWithPropertyList:sibling]];
    }
    
    return result;
   }
   
   [NSException raise:@"NSKeyedUnarchiverException" format:@"Unable to decode property list with class %@",[plist class]];
   return nil;
}

-decodeObjectForKey:(NSString *)key {
   id result;
      
   id plist=[[_plistStack lastObject] objectForKey:key];
   
   if(plist==nil)
    result==nil;
   else
    result=[self _decodeObjectWithPropertyList:plist];

   return result;
}

-(void)finishDecoding {
}

-delegate {
   return _delegate;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

+(void)setClass:(Class)class forClassName:(NSString *)className {
}

+(Class)classForClassName:(NSString *)className {
   return Nil;
}

-(void)setClass:(Class)class forClassName:(NSString *)className {
   [_nameToReplacementClass setObject:class forKey:className];
}

-(Class)classForClassName:(NSString *)className {
   return [_nameToReplacementClass objectForKey:className];
}

@end
