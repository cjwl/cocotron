/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSCalendar.h>
#import <Foundation/NSDateComponents.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSRaise.h>

@implementation NSCalendar 

-copyWithZone:(NSZone *)zone {
   NSUnimplementedMethod();
   // this is wrong, need to actually copy;
   return [self retain];
}

+currentCalendar {
   return nil;
}

-initWithCalendarIdentifier:(NSString *)identifier {
   _identifier=[identifier copy];
   NSUnimplementedMethod();
   return self;
}

-(NSString *)calendarIdentifier {
   return _identifier;
}

-(NSUInteger)firstWeekday {
   return _firstWeekday;
}

-(NSUInteger)minimumDaysInFirstWeek {
   return _minimumDaysInFirstWeek;
}

-(NSTimeZone *)timeZone {
   return _timeZone;
}

-(NSLocale *)locale {
   return _locale;
}

-(void)setFirstWeekday:(NSUInteger)weekday {
   _firstWeekday=weekday;
}

-(void)setMinimumDaysInFirstWeek:(NSUInteger)days {
   _minimumDaysInFirstWeek=days;
}

-(void)setTimeZone:(NSTimeZone *)timeZone {
   timeZone=[timeZone retain];
   [_timeZone release];
   _timeZone=timeZone;
}

-(void)setLocale:(NSLocale *)locale {
   locale=[locale retain];
   [_locale release];
   _locale=locale;
}

-(NSRange)minimumRangeOfUnit:(NSCalendarUnit)unit {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSRange)maximumRangeOfUnit:(NSCalendarUnit)unit {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSRange)rangeOfUnit:(NSCalendarUnit)unit inUnit:(NSCalendarUnit)inUnit forDate:(NSDate *)date {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSUInteger)ordinalityOfUnit:(NSCalendarUnit)unit inUnit:(NSCalendarUnit)inUnit forDate:(NSDate *)date {
   NSUnimplementedMethod();
   return 0;
}

-(NSDateComponents *)components:(NSUInteger)flags fromDate:(NSDate *)date {
   NSUnimplementedMethod();
   return nil;
}

-(NSDateComponents *)components:(NSUInteger)flags fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate options:(NSUInteger)options {
   NSUnimplementedMethod();
   return nil;
}

-(NSDate *)dateByAddingComponents:(NSDateComponents *)components toDate:(NSDate *)date options:(NSUInteger)options {
   NSUnimplementedMethod();
   return nil;
}

-(NSDate *)dateFromComponents:(NSDateComponents *)components {
   NSUnimplementedMethod();
   return nil;
}

@end
