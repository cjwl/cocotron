/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSFormatter.h>
#import <Foundation/NSDate.h>

@interface NSDateFormatter : NSFormatter {
    NSString *_dateFormat;
    BOOL _allowsNaturalLanguage;
    NSDictionary *_locale;
}

-initWithDateFormat:(NSString *)format allowNaturalLanguage:(BOOL)flag; // shouldn't this be "allows" ?

// added because NSDateFormatter is the backend for initWithString:calendarFormat:locale
// shouldn't this really exist anyway?
-initWithDateFormat:(NSString *)format allowNaturalLanguage:(BOOL)flag locale:(NSDictionary *)locale;

-(NSString *)dateFormat;
-(BOOL)allowsNaturalLanguage;

// hmmm
-(NSDictionary *)locale;

@end

// internal use

NSTimeInterval NSAdjustTimeIntervalWithTimeZone(NSTimeInterval interval, NSTimeZone *timeZone);

// interval is not time zone adjusteed
NSTimeInterval NSTimeIntervalWithComponents(int year, int month, int day, int hour, int minute, int second, int milliseconds);

// interval has already been time zone adjusted
int NSDayOfCommonEraFromTimeInterval(NSTimeInterval interval);

int NSYearFromTimeInterval(NSTimeInterval interval);
int NSDayOfYearFromTimeInterval(NSTimeInterval interval); // 0-366

int NSMonthFromTimeInterval(NSTimeInterval interval); // 0-11
int NSDayOfMonthFromTimeInterval(NSTimeInterval interval); // 0-31

int NSWeekdayFromTimeInterval(NSTimeInterval interval); // 0-7

int NS24HourFromTimeInterval(NSTimeInterval interval); // 0-23
int NS12HourFromTimeInterval(NSTimeInterval interval); // 1-12
int NSAMPMFromTimeInterval(NSTimeInterval interval); // 0-1

int NSMinuteFromTimeInterval(NSTimeInterval interval); // 0-59

int NSSecondFromTimeInterval(NSTimeInterval interval); // 0-59

int NSMillisecondsFromTimeInterval(NSTimeInterval interval); // 0-999

// interval will be time-zone adjusted
NSString *NSStringWithDateFormatLocale(NSTimeInterval interval,NSString *format,NSDictionary *locale,NSTimeZone *timeZone);

NSCalendarDate *NSCalendarDateWithStringDateFormatLocale(NSString *string, NSString *format, NSDictionary *locale);
