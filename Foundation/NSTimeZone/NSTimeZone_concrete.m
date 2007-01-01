/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSTimeZone_concrete.h>
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

@implementation NSTimeZone_concrete

-initWithName:(NSString *)name data:(NSData *)data {
        NSMutableArray *transitions, *types;
        const struct tzhead *tzHeader;
        const char *tzData;
        const char *typeIndices;
        int numberOfGMTFlags, numberOfStandardFlags;
        int numberOfTransitionTimes, numberOfLocalTimes, numberOfAbbreviationCharacters;
        int i;
        const struct tzType {
            unsigned int offset;
            unsigned char isDST;
            unsigned char abbrevIndex;
        } *tzTypes;
        const char *tzTypesBytes;
        const char *abbreviations;

// FIX, The NSTimeZones directory is currently not enabled, it is large (2MB) and not used, need to come up with an alternative
        if (data == nil) {
            NSString *zonePath = [[NSBundle bundleForClass:[self class]] resourcePath];

            zonePath = [zonePath stringByAppendingPathComponent:@"NSTimeZones"];
            zonePath = [zonePath stringByAppendingPathComponent:name];
            // should do a replaceCharacters with @"/" vs. fileSystemSeparator

            data = [NSData dataWithContentsOfFile:zonePath];
        }
        if (data == nil)
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid name or data to -[NSTimeZone initWithName:data:]"];

        transitions = [NSMutableArray array];
        types = [NSMutableArray array];

        tzHeader=[data bytes];
        tzData=(const char *)tzHeader+sizeof(struct tzhead);
        
        numberOfGMTFlags = NSSwapBigIntToHost(*((int *)tzHeader->tzh_ttisgmtcnt));
        numberOfStandardFlags = NSSwapBigIntToHost(*((int *)tzHeader->tzh_ttisstdcnt));
        numberOfTransitionTimes = NSSwapBigIntToHost(*((int *)tzHeader->tzh_timecnt));
        numberOfLocalTimes = NSSwapBigIntToHost(*((int *)tzHeader->tzh_typecnt));
        numberOfAbbreviationCharacters = NSSwapBigIntToHost(*((int *)tzHeader->tzh_charcnt));

        typeIndices = tzData+(numberOfTransitionTimes * 4);
        for (i = 0; i < numberOfTransitionTimes; ++i) {
            [transitions addObject:[NSTimeZoneTransition
                timeZoneTransitionWithTransitionDate:[NSDate dateWithTimeIntervalSince1970:NSSwapBigIntToHost(((int *)tzData)[i])]
                                           typeIndex:typeIndices[i]]];
        }

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

        return [self initWithName:name data:data transitions:transitions types:types];
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

-(NSTimeZoneType *)timeZoneTypeForDate:(NSDate *)date {    
    if ([_timeZoneTransitions count] == 0 ||
        [date compare:[[_timeZoneTransitions objectAtIndex:0] transitionDate]] == NSOrderedAscending) {
        NSEnumerator *timeZoneTypeEnumerator = [_timeZoneTypes objectEnumerator];
        NSTimeZoneType *type;

        while (type = [timeZoneTypeEnumerator nextObject]) {
            if (![type isDaylightSavingTime])
                return type;
        }

        return [_timeZoneTypes objectAtIndex:0];
    }
    else {
        NSEnumerator *timeZoneTransitionEnumerator = [_timeZoneTransitions objectEnumerator];
        NSTimeZoneTransition *transition, *previousTransition = nil;

        while (transition = [timeZoneTransitionEnumerator nextObject]) {
            if ([date compare:[transition transitionDate]] == NSOrderedAscending) {
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

-(int)secondsFromGMTForDate:(NSDate *)date {
    return [[self timeZoneTypeForDate:date] secondsFromGMT];
}

-(NSString *)abbreviationForDate:(NSDate *)date {
    return [[self timeZoneTypeForDate:date] abbreviation];
}

-(BOOL)isDaylightSavingTimeForDate:(NSDate *)date {
    return [[self timeZoneTypeForDate:date] isDaylightSavingTime];
}

// cool!
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

@end
