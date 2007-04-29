/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSDatePickerCell.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSLocale.h>

@implementation NSDatePickerCell

-delegate {
   return _delegate;
}

-(NSDatePickerElementFlags)datePickerElements {
   return _elements;
}

-(NSDatePickerMode)datePickerMode {
   return _mode;
}

-(NSDatePickerStyle)datePickerStyle {
   return _style;
}

-(NSCalendar *)calendar {
   return _calendar;
}

-(NSLocale *)locale {
   return _locale;
}

-(NSDate *)minDate {
   return _minDate;
}

-(NSDate *)maxDate {
   return _maxDate;
}

-(NSDate *)dateValue {
   return _dateValue;
}

-(NSTimeInterval)timeInterval {
   return 0;
}

-(NSTimeZone *)timeZone {
   return _timeZone;
}

-(BOOL)drawsBackground {
   return _drawsBackground;
}

-(NSColor *)backgroundColor {
   return _backgroundColor;
}

-(NSColor *)textColor {
   return _textColor;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setDatePickerElements:(NSDatePickerElementFlags)elements {
   _elements=elements;
}

-(void)setDatePickerMode:(NSDatePickerMode)mode {
   _mode=mode;
}

-(void)setDatePickerStyle:(NSDatePickerStyle)style {
   _style=style;
}

-(void)setCalendar:(NSCalendar *)calendar {
   calendar=[calendar copy];
   [_calendar release];
   _calendar=calendar;
}

-(void)setLocale:(NSLocale *)locale {
   locale=[locale copy];
   [_locale release];
   _locale=locale;
}

-(void)setMinDate:(NSDate *)date {
   date=[date copy];
   [_minDate release];
   _minDate=date;
}

-(void)setMaxDate:(NSDate *)date {
   date=[date copy];
   [_maxDate release];
   _maxDate=date;
}


-(void)setDateValue:(NSDate *)date {
   date=[date copy];
   [_dateValue release];
   _dateValue=date;
}

-(void)setTimeInterval:(NSTimeInterval)interval {
}

-(void)setTimeZone:(NSTimeZone *)timeZone {
   timeZone=[timeZone copy];
   [_timeZone release];
   _timeZone=timeZone;
}

-(void)setDrawsBackground:(BOOL)flag {
   _drawsBackground=flag;
}

-(void)setBackgroundColor:(NSColor *)color {
   color=[color copy];
   [_backgroundColor release];
   _backgroundColor=color;
}

-(void)setTextColor:(NSColor *)color {
   color=[color copy];
   [_textColor release];
   _textColor=color;
}


@end
