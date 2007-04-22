/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNumber.h>

@implementation NSKeyedArchiver

static NSMapTable *_globalNameToClass=NULL;

+(void)initialize {
   if(self==[NSKeyedArchiver class]){
    _globalNameToClass=NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   }
}

+(NSData *)archivedDataWithRootObject:rootObject {
}

+(BOOL)archiveRootObject:rootObject toFile:(NSString *)path {
   NSData *data=[self archivedDataWithRootObject:rootObject];
   
   return [data writeToFile:path atomically:YES];
}

-initForWritingWithMutableData:(NSMutableData *)data {
   _data=[data retain];
   _plistStack=[NSMutableArray new];
   [_plistStack addObject:[NSMutableDictionary dictionary]];
   [[_plistStack lastObject] setObject:[NSMutableDictionary dictionary] forKey:@"$top"];
   _objects=[NSMutableArray new];
   [[_plistStack lastObject] setObject:_objects forKey:@"$objects"];
   [[_plistStack lastObject] setObject:[self className] forKey:@"$archiver"];
   [[_plistStack lastObject] setObject:@"100000" forKey:@"$version"];
   
   _nameToClass=NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   _pass=0;
   _objectToUid=NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,NSObjectMapValueCallBacks,0);
   return self;
}

-init {
   return [self initForWritingWithMutableData:[NSMutableData data]];
}

-(void)dealloc {
   [_data release];
   [_plistStack release];
   NSFreeMapTable(_nameToClass);
   NSFreeMapTable(_objectToUid);
   [super dealloc];
}

+(NSString *)classNameForClass:(Class)class {
   return NSMapGet(_globalNameToClass,(void *)class);
}

+(void)setClassName:(NSString *)className forClass:(Class)class {
  NSMapInsert(_globalNameToClass,class,className);
}

-delegate {
   return _delegate;
}

-(NSString *)classNameForClass:(Class)class {
   return NSMapGet(_nameToClass,(void *)class);
}

-(NSPropertyListFormat)outputFormat {
   return _outputFormat;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setClassName:(NSString *)className forClass:(Class)class {
  NSMapInsert(_nameToClass,class,className);
}

-(void)setOutputFormat:(NSPropertyListFormat)format {
   _outputFormat=format;
}

-(void)encodeBool:(BOOL)value forKey:(NSString *)key {
   if(_pass==0)
    return;

   [[_plistStack lastObject] setObject:[NSNumber numberWithBool:value] forKey:key];
}

-(void)encodeInt:(int)value forKey:(NSString *)key {
   if(_pass==0)
    return;

   [[_plistStack lastObject] setObject:[NSNumber numberWithInt:value] forKey:key];
}

-(void)encodeInt32:(int)value forKey:(NSString *)key {
   if(_pass==0)
    return;

   [[_plistStack lastObject] setObject:[NSNumber numberWithInt:value] forKey:key];
}

-(void)encodeInt64:(long long)value forKey:(NSString *)key {
   if(_pass==0)
    return;

   [[_plistStack lastObject] setObject:[NSNumber numberWithLongLong:value] forKey:key];
}

-(void)encodeFloat:(float)value forKey:(NSString *)key {
   if(_pass==0)
    return;

   [[_plistStack lastObject] setObject:[NSNumber numberWithFloat:value] forKey:key];
}

-(void)encodeDouble:(double)value forKey:(NSString *)key {
   if(_pass==0)
    return;

   [[_plistStack lastObject] setObject:[NSNumber numberWithDouble:value] forKey:key];
}

-(void)encodeBytes:(const void *)ptr length:(unsigned)length forKey:(NSString *)key {
   if(_pass==0)
    return;
   
   [[_plistStack lastObject] setObject:[NSData dataWithBytes:ptr length:length] forKey:key];
}

-plistForObject:object {
   NSNumber *uid=NSMapGet(_objectToUid,object);
   
   if(uid==nil){
    uid=[NSNumber numberWithInt:[_objects count]];
    NSMapInsert(_objectToUid,object,uid);
    
    [_objects addObject:[NSMutableDictionary dictionary]];
    [_plistStack addObject:[_objects lastObject]];
    //encode class;
    
    [object encodeWithCoder:self];
    [_plistStack removeLastObject];
   }
   
   return [NSDictionary dictionaryWithObject:uid forKey:@"CF$UID"];
}

-(void)encodeObject:object forKey:(NSString *)key {
   [[_plistStack lastObject] setObject:[self plistForObject:object] forKey:key];
}

-(void)encodeConditionalObject:object forKey:(NSString *)key {
   if(_pass==0)
    return;
    
   [self encodeObject:object forKey:key];
}


-(void)finishEncoding {
   if(_pass==0)
    return;
}

@end
