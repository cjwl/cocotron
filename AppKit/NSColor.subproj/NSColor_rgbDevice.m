/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSColor_rgbDevice.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <ApplicationServices/ApplicationServices.h>

#import <AppKit/conversions.h>

@implementation NSColor_rgbDevice

-initWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   _red=red;
   _green=green;
   _blue=blue;
   _alpha=alpha;
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   [coder encodeObject:[self colorSpaceName]];
   [coder encodeValuesOfObjCTypes:"ffff",&_red,&_green,&_blue,&_alpha];
}

-(BOOL)isEqual:otherObject {
   if(self==otherObject)
    return YES;

   if([otherObject isKindOfClass:[self class]]){
    NSColor_rgbDevice *other=otherObject;

    return (_red==other->_red && _green==other->_green &&
            _blue==other->_blue && _alpha==other->_alpha);
   }

   return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ red: %f green: %f blue: %f alpha: %f>",
        [[self class] description], _red, _green, _blue, _alpha];
}

+(NSColor *)colorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   return [[[self alloc] initWithRed:red green:green blue:blue alpha:alpha] autorelease];
}

+(NSColor *)colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha {
   float red,green,blue;

   NSColorHSBToRGB(hue,saturation,brightness,&red,&green,&blue);

   return [[[self alloc] initWithRed:red green:green blue:blue alpha:alpha] autorelease];
}

-(void)getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha {
   if(red!=NULL)
    *red = _red;
   if(green!=NULL)
    *green = _green;
   if(blue!=NULL)
    *blue = _blue;
   if(alpha!=NULL)
    *alpha = _alpha;
}

-(void)getHue:(float *)huep saturation:(float *)saturationp brightness:(float *)brightnessp alpha:(float *)alphap {

   NSColorRGBToHSB(_red,_green,_blue,huep,saturationp,brightnessp);

   if(alphap!=NULL)
    *alphap=_alpha;
}

-(float)alphaComponent {
   return _alpha;
}

-(NSColor *)colorWithAlphaComponent:(float)alpha { 
   return [[[[self class] alloc] initWithRed:_red green:_green blue:_blue alpha:alpha] autorelease]; 
} 

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace device:(NSDictionary *)device {
   if([colorSpace isEqualToString:NSDeviceRGBColorSpace] || colorSpace==nil)
    return self;

   if([colorSpace isEqualToString:NSDeviceWhiteColorSpace])
    return [NSColor colorWithDeviceWhite:(_red+_green+_blue)/3 alpha:_alpha];

   if([colorSpace isEqualToString:NSDeviceCMYKColorSpace])
    return [NSColor colorWithDeviceCyan:1.0-_red magenta:1.0-_green yellow:1.0-_blue black:0.0 alpha:_alpha];

// FIX, These are not accurate
   if([colorSpace isEqualToString:NSCalibratedRGBColorSpace])
    return [NSColor colorWithCalibratedRed:_red green:_green blue:_blue alpha:_alpha];

   if([colorSpace isEqualToString:NSCalibratedWhiteColorSpace])
    return [NSColor colorWithCalibratedWhite:(_red+_green+_blue)/3 alpha:_alpha];

   return nil;
}

-(NSString *)colorSpaceName {
   return NSDeviceRGBColorSpace;
}

-(CGColorRef)createCGColorRef {
   CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
   float         components[4]={_red,_green,_blue,_alpha};
   CGColorRef color=CGColorCreate(colorSpace,components);
   
   CGColorSpaceRelease(colorSpace);
   return color;
}

-(void)setStroke {
   CGContextSetRGBStrokeColor(NSCurrentGraphicsPort(),_red,_green,_blue,_alpha);
}

-(void)setFill {
    CGContextSetRGBFillColor(NSCurrentGraphicsPort(),_red,_green,_blue,_alpha);
}

@end
