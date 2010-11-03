/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSProcessInfo.h>
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
   NSUInteger length=[self length];
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
	if ([string length])
   	 [array addObject:string];
    e++; // skip sepchar
   }while(e<length);

   return array;
}

-(NSString *)lastPathComponent {
   NSUInteger length=[self length];
   unichar  buffer[length];
   NSInteger      i;

   [self getCharacters:buffer];

   if(length>1 && ISSLASH(buffer[length-1]))
    length--;

   for(i=length;--i>=0;)
    if(ISSLASH(buffer[i]) && i<length-1)
     return [NSString stringWithCharacters:buffer+i+1 length:(length-i)-1];

   return [NSString stringWithCharacters:buffer length:length];
}

-(NSString *)pathExtension {
   NSUInteger length=[self length];
   unichar  buffer[length];
   NSInteger      i;

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
   NSUInteger selfLength=[self length];
   
   if(selfLength==0){
    if(other)
     return [NSString stringWithString:other];
    else
     return @"";
   }
   
   NSUInteger otherLength=[other length];
   NSUInteger totalLength=selfLength+1+otherLength;
   unichar  characters[totalLength];

   [self getCharacters:characters];
   NSUInteger p=selfLength;
   while(--p>=0 && ISSLASH(characters[p]));
   characters[++p]=SLASH;
   NSUInteger q=0;
   while(q<otherLength && ISSLASH([other characterAtIndex:q])) q++;
   [other getCharacters:characters+p+1 range:NSMakeRange(q, otherLength-q)];

   return [NSString stringWithCharacters:characters length:p+1-q+otherLength];
}

-(NSString *)stringByAppendingPathExtension:(NSString *)other {
   NSUInteger selfLength=[self length];
	if(selfLength && [self characterAtIndex:selfLength-1]==SLASH)
		selfLength--;
   NSUInteger otherLength=[other length];
   NSUInteger totalLength=selfLength+1+otherLength;
   unichar  characters[totalLength];

   [self getCharacters:characters];
   characters[selfLength]='.';
   [other getCharacters:characters+selfLength+1];

   return [NSString stringWithCharacters:characters length:totalLength];
}

-(NSString *)stringByDeletingLastPathComponent {
   NSUInteger length=[self length];
   unichar  buffer[length];
   NSInteger      i;

   [self getCharacters:buffer];

   for(i=length;--i>=0;)
    if(ISSLASH(buffer[i])){
     if(i==0)
      return SLASHSTRING;
     else if(i+1<length)
      return [NSString stringWithCharacters:buffer length:i];
    }
    
   return @"";
}

-(NSString *)stringByDeletingPathExtension {
   NSUInteger length=[self length];
   unichar  buffer[length];
   NSInteger      i;

   [self getCharacters:buffer];

   if (length>1 && ISSLASH(buffer[length-1]))
    length--;

   for(i=length;--i>0;){
    if(ISSLASH(buffer[i]) || ISSLASH(buffer[i-1]))
     break;
    else if(buffer[i]=='.')
     return [NSString stringWithCharacters:buffer length:i];
   }

   return [NSString stringWithCharacters:buffer length:length];
}

-(NSString *)stringByExpandingTildeInPath {
   NSString *user,*homedir,*rest;
   NSUInteger  length=[self length];
   unichar   buffer[length];
   int       i;

   [self getCharacters:buffer];

   if(length==0)
    return @"";
   else if(buffer[0]!='~')
    return [NSString stringWithCharacters:buffer length:length];

   for(i=1;!ISSLASH(buffer[i]) && i<length;i++)
    ;

   if(i==1)
    homedir=NSHomeDirectory();
   else{
    user=[NSString stringWithCharacters:buffer+1 length:i-1];
    homedir=nil; //NSHomeDirectoryForUser(user);
   }

   if(homedir==nil)
    return [NSString stringWithCharacters:buffer length:length];

   rest=[NSString stringWithCharacters:buffer+i length:length-i];

   return [homedir stringByAppendingString:rest];
}

-(NSString *)stringByAbbreviatingWithTildeInPath {
   NSString *homedir=NSHomeDirectory(),*rest;
   NSUInteger  length=[self length],homelength=[homedir length];
   unichar   buffer[length],homebuffer[homelength];
   int       i;

   [self getCharacters:buffer];
   if(homedir==nil)
    return [NSString stringWithCharacters:buffer length:length];

   [homedir getCharacters:homebuffer];

   if(length<homelength || (length>homelength && !ISSLASH(buffer[homelength])))
    return [NSString stringWithCharacters:buffer length:length];

   for(i=0;i<homelength;i++)
    if(buffer[i]!=homebuffer[i])
     return [NSString stringWithCharacters:buffer length:length];

   rest=[NSString stringWithCharacters:buffer+homelength
                                length:length-homelength];

   return [@"~" stringByAppendingString:rest];
}

-(NSString *)stringByStandardizingPath {
    NSUInteger length = [self length];
    if (length < 1)
        return @"";
    
    // expand tilde
    NSString *standardPath = self;
    if ([self characterAtIndex:0] == '~') {
        standardPath = [standardPath stringByExpandingTildeInPath];
        length = [standardPath length];
    }

    unichar buffer[length];
    unichar cleanedBuffer[length];
    int cleanedN = 0;
    int i;

    [standardPath getCharacters:buffer];
    
    for (i = 0; i < length; i++) {
        cleanedBuffer[cleanedN++] = ISSLASH(buffer[i]) ? SLASH : buffer[i];  // convert all slashes to platform standard
        
        if (ISSLASH(buffer[i])) {
            while (i+1 < length && ISSLASH(buffer[i+1])) {
                i++;  // skip past all following slashes
            }
            if (i+2 < length && buffer[i+1] == '.' && ISSLASH(buffer[i+2]))
                i+=2; // skip past "./" sequence
        }
    }
    
    // this implementation doesn't do all transformations described in Cocoa documentation
    
    return [NSString stringWithCharacters:cleanedBuffer length:cleanedN];
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
   return [[NSFileManager defaultManager] fileSystemRepresentationWithPath:self];
}

-(const uint16_t *)fileSystemRepresentationW {
   return [[NSFileManager defaultManager] fileSystemRepresentationWithPathW:self];
}

@end

NSArray *NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory,NSSearchPathDomainMask mask,BOOL expand) {
   if(mask!=NSUserDomainMask)
    NSUnimplementedFunction();
    
   if(directory==NSCachesDirectory){
    NSString *path=[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
    
    return [NSArray arrayWithObject:path];
   }
   
   if(directory==NSApplicationSupportDirectory){
    NSString *path=[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
    
    return [NSArray arrayWithObject:path];
   }

    return nil;
}

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

