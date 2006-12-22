/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSDate.h>

@interface NSCalendarDate : NSDate {
    NSTimeInterval _timeInterval;
    NSString      *_format;
    NSTimeZone    *_timeZone;
}

+calendarDate;

-initWithYear:(int)year month:(unsigned)month day:(unsigned)day
  hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second
  timeZone:(NSTimeZone *)timeZone;
    
-initWithString:(NSString *)string calendarFormat:(NSString *)format
  locale:(NSDictionary *)locale;
-initWithString:(NSString *)string calendarFormat:(NSString *)format;
-initWithString:(NSString *)string;

+dateWithYear:(int)year month:(unsigned)month day:(unsigned)day
  hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second
  timeZone:(NSTimeZone *)timeZone;

+dateWithString:(NSString *)string calendarFormat:(NSString *)format
  locale:(NSDictionary *)locale;

+dateWithString:(NSString *)string calendarFormat:(NSString *)format;

-(NSString *)calendarFormat;
-(NSTimeZone *)timeZone;

-(void)setCalendarFormat:(NSString *)format;
-(void)setTimeZone:(NSTimeZone *)timeZone;

-(int)secondOfMinute;		// 0-59
-(int)minuteOfHour;		// 0-59
-(int)hourOfDay;		// 0-23
-(int)dayOfWeek;		// 0 through 6. how consistent
-(int)dayOfMonth;		// 1 through 31
-(int)dayOfYear;		// 1 through 366. also consistent
-(int)monthOfYear;		// 1 through 12 says spec
-(int)yearOfCommonEra;		// 1 through armageddon
-(int)dayOfCommonEra;

-(void)years:(int *)yearsp months:(int *)monthsp days:(int *)daysp
  hours:(int *)hoursp minutes:(int *)minutesp seconds:(int *)secondsp
  sinceDate:(NSCalendarDate *)date;

-(NSCalendarDate *)dateByAddingYears:(int)years months:(int)months
  days:(int)days hours:(int)hours minutes:(int)minutes seconds:(int)seconds;

-(NSString *)descriptionWithCalendarFormat:(NSString *)format
  locale:(NSDictionary *)locale;
-(NSString *)descriptionWithCalendarFormat:(NSString *)format;
-(NSString *)descriptionWithLocale:(NSDictionary *)locale;

@end
