/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSFormatter.h>

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

-(NSString *)format;
-(BOOL)allowsFloats;
-(BOOL)localizesFormat;
-(BOOL)hasThousandSeparators;
-(NSString *)thousandSeparator;
-(NSString *)decimalSeparator;

-(NSString *)positiveFormat;
-(NSString *)negativeFormat;
-(NSDictionary *)textAttributesForPositiveValues;
-(NSDictionary *)textAttributesForNegativeValues;
-(NSAttributedString *)attributedStringForNil;
-(NSAttributedString *)attributedStringForNotANumber;
-(NSAttributedString *)attributedStringForZero;

-(void)setFormat:(NSString *)format;
-(void)setAllowsFloats:(BOOL)flag;
-(void)setLocalizesFormat:(BOOL)flag;

-(void)setHasThousandSeparators:(BOOL)flag;
-(void)setThousandSeparator:(NSString *)separator;
-(void)setDecimalSeparator:(NSString *)separator;

-(void)setPositiveFormat:(NSString *)format;
-(void)setNegativeFormat:(NSString *)format;

-(void)setTextAttributesForNegativeValues:(NSDictionary *)attributes;
-(void)setTextAttributesForPositiveValues:(NSDictionary *)attributes;

-(void)setAttributedStringForNil:(NSAttributedString *)attributedString;
-(void)setAttributedStringForNotANumber:(NSAttributedString *)attributedString;
-(void)setAttributedStringForZero:(NSAttributedString *)attributedString;

@end
