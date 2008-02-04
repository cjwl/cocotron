/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSTimeZone.h>
#import <math.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSKeyedUnarchiver.h>

// anyway, the code in this file has been subjected to a rather grueling
// test suite (see dateTester.m) which appears to prove that the code
// works for all dates (note: not times) from 1/1/1 0:0:0 to 4009-08-30 0:0:0. (distantFuture)

@implementation NSDateFormatter

-initWithDateFormat:(NSString *)format allowNaturalLanguage:(BOOL)flag {
    return [self initWithDateFormat:format allowNaturalLanguage:flag locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

-initWithDateFormat:(NSString *)format allowNaturalLanguage:(BOOL)flag locale:(NSDictionary *)locale {
    [super init];
    _dateFormat = [format retain];
    _allowsNaturalLanguage = flag;
    _locale = [locale retain];

    return self;
}

-(void)dealloc {
    [_dateFormat release];
    [_locale release];

    [super dealloc];
}

-initWithCoder:(NSCoder*)coder {
   [super initWithCoder:coder];
   
   if([coder isKindOfClass:[NSKeyedUnarchiver class]]){
    /* attributes in key NS.attributes
        "formatBehavior" is key in attributes
     */
    _dateFormat=[[coder decodeObjectForKey:@"NS.format"] retain];
    _allowsNaturalLanguage=[coder decodeBoolForKey:@"NS.natural"];
   }
   
   return self;
}

-(NSString *)dateFormat {
    return _dateFormat;
}

-(BOOL)allowsNaturalLanguage {
    return _allowsNaturalLanguage;
}

-(NSDictionary *)locale {
    return _locale;
}

-(NSString *)stringForObjectValue:(id)object {
    if ([object isKindOfClass:[NSDate class]]) {
        NSTimeZone *zone;

        if ([object isKindOfClass:[NSCalendarDate class]]) 
            zone = [object timeZone];
        else 
            zone = [NSTimeZone defaultTimeZone];

        // will adjust time zone
        return NSStringWithDateFormatLocale([object timeIntervalSinceReferenceDate], _dateFormat, _locale, zone);
    }
    
    return nil;
}

-(NSAttributedString *)attributedStringForObjectValue:(id)object
   withDefaultAttributes:(NSDictionary *)attributes {
    return [[[NSAttributedString allocWithZone:NULL] initWithString:[self stringForObjectValue:object] attributes:attributes] autorelease];
}

-(NSString *)editingStringForObjectValue:(id)object {
    return [self stringForObjectValue:object];
}

-(BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error {
    *object = NSCalendarDateWithStringDateFormatLocale(string, _dateFormat, _locale);
    if (*object == nil) {
// FIX localization
       if(error!=NULL)
        *error = @"Couldn't convert string to a valid NSCalendarDate object.";
        return NO;
    }

    return YES;
}

-(BOOL)isPartialStringValid:(NSString *)partialString
   newEditingString:(NSString **)newString errorDescription:(NSString **)error {
   NSUnimplementedMethod();
   return NO;
}

@end


@interface NSMutableString(NSDateFormatterExtensions)

-(void)__appendCharacter:(unichar)character;

-(void)__appendLocale:(NSDictionary *)locale key:(NSString *)key
              index:(int)index;

@end

@implementation NSMutableString(NSDateFormatterExtensions)

// blek, get rid of these
-(void)__appendCharacter:(unichar)character {
    [self appendString:[NSString stringWithCharacters:&character length:1]];
}

-(void)__appendLocale:(NSDictionary *)locale key:(NSString *)key
              index:(int)index {
    NSArray *array=[locale objectForKey:key];

    if(array!=nil)
        [self appendString:[array objectAtIndex:index]];
}

@end

NSTimeInterval NSAdjustTimeIntervalWithTimeZone(NSTimeInterval interval,
                                                NSTimeZone *timeZone) {
    return interval+[timeZone secondsFromGMT];
}

#define NSDaysOfCommonEraOfReferenceDate	730486

// thirty days hath september, april, june, and november.
// all the rest have thirty-one, except February, which is borked.
static inline int numberOfDaysInMonthOfYear(int month, int year) {
    switch (month) {
        case 2:
            if (((year % 4) == 0 && (year % 100) != 0) || (year % 400) == 0)
                return 29;
            else
                return 28;
        case 4:
        case 6:
        case 9:
        case 11:
            return 30;
        default:
            return 31;
    }
}

static inline int numberOfDaysInCommonEraOfDayMonthAndYear(int day, int month, int year) {
    int result = 0;

    for (month--; month > 0; month--)
        result += numberOfDaysInMonthOfYear(month, year);

    result += 365 * (year-1);
    result += (year - 1)/4;
    result -= (year - 1)/100;
    result += (year - 1)/400;
    
    // wtf, i tried this using day as the result variable and it started from zero
    result += day;

    return result;
}

NSTimeInterval NSTimeIntervalWithComponents(int year, int month, int day, int hour, int minute, int second, int milliseconds) {
    int daysOfCommonEra;
    NSTimeInterval interval;

    daysOfCommonEra = numberOfDaysInCommonEraOfDayMonthAndYear(day, month, year);
    daysOfCommonEra -= NSDaysOfCommonEraOfReferenceDate;
    daysOfCommonEra++;

    interval = (daysOfCommonEra * 86400.0) + (hour * 3600) + (minute * 60) + second + (milliseconds/1000);

    return interval;
}

int NSDayOfCommonEraFromTimeInterval(NSTimeInterval interval) {
    return (interval/86400.0) + NSDaysOfCommonEraOfReferenceDate;
}

int NSYearFromTimeInterval(NSTimeInterval interval) {
    int days = NSDayOfCommonEraFromTimeInterval(interval);
    int year = days/366;

    while (days > numberOfDaysInCommonEraOfDayMonthAndYear(1, 1, year+1)) 
        year++;

    return year;
}

int NSDayOfYearFromTimeInterval(NSTimeInterval interval){ // 0-366
    int year = NSYearFromTimeInterval(interval);

    return numberOfDaysInCommonEraOfDayMonthAndYear(31, 12, year) - NSDayOfCommonEraFromTimeInterval(interval);
}

int NSMonthFromTimeInterval(NSTimeInterval interval){ // 0-11
    int year = NSYearFromTimeInterval(interval);
    int days = NSDayOfCommonEraFromTimeInterval(interval);
    int month = 1;

    while (days > numberOfDaysInCommonEraOfDayMonthAndYear(numberOfDaysInMonthOfYear(month, year), month, year)+1)
        month++;

    return month-1;
}

int NSDayOfMonthFromTimeInterval(NSTimeInterval interval){ // 0-31
    int dayOfCommonEra = NSDayOfCommonEraFromTimeInterval(interval);
    int year = NSYearFromTimeInterval(interval);
    int month = NSMonthFromTimeInterval(interval)+1;

    dayOfCommonEra -= numberOfDaysInCommonEraOfDayMonthAndYear(1, month, year);

    return dayOfCommonEra;
}

int NSWeekdayFromTimeInterval(NSTimeInterval interval){ // 0-7
    int weekday = NSDayOfCommonEraFromTimeInterval(interval);

    weekday = weekday % 7;
    if (weekday < 0)
        weekday += 7;

    return weekday;
}

int NS24HourFromTimeInterval(NSTimeInterval interval){ // 0-23
    NSTimeInterval hour = NSDayOfCommonEraFromTimeInterval(interval);

    hour -= NSDaysOfCommonEraOfReferenceDate;
    hour *= 86400.0;
    hour -= interval;
    hour /= 3600;
    hour = fabs(hour);

    if (hour == 24)
        hour = 0;

    return hour;
}

int NS12HourFromTimeInterval(NSTimeInterval interval){ // 1-12
    int hour = NS24HourFromTimeInterval(interval)%12;
    if (hour == 0)
        hour = 12;
    return hour;
}

int NSAMPMFromTimeInterval(NSTimeInterval interval){ // 0-1
    int hour=NS24HourFromTimeInterval(interval);

    return (hour < 11) ? 0 : 1;
}

int NSMinuteFromTimeInterval(NSTimeInterval interval){ // 0-59
    NSTimeInterval startOfHour = NSTimeIntervalWithComponents(NSYearFromTimeInterval(interval),
                                                              NSMonthFromTimeInterval(interval)+1,
                                                              NSDayOfMonthFromTimeInterval(interval),
                                                              NS24HourFromTimeInterval(interval), 0, 0, 0);

    return (int)(interval - startOfHour)/60;
}

int NSSecondFromTimeInterval(NSTimeInterval interval){ // 0-59
    int seconds = fmod(interval,60);
    if (seconds < 0)
        seconds = (60 + seconds);

    return seconds;
}

int NSMillisecondsFromTimeInterval(NSTimeInterval interval){ // 0-999
    return fabs(fmod(interval*1000,1000));
}

NSString *NSStringWithDateFormatLocale(NSTimeInterval interval,NSString *format,NSDictionary *locale,NSTimeZone *timeZone) {
    unsigned         pos,fmtLength=[format length];
    unichar          fmtBuffer[fmtLength],unicode;
    NSMutableString *result=[NSMutableString stringWithCapacity:fmtLength];

    unichar fillChar='0';
    BOOL    suppressZero=NO;

    enum {
        STATE_SCANNING,
        STATE_PERCENT,
        STATE_CONVERSION
    } state=STATE_SCANNING;

    interval=NSAdjustTimeIntervalWithTimeZone(interval,timeZone);
    if (locale == nil)
        locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    [format getCharacters:fmtBuffer];

    for(pos=0;pos<fmtLength;pos++){
        unicode=fmtBuffer[pos];

        switch(state){

            case STATE_SCANNING:
                if(unicode!='%')
                    [result __appendCharacter:unicode];
                else{
                    fillChar='0';
                    suppressZero=NO;
                    state=STATE_PERCENT;
                }
                    break;

            case STATE_PERCENT:
                switch(unicode){

                    case '.': suppressZero=YES; break;
                    case ' ': fillChar=' '; break;

                    default:
                        pos--;
                        state=STATE_CONVERSION;
                        break;
                }
                break;

            case STATE_CONVERSION:
                switch(unicode){

                    case '%':
                        [result __appendCharacter:'%'];
                        break;

                    case 'a':
                        [result __appendLocale:locale key:NSShortWeekDayNameArray
                                       index:NSWeekdayFromTimeInterval(interval)];
                        break;

                    case 'A':
                        [result __appendLocale:locale key:NSWeekDayNameArray
                                       index:NSWeekdayFromTimeInterval(interval)];
                        break;

                    case 'b':
                        [result __appendLocale:locale key:NSShortMonthNameArray
                                       index:NSMonthFromTimeInterval(interval)];
                        break;

                    case 'B':
                        [result __appendLocale:locale key:NSMonthNameArray
                                       index:NSMonthFromTimeInterval(interval)];
                        break;

                    case 'c':
                        [result appendFormat:@"%@", NSStringWithDateFormatLocale(interval,[locale objectForKey:NSTimeDateFormatString],locale,timeZone)];
                        break;

                    case 'd':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NSDayOfMonthFromTimeInterval(interval)+1];
                    }
                        break;

                    case 'e':{ 
                        id fmt=@"%d"; 
                        [result appendFormat:fmt,NSDayOfMonthFromTimeInterval(interval)+1]; 
                    } 
                        break; 

                   case 'F':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%3d":@"%03d");

                        [result appendFormat:fmt,NSMillisecondsFromTimeInterval(interval)];
                    }
                        break;

                    case 'H':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NS24HourFromTimeInterval(interval)];
                    }
                        break;

                    case 'I':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NS12HourFromTimeInterval(interval)];
                    }
                        break;

                    case 'j':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%3d":@"%03d");

                        [result appendFormat:fmt,NSDayOfYearFromTimeInterval(interval)];
                    }
                        break;

                    case 'm':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NSMonthFromTimeInterval(interval)+1];
                    }
                        break;

                    case 'M':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NSMinuteFromTimeInterval(interval)];
                    }
                        break;

                    case 'p':
                        [result __appendLocale:locale key:NSAMPMDesignation
                                       index:NSAMPMFromTimeInterval(interval)];
                        break;

                    case 'S':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NSSecondFromTimeInterval(interval)];
                    }
                        break;

                    case 'w':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%1d":@"%01d");

                        [result appendFormat:fmt,NSWeekdayFromTimeInterval(interval)];
                    }
                        break;

                    case 'x':
                        [result appendFormat:@"%@", NSStringWithDateFormatLocale(interval,[locale objectForKey:NSDateFormatString],locale,timeZone)];
                        break;

                    case 'X':
                        [result appendFormat:@"%@", NSStringWithDateFormatLocale(interval,[locale objectForKey:NSTimeFormatString],locale,timeZone)];
                        break;

                    case 'y':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%2d":@"%02d");

                        [result appendFormat:fmt,NSYearFromTimeInterval(interval)%100];
                    }
                        break;

                    case 'Y':{
                        id fmt=(suppressZero)?@"%d":((fillChar==' ')?@"%4d":@"%04d");

                        [result appendFormat:fmt,NSYearFromTimeInterval(interval)];
                    }
                        break;

                    case 'Z':
                        [result appendString:[timeZone name]];
                        break;

                    case 'z':
                        [result appendString:[timeZone abbreviationForDate:[NSDate dateWithTimeIntervalSinceReferenceDate:interval]]];
                        break;
                }
                state=STATE_SCANNING;
                break;
        }

    }

    return result;
}

// might as well use the same code since they're the exact same formatting specifiers
// ok. we need at minimum the year. everything else is optional.
// weekday information is useless.
NSCalendarDate *NSCalendarDateWithStringDateFormatLocale(NSString *string, NSString *format, NSDictionary *locale) {
    NSScanner       *scanner = [NSScanner scannerWithString:string];
    unsigned         pos,fmtLength=[format length];
    unichar          fmtBuffer[fmtLength],unicode;
    int		     years = -1, months = -1, days = -1, hours = -1, minutes = -1, seconds = -1, milliseconds = -1;
    int		     AMPMMultiplier = 0;
    NSTimeInterval   adjustment = 0;
    NSArray	    *monthNames, *shortMonthNames, *AMPMDesignations;
    NSTimeZone      *timeZone = nil;
    NSTimeInterval   timeInterval;
    NSCalendarDate  *calendarDate;

    enum {
        STATE_SCANNING,
        STATE_PERCENT,
        STATE_CONVERSION
    } state=STATE_SCANNING;

    if ([string length] == 0)
        return nil;

    if (locale == nil)
        locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    monthNames = [locale objectForKey:NSMonthNameArray];
    shortMonthNames = [locale objectForKey:NSShortMonthNameArray];
    AMPMDesignations = [locale objectForKey:NSAMPMDesignation];

    // although we don't use the weekday arrays for anything, the spec
    // says to check them anyway.
    if ([monthNames count] > 12 || [shortMonthNames count] > 12 ||
        [[locale objectForKey:NSShortWeekDayNameArray] count] > 7 ||
        [[locale objectForKey:NSWeekDayNameArray] count] > 7)
        return nil;
    
    [format getCharacters:fmtBuffer];

    for(pos=0;pos<fmtLength;pos++){
        unicode=fmtBuffer[pos];

        switch(state){
            case STATE_SCANNING:
                if(unicode=='%') {
                    state=STATE_PERCENT;
                }
                else if (![scanner scanString:[NSString stringWithCharacters:&unicode length:1] intoString:NULL])
                    return nil;
                break;

            case STATE_PERCENT:
                switch(unicode){
                    case '.':
                    case ' ':
                    default:
                        pos--;
                        state=STATE_CONVERSION;
                        break;
                }
                break;

            case STATE_CONVERSION:
                switch(unicode){
                    case '%':
                        if (![scanner scanString:[NSString stringWithCharacters:&unicode length:1] intoString:NULL])
                            return nil;
                        break;

                        // can't really do anything with the day of the week, but we have to skip it.
                    case 'a':
                        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:NULL])
                            return nil;
                        break;
                        
                    case 'A':
                        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:NULL])
                            return nil;
                        break;

                        // month or its abbreviation. look it up in the arrays..
                    case 'b': {
                        NSString *temp;

                        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&temp])
                            return nil;

                        months = [shortMonthNames indexOfObject:temp];
                        if (months == -1) // unknown month name
                            return nil;
                    }
                        break;

                    case 'B': {
                        NSString *temp;

                        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&temp])
                            return nil;

                        months = [monthNames indexOfObject:temp];
                        if (months == -1) // unknown month name
                            return nil;
                    }
                        break;

                    case 'c':
                        return NSCalendarDateWithStringDateFormatLocale(string, [locale objectForKey:NSTimeDateFormatString], locale);

                    case 'd':
                        if (![scanner scanInt:&days])
                            return nil;
                        break;

                    case 'F':
                        if (![scanner scanInt:&milliseconds])
                            return nil;
                        break;

                    case 'H':
                        if (![scanner scanInt:&hours])
                            return nil;
                        break;

                    case 'I':
                        if (![scanner scanInt:&hours])
                            return nil;
                        AMPMMultiplier = 1;
                        break;

                    // grr
                    case 'j': {
                        int numberOfDays = 0;
                        if (![scanner scanInt:&numberOfDays])
                            return nil;
                        adjustment += numberOfDays * 86400.0;
                    }
                        break;

                    case 'm':
                        if (![scanner scanInt:&months])
                            return nil;
                        break;

                    case 'M':
                        if (![scanner scanInt:&minutes])
                            return nil;
                        break;

                    case 'p': {
                        NSString *temp;

                        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&temp])
                            return nil;
                        AMPMMultiplier = [AMPMDesignations indexOfObject:temp];
                        if (AMPMMultiplier == -1)
                            return nil;
                        AMPMMultiplier++;		// e.g. 0 = 1, 1 = 2...
                        break;
                    }

                    case 'S':
                        if (![scanner scanInt:&seconds])
                            return nil;
                        break;

                    // again, weekdays are useless
                    case 'w': {
                        int nothing;
                        if (![scanner scanInt:&nothing])
                            return nil;
                        break;
                    }

                    case 'x':
                        return NSCalendarDateWithStringDateFormatLocale(string,[locale objectForKey:NSDateFormatString],locale);

                    case 'X':
                        return NSCalendarDateWithStringDateFormatLocale(string,[locale objectForKey:NSTimeFormatString],locale);

                    case 'y':
                        if (![scanner scanInt:&years])
                            return nil;
// FIX QUESTIONABLE
// 1900 or 2000??, YB does 2000, for some? all?
                        years += 2000;
                        break;

                    case 'Y':
                        if (![scanner scanInt:&years])
                            return nil;
                        break;

                    case 'Z': {
                        NSString *temp;

                        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&temp])
                            return nil;
                        timeZone = [NSTimeZone timeZoneWithName:temp];
                        break;
                    }

                    case 'z': {
                        int hoursMinutes, hours, minutes;
                        if (![scanner scanInt:&hoursMinutes])
                            return nil;
                        hours = hoursMinutes / 100;
                        minutes = hoursMinutes % 100;
                        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(hours * 3600) + (minutes * 60)];
                        break;
                    }
                }
                state=STATE_SCANNING;
                break;
        }
   }

   // now that we've got whatever information we can get from the string,
   // try to make an NSCalendarDate of it.
    if (AMPMMultiplier != 0 && hours != -1)
        hours *= AMPMMultiplier;

    // maybe we've been given the number of days in the year but not the month/day
    if (months == -1 && days == -1) {
        months = 1;
        days = 1;
    }

    // if no year, then this year
    if (years == -1)
        years = [[NSCalendarDate date] yearOfCommonEra];

    if (hours == -1)
        hours = 0;
    if (minutes == -1)
        minutes = 0;
    if (seconds == -1)
        seconds = 0;
    if (milliseconds == -1)
        milliseconds = 0;

    if (timeZone == nil)
        timeZone = [NSTimeZone defaultTimeZone];

    timeInterval = NSTimeIntervalWithComponents(years, months, days, hours, minutes, seconds, milliseconds);
    timeInterval += adjustment;

    // adjusting twice "makes it work", dunno why though.
    timeInterval = NSAdjustTimeIntervalWithTimeZone(timeInterval, timeZone);
    timeInterval = NSAdjustTimeIntervalWithTimeZone(timeInterval, timeZone);

    calendarDate = [[[NSCalendarDate allocWithZone:NULL] initWithTimeIntervalSinceReferenceDate:timeInterval] autorelease];
    [calendarDate setTimeZone:timeZone];

    return calendarDate;
}

