/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSColor_whiteCalibrated.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation NSColor_whiteCalibrated

-initWithGray:(float)gray alpha:(float)alpha {
   _white=gray;
   _alpha=alpha;
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding])
    [super encodeWithCoder:coder];
   else {
    [coder encodeObject:[self colorSpaceName]];
    [coder encodeValuesOfObjCTypes:"ff",&_white,&_alpha];
   }
}

-(BOOL)isEqual:otherObject {
   if(self==otherObject)
    return YES;

   if([otherObject isKindOfClass:[self class]]){
    NSColor_whiteCalibrated *other=otherObject;

    return (_white==other->_white && _alpha==other->_alpha);
   }

   return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ _white: %f alpha: %f>",
        [[self class] description], _white, _alpha];
}

+(NSColor *)colorWithGray:(float)gray alpha:(float)alpha {
   return [[[self alloc] initWithGray:gray alpha:alpha] autorelease];
}

+(NSColor *)blackColor {
   static NSColor *shared=nil;

   if(shared==nil)
    shared=[[NSColor_whiteCalibrated alloc] initWithGray:0 alpha:1.0];

   return shared;
}

+(NSColor *)darkGrayColor {
   static NSColor *shared=nil;

   if(shared==nil)
    shared=[[NSColor_whiteCalibrated alloc] initWithGray:1/3. alpha:1.0];

   return shared;
}

+(NSColor *)lightGrayColor {
   static NSColor *shared=nil;

   if(shared==nil)
    shared=[[NSColor_whiteCalibrated alloc] initWithGray:2/3. alpha:1.0];

   return shared;
}

+(NSColor *)whiteColor {
   static NSColor *shared=nil;

   if(shared==nil)
    shared=[[NSColor_whiteCalibrated alloc] initWithGray:1 alpha:1.0];

   return shared;
}

+(NSColor *)grayColor {
   static NSColor *shared=nil;

   if(shared==nil)
    shared=[[NSColor_whiteCalibrated alloc] initWithGray:0.5 alpha:1.0];

   return shared;
}

-(NSString *)colorSpaceName {
   return NSCalibratedWhiteColorSpace;
}

-(void)getWhite:(float *)white alpha:(float *)alpha {
   if(white!=NULL)
    *white = _white;
   if(alpha!=NULL)
    *alpha = _alpha;
}

- (void)getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha
{
	if (red)   *red = _white;
	if (green) *green = _white;
	if (blue)  *blue = _white;
	if (alpha) *alpha = _alpha;
}

-(float)alphaComponent {
   return _alpha;
}

-(NSColor *)colorWithAlphaComponent:(float)alpha { 
   return [[[[self class] alloc] initWithGray:_white alpha:alpha] autorelease]; 
} 

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace device:(NSDictionary *)device {
   if([colorSpace isEqualToString:NSCalibratedWhiteColorSpace])
    return self;

   if([colorSpace isEqualToString:NSCalibratedRGBColorSpace] || colorSpace == nil)
    return [NSColor colorWithCalibratedRed:_white green:_white blue:_white alpha:_alpha];

   if([colorSpace isEqualToString:NSDeviceCMYKColorSpace])
    return [NSColor colorWithDeviceCyan:0 magenta:0 yellow:0 black:1-_white alpha:_alpha];

   return [super colorUsingColorSpaceName:colorSpace device:device];
}

-(CGColorRef)createCGColorRef {
   CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceGray();
   float         components[2]={_white,_alpha};
   CGColorRef color=CGColorCreate(colorSpace,components);
   
   CGColorSpaceRelease(colorSpace);
   return color;
}

-(void)setStroke {
   CGContextSetGrayStrokeColor(NSCurrentGraphicsPort(),_white,_alpha);
}

-(void)setFill {
    CGContextSetGrayFillColor(NSCurrentGraphicsPort(),_white,_alpha);
}

@end
