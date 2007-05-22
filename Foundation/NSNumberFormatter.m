/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNumberFormatter.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCharacterSet.h>

/*
comparison of our output:
Aug 10 14:40:19 formatters[12633] nil object: *nil*
Aug 10 14:40:19 formatters[12633] 365.25: $365
Aug 10 14:40:19 formatters[12633] 0: 0.000
Aug 10 14:40:19 formatters[12633] -38128.7575: ($38128)
Aug 10 14:40:19 formatters[12633] 1.0: $1
Aug 10 14:40:19 formatters[12633] 0.11111: $0

..with apple's

Aug 10 14:40:35 formatters[12645] nil object: (null)
Aug 10 14:40:35 formatters[12645] 365.25: $365
Aug 10 14:40:35 formatters[12645] 0: 0.000
Aug 10 14:40:35 formatters[12645] -38128.7575: ($38129)
Aug 10 14:40:35 formatters[12645] 1.0: $1
Aug 10 14:40:35 formatters[12645] 0.11111: $

.. the notable differences are rounding and the last line,
 where 0.11111 becomes an empty string
 (that doesn't seem right to me)...

 */

#define NSNumberFormatterThousandSeparator 	','
#define NSNumberFormatterDecimalSeparator 	'.'
#define NSNumberFormatterPlaceholder		'#'
#define NSNumberFormatterSpace			'_'
#define NSNumberFormatterCurrency		'$'

@implementation NSNumberFormatter

-(id)init {
   [super init];
   _thousandSeparator = @",";
   _decimalSeparator = @".";
   _attributedStringForNil=[[NSAttributedString allocWithZone:NULL] initWithString:@"(null)"];
   _attributedStringForNotANumber=[[NSAttributedString allocWithZone:NULL] initWithString:@"NaN"];
   _attributedStringForZero=[[NSAttributedString allocWithZone:NULL] initWithString:@"0.0"];
   _allowsFloats = YES;

   return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
	if(self=[super initWithCoder:coder])
	{
		// FIX: decode & set other values
		/*NS.allowsfloats = 1;
		NS.attributes = {
			CF$UID = 196;
		};
		NS.decimal = {
			CF$UID = 70;
		};
		NS.hasthousands = 1;
		NS.localized = 0;
		NS.max = {
			CF$UID = 68;
		};
		NS.min = {
			CF$UID = 68;
		};
		NS.nan = {
			CF$UID = 200;
		};
		NS.negativeattrs = {
			CF$UID = 0;
		};
		NS.negativeformat = {
			CF$UID = 58;
		};
		NS.nil = {
			CF$UID = 199;
		};
		NS.positiveattrs = {
			CF$UID = 0;
		};
		NS.positiveformat = {
			CF$UID = 57;
		};
		NS.rounding = {
			CF$UID = 0;
		};
		NS.thousand = {
			CF$UID = 71;
		};
		NS.zero = {
			CF$UID = 198;
		};		 
		 */
		[self setPositiveFormat:[coder decodeObjectForKey:@"NS.positiveformat"]];
		[self setNegativeFormat:[coder decodeObjectForKey:@"NS.negativeformat"]];
	}
	return self;
}

-(void)dealloc {
   [_negativeFormat release];
   [_positiveFormat release];
   [_negativeAttributes release];
   [_positiveAttributes release];
   [super dealloc];
}

-(NSString *)format {
   return [NSString stringWithFormat:@"%@;%@;%@", _positiveFormat, _attributedStringForZero, _negativeFormat];
}

-(BOOL)allowsFloats {
   return _allowsFloats;
}

-(BOOL)localizesFormat {
   return _localizesFormat;
}


-(BOOL)hasThousandSeparators {
   return _hasThousandSeparators;
}

-(NSString *)thousandSeparator {
   return _thousandSeparator;
}

-(NSString *)decimalSeparator {
   return _decimalSeparator;
}


-(NSString *)positiveFormat {
   return _positiveFormat;
}

-(NSString *)negativeFormat {
   return _negativeFormat;
}

-(NSDictionary *)textAttributesForPositiveValues {
   return _positiveAttributes;
}

-(NSDictionary *)textAttributesForNegativeValues {
   return _negativeAttributes;
}

-(NSAttributedString *)attributedStringForNil {
   return _attributedStringForNil;
}

-(NSAttributedString *)attributedStringForNotANumber {
   return _attributedStringForNotANumber;
}

-(NSAttributedString *)attributedStringForZero {
   return _attributedStringForZero;
}

-(void)setFormat:(NSString *)format {
   NSArray *formatStrings = [format componentsSeparatedByString:@";"];

   _positiveFormat = [[formatStrings objectAtIndex:0] retain];

   if ([formatStrings count] == 3) {
      _negativeFormat = [[formatStrings objectAtIndex:2] retain];
      _attributedStringForZero = [[NSAttributedString allocWithZone:NULL] initWithString:[formatStrings objectAtIndex:1]
         attributes:[NSDictionary dictionary]];
   }
   else if ([formatStrings count] == 2)
      _negativeFormat = [[formatStrings objectAtIndex:1] retain];
   else
      _negativeFormat = [NSString stringWithFormat:@"-%@", _positiveFormat];

   if ([format rangeOfString:@","].location != NSNotFound || 
      [format rangeOfString:_thousandSeparator].location != NSNotFound)
      [self setHasThousandSeparators:YES];
}

-(void)setAllowsFloats:(BOOL)flag {
   _allowsFloats = flag;
}

-(void)setLocalizesFormat:(BOOL)flag {
   _localizesFormat = flag;
}

-(void)setHasThousandSeparators:(BOOL)flag {
   _hasThousandSeparators = flag;
}

-(void)setThousandSeparator:(NSString *)separator {
   [_thousandSeparator release];
   _thousandSeparator = [separator retain];
   [self setHasThousandSeparators:YES];
}

-(void)setDecimalSeparator:(NSString *)separator {
   [_decimalSeparator release];
   _decimalSeparator = [separator retain];
}

-(void)setPositiveFormat:(NSString *)format {
   [_positiveFormat release];
   _positiveFormat = [format retain];
}

-(void)setNegativeFormat:(NSString *)format {
   [_negativeFormat release];
   _negativeFormat = [format retain];
}

-(void)setTextAttributesForNegativeValues:(NSDictionary *)attributes {
   [_negativeAttributes release];
   _negativeAttributes = [attributes retain];
}

-(void)setTextAttributesForPositiveValues:(NSDictionary *)attributes {
   [_positiveAttributes release];
   _positiveAttributes = [attributes retain];
}

-(void)setAttributedStringForZero:(NSAttributedString *)attributedString {
   [_attributedStringForZero release];
   _attributedStringForZero = [attributedString retain];
}

-(void)setAttributedStringForNil:(NSAttributedString *)attributedString {
   [_attributedStringForNil release];
   _attributedStringForNil = [attributedString retain];
}

-(void)setAttributedStringForNotANumber:(NSAttributedString *)attributedString {
   [_attributedStringForNotANumber release];
   _attributedStringForNotANumber = [attributedString retain];
}

// BROKEN
#if 0  
-(NSString *)_objectValue:(id)object withNumberFormat:(NSString *)format {
   NSString *stringValue = [[NSNumber numberWithDouble:[object doubleValue]] stringValue];
   unichar *valueBuffer = NSAllocateMemoryPages([stringValue length]+1);
   unichar *formatBuffer = NSAllocateMemoryPages([format length]+1);
   unichar *outputBuffer = NSAllocateMemoryPages([format length]+64);
   BOOL isNegative = [stringValue hasPrefix:@"-"];
   BOOL done = NO;
   unsigned formatIndex, valueIndex = 0, outputIndex = 0;
   unsigned prePoint, postPoint;
   int thousandSepCounter;

   // remove -
   if (isNegative)
      stringValue = [stringValue substringWithRange:NSMakeRange(1, [stringValue length]-1)];

   prePoint = [stringValue rangeOfString:@"."].location;
   postPoint = [stringValue length] - prePoint - 1;

   // decremented in main loop, when zero, time for a separator
   if (_hasThousandSeparators)
      thousandSepCounter = (prePoint % 3) ? (prePoint % 3) : 3;  
   else
      thousandSepCounter = -1;		   // never

   NSLog(@"%@: pre %d post %d sep %d", stringValue, prePoint, postPoint, thousandSepCounter);

   [format getCharacters:formatBuffer];
   [stringValue getCharacters:valueBuffer];

   while (!done) {
      switch(formatBuffer[formatIndex]) {
         case NSNumberFormatterThousandSeparator:
            [self setHasThousandSeparators:YES];
            [self setThousandSeparator:[NSString stringWithCharacters:formatBuffer+formatIndex length:1]];
            break;

         case NSNumberFormatterDecimalSeparator:
            [self setDecimalSeparator:[NSString stringWithCharacters:formatBuffer+formatIndex length:1]];
            break;

         case NSNumberFormatterPlaceholder:
         case NSNumberFormatterSpace:
            outputBuffer[outputIndex++] = valueBuffer[valueIndex++];

            if (valueIndex < prePoint) {
               thousandSepCounter--;
               if (thousandSepCounter == 0) {
                  outputBuffer[outputIndex++] = [_thousandSeparator characterAtIndex:0];
                  thousandSepCounter = 3;
               }
            }
            else if (valueIndex == prePoint)
               outputBuffer[outputIndex++] = [_decimalSeparator characterAtIndex:0];
            else {
               postPoint--;
               if (postPoint == 0)
                  done = YES;
            }

            break;

         case NSNumberFormatterCurrency:
            // localize

         default:
            outputBuffer[outputIndex++] = formatBuffer[formatIndex];
            break;
      }

      formatIndex++;
   }

   NSLog(@"stringValue %@ format %@", stringValue, format);
   return [NSString stringWithCharacters:outputBuffer length:outputIndex];
}
#endif

// this section works, but it's pretty lame...
// it doesn't round, it truncates; integers in the format specifier are ignored... 
-(NSString *)_separatedStringIfNeededWithString:(NSString *)string {
   unsigned thousandSepCounter, i, j = 0;
   unichar buffer[256];

   if (!_hasThousandSeparators)
      return string;

   if ([string length] < 4)
      return string;

   thousandSepCounter = ([string length] % 3) ? ([string length] % 3) : 3;  
   for (i = 0; i < [string length]; ++i) {
      buffer[j++] = [string characterAtIndex:i];
      thousandSepCounter--;
      if (thousandSepCounter == 0) {
         buffer[j++] = [_thousandSeparator characterAtIndex:0];
         thousandSepCounter = 3;
      }
   }
   buffer[--j] = (unichar)0;

   return [NSString stringWithCharacters:buffer length:j];
}

-(NSString *)_stringValue:(NSString *)stringValue withNumberFormat:(NSString *)format {
   NSString *rightSide = nil, *leftSide = nil;
   NSMutableString *result = [NSMutableString string];
   NSRange r;
   unsigned i, indexRight = 0;
   BOOL formatNoDecPoint = ([format rangeOfString:@"."].location == NSNotFound);
   BOOL havePassedDecPoint = NO;
   int lastPlaceholder = 0;

   // remove negative sign if present
   if ([stringValue hasPrefix:@"-"])
      stringValue = [stringValue substringWithRange:NSMakeRange(1, [stringValue length]-1)];

   // since we key from the decimal point... if there isn't one in the format spec
   // we have to go on the "last placeholder"; if we have neither decimal NOR
   // placeholders, well, we can't really format the number can we
   if (formatNoDecPoint) {
      lastPlaceholder = [format rangeOfString:@"#" options:NSBackwardsSearch].location;
      if (lastPlaceholder == NSNotFound)
          [NSException raise:NSInvalidArgumentException format:@"NSNumberFormatter: Invalid format string"];
   }

   // split this into left/right strings
   r = [stringValue rangeOfString:@"."];
   if (r.location != NSNotFound) {
      leftSide = [stringValue substringWithRange:NSMakeRange(0, r.location)];
      rightSide = [stringValue substringWithRange:NSMakeRange(r.location+1, [stringValue length]-r.location-1)];
   }
   else
      leftSide = stringValue;

   // do commas
   leftSide = [self _separatedStringIfNeededWithString:leftSide];

   // ugh. loop through the format string, looking for the decimal point
   // or the last placeholder. characters other than special are passed through
   for (i = 0; i < [format length]; ++i) {
      unichar ch = [format characterAtIndex:i];

      switch(ch) {
         case NSNumberFormatterPlaceholder:
            if (formatNoDecPoint && i == lastPlaceholder)
               [result appendString:leftSide];
            break;

         // ignore?
         case NSNumberFormatterSpace:
         // ignore; already handled
         case NSNumberFormatterThousandSeparator:   
            break;

         case NSNumberFormatterDecimalSeparator:
            [result appendString:leftSide];
            [result appendString:_decimalSeparator];
            havePassedDecPoint = YES;
            break;

         case NSNumberFormatterCurrency:
// FIX, add localization

         default:
            if (ch >= (unichar)'0' && ch <= (unichar)'9') {
               if (havePassedDecPoint == YES) {
                  ch = [rightSide characterAtIndex:indexRight++];
                  if (ch == (unichar)0)
                     ch = (unichar)'0';
               }
               else
                  break;
            }

            [result appendString:[NSString stringWithCharacters:&ch length:1]];
            break;
      }
   }

   return result;
}

-(NSString *)_objectValue:(id)object withNumberFormat:(NSString *)format {
   return [self _stringValue:[[NSNumber numberWithDouble:[object doubleValue]] stringValue]
      withNumberFormat:format];
}

-(NSString *)stringForObjectValue:(id)object {
   return [[self attributedStringForObjectValue:object 
      withDefaultAttributes:[NSDictionary dictionary]] string];
}

-(NSAttributedString *)attributedStringForObjectValue:(id)object 
   withDefaultAttributes:(NSDictionary *)attributes {
   if (object == nil)
      return _attributedStringForNil;

   if ([object doubleValue] > 0.0) {
      return [[[NSAttributedString allocWithZone:NULL] initWithString:[self _objectValue:object withNumberFormat:_positiveFormat] 
         attributes:_positiveAttributes] autorelease];
   }
   else if ([object doubleValue] < 0.0) {
      return [[[NSAttributedString allocWithZone:NULL] initWithString: [self _objectValue:object withNumberFormat:_negativeFormat] 
         attributes:_negativeAttributes] autorelease];
   } 
   else
      return _attributedStringForZero;
}

-(NSString *)editingStringForObjectValue:(id)object {
   return [self stringForObjectValue:object];
}

// what's the story with this method? dox are pretty unclear
// tests with MacOS X 10.0.4:
// @"365.25" = NSDecimalNumber[0x65ad0] 365.25
// @"bork", @"j80.0", @" 80." = Invalid number
-(BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error {
   // simple test of characters...
   NSMutableCharacterSet *digitsAndSeparators = [[[NSCharacterSet decimalDigitCharacterSet] mutableCopy] autorelease];
   NSMutableString *mutableString = [[string mutableCopy] autorelease];
   unichar thousandSeparator = [_thousandSeparator characterAtIndex:0];
   unsigned i;

   [digitsAndSeparators addCharactersInString:_decimalSeparator];
   [digitsAndSeparators addCharactersInString:_thousandSeparator];

   for (i = 0; i < [mutableString length]; ++i) {
      if (![digitsAndSeparators characterIsMember:[mutableString characterAtIndex:i]]) {
         if (error != NULL)
            *error = @"Invalid number";
         return NO;
      }

      // take out commas
      if ([mutableString characterAtIndex:i] == thousandSeparator)
         [mutableString deleteCharactersInRange:NSMakeRange(i, 1)];
   }

   *object = [NSNumber numberWithFloat:[mutableString floatValue]];
   return YES;
}

-(BOOL)isPartialStringValid:(NSString *)partialString 
   newEditingString:(NSString **)newString 
   errorDescription:(NSString **)error {
   // 
   return YES;
}

@end
