/* Copyright (c) 2009 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "Predicate.h"


@implementation Predicate
-(void)testPredicateParsing {
   id dict=[NSDictionary dictionaryWithObjectsAndKeys:
            @"Something", @"name",
            [NSNumber numberWithDouble:17.5], @"value", nil];
   
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"name contains %@", @"Some"] evaluateWithObject:dict]), nil);

   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"name beginswith %@", @"Some"] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"name endswith %@", @"thing"] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow((![[NSPredicate predicateWithFormat:@"name beginswith %@", @"None"] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow((![[NSPredicate predicateWithFormat:@"name endswith %@", @"None"] evaluateWithObject:dict]), nil);

   STAssertTrueNoThrow((![[NSPredicate predicateWithFormat:@"name contains %@", @"None"] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow((![[NSPredicate predicateWithFormat:@"unavailable like %@", @"None"] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"value < %f", 20.0] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"value > %f", 17.3] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"value between {%f, %f}", 15.0, 20.0] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow((![[NSPredicate predicateWithFormat:@"value between {%f, %f}", 20.0, 25.0] evaluateWithObject:dict]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"self == %@", @"Hello"] evaluateWithObject:@"Hello"]), nil);
   STAssertTrueNoThrow((![[NSPredicate predicateWithFormat:@"self != %@", @"Hello"] evaluateWithObject:@"Hello"]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"self like %@", @"H?llo"] evaluateWithObject:@"Hello"]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"NOT (self == %@)", @"Hello"] evaluateWithObject:@"Jello"]), nil);
   STAssertTrueNoThrow(([[NSPredicate predicateWithFormat:@"self == \"Hello\""] evaluateWithObject:@"Hello"]), nil);
}
@end
