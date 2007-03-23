/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "KGShading.h"
#import "KGColorSpace.h"
#import "KGFunction.h"

@implementation KGShading

-initWithColorSpace:(KGColorSpace *)colorSpace startPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd {
   _colorSpace=[colorSpace retain];
   _startPoint=startPoint;
   _endPoint=endPoint;
   _function=[function retain];
   _extendStart=extendStart;
   _extendEnd=extendEnd;
   _isRadial=NO;
   return self;
}

-initWithColorSpace:(KGColorSpace *)colorSpace startPoint:(NSPoint)startPoint startRadius:(float)startRadius endPoint:(NSPoint)endPoint endRadius:(float)endRadius function:(KGFunction *)function extendStart:(BOOL)extendStart extendEnd:(BOOL)extendEnd {
   _colorSpace=[colorSpace retain];
   _startPoint=startPoint;
   _endPoint=endPoint;
   _function=[function retain];
   _extendStart=extendStart;
   _extendEnd=extendEnd;
   _isRadial=YES;
   _startRadius=startRadius;
   _endRadius=endRadius;
   return self;
}

-(void)dealloc {
   [_colorSpace release];
   [_function release];
   [super dealloc];
}

-(KGColorSpace *)colorSpace {
   return _colorSpace;
}

-(NSPoint)startPoint {
   return _startPoint;
}

-(NSPoint)endPoint {
   return _endPoint;
}

-(BOOL)extendStart {
   return _extendStart;
}

-(BOOL)extendEnd {
   return _extendEnd;
}

-(KGFunction *)function {
   return _function;
}

-(BOOL)isAxial {
   return _isRadial?NO:YES;
}

@end
