/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSData.h>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSData_concrete.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSKeyedUnarchiver.h>

#import <Foundation/NSRaise.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSURL.h>

@implementation NSData

+allocWithZone:(NSZone *)zone {
   if(self==OBJCClassFromString("NSData"))
    return NSAllocateObject([NSData_concrete class],0,zone);

   return NSAllocateObject(self,0,zone);
}

-initWithBytesNoCopy:(void *)bytes length:(unsigned)length freeWhenDone:(BOOL)freeOnDealloc {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithBytesNoCopy:(void *)bytes length:(unsigned)length {
   return [self initWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

-initWithBytes:(const void *)bytes length:(unsigned)length {
   return [self initWithBytesNoCopy:NSBytesReplicate(bytes,length,
    NSZoneFromPointer(self)) length:length];
}

-initWithData:(NSData *)data {
   return [self initWithBytes:[data bytes] length:[data length]];
}

-initWithContentsOfFile:(NSString *)path {
   unsigned length;
   void    *bytes=[[NSPlatform currentPlatform] contentsOfFile:path length:&length];

   if(bytes==NULL){
    [self dealloc];
    return nil;
   }

   return [self initWithBytesNoCopy:bytes length:length];
}

-initWithContentsOfMappedFile:(NSString *)path {
   unsigned length;
   void    *bytes=[[NSPlatform currentPlatform] contentsOfFile:path length:&length];

   if(bytes==NULL){
    [self dealloc];
    return nil;
   }

   return [self initWithBytesNoCopy:bytes length:length];
}

-initWithContentsOfURL:(NSURL *)url {
   if(![url isFileURL]){
    [self dealloc];
    return nil;
   }
   return [self initWithContentsOfFile:[url path]];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [[NSMutableData allocWithZone:zone] initWithData:self];
}

-(Class)classForCoder {
   return [NSData class];
}

-initWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    NSData            *data=[keyed decodeObjectForKey:@"NS.data"];
    
    return [self initWithData:data];
   }
   else {
    [self dealloc];
    return [[coder decodeDataObject] retain];
   }
}

-(void)encodeWithCoder:(NSCoder *)coder {
   [coder encodeDataObject:self];
}

+data {
   if(self==OBJCClassFromString("NSData"))
    return NSAutorelease(NSData_concreteNew(NULL,NULL,0));

   return [[[self allocWithZone:NULL] init] autorelease];
}

+dataWithBytesNoCopy:(void *)bytes length:(unsigned)length freeWhenDone:(BOOL)freeOnDealloc{
   return [[[self allocWithZone:NULL] initWithBytesNoCopy:bytes length:length freeWhenDone:freeOnDealloc] autorelease];
}

+dataWithBytesNoCopy:(void *)bytes length:(unsigned)length {
   if(self==OBJCClassFromString("NSData"))
    return NSAutorelease(NSData_concreteNewNoCopy(NULL,bytes,length));

   return [[[self allocWithZone:NULL] initWithBytesNoCopy:bytes length:length] autorelease];
}

+dataWithBytes:(const void *)bytes length:(unsigned)length {
   if(self==OBJCClassFromString("NSData"))
    return NSAutorelease(NSData_concreteNew(NULL,bytes,length));

   return [[[self allocWithZone:NULL] initWithBytes:bytes length:length] autorelease];
}

+dataWithData:(NSData *)data {
   if(self==OBJCClassFromString("NSData"))
    return NSAutorelease(NSData_concreteNew(NULL,[data bytes],[data length]));

   return [[[self allocWithZone:NULL] initWithBytes:[data bytes] length:[data length]] autorelease];
}

+dataWithContentsOfFile:(NSString *)path {
   return [[[self allocWithZone:NULL] initWithContentsOfFile:path] autorelease];
}

+dataWithContentsOfMappedFile:(NSString *)path {
   return [[[self allocWithZone:NULL] initWithContentsOfMappedFile:path] autorelease];
}

+dataWithContentsOfURL:(NSURL *)url {
   return [[[self allocWithZone:NULL] initWithContentsOfURL:url] autorelease];
}

-(const void *)bytes {
   NSInvalidAbstractInvocation();
   return NULL;
}

-(unsigned)length {
   NSInvalidAbstractInvocation();
   return 0;
}

-(BOOL)isEqual:other {
   if(self==other)
    return YES;

   if(![other isKindOfClass:OBJCClassFromString("NSData")])
    return NO;

   return [self isEqualToData:other];
}

-(BOOL)isEqualToData:(NSData *)other {
   unsigned length;

   if(self==other)
    return YES;

   length=[self length];
   if(length!=[other length])
    return NO;

   return NSBytesEqual([self bytes],[other bytes],length);
}

-(void)getBytes:(void *)buffer range:(NSRange)range {
   const char *bytes=[self bytes];
   unsigned    i;

   if(NSMaxRange(range)>[self length]){
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond length %d",
     NSStringFromRange(range),[self length]);
   }

   for(i=0;i<range.length;i++)
    ((char *)buffer)[i]=bytes[range.location+i];
}

-(void)getBytes:(void *)buffer {
   NSRange range={0,[self length]};
   [self getBytes:buffer range:range];
}

-(void)getBytes:(void *)buffer length:(unsigned)length {
   NSRange range={0,length};
   [self getBytes:buffer range:range];
}

-(NSData *)subdataWithRange:(NSRange)range {
   void *buffer;

   if(NSMaxRange(range)>[self length]){
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond length %d",
     NSStringFromRange(range),[self length]);
   }

   buffer=NSZoneCalloc(NSZoneFromPointer(self),range.length,sizeof(char));

   [self getBytes:buffer range:range];

   return NSAutorelease(NSData_concreteNewNoCopy(NULL,buffer,range.length));
}

-(BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically {
   return [[NSPlatform currentPlatform] writeContentsOfFile:path bytes:[self bytes] length:[self length] atomically:atomically];
}

-(NSString *)description {
   const char *hex="0123456789ABCDEF";
   const char *bytes=[self bytes];
   unsigned    length=[self length];
   unsigned    pos=0,i;
   char       *cString;
   NSString   *string=NSAutorelease(NSString_cStringNewWithCapacity(NULL,
     1+length*2+(length/4)+1,&cString));

   cString[pos++]='<';
   for(i=0;i<length;){
    unsigned char byte=bytes[i];

    cString[pos++]=hex[byte>>4];
    cString[pos++]=hex[byte&0x0F];
    i++;

    if((i%4)==0 && i<length)
     cString[pos++]=' ';
   }
   cString[pos++]='>';

   return string;
}

@end
