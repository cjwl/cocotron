/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSMutableData_concrete.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSData_concrete.h>

@implementation NSMutableData

+allocWithZone:(NSZone *)zone {
   if(self==OBJCClassFromString("NSMutableData"))
    return NSAllocateObject(OBJCClassFromString("NSMutableData_concrete"),0,zone);

   return NSAllocateObject(self,0,zone);
}

-initWithCapacity:(unsigned)capacity {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithLength:(unsigned)length {
   self=[self initWithCapacity:length];
   [self setLength:length];
   return self;
}

-initWithBytesNoCopy:(void *)bytes length:(unsigned)length freeWhenDone:(BOOL)freeWhenDone {
   self=[self initWithCapacity:length];

   [self appendBytes:bytes length:length];

   NSZoneFree(NSZoneFromPointer(bytes),bytes);

   return self;
}

-initWithContentsOfMappedFile:(NSString *)path {
    NSUnimplementedMethod();
}

+dataWithCapacity:(unsigned)capacity {
   return [[[self allocWithZone:NULL] initWithCapacity:capacity] autorelease];
}

+dataWithLength:(unsigned)length {
   return [[[self allocWithZone:NULL] initWithLength:length] autorelease];
}

-copyWithZone:(NSZone *)zone {
   return [[NSData allocWithZone:zone] initWithBytes:[self bytes] length:[self length]];
}

-(Class)classForCoder {
   return [NSMutableData class];
}

-(void *)mutableBytes {
   NSInvalidAbstractInvocation();
   return NULL;
}

-(void)setLength:(unsigned)length {
   NSInvalidAbstractInvocation();
}

-(void)increaseLengthBy:(unsigned)delta {
   [self setLength:[self length]+delta];
}

-(void)appendBytes:(const void *)bytes length:(unsigned)length {
   unsigned selfLength=[self length];
   NSRange  range=NSMakeRange(selfLength,length);

   [self setLength:selfLength+length];
   [self replaceBytesInRange:range withBytes:bytes];
}

-(void)appendData:(NSData *)data {
   [self appendBytes:[data bytes] length:[data length]];
}

-(void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes {
   int   i,length=[self length];
   void *mutableBytes;

   if(range.location>length)
    NSRaiseException(NSRangeException,self,_cmd,@"location %d beyond length %d",range.location,[self length]);

   if(range.location+range.length>length)
    [self setLength:range.location+range.length];
    
   mutableBytes=[self mutableBytes];

   for(i=0;i<range.length;i++)
    ((char *)mutableBytes)[range.location+i]=((char *)bytes)[i];
}

-(void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes length:(unsigned)bytesLength {
   int   i,length=[self length];
   char *mutableBytes;

   if(range.location>length)
    NSRaiseException(NSRangeException,self,_cmd,@"location %d beyond length %d",range.location,[self length]);

   if(bytesLength>range.length){
    int delta=bytesLength-range.length;
    int pos=length;
    
    [self setLength:length+delta];

    mutableBytes=[self mutableBytes];

    while(--pos>range.location+range.length)
     mutableBytes[pos-delta]=mutableBytes[pos-delta-1];
   }
   else if(bytesLength<range.length){
    int delta=range.length-bytesLength;
    
    mutableBytes=[self mutableBytes];

    for(i=range.location+bytesLength;i<length-delta;i++)
     mutableBytes[i]=mutableBytes[i+delta];
     
    [self setLength:length-delta];

    mutableBytes=[self mutableBytes];
   }
   else {
    mutableBytes=[self mutableBytes];
   }
   
   for(i=0;i<bytesLength;i++)
    mutableBytes[range.location+i]=((char *)bytes)[i];
}

-(void)setData:(NSData *)data {
   [self setLength:[data length]];
   [self replaceBytesInRange:NSMakeRange(0,[data length]) withBytes:[data bytes]];
}

-(void)resetBytesInRange:(NSRange)range {
   if(NSMaxRange(range)>[self length])
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond length %d",NSStringFromRange(range),[self length]);

   NSByteZeroRange([self mutableBytes],range);
}

@end
