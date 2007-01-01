/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSThread-Private.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSPersistantDomain.h>

NSString *NSGlobalDomain=@"NSGlobalDomain";
NSString *NSArgumentDomain=@"NSArgumentDomain";
NSString *NSRegistrationDomain=@"NSRegistrationDomain";

NSString *NSMonthNameArray=@"NSMonthNameArray";
NSString *NSWeekDayNameArray=@"NSWeekDayNameArray";
NSString *NSTimeFormatString=@"NSTimeFormatString";
NSString *NSDateFormatString=@"NSDateFormatString";
NSString *NSAMPMDesignation=@"NSAMPMDesignation";
NSString *NSTimeDateFormatString=@"NSTimeDateFormatString";

NSString *NSShortWeekDayNameArray=@"NSShortWeekDayNameArray";
NSString *NSShortMonthNameArray=@"NSShortMonthNameArray";

@implementation NSUserDefaults

-(void)registerArgumentDefaults {
   NSMutableDictionary *reg=[NSMutableDictionary dictionary];
   NSArray             *args=[[NSProcessInfo processInfo] arguments];
   int                  i,count=[args count];

   for(i=1;i<count-1;i+=2){
    NSString *key=[args objectAtIndex:i];
    NSString *val=[args objectAtIndex:i+1];
    NSString *pval;

    if([key length]==0 || [key characterAtIndex:0]!='-')
     break;

    key=[key substringFromIndex:1];

    NS_DURING
     pval=[val propertyList];
    NS_HANDLER
     pval=val;
    NS_ENDHANDLER

    [reg setObject:pval forKey:key];
   }

   [_domains setObject:reg forKey:NSArgumentDomain];
}

-(void)registerFoundationDefaults {
   NSString     *path=[[NSBundle bundleForClass:[self class]] 
                  pathForResource:@"NSUserDefaults" ofType:@"plist"];
   NSDictionary *plist=[NSDictionary dictionaryWithContentsOfFile:path];

   if(plist==nil)
    OBJCLog("internal error, unable to locate NSUserDefaults.plist, path=%s, bundle at %s",[path cString],[[[NSBundle bundleForClass:[self class]]  resourcePath] cString]);
   else
    [_domains setObject:plist forKey:@"Foundation"];
}

-(void)registerProcessNameDefaults {
#if 0
   NSString *directory=[[_domains objectForKey:@"Foundation"] objectForKey:@"NSUserDefaultsUserDirectory"];
   NSString *path=[[[directory stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathExtension:@"plist"] stringByExpandingTildeInPath];

   if(path!=nil){
    NSDictionary *plist=[NSDictionary dictionaryWithContentsOfFile:path];

    [_domains setObject:plist forKey:[[NSProcessInfo processInfo] processName]];
   }
#else
  NSString           *name=[[NSBundle mainBundle] bundleIdentifier];
  NSPersistantDomain *domain;
  
  if(name==nil)
   name=[NSString stringWithFormat:@"noid.%@",[[NSProcessInfo processInfo] processName]];
   
  domain=[[[NSPlatform currentPlatform] persistantDomainClass] persistantDomainWithName:name];

  [_domains setObject:domain forKey:[[NSProcessInfo processInfo] processName]];
#endif

}

-init {
   _domains=[NSMutableDictionary new];
   _searchList=[[NSArray allocWithZone:NULL] initWithObjects:
      NSArgumentDomain,
      [[NSProcessInfo processInfo] processName],
      NSGlobalDomain,
      NSRegistrationDomain,
     @"Foundation",
      nil];

   [[NSProcessInfo processInfo] environment];
   
   [self registerFoundationDefaults];

   [self registerArgumentDefaults];
   [self registerProcessNameDefaults];

   [_domains setObject:[NSMutableDictionary dictionary]
                forKey:NSRegistrationDomain];

   return self;
}

-initWithUser:(NSString *)user {
   NSUnimplementedMethod();
   return nil;
}


+(NSUserDefaults *)standardUserDefaults {
   return NSThreadSharedInstance(@"NSUserDefaults");
}

-(NSArray *)searchList {
   return _searchList;
}

-(void)setSearchList:(NSArray *)array {
   [array retain];
   [_searchList release];
   _searchList=array;
}

-(NSDictionary *)_buildDictionaryRep {
   NSMutableDictionary *result=[NSMutableDictionary dictionary];
   int                  i,count=[_searchList count];

   for(i=0;i<count;i++){
    NSDictionary *domain=[_domains objectForKey:[_searchList objectAtIndex:i]];
    NSEnumerator *state=[domain keyEnumerator];
    id            key;

    while((key=[state nextObject])!=nil){
     id value=[domain objectForKey:key];

// NSPersistantDomain may return nil, addEntriesFromDictionary doesn't do that test
     if(value!=nil)
      [result setObject:value forKey:key];
    }
   }

   return result;
}

-(NSDictionary *)dictionaryRepresentation {
   if(_dictionaryRep==nil)
    _dictionaryRep=[[self _buildDictionaryRep] retain];

   return _dictionaryRep;
}

-(void)registerDefaults:(NSDictionary *)registrationDictionary {
   [[_domains objectForKey:NSRegistrationDomain]
                    addEntriesFromDictionary:registrationDictionary];
}


-(NSArray *)volatileDomainNames {
   NSUnimplementedMethod();
   return nil;
}

-(NSArray *)persistentDomainNames {
   NSUnimplementedMethod();
   return nil;
}

-(NSDictionary *)volatileDomainForName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(NSDictionary *)persistentDomainForName:(NSString *)name {
   NSMutableDictionary   *result=[NSMutableDictionary dictionary];
   NSPersistantDomain    *domain=[[[NSPlatform currentPlatform] persistantDomainClass] persistantDomainWithName:name];
   NSArray               *allKeys=[domain allKeys];
   int                    i,count=[allKeys count];

   for(i=0;i<count;i++){
    NSString *key=[allKeys objectAtIndex:i];

    [result setObject:[domain objectForKey: key] forKey:key];
   }

   return result;
}

-(void)setVolatileDomain:(NSDictionary *)domain
  forName:(NSString *)name {
   NSUnimplementedMethod();
}

-(void)setPersistentDomain:(NSDictionary *)domain
   forName:(NSString *)name {
   NSUnimplementedMethod();
}


-(void)removeVolatileDomainForName:(NSString *)name {
   NSUnimplementedMethod();
}

-(void)removePersistentDomainForName:(NSString *)name {
   NSUnimplementedMethod();
}

-(BOOL)synchronize {
   return 0;
}

-(NSMutableDictionary *)persistantDomain {
   return [_domains objectForKey:[[NSProcessInfo processInfo] processName]];
}

-objectForKey:(NSString *)defaultName {
   int i,count=[_searchList count];

   for(i=0;i<count;i++){
    NSDictionary *domain=[_domains objectForKey:[_searchList objectAtIndex:i]];
    id            object=[domain objectForKey:defaultName];

    if(object!=nil)
     return object;
   }

   return nil;
}

-(NSData *)dataForKey:(NSString *)defaultName {
   NSData *data=[self objectForKey:defaultName];

   return [data isKindOfClass:OBJCClassFromString("NSData")]?data:nil;
}

-(NSString *)stringForKey:(NSString *)defaultName {
   NSString *string=[self objectForKey:defaultName];

   return [string isKindOfClass:OBJCClassFromString("NSString")]?string:nil;
}

-(NSArray *)arrayForKey:(NSString *)defaultName {
   NSArray *array=[self objectForKey:defaultName];

   return [array isKindOfClass:OBJCClassFromString("NSArray")]?array:nil;
}


-(NSDictionary *)dictionaryForKey:(NSString *)defaultName {
   NSDictionary *dictionary=[self objectForKey:defaultName];

   return [dictionary isKindOfClass:OBJCClassFromString("NSDictionary")]?dictionary:nil;
}

-(NSArray *)stringArrayForKey:(NSString *)defaultName {
   NSArray *array=[self objectForKey:defaultName];
   int      count;

   if(![array isKindOfClass:OBJCClassFromString("NSArray")])
    return nil;

   count=[array count];
   while(--count>=0)
    if(![[array objectAtIndex:count] isKindOfClass:OBJCClassFromString("NSString")])
     return nil;

   return array;
}


-(BOOL)boolForKey:(NSString *)defaultName {
   NSString *string=[self objectForKey:defaultName];

   if(![string isKindOfClass:OBJCClassFromString("NSString")])
    return NO;

   if([string caseInsensitiveCompare:@"YES"]==NSOrderedSame)
    return YES;

   return [string intValue];
}

-(int)integerForKey:(NSString *)defaultName {
   NSString *string=[self objectForKey:defaultName];

   return [string isKindOfClass:OBJCClassFromString("NSString")]?[string intValue]:0;
}


-(float)floatForKey:(NSString *)defaultName {
   NSString *string=[self objectForKey:defaultName];

   return [string isKindOfClass:OBJCClassFromString("NSString")]?[string floatValue]:0.0;
}

-(void)setObject:value forKey:(NSString *)key {
   [[self persistantDomain] setObject:value forKey:key];
   [_dictionaryRep autorelease];
   _dictionaryRep=nil;
}

-(void)setBool:(BOOL)value forKey:(NSString *)defaultName {
   [self setObject:value?@"YES":@"NO" forKey:defaultName];
}

-(void)setInteger:(int)value forKey:(NSString *)defaultName {
   [self setObject:[NSString stringWithFormat:@"%d",value] forKey:defaultName];
}

-(void)setFloat:(float)value forKey:(NSString *)defaultName {
   [self setObject:[NSString stringWithFormat:@"%f",value] forKey:defaultName];
}

-(void)removeObjectForKey:(NSString *)key {
   [[self persistantDomain] removeObjectForKey:key];
}



@end
