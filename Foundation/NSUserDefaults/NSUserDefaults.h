/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

@class NSArray,NSData,NSMutableDictionary,NSDictionary,NSMutableArray;

FOUNDATION_EXPORT NSString *NSGlobalDomain;
FOUNDATION_EXPORT NSString *NSArgumentDomain;
FOUNDATION_EXPORT NSString *NSRegistrationDomain;

FOUNDATION_EXPORT NSString *NSMonthNameArray;
FOUNDATION_EXPORT NSString *NSWeekDayNameArray;
FOUNDATION_EXPORT NSString *NSTimeFormatString;
FOUNDATION_EXPORT NSString *NSDateFormatString;
FOUNDATION_EXPORT NSString *NSAMPMDesignation;

FOUNDATION_EXPORT NSString *NSTimeDateFormatString;

FOUNDATION_EXPORT NSString *NSShortWeekDayNameArray;
FOUNDATION_EXPORT NSString *NSShortMonthNameArray;

@interface NSUserDefaults : NSObject {
   NSMutableDictionary *_domains;
   NSArray             *_searchList;
   NSDictionary        *_dictionaryRep;
}

-init;
-initWithUser:(NSString *)user;

+(NSUserDefaults *)standardUserDefaults;

-(NSArray *)searchList;
-(void)setSearchList:(NSArray *)array;

-(NSDictionary *)dictionaryRepresentation;

-(void)registerDefaults:(NSDictionary *)registrationDictionary;

-(NSArray *)volatileDomainNames;
-(NSArray *)persistentDomainNames;

-(NSDictionary *)volatileDomainForName:(NSString *)name;
-(NSDictionary *)persistentDomainForName:(NSString *)name;

-(void)setVolatileDomain:(NSDictionary *)domain forName:(NSString *)name;
-(void)setPersistentDomain:(NSDictionary *)domain
   forName:(NSString *)name;

-(void)removeVolatileDomainForName:(NSString *)name;
-(void)removePersistentDomainForName:(NSString *)name;

-(BOOL)synchronize;

-objectForKey:(NSString *)key;
-(NSData *)dataForKey:(NSString *)key;
-(NSString *)stringForKey:(NSString *)key;
-(NSArray *)arrayForKey:(NSString *)key;
-(NSDictionary *)dictionaryForKey:(NSString *)key;
-(NSArray *)stringArrayForKey:(NSString *)key;
-(BOOL)boolForKey:(NSString *)key;  
-(int)integerForKey:(NSString *)key; 
-(float)floatForKey:(NSString *)key;

-(void)setObject:value forKey:(NSString *)key;
-(void)setBool:(BOOL)value forKey:(NSString *)key;
-(void)setInteger:(int)value forKey:(NSString *)key;
-(void)setFloat:(float)value forKey:(NSString *)key;

-(void)removeObjectForKey:(NSString *)key;

@end

