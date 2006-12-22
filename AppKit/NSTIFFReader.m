/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSTIFFReader.h"
#import "NSTIFFImageFileDirectory.h"

@implementation NSTIFFReader

-(BOOL)tracingEnabled {
   return [[NSUserDefaults standardUserDefaults] boolForKey:@"NSTIFFTracingEnabled"];
}

-(unsigned)currentOffset {
   return _position;
}

-(void)seekToOffset:(unsigned)offset {
   if(offset>=_length)
    [NSException raise:NSInvalidArgumentException format:@"Attempt to seek past end of TIFF, length=%d,offset=%d",_length,offset];

   _position=offset;
}

-(unsigned)currentThenSeekToOffset:(unsigned)offset {
   unsigned result=[self currentOffset];

   [self seekToOffset:offset];

   return result;
}

-(unsigned char)nextUnsigned8 {
   if(_position<_length)
    return _bytes[_position++];

   [NSException raise:NSInvalidArgumentException format:@"Attempt to read past end of TIFF, length=%d",_length];
   return 0;
}

-(unsigned)nextUnsigned16 {
   unsigned result;
   unsigned byte0=[self nextUnsigned8];
   unsigned byte1=[self nextUnsigned8];

   if(_bigEndian){
    result=byte0;
    result<<=8;
    result|=byte1;
   }
   else {
    result=byte1;
    result<<=8;
    result|=byte0;
   }

   return result;
}

-(unsigned)nextUnsigned32 {
   unsigned result;
   unsigned byte0=[self nextUnsigned8];
   unsigned byte1=[self nextUnsigned8];
   unsigned byte2=[self nextUnsigned8];
   unsigned byte3=[self nextUnsigned8];

   if(_bigEndian){
    result=byte0;
    result<<=8;
    result|=byte1;
    result<<=8;
    result|=byte2;
    result<<=8;
    result|=byte3;
   }
   else {
    result=byte3;
    result<<=8;
    result|=byte2;
    result<<=8;
    result|=byte1;
    result<<=8;
    result|=byte0;
   }

   return result;
}

-(unsigned)nextUnsigned8AtOffset:(unsigned *)offset {
   unsigned result;
   unsigned save=[self currentThenSeekToOffset:*offset];

   result=[self nextUnsigned8];

   *offset=[self currentThenSeekToOffset:save];

   return result;
}

-(unsigned)nextUnsigned16AtOffset:(unsigned *)offset {
   unsigned result;
   unsigned save=[self currentThenSeekToOffset:*offset];

   result=[self nextUnsigned16];

   *offset=[self currentThenSeekToOffset:save];

   return result;
}

-(unsigned)nextUnsigned32AtOffset:(unsigned *)offset {
   unsigned result;
   unsigned save=[self currentThenSeekToOffset:*offset];

   result=[self nextUnsigned32];

   *offset=[self currentThenSeekToOffset:save];

   return result;
}

-(unsigned)expectUnsigned16 {
   unsigned result=0;
   unsigned type=[self nextUnsigned16];
   unsigned numberOfValues=[self nextUnsigned32];

   if(numberOfValues!=1){
    NSLog(@"TIFF parse error, expecting 1 value, got %d,type=%d",numberOfValues,type);
    return 0;
   }

   if(type==NSTIFFTypeSHORT)
    result=[self nextUnsigned16];
   else
    NSLog(@"TIFF parse error, expecting unsigned16 or unsinged32, got %d",type);

   return result;
}

-(unsigned)expectUnsigned32 {
   unsigned result=0;
   unsigned type=[self nextUnsigned16];
   unsigned numberOfValues=[self nextUnsigned32];

   if(numberOfValues!=1){
    NSLog(@"TIFF parse error, expecting 1 value, got %d,type=%d",numberOfValues,type);
    return 0;
   }

   if(type==NSTIFFTypeLONG)
    result=[self nextUnsigned32];
   else
    NSLog(@"TIFF parse error, expecting unsigned16 or unsinged32, got %d",type);

   return result;
}

-(double)expectRational {
   unsigned type=[self nextUnsigned16];
   unsigned numberOfValues=[self nextUnsigned32];
   unsigned offset=[self nextUnsigned32];
   double numerator,denominator;

   if(type!=NSTIFFTypeRATIONAL){
    NSLog(@"TIFF parse error, expecting rational, got %d",type);
    return 0;
   }

   if(numberOfValues!=1){
    NSLog(@"TIFF parse error, expecting 1 value, got %d,type=%d",numberOfValues,type);
    return 0;
   }

   numerator=[self nextUnsigned32AtOffset:&offset];
   denominator=[self nextUnsigned32AtOffset:&offset];

   return numerator/denominator;
}

-(void)_decodeArrayOfUnsigned8:(unsigned char **)valuesp count:(unsigned *)countp {
   unsigned       numberOfValues=[self nextUnsigned32];
   unsigned char *values;

   values=NSZoneMalloc([self zone],numberOfValues*sizeof(unsigned));

   if(numberOfValues==1)
    values[0]=[self nextUnsigned8];
   else if(numberOfValues==2){
    values[0]=[self nextUnsigned8];
    values[1]=[self nextUnsigned8];
   }
   else {
    unsigned i,offset=[self nextUnsigned32];

    for(i=0;i<numberOfValues;i++)
     values[i]=[self nextUnsigned8AtOffset:&offset];
   }

   *countp=numberOfValues;
   *valuesp=values; 
}

-(void)_decodeArrayOfUnsigned16:(unsigned **)valuesp count:(unsigned *)countp {
   unsigned  numberOfValues=[self nextUnsigned32];
   unsigned *values;

   values=NSZoneMalloc([self zone],numberOfValues*sizeof(unsigned));

   if(numberOfValues==1)
    values[0]=[self nextUnsigned16];
   else if(numberOfValues==2){
    values[0]=[self nextUnsigned16];
    values[1]=[self nextUnsigned16];
   }
   else {
    unsigned i,offset=[self nextUnsigned32];

    for(i=0;i<numberOfValues;i++)
     values[i]=[self nextUnsigned16AtOffset:&offset];
   }

   *countp=numberOfValues;
   *valuesp=values; 
}

-(void)_decodeArrayOfUnsigned32:(unsigned **)valuesp count:(unsigned *)countp {
   unsigned  numberOfValues=[self nextUnsigned32];
   unsigned *values;

   values=NSZoneMalloc([self zone],numberOfValues*sizeof(unsigned));

   if(numberOfValues==1)
    values[0]=[self nextUnsigned32];
   else {
    unsigned i,offset=[self nextUnsigned32];

    for(i=0;i<numberOfValues;i++)
     values[i]=[self nextUnsigned32AtOffset:&offset];
   }

   *countp=numberOfValues;
   *valuesp=values; 
}

-(NSString *)expectASCII {
   unsigned       type=[self nextUnsigned16];
   unsigned       count;
   unsigned char *ascii;

   if(type!=NSTIFFTypeASCII){
    NSLog(@"TIFF parse error, expecting ASCII, got %d",type);
    return nil;
   }

   [self _decodeArrayOfUnsigned8:&ascii count:&count];

   if(count==0){
    NSLog(@"TIFF parse error, ASCII count = 0");
    return nil;
   }

   return [NSString stringWithCString:(char *)ascii length:count-1];
}

-(unsigned)expectUnsigned16OrUnsigned32 {
   unsigned result=0;
   unsigned type=[self nextUnsigned16];
   unsigned numberOfValues=[self nextUnsigned32];

   if(numberOfValues!=1)
    NSLog(@"TIFF parse error, expecting 1 value, got %d,type=%d",numberOfValues,type);

   if(type==NSTIFFTypeSHORT)
    result=[self nextUnsigned16];
   else if(type==NSTIFFTypeLONG)
    result=[self nextUnsigned32];
   else
    NSLog(@"TIFF parse error, expecting unsigned16 or unsinged32, got %d",type);

   return result;
}


-(void)expectArrayOfUnsigned16:(unsigned **)valuesp count:(unsigned *)countp {
   unsigned type=[self nextUnsigned16];

   if(type!=NSTIFFTypeSHORT){
    NSLog(@"TIFF parse error, expecting unsigned16");
    return;
   }

   [self _decodeArrayOfUnsigned16:valuesp count:countp];
}

-(void)expectArrayOfUnsigned16OrUnsigned32:(unsigned **)valuesp count:(unsigned *)countp {
   unsigned type=[self nextUnsigned16];

   if(type==NSTIFFTypeSHORT)
    [self _decodeArrayOfUnsigned16:valuesp count:countp];
   else if(type==NSTIFFTypeLONG)
    [self _decodeArrayOfUnsigned32:valuesp count:countp];
   else
    NSLog(@"TIFF parse error, expecting unsigned16");
}

-(unsigned)parseImageFileDirectoryAtOffset:(unsigned)offset {
   NSTIFFImageFileDirectory *imageFileDirectory;

   [self seekToOffset:offset];

   imageFileDirectory=[[[NSTIFFImageFileDirectory alloc] initWithTIFFReader:self] autorelease];

   [_directory addObject:imageFileDirectory];

   return [self nextUnsigned32];
}

-(BOOL)parseImageFileHeader {
   BOOL result=YES;

   NS_DURING
    unsigned char byte0=[self nextUnsigned8];
    unsigned char byte1=[self nextUnsigned8];
    unsigned      fortyTwo;
    unsigned      nextEntryOffset;

    if(byte0=='I' && byte1=='I')
     _bigEndian=NO;
    else if(byte0=='M' && byte1=='M')
     _bigEndian=YES;
    else {
     NSLog(@"Unknown endian markers %02X %02X",byte0,byte1);
     return NO;
    }

    fortyTwo=[self nextUnsigned16];
    nextEntryOffset=[self nextUnsigned32];

    if(fortyTwo!=42){
     NSLog(@"FortyTwo does not equal 42, got %d",fortyTwo);
     return NO;
    }

    while((nextEntryOffset=[self parseImageFileDirectoryAtOffset:nextEntryOffset])!=0)
     ;

   NS_HANDLER
    result=NO;
   NS_ENDHANDLER

   return result;
}

-initWithData:(NSData *)data {
   _data=[data copy];
   _bytes=[_data bytes];
   _length=[_data length];
   _position=0;

   _directory=[NSMutableArray new];

   if(![self parseImageFileHeader]){
    [self dealloc];
    return nil;
   }
   return self;
}

-initWithContentsOfFile:(NSString *)path {
   NSData *data=[NSData dataWithContentsOfFile:path];
   
   if(data==nil){
    [self dealloc];
    return nil;
   }
   
   return [self initWithData:data];
}

-(void)dealloc {
   [_data release];
   [_directory release];
   [super dealloc];
}

-(int)pixelsWide {
   if([_directory count]==0)
    return 0;

   return [[_directory objectAtIndex:0] imageWidth];
}

-(int)pixelsHigh {
   if([_directory count]==0)
    return 0;

   return [[_directory objectAtIndex:0] imageLength];
}

-(BOOL)getRGBAImageBytes:(unsigned char *)bytes width:(int)width height:(int)height {
   if([_directory count]==0)
    return NO;

   [[_directory objectAtIndex:0] getRGBAImageBytes:bytes data:_data];
   return YES;
}

@end
