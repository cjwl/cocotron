/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSMutableString_unicodePtr.h>
#import <Foundation/NSAutoreleasePool-private.h>
#import <Foundation/NSStringFormatter.h>
#import <Foundation/NSStringFileIO.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSArray.h>
#import <string.h>

@implementation NSMutableString : NSString

+allocWithZone:(NSZone *)zone {
   if(self==OBJCClassFromString("NSMutableString"))
    return NSAllocateObject(OBJCClassFromString("NSMutableString_unicodePtr"),0,zone);

   return NSAllocateObject(self,0,zone);
}

-initWithCapacity:(unsigned)capacity {
   NSInvalidAbstractInvocation();
   return nil;
}

-copy {
   return [[NSString allocWithZone:NULL] initWithString:self];
}

-copyWithZone:(NSZone *)zone {
   return [[NSString allocWithZone:zone] initWithString:self];
}

-(Class)classForCoder {
   return OBJCClassFromString("NSMutableString");
}

+string {
   return NSAutorelease(NSMutableString_unicodePtrNew(NULL,NULL,0));
}

+stringWithCharacters:(const unichar *)unicode length:(unsigned)length {
   return NSAutorelease(NSMutableString_unicodePtrNew(NULL,unicode,length));
}

+stringWithCString:(const char *)bytes length:(unsigned)length {
   return NSAutorelease(
     NSMutableString_unicodePtrNewWithCString(NULL,bytes,length));
}

+stringWithCString:(const char *)bytes {
   return NSAutorelease(
      NSMutableString_unicodePtrNewWithCString(NULL,bytes,strlen(bytes)));
}

+stringWithFormat:(NSString *)format,... {
   va_list   arguments;
   unsigned  length;
   unichar  *unicode;

   va_start(arguments,format);

   unicode=NSCharactersNewWithFormat(format,nil,arguments,&length,NULL);

   return NSAutorelease(
     NSMutableString_unicodePtrNewNoCopy(NULL,unicode,length));
}

+stringWithContentsOfFile:(NSString *)path {
   unsigned  length;
   unichar  *unicode;

   if((unicode=NSCharactersWithContentsOfFile(path,&length,NULL))==NULL)
    return nil;

   return NSAutorelease(
     NSMutableString_unicodePtrNewNoCopy(NULL,unicode,length));
}

+localizedStringWithFormat:(NSString *)format,... {
   va_list   arguments;
   unsigned  length;
   unichar  *unicode;

   va_start(arguments,format);

   unicode=NSCharactersNewWithFormat(format,nil,arguments,&length,NULL);

   return NSAutorelease(
     NSMutableString_unicodePtrNewNoCopy(NULL,unicode,length));
}

+stringWithCapacity:(unsigned)capacity {
   return NSAutorelease(
     NSMutableString_unicodePtrNewWithCapacity(NULL,capacity));
}

-(void)appendString:(NSString *)string {
   NSRange range={[self length],0};

   [self replaceCharactersInRange:range withString:string];
}

-(void)appendFormat:(NSString *)format,... {
   NSString *string;
   NSRange   range={[self length],0};
   va_list   arguments;

   va_start(arguments,format);

   string=NSAutorelease(NSStringNewWithFormat(format,nil,arguments,NULL));

   [self replaceCharactersInRange:range withString:string];
}

-(void)deleteCharactersInRange:(NSRange)range {
   if(NSMaxRange(range)>[self length]){
    NSRaiseException(NSRangeException,self,_cmd,@"range %@ beyond length %d",
     NSStringFromRange(range),[self length]);
   }
    
   [self replaceCharactersInRange:range withString:@""];
}

-(void)insertString:(NSString *)string atIndex:(unsigned)index {
   NSRange range={index,0};

   if(index>[self length]){
    NSRaiseException(NSRangeException,self,_cmd,@"index %d beyond length %d",
     index,[self length]);
   }

   [self replaceCharactersInRange:range withString:string];
}

-(void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
   NSInvalidAbstractInvocation();
}

-(void)setString:(NSString *)string {
   NSRange range={0,[self length]};

   [self replaceCharactersInRange:range withString:string];
}

- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement 
options:(NSStringCompareOptions)opts range:(NSRange)searchRange
{
	NSMutableArray* tokens = [NSMutableArray array];
	NSRange found;

	// Find all hits
	found = [self rangeOfString:target options:opts range:searchRange];		
	while (found.location != NSNotFound)
	{
		[tokens addObject:[NSNumber numberWithLong:found.location]];
		int oldLocation = searchRange.location;
		// Advance to after the hit
		searchRange.location = found.location+found.length;
		// Shorten the search range accordingly or bail if we're done
		if (searchRange.length < searchRange.location-oldLocation)
			break;
		else
			searchRange.length -= searchRange.location-oldLocation;
		found = [self rangeOfString:target options:opts range:searchRange];		
	} 

	// Make replacements in reverse order
	int x; for (x = [tokens count]-1; x >= 0; x--)
	{
		found.location = [[tokens objectAtIndex:x] longValue];
		found.length = [target length];
		[self replaceCharactersInRange:found withString:replacement];
	}
	
	return [tokens count];
}

@end
