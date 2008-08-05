//
//  KeyedUnarchiver.m
//  UnitTests
//
//  Created by Johannes Fortmann on 05.08.08.
//  Copyright 2008 -. All rights reserved.
//

#import "KeyedUnarchiver.h"




@implementation KeyedUnarchiver
+(id)sampleList
{
   id plistDict;
   plistDict=[NSMutableDictionary dictionary];
   [plistDict setObject:@"string" forKey:@"string"];
   [plistDict setObject:[NSNumber numberWithFloat:17.5] forKey:@"float"];
   [plistDict setObject:[NSNumber numberWithBool:YES] forKey:@"boolean"];
   [plistDict setObject:[NSArray arrayWithObjects:@"first",@"second",@"third", nil] forKey:@"array"];
   [plistDict setObject:[NSDate dateWithTimeIntervalSince1970:20] forKey:@"date"];
   
   char data[]={1, 2, 3, 4, 5};
   [plistDict setObject:[NSData dataWithBytes:data length:5] forKey:@"data"];
   
   return plistDict;
}


-(void)testBinary
{
   id error;
   NSInteger format;
   id data=[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:isa] pathForResource:@"Binary" ofType:@"plist"]];
   STAssertNotNil(data, @"Data file not found");

   id plist=[NSPropertyListSerialization propertyListFromData:data
                                             mutabilityOption:NSPropertyListImmutable 
                                                       format:(NSUInteger*)&format 
                                             errorDescription:&error];
   STAssertNotNil(plist,error);
   STAssertEquals(format, NSPropertyListBinaryFormat_v1_0, nil);

   STAssertEqualObjects([isa sampleList], plist, @"Property list unarchived but doesn't match sample list");
}

-(void)testXML
{
   id error;
   NSInteger format;
   id data=[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:isa] pathForResource:@"XML" ofType:@"plist"]];
   STAssertNotNil(data, @"Data file not found");
   id plist=[NSPropertyListSerialization propertyListFromData:data
                                             mutabilityOption:NSPropertyListImmutable 
                                                       format:(NSUInteger*)&format 
                                             errorDescription:&error];
   STAssertNotNil(plist,error);
   STAssertEquals(format, NSPropertyListXMLFormat_v1_0, nil);
   
   STAssertEqualObjects([isa sampleList], plist, @"Property list unarchived but doesn't match sample list");
}

@end
