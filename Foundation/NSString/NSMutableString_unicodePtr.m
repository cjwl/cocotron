/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSMutableString_unicodePtr.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSStringHashing.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSStringFileIO.h>
#import <Foundation/NSString_cString.h>
#import <string.h>

@implementation NSMutableString_unicodePtr

-(unsigned)length {
   return _length;
}

-(unichar)characterAtIndex:(unsigned)location {
   if(location>=_length){
    NSRaiseException(NSRangeException,self,_cmd,@"index %d beyond length %d",
     location,[self length]);
   }

   return _unicode[location];
}

-(void)getCharacters:(unichar *)buffer {
   int i;

   for(i=0;i<_length;i++)
    buffer[i]=_unicode[i];
}

-(void)getCharacters:(unichar *)buffer range:(NSRange)range {
   int i,loc=range.location;

   if(NSMaxRange(range)>_length){
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond length %d",
     NSStringFromRange(range),[self length]);
   }

   for(i=0;i<range.length;i++)
    buffer[i]=_unicode[loc+i];
}

-(void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
   unsigned otherlength=[string length];
   unsigned i,loc=range.location;

   if(NSMaxRange(range)>_length){
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond length %d",
     NSStringFromRange(range),[self length]);
   }

   if(range.length<otherlength){ // make room
    unsigned delta=otherlength-range.length;

    _length+=delta;

    if(_length>_capacity){
     while(_length>_capacity)
      _capacity*=2;

     _unicode=NSZoneRealloc(NSZoneFromPointer(_unicode),_unicode,sizeof(unichar)*_capacity);
    }

    for(i=_length;--i>=loc+otherlength;)
     _unicode[i]=_unicode[i-delta];
   }
   else if(range.length>otherlength){ // delete some
    unsigned delta=range.length-otherlength;

    _length-=delta;

    for(i=loc+otherlength;i<_length;i++)
     _unicode[i]=_unicode[i+delta];
   }

   [string getCharacters:_unicode+loc range:NSMakeRange(0,otherlength)];
}

-(unsigned)hash {
   return NSStringHashUnicode(_unicode,MIN(_length,NSHashStringLength));
}

static inline unsigned roundCapacityUp(unsigned capacity){
   return (capacity<4)?4:capacity;
}

NSString *NSMutableString_unicodePtrInitWithCString(NSMutableString_unicodePtr *self,
 const char *cString,unsigned length,NSZone *zone){

   self->_unicode=NSCharactersFromCString(cString,length,
          &(self->_length),zone);
   self->_capacity=self->_length;

   return self;
}

NSString *NSMutableString_unicodePtrInit(NSMutableString_unicodePtr *self,
 const unichar *unicode,unsigned length,NSZone *zone){
   int i;

   self->_length=length;
   self->_capacity=roundCapacityUp(length);
   self->_unicode=NSZoneMalloc(zone,sizeof(unichar)*self->_capacity);
   for(i=0;i<length;i++)
    self->_unicode[i]=unicode[i];

   return self;
}

NSString *NSMutableString_unicodePtrInitNoCopy(NSMutableString_unicodePtr *self,
 unichar *unicode,unsigned length,NSZone *zone){

   self->_length=length;
   self->_capacity=length;
   self->_unicode=unicode;

   return self;
}

NSString *NSMutableString_unicodePtrInitWithCapacity(NSMutableString_unicodePtr *self,
 unsigned capacity,NSZone *zone) {

   self->_length=0;
   self->_capacity=roundCapacityUp(capacity);
   self->_unicode=NSZoneMalloc(zone,sizeof(unichar)*self->_capacity);

   return self;
}

NSString *NSMutableString_unicodePtrNewWithCString(NSZone *zone,
 const char *cString,unsigned length) {
   NSMutableString_unicodePtr *self=NSAllocateObject(OBJCClassFromString("NSMutableString_unicodePtr"),0,zone);

   return NSMutableString_unicodePtrInitWithCString(self,cString,length,zone);
}

NSString *NSMutableString_unicodePtrNew(NSZone *zone,
 const unichar *unicode,unsigned length) {
   NSMutableString_unicodePtr *self=NSAllocateObject(OBJCClassFromString("NSMutableString_unicodePtr"),0,zone);

   return NSMutableString_unicodePtrInit(self,unicode,length,zone);
}

NSString *NSMutableString_unicodePtrNewNoCopy(NSZone *zone,
 unichar *unicode,unsigned length) {
   NSMutableString_unicodePtr *self;

   self=NSAllocateObject(OBJCClassFromString("NSMutableString_unicodePtr"),0,zone);

   return NSMutableString_unicodePtrInitNoCopy(self,unicode,length,zone);
}

NSString *NSMutableString_unicodePtrNewWithCapacity(NSZone *zone,
 unsigned capacity) {
   NSMutableString_unicodePtr *self;

   self=NSAllocateObject(OBJCClassFromString("NSMutableString_unicodePtr"),0,zone);

   return NSMutableString_unicodePtrInitWithCapacity(self,capacity,zone);
}

-(void)dealloc {
   NSZoneFree(NSZoneFromPointer(self->_unicode),self->_unicode);
   NSDeallocateObject(self); 
}

-init {
   return NSMutableString_unicodePtrInitWithCapacity(self,0,
     NSZoneFromPointer(self));
}

-initWithCharactersNoCopy:(unichar *)characters length:(unsigned)length
             freeWhenDone:(BOOL)freeBuffer {
   NSString *string=NSMutableString_unicodePtrInit(self,characters,length,
     NSZoneFromPointer(self));

   if(freeBuffer)
    NSZoneFree(NSZoneFromPointer(characters),characters);

   return string;
}

-initWithCharacters:(const unichar *)characters length:(unsigned)length {
   return NSMutableString_unicodePtrInit(self,characters,length,
     NSZoneFromPointer(self));
}

-initWithCStringNoCopy:(char *)bytes length:(unsigned)length
          freeWhenDone:(BOOL)freeBuffer {
   NSString *string=NSMutableString_unicodePtrInitWithCString(self,bytes,length,
     NSZoneFromPointer(self));

   if(freeBuffer)
    NSZoneFree(NSZoneFromPointer(bytes),bytes);

   return string;
}

-initWithCString:(const char *)bytes length:(unsigned)length {
   return NSMutableString_unicodePtrInitWithCString(self,bytes,length,
     NSZoneFromPointer(self));
}

-initWithCString:(const char *)bytes {
   unsigned length=strlen(bytes);

   return NSMutableString_unicodePtrInitWithCString(self,bytes,length,
     NSZoneFromPointer(self));
}

-initWithString:(NSString *)string {
   unsigned length=[string length];
   unichar  unicode[length];

   [string getCharacters:unicode];

   return NSMutableString_unicodePtrInit(self,unicode,length,NSZoneFromPointer(self));
}

-initWithFormat:(NSString *)format,... {
   va_list   arguments;
   unsigned  length;
   unichar  *unicode;

   va_start(arguments,format);

   unicode=NSCharactersNewWithFormat(format,nil,arguments,&length,
     NSZoneFromPointer(self));

   return NSMutableString_unicodePtrInitNoCopy(self,unicode,length,
     NSZoneFromPointer(self));
}

-initWithFormat:(NSString *)format arguments:(va_list)arguments {
   unsigned  length;
   unichar  *unicode;

   unicode=NSCharactersNewWithFormat(format,nil,arguments,&length,
     NSZoneFromPointer(self));

   return NSMutableString_unicodePtrInitNoCopy(self,unicode,length,
     NSZoneFromPointer(self));
}

-initWithFormat:(NSString *)format locale:(NSDictionary *)locale,... {
   va_list   arguments;
   unsigned  length;
   unichar  *unicode;

   va_start(arguments,locale);

   unicode=NSCharactersNewWithFormat(format,locale,arguments,&length,
     NSZoneFromPointer(self));

   return NSMutableString_unicodePtrInitNoCopy(self,unicode,length,
     NSZoneFromPointer(self));
}

-initWithFormat:(NSString *)format
             locale:(NSDictionary *)locale arguments:(va_list)arguments {
   unsigned  length;
   unichar  *unicode;

   unicode=NSCharactersNewWithFormat(format,locale,arguments,&length,
     NSZoneFromPointer(self));

   return NSMutableString_unicodePtrInitNoCopy(self,unicode,length,
     NSZoneFromPointer(self));
}

-initWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
#if 0
   if(encoding==NSString_cStringEncoding)
    return NSString_cStringInitWithBytes(NULL,[data bytes],[data length]);

   switch(encoding){

    case NSString_unicodeEncoding:
     return NSString_unicodeInit(NULL,[data bytes],[data length]);

    case NSNEXTSTEPStringEncoding:
     return NSNEXTSTEPStringInitWithBytes(NULL,[data bytes],[data length]);

    case NSISOLatin1StringEncoding:
     return NSString_isoLatin1InitWithBytes(NULL,[data bytes],[data length]);

    case NSSymbolStringEncoding:
     break;

    default:
     break;
   }
#endif

   NSInvalidAbstractInvocation();
   return nil;
}

-initWithContentsOfFile:(NSString *)path {
   unsigned  length;
   unichar  *unicode;

   if((unicode=NSCharactersWithContentsOfFile(path,&length,NSZoneFromPointer(self)))==NULL){
    NSDeallocateObject(self); 
    return nil;
   }

   return NSMutableString_unicodePtrInitNoCopy(self,unicode,length,
     NSZoneFromPointer(self));
}

-initWithCapacity:(unsigned)capacity {
   return NSMutableString_unicodePtrInitWithCapacity(self,capacity,
     NSZoneFromPointer(self));
}

@end
