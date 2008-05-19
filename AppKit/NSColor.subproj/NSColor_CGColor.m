/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSColor_CGColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <ApplicationServices/ApplicationServices.h>

#import <AppKit/conversions.h>

@implementation NSColor_CGColor

-initWithColorRef:(CGColorRef)colorRef {
   _colorRef=CGColorRetain(colorRef);
   return self;
}

-(void)dealloc {
   CGColorRelease(_colorRef);
   [super dealloc];
}

+(NSColor *)colorWithColorRef:(CGColorRef)colorRef {
   return [[[self alloc] initWithColorRef:colorRef] autorelease];
}


-(BOOL)isEqual:otherObject {
   if(self==otherObject)
    return YES;

   if([otherObject isKindOfClass:[self class]]){
    NSColor_CGColor *other=otherObject;

    return CGColorEqualToColor(_colorRef,other->_colorRef);
   }

   return NO;
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@ colorRef=%@>",[self class], _colorRef];
}

-(float)alphaComponent {
   return CGColorGetAlpha(_colorRef);
}

-(NSColor *)colorWithAlphaComponent:(CGFloat)alpha {
   CGColorRef ref=CGColorCreateCopyWithAlpha(_colorRef,alpha);
   NSColor   *result=[[[isa alloc] initWithColorRef:ref] autorelease];
   
   CGColorRelease(ref);
   return result;
} 

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace device:(NSDictionary *)device {
   return nil;
}

-(NSString *)colorSpaceName {
   return nil;
}

-(void)setStroke {
   CGContextSetStrokeColorWithColor(NSCurrentGraphicsPort(),_colorRef);
}

-(void)setFill {
   CGContextSetFillColorWithColor(NSCurrentGraphicsPort(),_colorRef);
}

@end
