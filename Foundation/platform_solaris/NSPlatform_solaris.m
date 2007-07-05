/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/ObjectiveC.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSPlatform_solaris.h>
#import <Foundation/NSTask_solaris.h>

#import <rpc/types.h>
#import <time.h>
#import <netdb.h>

NSString *NSPlatformClassName=@"NSPlatform_solaris";

@implementation NSPlatform_solaris

/*
     The external time_t variable altzone  contains  the  differ-
     ence, in seconds, between Coordinated Universal Time and the
     alternate time zone. The external variable timezone contains
     the  difference,  in seconds, between UTC and local standard
     time.  The external variable daylight indicates whether time
     should  reflect  daylight  savings  time.  Both timezone and
     altzone default to 0 (UTC). The external  variable  daylight
     is  non-zero if an alternate time zone exists. The time zone
     names are contained in the external variable  tzname,  which
     by default is set to:
 */
-(NSTimeZone *)systemTimeZone {
   NSTimeZone *systemTimeZone;
    NSString *timeZoneName;
    int secondsFromGMT;

#if 0		// time zone method 1. not great.
   tzset();
   printf("abbrev is %s\n", __tzname[__daylight]); 
   printf("TZ is %s tzname is %s\n", getenv("TZ"), tzname[1]);
   systemTimeZone = [[NSTimeZone timeZoneWithAbbreviation:[NSString stringWithCString:__tzname[__daylight]]] retain];
#endif

#if 0		// more anomalous results...
   systemTimeZone = [[NSTimeZone alloc] initWithName:@"SolarisSystem" 
               data:[NSData dataWithContentsOfFile:@"/etc/localtime"]];
#endif

   // similar to Win32's implementation
   tzset();
   secondsFromGMT = 0-timezone + daylight*3600;
   systemTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:secondsFromGMT];

   return systemTimeZone;
}

/*
 BSD  4.3.  The SUSv2 version returns int, and this is also
 the prototype used by glibc 2.2.2.  Only the EINVAL  error
 return is documented by SUSv2.
 */
-(void)sleepThreadForTimeInterval:(NSTimeInterval)interval {
    if (interval <= 0.0)
        return;

    if (interval > 1.0)
        sleep((unsigned int) interval);
    else {
     unsigned long value= 1000.0*interval;
     poll(NULL,0,value);
    }
}

/*
 SVr4,  4.4BSD   (this  function first appeared in 4.2BSD).
 POSIX.1 does  not  define  these  functions,  but  ISO/IEC
 9945-1:1990 mentions them in B.4.4.1.
 */
-(NSString *)hostName {
    char buf[MAXHOSTNAMELEN];
    gethostname(buf, MAXHOSTNAMELEN);
    return [NSString stringWithCString:buf];
}

-(NSString *)DNSHostName {
    // if we wanted to get crazy, we could open a dummy socket
    // and then get its local address, the do a gethostbyaddr on that...
    return [self hostName];
}

-(NSString *)executableDirectory {
   return @"Solaris";
}

-(NSString *)resourceNameSuffix {
   return @"solaris";
}

-(NSString *)loadableObjectFileExtension {
   return @"so";
}

-(NSString *)loadableObjectFilePrefix {
   return @"lib";
}

-(Class)taskClass {
   return [NSTask_solaris class];
}

@end

char **NSPlatform_environ() {
   extern char **environ;
   
   return environ;
}

