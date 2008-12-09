/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "PropertyListUnarchiving.h"




@implementation PropertyListUnarchiving
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
   id error=nil;
   NSInteger format=NSPropertyListBinaryFormat_v1_0;
   id path=[[NSBundle bundleForClass:isa] pathForResource:@"Binary" ofType:@"plist"];
   STAssertNotNil(path, @"Data file not found");
   id data=[NSData dataWithContentsOfFile:path];
   STAssertNotNil(data, @"Data file couldn't be opened");

   id plist=[NSPropertyListSerialization propertyListFromData:data
                                             mutabilityOption:NSPropertyListImmutable 
                                                       format:(NSUInteger*)&format 
                                             errorDescription:&error];
   STAssertNotNil(plist,error);
   STAssertEquals(format, NSPropertyListBinaryFormat_v1_0, nil);

   STAssertEqualObjects([isa sampleList], plist, @"Property list unarchived but doesn't match sample list");
}

-(void)testFailureCase
{
   char data[]={1, 2, 3, 4, 5};
   id error=nil;
   NSInteger format=0;
   id plist=nil;
   STAssertNoThrow(plist=[NSPropertyListSerialization propertyListFromData:[NSData dataWithBytes:data length:5]
                                                          mutabilityOption:NSPropertyListImmutable 
                                                                    format:(NSUInteger*)&format 
                                                          errorDescription:&error],
                   nil);
   STAssertTrue(plist==nil, nil);
}

-(void)testXML
{
   id error=nil;
   NSInteger format=0;
   id data=[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:isa] pathForResource:@"XML" ofType:@"plist"]];
   STAssertNotNil(data, @"Data file not found");
   id plist=[NSPropertyListSerialization propertyListFromData:data
                                             mutabilityOption:NSPropertyListImmutable 
                                                       format:(NSUInteger*)&format 
                                             errorDescription:&error];
   STAssertNotNil(plist,error);
   STAssertEquals(format, NSPropertyListXMLFormat_v1_0, nil);
   
   STAssertEqualObjects(plist, [isa sampleList], @"Property list unarchived but doesn't match sample list");
}

@end
