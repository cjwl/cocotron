/* Copyright (c) 2009 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KeyedArchiving.h"

@interface ArchivableClass : NSObject <NSCoding>
{
}

@end

@implementation ArchivableClass

- (void)encodeWithCoder:(NSCoder *)encoder {
   if([encoder allowsKeyedCoding]) {
      NSKeyedArchiver *coder=(NSKeyedArchiver*)encoder;
      [coder encodeObject:@"string" forKey:@"string"];
      [coder encodeFloat:17.5 forKey:@"float"];

   }
   else {
      [NSException raise:NSInternalInconsistencyException format:@"%@ only supports keyed coding", [self className]];
   }
}

- (id)initWithCoder:(NSCoder *)decoder {
   if([decoder allowsKeyedCoding]) {
      NSKeyedUnarchiver *coder=(NSKeyedUnarchiver*)decoder;
   
      NSAssert([[coder decodeObjectForKey:@"string"] isEqual:@"string"], @"keyed string decoding");
      NSAssert([coder decodeFloatForKey:@"float"]==17.5, @"keyed string decoding");
   }
   else {
      [NSException raise:NSInternalInconsistencyException format:@"%@ only supports keyed coding", [self className]];
   }
   return self;  
}

@end


@implementation KeyedArchiving

-(void)testOwnCoding {
   id object=[[ArchivableClass new] autorelease];
   id data=[NSKeyedArchiver archivedDataWithRootObject:object];
   
   // if you change the encoding of ArchivableClass, you need to uncomment the line below, run on Apple-Darwin,
   // then copy the resulting data file
   //[data writeToFile:[@"~/ArchivableClass.keyedArchive" stringByExpandingTildeInPath] atomically:NO];

   object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(void)testForeignDecoding {
   id path=[[NSBundle bundleForClass:isa] pathForResource:@"ArchivableClass" ofType:@"keyedArchive"];
   STAssertNotNil(path, @"Data file not found");
   id data=[NSData dataWithContentsOfFile:path];
   STAssertNotNil(data, @"Data file couldn't be opened");
   
   STAssertNoThrow([NSKeyedUnarchiver unarchiveObjectWithData:data], nil);
}

@end
