/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSCoder.h>

// given in spec. is this a default someplace?
#define DEFAULT_CALENDAR_FORMAT                @"%Y-%m-%d %H:%M:%S%z"

@implementation NSCalendarDate

+calendarDate {
   return [[[self allocWithZone:NULL] init] autorelease];
}

-initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)seconds {
    _timeInterval=seconds;
    _format=DEFAULT_CALENDAR_FORMAT;
    _timeZone=[[NSTimeZone defaultTimeZone] retain];

    return self;
}

-(NSTimeInterval)timeIntervalSinceReferenceDate {
    return _timeInterval;
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-initWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day
         hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second
     timeZone:(NSTimeZone *)timeZone {
    [super init];
    _timeInterval = NSTimeIntervalWithComponents(year, month, day, hour, minute, second, 0);
    _timeZone = [timeZone retain];
    _format = DEFAULT_CALENDAR_FORMAT;
    
    return self;
}
    
-initWithString:(NSString *)string calendarFormat:(NSString *)format locale:(NSDictionary *)locale {
   NSMutableString* mu=[[string mutableCopy] autorelease];
   
	if ([mu rangeOfString:@"T"].location != NSNotFound)
 	  [mu replaceCharactersInRange:[mu rangeOfString:@"T"] withString:@" "];
   
    NSDateFormatter *dateFormatter = [[[NSDateFormatter allocWithZone:NULL] initWithDateFormat:format allowNaturalLanguage:YES locale:locale] autorelease];
    NSString *error;
    
    [self autorelease];
    if ([dateFormatter getObjectValue:&self forString:mu errorDescription:&error]) {
        [self retain];	// getObjectValues are autoreleased
        return self;
    }
    
    return nil;
}

-initWithString:(NSString *)string calendarFormat:(NSString *)format {
    return [self initWithString:string calendarFormat:format locale:nil];
}

-initWithString:(NSString *)string {
    return [self initWithString:string calendarFormat:DEFAULT_CALENDAR_FORMAT];
}

-(void)dealloc {
    [_format release];
    [_timeZone release];

    [super dealloc];
}

+dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day
         hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second
     timeZone:(NSTimeZone *)timeZone {
    return [[[self allocWithZone:NULL] initWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:timeZone] autorelease];;
}

+dateWithString:(NSString *)string calendarFormat:(NSString *)format
         locale:(NSDictionary *)locale {
    return [[[self allocWithZone:NULL] initWithString:string calendarFormat:format locale:locale] autorelease];;
}

+dateWithString:(NSString *)string calendarFormat:(NSString *)format {
    return [[[self allocWithZone:NULL] initWithString:string calendarFormat:format] autorelease];;
}

-(Class)classForCoder {
   return [NSCalendarDate class];
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeValueOfObjCType:@encode(double) at:&_timeInterval];
    [coder encodeObject:_timeZone];
    [coder encodeObject:_format];
}

-initWithCoder:(NSCoder *)coder {
    [coder decodeValueOfObjCType:@encode(double) at:&_timeInterval];
    _timeZone = [[coder decodeObject] retain];
    _format = [[coder decodeObject] retain];

    return self;
}

-(NSString *)calendarFormat {
   return _format;
}

-(NSTimeZone *)timeZone {
   return _timeZone;
}


-(void)setCalendarFormat:(NSString *)format {
   [format retain];
   [_format release];
   _format=format;
}

-(void)setTimeZone:(NSTimeZone *)timeZone {
   [timeZone retain];
   [_timeZone release];
   _timeZone=timeZone;
}

-(NSTimeInterval)timeZoneAdjustedInterval {
   return NSAdjustTimeIntervalWithTimeZone(_timeInterval,_timeZone);
}

-(NSInteger)secondOfMinute {
   return NSSecondFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)minuteOfHour {
   return NSMinuteFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)hourOfDay {
   return NS24HourFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)dayOfWeek {
   return NSWeekdayFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)dayOfMonth {
   return NSDayOfMonthFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)dayOfYear {
   return NSDayOfYearFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)monthOfYear {
   return NSMonthFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)yearOfCommonEra {
   return NSYearFromTimeInterval([self timeZoneAdjustedInterval]);
}

-(NSInteger)dayOfCommonEra {
    return NSDayOfCommonEraFromTimeInterval([self timeZoneAdjustedInterval]);
}

// Needs to be verified, lame implementation
-(void)years:(NSInteger *)yearsp months:(NSInteger *)monthsp days:(NSInteger *)daysp
  hours:(NSInteger *)hoursp minutes:(NSInteger *)minutesp seconds:(NSInteger *)secondsp
  sinceDate:(NSCalendarDate *)since {
   NSTimeInterval delta=[self timeIntervalSinceReferenceDate]-[since timeIntervalSinceReferenceDate];

   if(yearsp!=NULL) {
    *yearsp = NSYearFromTimeInterval(delta);
    (*yearsp)-=2000;
   }
   if(monthsp!=NULL)
    *monthsp = NSMonthFromTimeInterval(delta);
   if(daysp!=NULL)
    *daysp = NSDayOfMonthFromTimeInterval(delta);
   if(hoursp!=NULL)
    *hoursp = NS24HourFromTimeInterval(delta);
   if(minutesp!=NULL)
    *minutesp = NSMinuteFromTimeInterval(delta);
   if(secondsp!=NULL)
    *secondsp = NSSecondFromTimeInterval(delta);
}

// Might be a little off with daylight savings, etc., needs to be verified
-(NSCalendarDate *)dateByAddingYears:(NSInteger)yearDelta months:(NSInteger)monthDelta
  days:(NSInteger)dayDelta hours:(NSInteger)hourDelta minutes:(NSInteger)minuteDelta seconds:(NSInteger)secondDelta {
   NSTimeInterval result;
   NSInteger            years=NSYearFromTimeInterval(_timeInterval);
   NSInteger            months=NSMonthFromTimeInterval(_timeInterval);
   NSInteger            days=NSDayOfMonthFromTimeInterval(_timeInterval);
   NSInteger            hours=NS24HourFromTimeInterval(_timeInterval);
   NSInteger            minutes=NSMinuteFromTimeInterval(_timeInterval);
   NSInteger            seconds=NSSecondFromTimeInterval(_timeInterval);

   years+=yearDelta;
   years+=monthDelta/12;
   monthDelta%=12;
   months+=monthDelta;
   if(months>11){
    years++;
    months-=11;
   }
   else if(months<0){
    years--;
    months+=11;
   }

   result=NSTimeIntervalWithComponents(years,months+1,days,hours,minutes,seconds,0);

   result+=dayDelta*86400.0;
   result+=hourDelta*3600.0;
   result+=minuteDelta*60.0;
   result+=secondDelta;

   return [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:result];
}

-(NSString *)descriptionWithCalendarFormat:(NSString *)format locale:(NSDictionary *)locale {
   return NSStringWithDateFormatLocale(_timeInterval, format,locale,_timeZone);
}

-(NSString *)descriptionWithCalendarFormat:(NSString *)format {
   return NSStringWithDateFormatLocale(_timeInterval,format,nil,_timeZone);
}

-(NSString *)descriptionWithLocale:(NSDictionary *)locale {
   return NSStringWithDateFormatLocale(_timeInterval,_format,locale,_timeZone);
}

-(NSString *)description {
   return NSStringWithDateFormatLocale(_timeInterval,_format,nil,_timeZone);
}

@end

