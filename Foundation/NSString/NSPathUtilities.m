/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSPlatform.h>
#import <Foundation/NSRaise.h>

#import <string.h>
#import <stdio.h>

#define ISSLASH(X)  ((X)=='/' || (X)=='\\')

#ifdef WIN32
#define SLASH '\\'
#define SLASHSTRING @"\\"
#else
#define SLASH '/'
#define SLASHSTRING @"/"
#endif

@implementation NSString(NSStringPathUtilities)

+(NSString *)pathWithComponents:(NSArray *)components {
   return [components componentsJoinedByString:SLASHSTRING];
}

-(NSArray *)pathComponents {
   NSMutableArray *array=[NSMutableArray array];
   unsigned length=[self length];
   unichar  unicode[length];
   NSString *string;
   int b,e;

   [self getCharacters:unicode];

   e=0;
   do{
    b=e;
    while(e<length && unicode[e]!='\\' && unicode[e]!='/')
     e++;
    string=[NSString stringWithCharacters:unicode+b length:e-b];
    [array addObject:string];
    e++; // skip sepchar
   }while(e<length);

   return array;
}

-(NSString *)lastPathComponent {
   unsigned length=[self length];
   unichar  buffer[length];
   int      i;

   [self getCharacters:buffer];

   if(length>0 && ISSLASH(buffer[length-1]))
    length--;

   for(i=length;--i>=0;)
    if(ISSLASH(buffer[i]) && i<length-1)
     return [NSString stringWithCharacters:buffer+i+1 length:(length-i)-1];

   return self;
}

-(NSString *)pathExtension {
   unsigned length=[self length];
   unichar  buffer[length];
   int      i;

   [self getCharacters:buffer];

   if(length>0 && ISSLASH(buffer[length-1]))
    length--;

   for(i=length;--i>=0;){
    if(ISSLASH(buffer[i]))
     return @"";
    if(buffer[i]=='.')
     return [NSString stringWithCharacters:buffer+i+1 length:(length-i)-1];
   }

   return @"";
}

-(NSString *)stringByAppendingPathComponent:(NSString *)other {
   unsigned selfLength=[self length];
   unsigned otherLength=[other length];
   unsigned totalLength=selfLength+1+otherLength;
   unichar  characters[totalLength];

   [self getCharacters:characters];
   characters[selfLength]=SLASH;
   [other getCharacters:characters+selfLength+1];

   return [NSString stringWithCharacters:characters length:totalLength];
}

-(NSString *)stringByAppendingPathExtension:(NSString *)other {
   unsigned selfLength=[self length];
   unsigned otherLength=[other length];
   unsigned totalLength=selfLength+1+otherLength;
   unichar  characters[totalLength];

   [self getCharacters:characters];
   characters[selfLength]='.';
   [other getCharacters:characters+selfLength+1];

   return [NSString stringWithCharacters:characters length:totalLength];
}

-(NSString *)stringByDeletingLastPathComponent {
   unsigned length=[self length];
   unichar  buffer[length];
   int      i;

   [self getCharacters:buffer];

   for(i=length;--i>=0;)
    if(ISSLASH(buffer[i]))
     return [NSString stringWithCharacters:buffer length:i];

   return self;
}

-(NSString *)stringByDeletingPathExtension {
   unsigned length=[self length];
   unichar  buffer[length];
   int      i;

   [self getCharacters:buffer];

   for(i=length;--i>=0;)
    if(buffer[i]=='.')
     return [NSString stringWithCharacters:buffer length:i];

   return self;
}

-(NSString *)stringByExpandingTildeInPath {
   NSString *user,*homedir,*rest;
   unsigned  length=[self length];
   unichar   buffer[length];
   int       i;

   [self getCharacters:buffer];

   if(length==0 || buffer[0]!='~')
    return self;

   for(i=1;!ISSLASH(buffer[i]) && i<length;i++)
    ;

   if(i==1)
    homedir=NSHomeDirectory();
   else{
    user=[NSString stringWithCharacters:buffer+1 length:i-1];
    homedir=nil; //NSHomeDirectoryForUser(user);
   }

   if(homedir==nil)
    return self;

   rest=[NSString stringWithCharacters:buffer+i length:length-i];

   return [homedir stringByAppendingString:rest];
}

-(NSString *)stringByAbbreviatingWithTildeInPath {
   NSString *homedir=NSHomeDirectory(),*rest;
   unsigned  length=[self length],homelength=[homedir length];
   unichar   buffer[length],homebuffer[homelength];
   int       i;

   if(homedir==nil)
    return self;

   [self getCharacters:buffer];
   [homedir getCharacters:homebuffer];

   if(length<homelength || (length>homelength && !ISSLASH(buffer[homelength])))
    return self;

   for(i=0;i<homelength;i++)
    if(buffer[i]!=homebuffer[i])
     return self;

   rest=[NSString stringWithCharacters:buffer+homelength
                                length:length-homelength];

   return [@"~" stringByAppendingString:rest];
}

-(NSString *)stringByStandardizingPath {
   NSUnimplementedMethod();
   return self;
}

-(BOOL)isAbsolutePath {
   if([self length]>0){
    if(ISSLASH([self characterAtIndex:0]))
     return YES;

    if([self length]>1){
     if([self characterAtIndex:1]==':')
      return YES;
    }
   }

   return NO;
}

-(const char *)fileSystemRepresentation {
   return [[NSFileManager defaultManager]
                       fileSystemRepresentationWithPath:self];
}

@end

NSString *NSHomeDirectory(void) {
   return [[NSPlatform currentPlatform] homeDirectory];
}

NSString *NSTemporaryDirectory(void) {
   return [[NSPlatform currentPlatform] temporaryDirectory];
}

NSString *NSUserName(void) {
   return [[NSPlatform currentPlatform] userName];
}

NSString *NSFullUserName(void) {
   return [[NSPlatform currentPlatform] fullUserName];
}

