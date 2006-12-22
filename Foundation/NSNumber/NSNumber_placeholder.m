/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSNumber_placeholder.h>
#import <Foundation/NSNumber_char.h>
#import <Foundation/NSNumber_double.h>
#import <Foundation/NSNumber_float.h>
#import <Foundation/NSNumber_int.h>
#import <Foundation/NSNumber_longLong.h>
#import <Foundation/NSNumber_long.h>
#import <Foundation/NSNumber_short.h>
#import <Foundation/NSNumber_unsignedChar.h>
#import <Foundation/NSNumber_unsignedInt.h>
#import <Foundation/NSNumber_unsignedLongLong.h>
#import <Foundation/NSNumber_unsignedLong.h>
#import <Foundation/NSNumber_unsignedShort.h>
#import <Foundation/NSNumber_BOOL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>

@implementation NSNumber_placeholder

-initWithChar:(char)value {
   NSDeallocateObject(self);
   return NSNumber_charNew(NULL,value);
}

-initWithUnsignedChar:(unsigned char)value {
   NSDeallocateObject(self);
   return NSNumber_unsignedCharNew(NULL,value);
}

-initWithShort:(short)value {
   NSDeallocateObject(self);
   return NSNumber_shortNew(NULL,value);
}

-initWithUnsignedShort:(unsigned short)value {
   NSDeallocateObject(self);
   return NSNumber_unsignedShortNew(NULL,value);
}

-initWithInt:(int)value {
   NSDeallocateObject(self);
   return NSNumber_intNew(NULL,value);
}

-initWithUnsignedInt:(unsigned int)value {
   NSDeallocateObject(self);
   return NSNumber_unsignedIntNew(NULL,value);
}

-initWithLong:(long)value {
   NSDeallocateObject(self);
   return NSNumber_longNew(NULL,value);
}

-initWithUnsignedLong:(unsigned long)value {
   NSDeallocateObject(self);
   return NSNumber_unsignedLongNew(NULL,value);
}

-initWithLongLong:(long long)value {
   NSDeallocateObject(self);
   return NSNumber_longLongNew(NULL,value);
}

-initWithUnsignedLongLong:(unsigned long long)value {
   NSDeallocateObject(self);
   return NSNumber_unsignedLongLongNew(NULL,value);
}

-initWithFloat:(float)value {
   NSDeallocateObject(self);
   return NSNumber_floatNew(NULL,value);
}

-initWithDouble:(double)value {
   NSDeallocateObject(self);
   return NSNumber_doubleNew(NULL,value);
}

-initWithBool:(BOOL)value {
   NSDeallocateObject(self);
   return NSNumber_BOOLNew(NULL,value);
}

@end
