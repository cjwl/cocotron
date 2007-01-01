/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSColor_cmykDevice.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/CoreGraphics.h>

@implementation NSColor_cmykDevice

-initWithCyan:(float)cyan magenta:(float)magenta yellow:(float)yellow black:(float)black alpha:(float)alpha {
   _cyan=cyan;
   _magenta=magenta;
   _yellow=yellow;
   _black=black;
   _alpha=alpha;
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   [coder encodeObject:[self colorSpaceName]];
   [coder encodeValuesOfObjCTypes:"fffff",&_cyan,&_magenta,&_yellow,&_black,&_alpha];
}

-(BOOL)isEqual:otherObject {
   if(self==otherObject)
    return YES;

   if([otherObject isKindOfClass:[self class]]){
    NSColor_cmykDevice *other=otherObject;

    return (_cyan==other->_cyan && _magenta==other->_magenta &&
            _yellow==other->_yellow && _black==other->_black && _alpha==other->_alpha);
   }

   return NO;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ cyan: %f magenta: %f yellow: %f black: %f alpha: %f>",
        [[self class] description], _cyan, _magenta, _yellow, _black, _alpha];
}

+(NSColor *)colorWithCyan:(float)cyan magenta:(float)magenta yellow:(float)yellow black:(float)black alpha:(float)alpha {
   return [[[self alloc] initWithCyan:cyan magenta:magenta yellow:yellow black:black alpha:alpha] autorelease];
}

-(NSString *)colorSpaceName {
   return NSDeviceCMYKColorSpace;
}

-(void)getCyan:(float *)cyan magenta:(float *)magenta yellow:(float *)yellow black:(float *)black alpha:(float *)alpha {
   if(cyan!=NULL)
    *cyan = _cyan;
   if(magenta!=NULL)
    *magenta = _magenta;
   if(yellow!=NULL)
    *yellow = _yellow;
   if(black!=NULL)
    *black = _black;
   if(alpha!=NULL)
    *alpha = _alpha;
}

-(float)alphaComponent {
   return _alpha;
}

// ahh, subtractive color space.
-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace device:(NSDictionary *)device {
    if([colorSpace isEqualToString:[self colorSpaceName]])
        return self;

    if([colorSpace isEqualToString:NSCalibratedRGBColorSpace] || colorSpace == nil) {
        float white = 1 - _black;
        return [NSColor colorWithCalibratedRed:(_cyan > white ? 0 : white - _cyan) 
                                         green:(_magenta > white ? 0 : white - _magenta)
                                          blue:(_yellow > white ? 0 : white - _yellow)
                                         alpha:_alpha];
    }

    if([colorSpace isEqualToString:NSCalibratedWhiteColorSpace]) {
        float white = 1 - _cyan - _magenta - _yellow - _black;
        return [NSColor colorWithCalibratedWhite:(white > 0 ? white : 0) alpha:_alpha];
    }

    return [super colorUsingColorSpaceName:colorSpace device:device];
}

-(void)set {
    // temporary fix
    NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    CGContextSetCalibratedRGBColor(NSCurrentGraphicsPort(),
                                   [convertedColor redComponent],
                                   [convertedColor greenComponent],
                                   [convertedColor blueComponent], _alpha);
    
//   CGContextSetDeviceCMYKColor(NSCurrentGraphicsPort(),_cyan,_magenta,_yellow,_black,_alpha);
}

@end
