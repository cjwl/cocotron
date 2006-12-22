/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSRange.h>

@class NSDictionary;

@interface NSAttributedString : NSObject <NSCopying>

-initWithString:(NSString *)string;
-initWithString:(NSString *)string attributes:(NSDictionary *)attributes;
-initWithAttributedString:(NSAttributedString *)other;

-(BOOL)isEqualToAttributedString:(NSAttributedString *)other;

-(unsigned)length;
-(NSString *)string;

-(NSDictionary *)attributesAtIndex:(unsigned)location effectiveRange:(NSRangePointer)range;
-(NSDictionary *)attributesAtIndex:(unsigned)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)inRange;

-attribute:(NSString *)name atIndex:(unsigned)location effectiveRange:(NSRangePointer)range;
-attribute:(NSString *)name atIndex:(unsigned)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)inRange;

-(NSAttributedString *)attributedSubstringFromRange:(NSRange)range;


@end

