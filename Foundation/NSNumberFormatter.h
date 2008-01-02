/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSFormatter.h>

@class NSDecimalNumberHandler;

typedef int NSNumberFormatterBehavior;
typedef int NSNumberFormatterStyle;
typedef int NSNumberFormatterPadPosition;
typedef int NSNumberFormatterRoundingMode;

@interface NSNumberFormatter : NSFormatter {
    NSString     *_positiveFormat;
    NSString     *_negativeFormat;
    NSDictionary *_positiveAttributes;
    NSDictionary *_negativeAttributes;
    NSString     *_thousandSeparator;
    NSString     *_decimalSeparator;

    NSAttributedString *_attributedStringForNil;
    NSAttributedString *_attributedStringForNotANumber; 
    NSAttributedString *_attributedStringForZero;

    BOOL _allowsFloats;
    BOOL _localizesFormat;
    BOOL _hasThousandSeparators;
}

+(NSNumberFormatterBehavior)defaultFormatterBehavior;
+(void)setDefaultFormatterBehavior:(NSNumberFormatterBehavior)value;

-(NSNumberFormatterBehavior)formatterBehavior;
-(NSNumberFormatterStyle)numberStyle;

-(NSString *)format;
-(NSUInteger)formatWidth;
-(NSLocale *)locale;
-(NSNumber *)multiplier;

-(BOOL)allowsFloats;
-(BOOL)localizesFormat;
-(BOOL)hasThousandSeparators;
-(BOOL)alwaysShowsDecimalSeparator;
-(BOOL)isLenient;
-(BOOL)isPartialStringValidationEnabled;
-(BOOL)generatesDecimalNumbers;
-(BOOL)usesGroupingSeparator;
-(BOOL)usesSignificantDigits;

-(NSNumber *)minimum;
-(NSUInteger)minimumIntegerDigits;
-(NSUInteger)minimumFractionDigits;
-(NSUInteger)minimumSignificantDigits;

-(NSNumber *)maximum;
-(NSUInteger)maximumIntegerDigits;
-(NSUInteger)maximumFractionDigits;
-(NSUInteger)maximumSignificantDigits;

-(NSString *)nilSymbol;
-(NSString *)notANumberSymbol;
-(NSString *)zeroSymbol;
-(NSString *)plusSign;
-(NSString *)minusSign;
-(NSString *)negativePrefix;
-(NSString *)negativeSuffix;
-(NSString *)positivePrefix;
-(NSString *)positiveSuffix;
-(NSString *)negativeInfinitySymbol;
-(NSString *)positiveInfinitySymbol;
-(NSString *)thousandSeparator;
-(NSString *)decimalSeparator;
-(NSString *)exponentSymbol;
-(NSString *)currencyCode;
-(NSString *)currencySymbol;
-(NSString *)internationalCurrencySymbol;
-(NSString *)currencyDecimalSeparator;
-(NSString *)currencyGroupingSeparator;
-(NSString *)groupingSeparator;
-(NSUInteger)groupingSize;
-(NSUInteger)secondaryGroupingSize;
-(NSString *)paddingCharacter;
-(NSNumberFormatterPadPosition)paddingPosition;
-(NSString *)percentSymbol;
-(NSString *)perMillSymbol;
-(NSDecimalNumberHandler *)roundingBehavior;
-(NSNumber *)roundingIncrement;
-(NSNumberFormatterRoundingMode)roundingMode;

-(NSString *)positiveFormat;
-(NSString *)negativeFormat;
-(NSDictionary *)textAttributesForPositiveValues;
-(NSDictionary *)textAttributesForNegativeValues;
-(NSAttributedString *)attributedStringForNil;
-(NSAttributedString *)attributedStringForNotANumber;
-(NSAttributedString *)attributedStringForZero;
-(NSDictionary *)textAttributesForNegativeInfinity;
-(NSDictionary *)textAttributesForNil;
-(NSDictionary *)textAttributesForNotANumber;
-(NSDictionary *)textAttributesForPositiveInfinity;
-(NSDictionary *)textAttributesForZero;

-(void)setFormat:(NSString *)format;
-(void)setAllowsFloats:(BOOL)flag;
-(void)setLocalizesFormat:(BOOL)flag;

-(void)setCurrencyCode:(NSString *)value;
-(void)setCurrencyDecimalSeparator:(NSString *)value;
-(void)setCurrencyGroupingSeparator:(NSString *)value;
-(void)setCurrencySymbol:(NSString *)value;
-(void)setDecimalSeparator:(NSString *)value;
-(void)setExponentSymbol:(NSString *)value;
-(void)setFormatterBehavior:(NSNumberFormatterBehavior)value;
-(void)setFormatWidth:(NSUInteger)value;
-(void)setGeneratesDecimalNumbers:(BOOL)value;
-(void)setGroupingSeparator:(NSString *)value;
-(void)setGroupingSize:(NSUInteger)value;
-(void)setInternationalCurrencySymbol:(NSString *)value;
-(void)setLenient:(BOOL)value;
-(void)setLocale:(NSLocale *)value;
-(void)setMaximum:(NSNumber *)value;
-(void)setMaximumFractionDigits:(NSUInteger)value;
-(void)setMaximumIntegerDigits:(NSUInteger)value;
-(void)setMaximumSignificantDigits:(NSUInteger)value;
-(void)setMinimum:(NSNumber *)value;
-(void)setMinimumFractionDigits:(NSUInteger)value;
-(void)setMinimumIntegerDigits:(NSUInteger)value;
-(void)setMinimumSignificantDigits:(NSUInteger)value;
-(void)setMinusSign:(NSString *)value;
-(void)setMultiplier:(NSNumber *)value;
-(void)setNegativeInfinitySymbol:(NSString *)value;
-(void)setNegativePrefix:(NSString *)value;
-(void)setNegativeSuffix:(NSString *)value;
-(void)setNilSymbol:(NSString *)value;
-(void)setNotANumberSymbol:(NSString *)value;
-(void)setNumberStyle:(NSNumberFormatterStyle)value;
-(void)setPaddingCharacter:(NSString *)value;
-(void)setPaddingPosition:(NSNumberFormatterPadPosition)value;
-(void)setPartialStringValidationEnabled:(BOOL)value;
-(void)setPercentSymbol:(NSString *)value;
-(void)setPerMillSymbol:(NSString *)value;
-(void)setPlusSign:(NSString *)value;
-(void)setPositiveInfinitySymbol:(NSString *)value;
-(void)setPositivePrefix:(NSString *)value;
-(void)setPositiveSuffix:(NSString *)value;
-(void)setRoundingBehavior:(NSDecimalNumberHandler *)value;
-(void)setRoundingIncrement:(NSNumber *)value;
-(void)setRoundingMode:(NSNumberFormatterRoundingMode)value;
-(void)setSecondaryGroupingSize:(NSUInteger)value;
-(void)setTextAttributesForNegativeInfinity:(NSDictionary *)value;
-(void)setTextAttributesForNil:(NSDictionary *)value;
-(void)setTextAttributesForNotANumber:(NSDictionary *)value;
-(void)setTextAttributesForPositiveInfinity:(NSDictionary *)value;
-(void)setTextAttributesForZero:(NSDictionary *)value;
-(void)setThousandSeparator:(NSString *)value;
-(void)setUsesGroupingSeparator:(BOOL)value;
-(void)setUsesSignificantDigits:(BOOL)value;
-(void)setZeroSymbol:(NSString *)value;

-(void)setHasThousandSeparators:(BOOL)value;
-(void)setAlwaysShowsDecimalSeparator:(BOOL)value;

-(void)setPositiveFormat:(NSString *)format;
-(void)setNegativeFormat:(NSString *)format;

-(void)setTextAttributesForNegativeValues:(NSDictionary *)attributes;
-(void)setTextAttributesForPositiveValues:(NSDictionary *)attributes;

-(void)setAttributedStringForNil:(NSAttributedString *)attributedString;
-(void)setAttributedStringForNotANumber:(NSAttributedString *)attributedString;
-(void)setAttributedStringForZero:(NSAttributedString *)attributedString;

-(NSString *)stringFromNumber:(NSNumber *)number;
-(NSNumber *)numberFromString:(NSString *)string;

-(BOOL)getObjectValue:(id *)valuep forString:(NSString *)string range:(NSRange *)rangep error:(NSError **)errorp;

@end
