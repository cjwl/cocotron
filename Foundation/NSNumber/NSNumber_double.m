/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSException.h>
#import <Foundation/NSNumber_double.h>
#import <Foundation/NSStringFormatter.h>


@implementation NSNumber_double


NSNumber *kNSNumberPositiveInfinity;
NSNumber *kNSNumberNegativeInfinity;
NSNumber *kNSNumberNaN;
NSNumber *kNSNumberPositiveZero;
NSNumber *kNSNumberNegativeZero;
NSNumber *kNSNumberPositiveOne;
NSNumber *kNSNumberNegativeOne;
const CFNumberRef kCFNumberPositiveInfinity = (CFNumberRef)&kNSNumberPositiveInfinity;
const CFNumberRef kCFNumberNegativeInfinity = (CFNumberRef)&kNSNumberNegativeInfinity;
const CFNumberRef kCFNumberNaN = (CFNumberRef)&kNSNumberNaN;


+ (void)initialize
{
    kNSNumberPositiveInfinity = [[self allocWithZone: NULL] initWithDouble: INFINITY];
    kNSNumberNegativeInfinity = [[self allocWithZone: NULL] initWithDouble: -INFINITY];
    kNSNumberNaN = [[self allocWithZone: NULL] initWithDouble: NAN];
    kNSNumberPositiveZero = [[self allocWithZone: NULL] initWithDouble: 0.0];
    kNSNumberNegativeZero = [[self allocWithZone: NULL] initWithDouble: -0.0];
    kNSNumberPositiveOne = [[self allocWithZone: NULL] initWithDouble: 1.0];
    kNSNumberNegativeOne = [[self allocWithZone: NULL] initWithDouble: -1.0];
}


+ numberWithSpecialDouble: (double)value
{
   switch (fpclassify(value)) {
      case FP_INFINITE:
         return signbit(value) ? kNSNumberNegativeInfinity : kNSNumberPositiveInfinity;
      case FP_NAN:
         return kNSNumberNaN;
      case FP_ZERO:
         return signbit(value) ? kNSNumberNegativeZero : kNSNumberPositiveZero;
      default:
         if (0) {
             // Without profiling, I'm assuming no one value is more likely than every other value put together, and the compiler will optimize for the first if() branch.
         } else if (value == 1.0) {
             return kNSNumberPositiveOne;
         } else if (value == -1.0) {
             return kNSNumberNegativeOne;
         }
         return nil;
   }
}


+ numberWithDouble: (double)value
{
    NSNumber *result = [self numberWithSpecialDouble: value];
    if (result == nil) {
        result = [[[self allocWithZone: NULL] initWithDouble: value] autorelease];
    }
    return result;
}


- init
{
    [super init];
    _type = kCFNumberDoubleType;
    return self;
}


- initWithDouble: (double)value
{
    [self init];
    _value = value;
    return self;
}


-(void)getValue:(void *)value {
   *((double *)value)=_value;
}

-(const char *)objCType {
   return @encode(double);
}

-(char)charValue {
   return _value;
}

-(unsigned char)unsignedCharValue {
   return _value;
}

-(short)shortValue {
   return _value;
}

-(unsigned short)unsignedShortValue {
   return _value;
}

-(int)intValue {
   return (int)_value;
}

-(unsigned int)unsignedIntValue {
   return (unsigned int)_value;
}

-(long)longValue {
   return _value;
}

-(unsigned long)unsignedLongValue {
   return _value;
}

-(long long)longLongValue {
   return _value;
}

-(unsigned long long)unsignedLongLongValue {
   return _value;
}

-(float)floatValue {
   return (float)_value;
}

-(double)doubleValue {
   return _value;
}

-(BOOL)boolValue {
   return _value?YES:NO;
}

-(NSInteger)integerValue {
   return (NSInteger)_value;
}

-(NSUInteger)unsignedIntegerValue {
   return (NSUInteger)_value;
}

-(NSString *)descriptionWithLocale:(NSDictionary *)locale {
   return NSStringWithFormatAndLocale(@"%0.15g",locale,_value);
}

@end
