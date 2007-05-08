/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSDateComponents,NSTimeZone,NSLocale,NSDate;

typedef int NSCalendarUnit;

@interface NSCalendar : NSObject <NSCopying> {
   NSString   *_identifier;
   unsigned    _firstWeekday;
   unsigned    _minimumDaysInFirstWeek;
   NSTimeZone *_timeZone;
   NSLocale   *_locale;
}

+currentCalendar;

-initWithCalendarIdentifier:(NSString *)identifier;

-(NSString *)calendarIdentifier;
-(unsigned)firstWeekday;
-(unsigned)minimumDaysInFirstWeek;
-(NSTimeZone *)timeZone;
-(NSLocale *)locale;

-(void)setFirstWeekday:(unsigned)weekday;
-(void)setMinimumDaysInFirstWeek:(unsigned)days;
-(void)setTimeZone:(NSTimeZone *)timeZone;
-(void)setLocale:(NSLocale *)locale;

-(NSRange)minimumRangeOfUnit:(NSCalendarUnit)unit;
-(NSRange)maximumRangeOfUnit:(NSCalendarUnit)unit;
-(NSRange)rangeOfUnit:(NSCalendarUnit)unit inUnit:(NSCalendarUnit)inUnit forDate:(NSDate *)date;
-(unsigned)ordinalityOfUnit:(NSCalendarUnit)unit inUnit:(NSCalendarUnit)inUnit forDate:(NSDate *)date;

-(NSDateComponents *)components:(unsigned)flags fromDate:(NSDate *)date;
-(NSDateComponents *)components:(unsigned)flags fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate options:(unsigned)options;

-(NSDate *)dateByAddingComponents:(NSDateComponents *)components toDate:(NSDate *)date options:(unsigned)options;
-(NSDate *)dateFromComponents:(NSDateComponents *)components;
 
@end
