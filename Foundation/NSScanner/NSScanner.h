/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

@class NSDictionary,NSCharacterSet;

@interface NSScanner : NSObject

-initWithString:(NSString *)string;

+scannerWithString:(NSString *)string;
+localizedScannerWithString:(NSString *)string;

-(NSString *)string;

-(NSCharacterSet *)charactersToBeSkipped;
-(BOOL)caseSensitive;
-(NSDictionary *)locale;

-(void)setCharactersToBeSkipped:(NSCharacterSet *)set;
-(void)setCaseSensitive:(BOOL)flag;
-(void)setLocale:(NSDictionary *)locale;

-(BOOL)isAtEnd;
-(unsigned)scanLocation;
-(void)setScanLocation:(unsigned)location;

-(BOOL)scanInt:(int *)value;
-(BOOL)scanLongLong:(long long *)value;
-(BOOL)scanFloat:(float *)value;
-(BOOL)scanDouble:(double *)value;

-(BOOL)scanHexInt:(unsigned *)value;

-(BOOL)scanString:(NSString *)string intoString:(NSString **)stringp;
-(BOOL)scanUpToString:(NSString *)string intoString:(NSString **)stringp;

-(BOOL)scanCharactersFromSet:(NSCharacterSet *)charset intoString:(NSString **)stringp;
-(BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)charset intoString:(NSString **)stringp;

@end
