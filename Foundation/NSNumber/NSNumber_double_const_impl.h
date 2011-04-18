/* Copyright (c) 2009 Jens Ayton
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSNumber_double.h>
#import <Foundation/NSNumber_double_const.h>


NS_DECLARE_CLASS_SYMBOL(NSNumber_double_const);


typedef struct
{
   const struct objc_class * const isa;
   CFNumberType _type;
   double _value;
} NSNumber_double_Def;


static const NSNumber_double_Def kPositiveInfinityDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   INFINITY
};


static const NSNumber_double_Def kNegativeInfinityDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   -INFINITY
};


static const NSNumber_double_Def kNaNDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   NAN
};


static const NSNumber_double_Def kPositiveZeroDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   0.0
};


static const NSNumber_double_Def kNegativeZeroDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   -0.0
};


static const NSNumber_double_Def kPositiveOneDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   1.0
};


static const NSNumber_double_Def kNegativeOneDef =
{
   &_OBJC_CLASS_NSNumber_double_const,
   kCFNumberDoubleType,
   -1.0
};

const CFNumberRef kCFNumberPositiveInfinity = (CFNumberRef)&kPositiveInfinityDef;
const CFNumberRef kCFNumberNegativeInfinity = (CFNumberRef)&kNegativeInfinityDef;
const CFNumberRef kCFNumberNaN = (CFNumberRef)&kNaNDef;

NS_CONSTOBJ_DEF NSNumber * const kNSNumberPositiveZero = (NSNumber *)&kPositiveZeroDef;
NS_CONSTOBJ_DEF NSNumber * const kNSNumberNegativeZero = (NSNumber *)&kNegativeZeroDef;
NS_CONSTOBJ_DEF NSNumber * const kNSNumberPositiveOne = (NSNumber *)&kPositiveOneDef;
NS_CONSTOBJ_DEF NSNumber * const kNSNumberNegativeOne = (NSNumber *)&kNegativeOneDef;
