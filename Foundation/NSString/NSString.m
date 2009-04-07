/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString_cString.h>
#import <Foundation/NSString_nextstep.h>
#import <Foundation/NSString_isoLatin1.h>
#import <Foundation/NSStringSymbol.h>
#import <Foundation/NSStringUTF8.h>
#import <Foundation/NSUnicodeCaseMapping.h>
#import <Foundation/NSPropertyListReader.h>
#import <Foundation/NSStringsFileParser.h>
#import <Foundation/NSRaise.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSLocale.h>

#import <Foundation/NSString_placeholder.h>
#import <Foundation/NSString_unicode.h>
#import <Foundation/NSString_unicodePtr.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSStringFileIO.h>
#import <Foundation/NSKeyedUnarchiver.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSStringHashing.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSAutoreleasePool.h>
#import <limits.h>
#import <objc/objc-class.h>
#import <string.h>

extern BOOL NSObjectIsKindOfClass(id object,Class kindOf);

const unsigned NSMaximumStringLength=INT_MAX-1;

// only needed for Darwin ppc
struct objc_class _NSConstantStringClassReference;
// only needed for Darwin i386
int __CFConstantStringClassReference[1];

@implementation NSString

+allocWithZone:(NSZone *)zone {
   if(self==objc_lookUpClass("NSString"))
    return NSAllocateObject(objc_lookUpClass("NSString_placeholder"),0,NULL);

   return NSAllocateObject(self,0,zone);
}

-initWithCharactersNoCopy:(unichar *)characters length:(unsigned)length
             freeWhenDone:(BOOL)freeWhenDone {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithCharacters:(const unichar *)characters length:(unsigned)length {
   NSInvalidAbstractInvocation();
   return nil;
}

-init {
   return self;
}

-initWithCStringNoCopy:(char *)cString length:(unsigned)length
          freeWhenDone:(BOOL)freeWhenDone {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithCString:(const char *)cString length:(unsigned)length{
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithCString:(const char *)cString {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithCString:(const char *)cString encoding:(NSStringEncoding)encoding {
   return [self initWithData:[NSData dataWithBytes:cString length:strlen(cString)] encoding:encoding];
}

-initWithString:(NSString *)string {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithFormat:(NSString *)format locale:(NSDictionary *)locale
      arguments:(va_list)arguments {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithFormat:(NSString *)format locale:(NSDictionary *)locale,... {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithFormat:(NSString *)format arguments:(va_list)arguments {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithFormat:(NSString *)format,... {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithUTF8String:(const char *)utf8 {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding {
   NSUnimplementedMethod();
   return 0;
}
-initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding freeWhenDone:(BOOL)freeWhenDone {
   NSUnimplementedMethod();
   return 0;
}

-initWithContentsOfFile:(NSString *)path {
   NSInvalidAbstractInvocation();
   return nil;
}

-initWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-initWithContentsOfFile:(NSString *)path usedEncoding:(NSStringEncoding *)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-initWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-initWithContentsOfURL:(NSURL *)url usedEncoding:(NSStringEncoding *)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

+(const NSStringEncoding *)availableStringEncodings {
   NSUnimplementedMethod();
   return 0;
}

+(NSString *)localizedNameOfStringEncoding:(NSStringEncoding)encoding {
   NSUnimplementedMethod();
   return 0;
}


+stringWithCharacters:(const unichar *)unicode length:(unsigned)length {
   if(self==objc_lookUpClass("NSString"))
    return NSAutorelease(NSString_unicodeNew(NULL,unicode,length));

   return [[[self allocWithZone:NULL] initWithCharacters:unicode length:length] autorelease];
}

+string {
   if(self==objc_lookUpClass("NSString"))
    return NSAutorelease(NSString_unicodeNew(NULL,NULL,0));

   return [[[self allocWithZone:NULL] init] autorelease];
}

+stringWithCString:(const char *)cString length:(unsigned)length {
   if(self==objc_lookUpClass("NSString"))
    return NSAutorelease(NSString_cStringNewWithBytes(NULL,cString,length));

   return [[[self allocWithZone:NULL] initWithCString:cString length:length] autorelease];
}

+stringWithCString:(const char *)cString {
   if(self==objc_lookUpClass("NSString"))
    return NSAutorelease(NSString_cStringNewWithBytesAndZero(NULL,cString));

   return [[[self allocWithZone:NULL] initWithCString:cString] autorelease];
}

+stringWithString:(NSString *)string {
   return [[[self allocWithZone:NULL] initWithString:string] autorelease];
}

+stringWithFormat:(NSString *)format,... {
   va_list arguments;

   va_start(arguments,format);

   if(self==objc_lookUpClass("NSString"))
    return NSAutorelease(NSStringNewWithFormat(format,nil,arguments,NULL));

   return [[[self allocWithZone:NULL] initWithFormat:format arguments:arguments] autorelease];
}

+stringWithContentsOfFile:(NSString *)path {
   if(self==objc_lookUpClass("NSString")){
    unsigned  length;
    unichar  *unicode;

    if((unicode=NSCharactersWithContentsOfFile(path,&length,NULL))==NULL)
     return nil;

    return NSAutorelease(NSString_unicodePtrNewNoCopy(NULL,unicode,length));
   }

   return [[[self allocWithZone:NULL] initWithContentsOfFile:path] autorelease];
}

+stringWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

+stringWithContentsOfFile:(NSString *)path usedEncoding:(NSStringEncoding *)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

+stringWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

+stringWithContentsOfURL:(NSURL *)url usedEncoding:(NSStringEncoding *)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

+stringWithCString:(const char *)cString encoding:(NSStringEncoding)encoding {
   NSUnimplementedMethod();
   return 0;
}

+stringWithUTF8String:(const char *)utf8 {
   return [[[NSString alloc] initWithUTF8String:utf8] autorelease];
}

+localizedStringWithFormat:(NSString *)format,... {
   va_list arguments;

   va_start(arguments,format);

   return NSAutorelease(NSStringNewWithFormat(format,[NSLocale currentLocale],arguments,NULL));
}

-copy {
   return [self retain];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-mutableCopy {
   return [[NSMutableString allocWithZone:NULL] initWithString:self];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [[NSMutableString allocWithZone:zone] initWithString:self];
}


-(Class)classForCoder {
   return objc_lookUpClass("NSString");
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSKeyedUnarchiver class]]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    NSString          *string=[keyed decodeObjectForKey:@"NS.string"];
    
    return [self initWithString:string];
   }
   else {
    unsigned length;
    char    *bytes;

    [self dealloc];

    bytes=[coder decodeBytesWithReturnedLength:&length];

    if(NSUTF8IsASCII(bytes,length))
     return NSString_cStringNewWithBytes(NULL,bytes,length);
    else {
     unsigned resultLength;
     unichar *characters=NSUTF8ToUnicode(bytes,length,&resultLength,NULL);

     return NSString_unicodePtrNewNoCopy(NULL,characters,resultLength);
    }
   }
}

-(void)encodeWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSKeyedArchiver class]]){
    NSKeyedArchiver *keyed=(NSKeyedArchiver *)coder;
    
    [keyed encodeObject:[NSString stringWithString:self] forKey:@"NS.string"];
   }
   else {
    unsigned length=[self length],utf8Length;
    unichar  buffer[length];
    char    *utf8;

    [self getCharacters:buffer];
    utf8=NSUnicodeToUTF8(buffer,length,NO,&utf8Length,NULL,NO);
    [coder encodeBytes:utf8 length:utf8Length];
    NSZoneFree(NSZoneFromPointer(utf8),utf8);
   }
}

-(unichar)characterAtIndex:(unsigned)location {
   NSInvalidAbstractInvocation();
   return 0;
}

-(unsigned)length {
   NSInvalidAbstractInvocation();
   return 0;
}

-(void)getCharacters:(unichar *)unicode range:(NSRange)range {
   int i,loc=range.location,len=range.length;

   for(i=0;i<len;i++)
    unicode[i]=[self characterAtIndex:loc+i];
}

-(void)getCharacters:(unichar *)unicode {
   NSRange range={0,[self length]};
   [self getCharacters:unicode range:range];
}

static inline NSComparisonResult compareWithOptions(NSString *self,NSString *other,unsigned options,NSRange range){
   unsigned i,otherLength=[other length];
   unichar  selfBuf[range.length],otherBuf[otherLength];

   [self getCharacters:selfBuf range:range];
   [other getCharacters:otherBuf];

   if(options&NSCaseInsensitiveSearch){
    NSUnicodeToUppercase(selfBuf,range.length);
    NSUnicodeToUppercase(otherBuf,otherLength);
   }

   for(i=0;i<range.length && i<otherLength;i++)
    if(selfBuf[i]<otherBuf[i])
     return NSOrderedAscending;
    else if(selfBuf[i]>otherBuf[i])
     return NSOrderedDescending;

   if(range.length==otherLength)
    return NSOrderedSame;

   return (i<otherLength)?NSOrderedAscending:NSOrderedDescending;
}

-(NSComparisonResult)compare:(NSString *)other options:(unsigned)options range:(NSRange)range locale:(NSLocale *)locale {
   NSUnimplementedMethod();
   return 0;
}

-(NSComparisonResult)compare:(NSString *)other options:(unsigned)options range:(NSRange)range {
   return compareWithOptions(self,other,options,range);
}

// but improve the case conversion
-(NSComparisonResult)compare:(NSString *)other options:(unsigned)options {
   return compareWithOptions(self,other,options,NSMakeRange(0,[self length]));
}

-(NSComparisonResult)compare:(NSString *)other {
   return compareWithOptions(self,other,0,NSMakeRange(0,[self length]));
}

-(NSComparisonResult)caseInsensitiveCompare:(NSString *)other {
   return compareWithOptions(self,other,NSCaseInsensitiveSearch,NSMakeRange(0,[self length]));
}

-(NSComparisonResult)localizedCompare:(NSString *)other {
   NSUnimplementedMethod();
   return 0;
}
-(NSComparisonResult)localizedCaseInsensitiveCompare:(NSString *)other {
   NSUnimplementedMethod();
   return 0;
}

-(unsigned)hash {
   NSRange  range={0,[self length]};
   unichar  unicode[NSHashStringLength];

   if(range.length>NSHashStringLength)
    range.length=NSHashStringLength;

   [self getCharacters:unicode range:range];

   return NSStringHashUnicode(unicode,range.length);
}

static inline BOOL isEqualString(NSString *str1,NSString *str2){
   if(str2==nil)
    return NO;
   if(str1==str2)
    return YES;
   else {
    unsigned length1=[str1 length],length2=[str2 length];

    if(length1!=length2)
     return NO;
    if(length1==0)
     return YES;
    else {
     unichar  buffer1[length1],buffer2[length2];
     int      i;

     [str1 getCharacters:buffer1];
     [str2 getCharacters:buffer2];

     for(i=0;i<length1;i++)
      if(buffer1[i]!=buffer2[i])
       return NO;

     return YES;
    }
   }
}


-(BOOL)isEqual:other {
   if(self==other)
    return YES;

   if(other==nil)
    return NO;

   if(!NSObjectIsKindOfClass(other,objc_lookUpClass("NSString")))
    return NO;

   return isEqualString(self,other);
}


-(BOOL)isEqualToString:(NSString *)other {
   return isEqualString(self,other);
}

-(BOOL)hasPrefix:(NSString *)prefix {
   unsigned i,selfLength=[self length], prefixLength=[prefix length];
   unichar  selfBuf[selfLength],prefixBuf[prefixLength];

   if(prefixLength>selfLength)
    return NO;

   [self getCharacters:selfBuf];
   [prefix getCharacters:prefixBuf];

   for(i=0;i<prefixLength;i++)
    if(selfBuf[i]!=prefixBuf[i])
     return NO;

   return YES;
}


-(BOOL)hasSuffix:(NSString *)suffix {
   unsigned i,selfLength=[self length],suffixLength=[suffix length];
   unsigned offset=selfLength-suffixLength;
   unichar  selfBuf[selfLength],suffixBuf[suffixLength];

   [self getCharacters:selfBuf];
   [suffix getCharacters:suffixBuf];

   if(suffixLength>selfLength)
    return NO;

   for(i=0;i<suffixLength;i++)
    if(selfBuf[offset+i]!=suffixBuf[i])
     return NO;

   return YES;
}

// Knuth-Morris-Pratt string search

static inline void computeNext(int next[],unichar patbuffer[],int patlength){
   int pos=0,i=-1;

   next[0]=-1;
   while(pos<patlength-1){
    while(i>-1 && patbuffer[pos]!=patbuffer[i])
     i=next[i];
    pos++;
    i++;
    if(patbuffer[pos]==patbuffer [i])
     next[pos]=next[i];
    else
     next[pos]=i;
   }
}

static inline NSRange rangeOfPatternNext(unichar *buffer,unichar *patbuffer,int *next,unsigned patlength,NSRange range){
   int i,pos=0,searchLength=range.location+range.length;
   int start=0;

   for(i=range.location;i<searchLength && pos<patlength;i++,pos++){
    while(pos>-1 && (patbuffer[pos]!=buffer[i]))
     pos=next[pos];

    if(pos<=0)
     start=i;
   }

   if(pos==patlength)
    return NSMakeRange(start,patlength);
   else
    return NSMakeRange(NSNotFound,0);
}

static inline void reverseString(unichar *buf, unsigned len) {
    unsigned i;
    unsigned half = len / 2;
    for (i = 0; i < half; i++) {
        unichar t = buf[len-1-i];
        buf[len-1-i] = buf[i];
        buf[i] = t;
    }
}

-(NSRange)rangeOfString:(NSString *)string options:(unsigned)options range:(NSRange)range locale:(NSLocale *)locale {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSRange)rangeOfString:(NSString *)pattern options:(unsigned)options range:(NSRange)range {
   unsigned length=[self length];
   unichar  buffer[length];
   unsigned patlength=[pattern length];
   unichar  patbuffer[patlength+1];
   int      next[patlength+1];

   if([pattern length]==0)
    return NSMakeRange(NSNotFound,0);

   if(range.location+range.length>[self length])
    [NSException raise:NSRangeException format:@"-[%@ %s] range %d,%d beyond length %d",isa,sel_getName(_cmd),range.location,range.length,[self length]];

   [self getCharacters:buffer];
   [pattern getCharacters:patbuffer];

    // it seems that this search is always literal anyway, so the NSLiteralSearch option can be ignored...?
    options &= ~((unsigned)NSLiteralSearch);

   if(options & NSCaseInsensitiveSearch) {
    NSUnicodeToUppercase(buffer,length);
    NSUnicodeToUppercase(patbuffer,patlength);
   }
   
   if(options & NSBackwardsSearch) {
    reverseString(buffer, length);
    reverseString(patbuffer, patlength);
    range.location = length - (range.location + range.length);
   }

   if(options & NSAnchoredSearch) {
    NSUnimplementedMethod();
   }

   computeNext(next,patbuffer,patlength);
   
   NSRange foundRange = rangeOfPatternNext(buffer,patbuffer,next,patlength,range);
   
   if((options & NSBackwardsSearch) && foundRange.location != NSNotFound) {
    foundRange.location = length - foundRange.location - foundRange.length;
   }
   return foundRange;
}

-(NSRange)rangeOfString:(NSString *)string options:(unsigned)options {
   NSRange range=NSMakeRange(0,[self length]);

   return [self rangeOfString:string options:options range:range];
}

-(NSRange)rangeOfString:(NSString *)string {
   return [self rangeOfString:string options:0];
}

-(NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)set
   options:(unsigned)options range:(NSRange)range {
   NSRange  result=NSMakeRange(NSNotFound,0);
   
   if (range.length < 1)
       return result;
      
   unichar  buffer[range.length];
   unsigned i;

    const BOOL isLiteral = (options & NSLiteralSearch) ? YES : NO;
    const BOOL isBackwards = (options & NSBackwardsSearch) ? YES : NO;
    options &= ~((unsigned)NSLiteralSearch);
    options &= ~((unsigned)NSBackwardsSearch);
 
    if(options != 0)
        NSUnimplementedMethod();

    [self getCharacters:buffer range:range];
    
    // Cocoa documentation suggests that the returned range's length is always expected to be 1?
    // The backwards search uses this assumption.

    if (isBackwards) {
        for(i = range.length; i > 0; i--) {
            if([set characterIsMember:buffer[i-1]]) {
                return NSMakeRange(range.location + (i-1), 1);
            }
        }
    }
    else {
       for(i=0;i<range.length;i++){
        if([set characterIsMember:buffer[i]]){
         result.location=i;

         for(;i<range.length;i++)
          if(![set characterIsMember:buffer[i]])
           break;

         result.length=i-result.location;
         result.location+=range.location;
         return result;
        }
       }
    }

   return NSMakeRange(NSNotFound,0);
}

// FIX
-(NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)set
   options:(unsigned)options {
   return [self rangeOfCharacterFromSet:set options:options range:NSMakeRange(0,[self length])];
}

-(NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)set {
   return [self rangeOfCharacterFromSet:set options:0];
}

-(void)getLineStart:(unsigned *)startp end:(unsigned *)endp contentsEnd:(unsigned *)contentsEndp forRange:(NSRange)range {
   unsigned start=range.location;
   unsigned end=NSMaxRange(range);
   unsigned contentsEnd=end;
   unsigned length=[self length];
   unichar  buffer[length];
   enum {
    scanning,gotR,done
   } state=scanning;

   [self getCharacters:buffer];

/*
U+000D (\r or CR), U+2028 (Unicode line separator), U+000A (\n or LF) 
U+2029 (Unicode paragraph separator), \r\n, in that order (also known as CRLF)
 */

   for(;start!=0;start--) {
    unichar check=buffer[start-1];

    if(check==0x2028 || check==0x000A || check==0x2029)
     break;

    if(check==0x000D && buffer[start]!=0x000A)
      break;
   }

   for(;end<length && state!=done;end++){
    unichar check=buffer[end];

    if(state==scanning){
     if(check==0x000D){
      contentsEnd=end;
      state=gotR;
     }
     else if(check==0x2028 || check==0x000A || check==0x2029){
      contentsEnd=end;
      state=done;
     }
    }
    else if(state==gotR){
     if(check!=0x000A){
      end--;
     }
     state=done;
    }
   }

        if((end >= length) && (state!=done)) 
                { 
                contentsEnd = end;       
                } 

   if(startp!=NULL)
    *startp=start;
   if(endp!=NULL)
    *endp=end;
   if(contentsEndp!=NULL)
    *contentsEndp=contentsEnd;
}


-(NSRange)lineRangeForRange:(NSRange)range {
   NSRange  result;
   unsigned start,end;

   [self getLineStart:&start end:&end contentsEnd:NULL forRange:range];
   result.location=start;
   result.length=end-start;

   return result;
}

-(void)getParagraphStart:(NSUInteger *)startp end:(NSUInteger *)endp contentsEnd:(NSUInteger *)contentsEndp forRange:(NSRange)range {
   NSUnimplementedMethod();
}
-(NSRange)paragraphRangeForRange:(NSRange)range {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSString *)substringWithRange:(NSRange)range {
   unichar *unicode;

   if(NSMaxRange(range)>[self length])
    [NSException raise:NSRangeException format:@"-[%@ %s] range %d,%d beyond length %d",isa,sel_getName(_cmd),range.location,range.length,[self length]];

   if(range.length==0)
    return @"";
    
   unicode=__builtin_alloca(sizeof(unichar)*range.length);

   [self getCharacters:unicode range:range];

   return [NSString stringWithCharacters:unicode length:range.length];
}

-(NSString *)substringFromIndex:(unsigned)location {
   NSRange range={location,[self length]-location};

   if(location>[self length])
    [NSException raise:NSRangeException format:@"-[%@ %s] index %d beyond length %d",isa,sel_getName(_cmd),location,[self length]];

   return [self substringWithRange:range];
}

-(NSString *)substringToIndex:(unsigned)location {
   NSRange range={0,location};
   return [self substringWithRange:range];
}

-(BOOL)boolValue {
   NSUnimplementedMethod();
   return 0;
}

-(int)intValue {
   unsigned pos,length=[self length];
   unichar  unicode[length];
   int      sign=1,value=0;

   [self getCharacters:unicode];

   for(pos=0;pos<length;pos++)
    if(unicode[pos]>' ')
     break;

   if(length==0)
    return 0;

   if(unicode[0]=='-'){
    sign=-1;
    pos++;
   }
   else if(unicode[0]=='+'){
    sign=1;
    pos++;
   }

   for(;pos<length;pos++){
    if(unicode[pos]<'0' || unicode[pos]>'9')
     break;

    value*=10;
    value+=unicode[pos]-'0';
   }

   return sign*value;
}

-(NSInteger)integerValue {
   NSUnimplementedMethod();
   return 0;
}
-(long long)longLongValue {
   NSUnimplementedMethod();
   return 0;
}

-(float)floatValue {
   return [self doubleValue];
}

-(double)doubleValue {
   unsigned pos,length=[self length];
   unichar  unicode[length];
   double   sign=1,value=0;

   [self getCharacters:unicode];

   for(pos=0;pos<length;pos++)
    if(unicode[pos]>' ')
     break;

   if(length==0)
    return 0.0;

   if(unicode[0]=='-'){
    sign=-1;
    pos++;
   }
   else if(unicode[0]=='+'){
    sign=1;
    pos++;
   }

   for(;pos<length;pos++){
    if(unicode[pos]<'0' || unicode[pos]>'9')
     break;

    value*=10;
    value+=unicode[pos]-'0';
   }

   if(pos<length && unicode[pos]=='.'){
    double multiplier=1;

    pos++;
    for(;pos<length;pos++){
     if(unicode[pos]<'0' || unicode[pos]>'9')
      break;

     multiplier/=10.0;
     value+=(unicode[pos]-'0')*multiplier;
    }
   }

   return sign*value;
}

-(NSString *)lowercaseString {
   unsigned length=[self length];
   unichar  unicode[length];

   [self getCharacters:unicode];

   NSUnicodeToLowercase(unicode,length);

   return [NSString stringWithCharacters:unicode length:length];
}

-(NSString *)uppercaseString {
   unsigned length=[self length];
   unichar  unicode[length];

   [self getCharacters:unicode];

   NSUnicodeToUppercase(unicode,length);

   return [NSString stringWithCharacters:unicode length:length];
}

-(NSString *)capitalizedString {
   unsigned length=[self length];
   unichar  unicode[length];

   [self getCharacters:unicode];

   NSUnicodeToCapitalized(unicode,length);

   return [NSString stringWithCharacters:unicode length:length];
}

-(NSString *)stringByAppendingFormat:(NSString *)format,... {
   NSString *append,*result;
   va_list   list;

   va_start(list,format);

   append=[[NSString allocWithZone:NULL] initWithFormat:format arguments:list];
   result=[self stringByAppendingString:append];
   [append release];

   return result;
}


-(NSString *)stringByAppendingString:(NSString *)other {
   unsigned selfLength=[self length];
   unsigned otherLength=[other length];
   unsigned totalLength=selfLength+otherLength;
   unichar  unicode[totalLength];

   [self getCharacters:unicode];
   [other getCharacters:unicode+selfLength];

   return [NSString stringWithCharacters:unicode length:totalLength];
}

-(NSArray *)componentsSeparatedByString:(NSString *)pattern {
   NSMutableArray *result=[NSMutableArray array];
   unsigned        length=[self length];
   unichar        *buffer;
   unsigned        patlength=[pattern length];
   unichar         patbuffer[patlength+1];
   int             next[patlength+1];
   NSRange         search=NSMakeRange(0,length),where;

   buffer=NSZoneMalloc(NULL,sizeof(unichar)*length);
   [self getCharacters:buffer];
   [pattern getCharacters:patbuffer];

   computeNext(next,patbuffer,patlength);

   do {
    where=rangeOfPatternNext(buffer,patbuffer,next,patlength,search);

    if(where.length>0){
     NSString *piece=[self substringWithRange:NSMakeRange(search.location,where.location-search.location)];

     [result addObject:piece];
     search.location=where.location+where.length;
     search.length=length-search.location;
    }
   }while(where.length>0);

   NSZoneFree(NULL,buffer);
   
   [result addObject:[self substringWithRange:search]];

   return result;
}

- (NSArray *) componentsSeparatedByCharactersInSet:(NSCharacterSet *)set
{
       NSAutoreleasePool * pool = [NSAutoreleasePool new];
       NSMutableArray * result = [NSMutableArray array];
       NSScanner * scanner = [NSScanner scannerWithString:self];
       NSString * chunk = nil;
       NSString * sepScan;
       BOOL found, sepFound;
       [scanner setCharactersToBeSkipped: nil];
       sepFound = [scanner scanCharactersFromSet: set intoString:&sepScan]; // skip any preceding separators
       if(sepFound)
               { // if initial separator(s), start with empty component(s)
               int sepCount = [sepScan length];
               while(sepCount--)
                       {
                       [result addObject:@""];
                       }
               }

       while((found = [scanner scanUpToCharactersFromSet: set intoString:&chunk]))
               {
               [result addObject:chunk];
               sepFound = [scanner scanCharactersFromSet: set intoString:&sepScan];
               if(sepFound)
                       {
                       int sepCount = [sepScan length]-1;
                       while(sepCount--)
                               {
                               [result addObject:@""];
                               }
                       }
               }
       if(sepFound)
               { // if final separator, end with empty component
               [result addObject: @""];
               }
       result = [result copy];
       [pool release];
       result = [result autorelease];
       return result;
}

-(NSString *)commonPrefixWithString:(NSString *)other options:(NSStringCompareOptions)options {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)stringByPaddingToLength:(NSUInteger)length withString:(NSString *)padding startingAtIndex:(NSUInteger)index {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)stringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)substitute {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)stringByReplacingOccurrencesOfString:(NSString *)original withString:(NSString *)substitute {
	NSMutableString* s=[self mutableCopy];
	[s replaceOccurrencesOfString:original withString:substitute options:0 range:NSMakeRange(0, [s length])];
   
   NSMutableString *ret=[[s copy] autorelease];
   [s release];
	return ret;
}
-(NSString *)stringByReplacingOccurrencesOfString:(NSString *)original withString:(NSString *)substitute options:(NSStringCompareOptions)options range:(NSRange)range {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)stringByFoldingWithOptions:(NSStringCompareOptions)options locale:(NSLocale *)locale {
   NSUnimplementedMethod();
   return 0;
}

-(NSRange)rangeOfComposedCharacterSequenceAtIndex:(NSUInteger)index {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}
-(NSRange)rangeOfComposedCharacterSequencesForRange:(NSRange)range {
   NSUnimplementedMethod();
   return NSMakeRange(0,0);
}

-(NSString *)precomposedStringWithCanonicalMapping {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)decomposedStringWithCanonicalMapping {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)precomposedStringWithCompatibilityMapping {
   NSUnimplementedMethod();
   return 0;
}
-(NSString *)decomposedStringWithCompatibilityMapping {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)description {
   return self;
}

-propertyList {
   return [NSPropertyListReader propertyListFromString:self];
}


-(NSDictionary *)propertyListFromStringsFileFormat {
   return NSDictionaryFromStringsFormatString(self);
}

-(BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically {
   NSData *data=[self dataUsingEncoding:[NSString defaultCStringEncoding]];
   return [data writeToFile:path atomically:atomically];
}

-(BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically encoding:(NSStringEncoding)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}
-(BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically encoding:(NSStringEncoding)encoding error:(NSError **)error {
   NSUnimplementedMethod();
   return 0;
}

-(NSStringEncoding)fastestEncoding {
   NSUnimplementedMethod();
   return 0;
}

-(NSStringEncoding)smallestEncoding {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)canBeConvertedToEncoding:(NSStringEncoding)encoding {
   return ([self dataUsingEncoding:encoding]!=nil)?YES:NO;
}

-(NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)encoding {
   NSUnimplementedMethod();
   return 0;
}

-(NSUInteger)maximumLengthOfBytesUsingEncoding:(NSStringEncoding)encoding {
   NSUnimplementedMethod();
   return 0;
}

// FIX, not complete
-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding
        allowLossyConversion:(BOOL)lossy {
   NSZone  *zone=[self zone];
   unsigned length=[self length];
   unichar  buffer[1+length],*unicode=buffer+1;
   unsigned byteLength=0;
   char    *bytes=NULL;

   [self getCharacters:unicode];
 
   if(encoding==NSNEXTSTEPStringEncoding)
    bytes=NSUnicodeToNEXTSTEP(unicode,length,lossy,&byteLength,zone);
   else if(encoding==NSISOLatin1StringEncoding || encoding==NSASCIIStringEncoding) // NSASCII not correct
    bytes=NSUnicodeToISOLatin1(unicode,length,lossy,&byteLength,zone);
   else if(encoding==NSSymbolStringEncoding)
    bytes=NSUnicodeToSymbol(unicode,length,lossy,&byteLength,zone);
   else if(encoding==NSUTF8StringEncoding)
    bytes=NSUnicodeToUTF8(unicode,length,lossy,&byteLength,zone,NO);
   else if(encoding==NSUnicodeStringEncoding){
    buffer[0]=0xFFFE;
    return [NSData dataWithBytes:buffer length:(1+length)*sizeof(unichar)];
   }
   else {
    NSRaiseException(NSInvalidArgumentException, self, 
                     @selector(dataUsingEncoding:allowLossyConversion:),
                     @"dataUsingEncoding: unsupported encoding %d", encoding);
    return nil;
   }

   if(bytes==NULL)
    return nil;

   return [NSData dataWithBytesNoCopy:bytes length:byteLength];
}

-(NSData *)dataUsingEncoding:(NSStringEncoding)encoding {
   return [self dataUsingEncoding:encoding allowLossyConversion:NO];
}

-(BOOL)getBytes:(void *)bytes maxLength:(NSUInteger)maxLength usedLength:(NSUInteger *)usedLength encoding:(NSStringEncoding)encoding options:(NSStringEncodingConversionOptions)options range:(NSRange)range remainingRange:(NSRange *)remainingRange {
   NSUnimplementedMethod();
   return 0;
}

-(const char *)UTF8String {
   unsigned length=[self length],byteLength;
   unichar  unicode[length];
   char    *bytes;
   
   [self getCharacters:unicode];
   
   if((bytes=NSUnicodeToUTF8(unicode,length,NO,&byteLength,NULL,YES))==NULL)
    return NULL;

   return [[NSData dataWithBytesNoCopy:bytes length:byteLength] bytes];
}

-(NSString *)stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)encoding {
 //  NSUnimplementedMethod();
   return self;
}

-(NSString *)stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)encoding {
  // NSUnimplementedMethod();
   return self;
}

-(NSString *)stringByTrimmingCharactersInSet:(NSCharacterSet *)set {
   unsigned length=[self length];
   unsigned location=0;
   unichar  buffer[length];
   
   [self getCharacters:buffer];
   for(;location<length;location++)
    if(![set characterIsMember:buffer[location]])
     break;
   
   while(length>location) {
    if(![set characterIsMember:buffer[length-1]])
     break;
     
    length--;
   }
   
   return [self substringWithRange:NSMakeRange(location,length-location)];
}

-(const char *)cStringUsingEncoding:(NSStringEncoding)encoding {
   NSUnimplementedMethod();
   return [self cString];
}

-(BOOL)getCString:(char *)cString maxLength:(NSUInteger)maxLength encoding:(NSStringEncoding)encoding {
    NSRange range={0,[self length]};
    
    if (range.length > maxLength-1)
        return NO;

    BOOL result = YES;    
    NSUInteger i;
    unichar  unicode[range.length];
    unsigned location;
    [self getCharacters:unicode range:range];
    
    // this implementation is very basic, doesn't support most encodings
    
    switch (encoding) {
        case NSASCIIStringEncoding: {
            NSGetCStringWithMaxLength(unicode,range.length,&range.location,cString,maxLength-1,NO);
            for (i = 0; i < maxLength-1; i++) {
                if ((unsigned char)cString[i] > 127) {  // invalid character for ASCII encoding
                    cString[i] = 0;
                    result = NO;
                    break;
                }
            }
            break;
        }
        case NSUnicodeStringEncoding: {
            NSUInteger ucByteLen = (range.length+1)*sizeof(unichar);
            result = (ucByteLen <= maxLength);
            if (result) {
                memcpy(cString, unicode, ucByteLen);
                *((unichar *)(cString + ucByteLen)) = 0;
            }
            break;
        }
        case NSNEXTSTEPStringEncoding:
            NSGetNEXTSTEPStringWithMaxLength(unicode,range.length,&range.location,cString,maxLength-1,NO);
            break;
        
        default:
            result = NO;
            NSUnimplementedMethod();
   }
   
    return result;
}

+(NSStringEncoding)defaultCStringEncoding {
   return NSString_cStringEncoding;
}

-(void)getCString:(char *)cString maxLength:(unsigned)maxLength
            range:(NSRange)range remainingRange:(NSRange *)leftoverRange {
   unichar  unicode[range.length];
   unsigned location;

   [self getCharacters:unicode range:range];

   NSGetCStringWithMaxLength(unicode,range.length,&location,cString,maxLength,YES);

   if(leftoverRange!=NULL){
    leftoverRange->location=range.location+location;
    leftoverRange->length=range.length-location;
   }
}

-(void)getCString:(char *)cString maxLength:(unsigned)maxLength {
   NSRange range={0,[self length]};
   [self getCString:cString maxLength:maxLength range:range remainingRange:NULL];
}

-(void)getCString:(char *)cString {
   NSRange range={0,[self length]};
   [self getCString:cString maxLength:NSMaximumStringLength range:range remainingRange:NULL];
}

-(unsigned)cStringLength {
   unsigned length=[self length];
   unichar  unicode[length];

   unsigned cStringLength;
   char    *cString;

   [self getCharacters:unicode];

   cString=NSString_cStringFromCharacters(unicode,length,YES,
                           &cStringLength,NULL);

   NSZoneFree(NULL,cString);

   return cStringLength;
}

-(const char *)cString {
   unsigned  length=[self length];
   unichar   unicode[length];
   NSString *string;

   [self getCharacters:unicode];

   if((string=[NSString_cStringNewWithCharacters(NULL,unicode,length,NO) autorelease])==nil){
    // FIX raise exception
   }

   return [string cString];
}


-(const char *)lossyCString {
   unsigned  length=[self length];
   unichar   unicode[length];
   NSString *string;

   [self getCharacters:unicode];

   string=[NSString_cStringNewWithCharacters(NULL,unicode,length,YES) autorelease];

   return [string cString];
}

@end
