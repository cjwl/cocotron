//
//  ObservableArray.m
//  UnitTests
//
//  Created by Johannes Fortmann on 10.02.09.
//  Copyright 2009 -. All rights reserved.
//

#import "ObservableArray.h"

#define AssertLastKeyWas(a) STAssertEqualObjects(self.lastObservedKey, a, nil); self.lastObservedKey=nil;

void* ObservableArrayTestContext;

@implementation ObservableArray
@synthesize lastObservedKey=_lastObservedKey;

-(void)setUp {
   _array=[[NSClassFromString(@"_NSObservableArray") alloc] init];
   if(!_array)
      return;
   
   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"First", @"name",
                      [NSNumber numberWithInt:10], @"value",
                      nil]];
   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Second", @"name",
                      [NSNumber numberWithInt:20], @"value",
                      nil]];
   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Third", @"name",
                      [NSNumber numberWithInt:30], @"value",
                      nil]];
   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Fourth", @"name",
                      [NSNumber numberWithInt:40], @"value",
                      nil]];  
   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Fifth", @"name",
                      [NSNumber numberWithInt:50], @"value",
                      nil]];
   
   [_array addObserver:self forKeyPath:@"name" options:0 context:&ObservableArrayTestContext];
   [_array addObserver:self forKeyPath:@"value" options:0 context:&ObservableArrayTestContext];
}


-(void)testArrayMutation {
   if(!_array) 
      return;
   [_array addObserver:self forKeyPath:@"@count" options:0 context:&ObservableArrayTestContext];

   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sixth", @"name",
                      [NSNumber numberWithInt:60], @"value",
                      nil]];
   AssertLastKeyWas(@"@count");
   
   [_array removeLastObject];

   AssertLastKeyWas(@"@count");
   
   [_array replaceObjectAtIndex:3 withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sixth", @"name",
                                              [NSNumber numberWithInt:60], @"value",
                                              nil]];
   AssertLastKeyWas(@"@count");

   [_array removeObserver:self forKeyPath:@"@count"];
}

-(void)testArrayOperatorMutation {
   [_array addObserver:self forKeyPath:@"@avg.value" options:0 context:&ObservableArrayTestContext];

   [_array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sixth", @"name",
                      [NSNumber numberWithInt:60], @"value",
                      nil]];
   
   AssertLastKeyWas(@"@avg.value");
   
   [[_array objectAtIndex:0] setValue:[NSNumber numberWithInt:0] forKey:@"value"];
   
   AssertLastKeyWas(@"@avg.value");
   
   [_array removeObserver:self forKeyPath:@"@avg.value"];
}

-(void)testArraySimpleMutation {
   [_array addObserver:self forKeyPath:@"value" options:0 context:&ObservableArrayTestContext];
   
   [[_array objectAtIndex:0] setValue:[NSNumber numberWithInt:0] forKey:@"value"];
   
   AssertLastKeyWas(@"value");
   
   [_array removeObserver:self forKeyPath:@"value"];
}

-(void)testROI {
   [_array addObserver:self forKeyPath:@"value" options:0 context:&ObservableArrayTestContext];
   id indexes=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 2)];
   id irrelevant=[NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
   [irrelevant addIndexesInRange:NSMakeRange(4, [_array count]-4)];
   
   [_array setROI:indexes];
   
   for(int i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
      [[_array objectAtIndex:i] setValue:[NSNumber numberWithInt:0] forKey:@"value"];
      AssertLastKeyWas(@"value");
   }
   
   for(int i=[irrelevant firstIndex]; i!=NSNotFound; i=[irrelevant indexGreaterThanIndex:i]) {
      [[_array objectAtIndex:i] setValue:[NSNumber numberWithInt:0] forKey:@"value"];
      AssertLastKeyWas(nil);
   }
   
   [_array removeObjectAtIndex:1];
   [_array insertObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sixth", @"name",
                         [NSNumber numberWithInt:60], @"value",
                         nil]
                atIndex:1];
   
   for(int i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
      [[_array objectAtIndex:i] setValue:[NSNumber numberWithInt:0] forKey:@"value"];
      AssertLastKeyWas(@"value");
   }
   
   for(int i=[irrelevant firstIndex]; i!=NSNotFound; i=[irrelevant indexGreaterThanIndex:i]) {
      [[_array objectAtIndex:i] setValue:[NSNumber numberWithInt:0] forKey:@"value"];
      AssertLastKeyWas(nil);
   }
   
   [_array removeObserver:self forKeyPath:@"value"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &ObservableArrayTestContext) {
       self.lastObservedKey=keyPath; 
   }
   else {
      [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
   }
}


-(void)tearDown {
   self.lastObservedKey=nil;
   
   [_array removeObserver:self forKeyPath:@"name"];
   [_array removeObserver:self forKeyPath:@"value"];
   
   for(id item in _array) {
      STAssertEqualObjects([item observationInfo], nil, nil);      
   }
   
   [_array release];
}

@end
