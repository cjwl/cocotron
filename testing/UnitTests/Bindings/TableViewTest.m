/* Copyright (c) 2009 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "TableViewTest.h"


@implementation TableViewTest
@synthesize table=_table;

-(void)dealloc {
   [_table release];
   [super dealloc];
}

-(void)setUp {
   [super setUp];
   [_arrayController bind:@"contentArray" toObject:self withKeyPath:@"table" options:nil];
   
   id table=[NSMutableArray array];
   
   [table addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Test", @"name",
                     [NSNumber numberWithInt:10], @"value",
                     nil]];
   [table addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Something", @"name",
                     [NSNumber numberWithInt:20], @"value",
                     nil]];
   [table addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Ultimate", @"name",
                     [NSNumber numberWithInt:30], @"value",
                     nil]];
   [table addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Nothing", @"name",
                     [NSNumber numberWithInt:40], @"value",
                     nil]];
   [table addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Abcdefg", @"name",
                     [NSNumber numberWithInt:50], @"value",
                     nil]];  

   self.table=table;
   
}

-(void)testBindings {
   STAssertEquals((int)[_tableView numberOfRows], (int)[_table count], nil);
   
   NSCell* cell=[_tableView preparedCellAtColumn:0 row:0];
   STAssertEqualObjects([cell objectValue], @"Test", nil);

   [_tableView setSortDescriptors:[NSArray arrayWithObject:[[[_tableView tableColumns] objectAtIndex:0] sortDescriptorPrototype]]];

   cell=[_tableView preparedCellAtColumn:0 row:0];
   STAssertEqualObjects([cell objectValue], @"Abcdefg", nil);
   
   [_arrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"name endswith %@", @"thing"]];
   
   cell=[_tableView preparedCellAtColumn:0 row:0];
   STAssertEqualObjects([cell objectValue], @"Nothing", nil);
}


@end
