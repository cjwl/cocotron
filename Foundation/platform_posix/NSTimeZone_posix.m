/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#include <time.h>
#import <Foundation/NSTimeZone_posix.h>
#import <Foundation/NSTimeZone.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSByteOrder.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSByteOrder.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSRaiseException.h>

// structures in tzfiles are big-endian, from public doman tzfile.h

#define	TZ_MAGIC	"TZif"

struct tzhead {
 	char	tzh_magic[4];		/* TZ_MAGIC */
	char	tzh_reserved[16];	/* reserved for future use */
	char	tzh_ttisgmtcnt[4];	/* coded number of trans. time flags */
	char	tzh_ttisstdcnt[4];	/* coded number of trans. time flags */
	char	tzh_leapcnt[4];		/* coded number of leap seconds */
	char	tzh_timecnt[4];		/* coded number of transition times */
	char	tzh_typecnt[4];		/* coded number of local time types */
	char	tzh_charcnt[4];		/* coded number of abbr. chars */
};

/*
** . . .followed by. . .
**
**	tzh_timecnt (char [4])s		coded transition times a la time(2)
**	tzh_timecnt (unsigned char)s	types of local time starting at above
**	tzh_typecnt repetitions of
**		one (char [4])		coded UTC offset in seconds
**		one (unsigned char)	used to set tm_isdst
**		one (unsigned char)	that's an abbreviation list index
**	tzh_charcnt (char)s		'\0'-terminated zone abbreviations
**	tzh_leapcnt repetitions of
**		one (char [4])		coded leap second transition times
**		one (char [4])		total correction after above
**	tzh_ttisstdcnt (char)s		indexed by type; if TRUE, transition
**					time is standard time, if FALSE,
**					transition time is wall clock time
**					if absent, transition times are
**					assumed to be wall clock time
**	tzh_ttisgmtcnt (char)s		indexed by type; if TRUE, transition
**					time is UTC, if FALSE,
**					transition time is local time
**					if absent, transition times are
**					assumed to be local time
*/

// private classes
#import <Foundation/NSTimeZoneTransition.h>
#import <Foundation/NSTimeZoneType.h>

@implementation NSTimeZone_posix

NSInteger sortTransitions(id trans1, id trans2, void *context) {
    NSDate  *d1 = [trans1 transitionDate];
    NSDate  *d2 = [trans2 transitionDate];

    return [d1 compare:d2];
}

-initWithName:(NSString *)name data:(NSData *)data {
        NSMutableArray  *transitions, *types;
        NSArray         *sortedTransitions;
        const struct    tzhead *tzHeader;
        const char      *tzData;
        const char      *typeIndices;
        //unused
        //int             numberOfGMTFlags, numberOfStandardFlags, numberOfAbbreviationCharacters;
        int             numberOfTransitionTimes, numberOfLocalTimes;
        int             i;

        const struct tzType {
            unsigned int offset;
            unsigned char isDST;
            unsigned char abbrevIndex;
        } *tzTypes;
        const char *tzTypesBytes;
        const char *abbreviations;

        if (data == nil) {
            NSString    *zonePath = [NSTimeZone_posix _zoneinfoPath];

            zonePath = [zonePath stringByAppendingPathComponent:name];

            data = [NSData dataWithContentsOfFile:zonePath];
        }
        if (data == nil)
            return nil;

        transitions = [NSMutableArray array];
        sortedTransitions = [NSArray array];
        types = [NSMutableArray array];

        tzHeader= (struct tzhead *)[data bytes];
        tzData=(const char *)tzHeader+sizeof(struct tzhead);

        //unused
        //numberOfGMTFlags = NSSwapBigIntToHost(*((int *)tzHeader->tzh_ttisgmtcnt));
        //numberOfStandardFlags = NSSwapBigIntToHost(*((int *)tzHeader->tzh_ttisstdcnt));
        //numberOfAbbreviationCharacters = NSSwapBigIntToHost(*((int *)tzHeader->tzh_charcnt));
        numberOfTransitionTimes = NSSwapBigIntToHost(*((int *)tzHeader->tzh_timecnt));
        numberOfLocalTimes = NSSwapBigIntToHost(*((int *)tzHeader->tzh_typecnt));

        typeIndices = tzData+(numberOfTransitionTimes * 4);
        for (i = 0; i < numberOfTransitionTimes; ++i) {
            NSDate *d1 = [NSDate dateWithTimeIntervalSince1970:NSSwapBigIntToHost(((int *)tzData)[i])];
            [transitions addObject:[NSTimeZoneTransition
                timeZoneTransitionWithTransitionDate:d1
                                           typeIndex:typeIndices[i]]];
        }

        //sort date array
        sortedTransitions = [transitions sortedArrayUsingFunction:sortTransitions context:NULL];

        // this is a bit more awkward, but i want to support non-3 character abbreviations theoretically.
        tzTypesBytes = (tzData+(numberOfTransitionTimes * 5));
        abbreviations = tzTypesBytes + numberOfLocalTimes * 6; //sizeof struct tzType
        for (i = 0; i < numberOfLocalTimes; ++i) {

         tzTypes=(struct tzType *)tzTypesBytes;
            [types addObject:[NSTimeZoneType timeZoneTypeWithSecondsFromGMT:NSSwapBigIntToHost(tzTypes->offset)
                    isDaylightSavingTime:tzTypes->isDST
                    abbreviation:[NSString stringWithCString:abbreviations+tzTypes->abbrevIndex]]];
            tzTypesBytes += 6;	// wtf, implementing as arrays didn't work.
            				// a-ha! sizeof(struct tzType) returns *8*, not 6 as it should!!!
        }

        return [self initWithName:name data:data transitions:sortedTransitions types:types];
}

-initWithName:(NSString *)name data:(NSData *)data transitions:(NSArray *)transitions types:(NSArray *)types {
    _name = [name retain];
    _data = [data retain];
    _timeZoneTransitions = [transitions retain];
    _timeZoneTypes = [types retain];

    return self;
}

-(void)dealloc {
    [_name release];
    [_data release];
    [_timeZoneTransitions release];
    [_timeZoneTypes release];

    [super dealloc];
}

-(NSString *)name {
    return _name;
}

-(NSData *)data {
    return _data;
}

+(NSTimeZone *)systemTimeZone {

    NSTimeZone      *systemTimeZone = nil;
    NSString        *timeZoneName;

    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/etc/localtime"] == YES) {
        NSError     *error;
        NSString    *path = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:@"/etc/localtime" error:&error];

        timeZoneName = [path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", [NSTimeZone_posix _zoneinfoPath]] withString:@""];

        systemTimeZone = [self timeZoneWithName:timeZoneName];
    }

#ifdef LINUX
// FIXME: BSD does not have 'timezone' or __timezone

    if (systemTimeZone == nil) {
        NSString        *abbreviation;

        tzset();
        abbreviation = [NSString stringWithCString:tzname[0]];

        systemTimeZone = [self timeZoneWithAbbreviation:abbreviation];

        if(systemTimeZone == nil) {
            //check if the error is because of a missing entry in NSTimeZoneAbbreviations.plist (only for logging)
            if([[self abbreviationDictionary] objectForKey:abbreviation] == nil) {
                NSCLog("Abbreviation [%s] not found in NSTimeZoneAbbreviations.plist -> using absolute timezone (no daylight saving)", [abbreviation cString]);
            }
            else {
                NSCLog("TimeZone [%s] not instantiable -> using absolute timezone (no daylight saving)", [[[self abbreviationDictionary] objectForKey:abbreviation] cString]);
            }

            systemTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:-timezone];
        }
    }
#endif

    return systemTimeZone;
}

-(NSTimeZoneType *)timeZoneTypeForDate:(NSDate *)date {
    if ([_timeZoneTransitions count] == 0 ||
        [date compare:[[_timeZoneTransitions objectAtIndex:0] transitionDate]] == NSOrderedAscending) {

        NSEnumerator *timeZoneTypeEnumerator = [_timeZoneTypes objectEnumerator];
        NSTimeZoneType *type;

        while ((type = [timeZoneTypeEnumerator nextObject])!=nil) {
            if (![type isDaylightSavingTime])
                return type;
        }

        return [_timeZoneTypes objectAtIndex:0];
    }
    else {
        NSEnumerator *timeZoneTransitionEnumerator = [_timeZoneTransitions objectEnumerator];
        NSTimeZoneTransition *transition, *previousTransition = nil;

        while ((transition = [timeZoneTransitionEnumerator nextObject])!=nil) {
            if ([date compare:[transition transitionDate]] == NSOrderedDescending) {
                previousTransition = transition;
            }
            else
                return [_timeZoneTypes objectAtIndex:[previousTransition typeIndex]];
        }
    }

    [NSException raise:NSInternalInconsistencyException
                format:@"%@ could not determine seconds from GMT for %@", self, date];
    return nil;
}

-(NSInteger)secondsFromGMTForDate:(NSDate *)date {
    return [[self timeZoneTypeForDate:date] secondsFromGMT];
}

-(NSString *)abbreviationForDate:(NSDate *)date {
    return [[self timeZoneTypeForDate:date] abbreviation];
}

-(BOOL)isDaylightSavingTimeForDate:(NSDate *)date {
    return [[self timeZoneTypeForDate:date] isDaylightSavingTime];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] name: %@ secondsFromGMT: %d isDaylightSavingTime: %@ abbreviation: %@>",
        [self class], self,
        [self name], [self secondsFromGMT], [self isDaylightSavingTime] ? @"YES" : @"NO", [self abbreviation]];
}

-copyWithZone:(NSZone *)zone {
    return [self retain];
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_name];
    [coder encodeObject:_data];
    [coder encodeObject:_timeZoneTransitions];
    [coder encodeObject:_timeZoneTypes];
}

-initWithCoder:(NSCoder *)coder {
    _name = [[coder decodeObject] retain];
    _data = [[coder decodeObject] retain];
    _timeZoneTransitions = [[coder decodeObject] retain];
    _timeZoneTypes = [[coder decodeObject] retain];

    return self;
}

+(NSString*)_zoneinfoPath
{
    static NSString *zoneinfoPath = nil;
    if(zoneinfoPath == nil) {
        BOOL            isDir;
        NSFileManager   *fileManager = [NSFileManager defaultManager];

        //we can create some subclasses for all os or a method on NSPlatform instead of this if else cascade
        if ([fileManager fileExistsAtPath:@"/usr/share/zoneinfo" isDirectory:&isDir] && isDir) { // os x & linux
            return @"/usr/share/zoneinfo";
        }
        else if ([fileManager fileExistsAtPath:@"/usr/share/lib/zoneinfo" isDirectory:&isDir] && isDir) { // solaris
            return @"/usr/share/lib/zoneinfo";
        }
        else if ([fileManager fileExistsAtPath:@"/usr/lib/zoneinfo" isDirectory:&isDir] && isDir) { // older linux
            return @"/usr/lib/zoneinfo";
        }
        else {
            [NSException raise:NSInternalInconsistencyException
                        format:@"could not find zoneinfo directory"];
            // compiler does not know if NSException+raise:… throws
            return nil;
        }
    }
    else {
        return zoneinfoPath;
    }
}

@end
