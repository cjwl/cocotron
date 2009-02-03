//
//  KeyedArchiving.m
//  UnitTests
//
//  Created by Johannes Fortmann on 03.02.09.
//  Copyright 2009 -. All rights reserved.
//

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
      [coder encodePoint:NSMakePoint(15, 12) forKey:@"point"];
      [coder encodeValueOfObjCType:@encode(SEL) at:&_cmd];
   }
   else {
      [NSException raise:NSInternalInconsistencyException format:@"%@ only supports keyed coding", [self className]];
   }
}

- (id)initWithCoder:(NSCoder *)decoder {
   if([decoder allowsKeyedCoding]) {
      NSKeyedUnarchiver *coder=(NSKeyedUnarchiver*)decoder;
      
      NSAssert([[coder decodeObjectForKey:@"string"] isEqual:@"string"], @"keyed string decoding");
      NSAssert([coder decodePointForKey:@"point"].x==15, @"keyed point decoding");
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
   NSLog(@"data %@", data);
   object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
