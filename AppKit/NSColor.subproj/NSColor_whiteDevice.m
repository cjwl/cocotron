/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSColor_whiteDevice.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/CoreGraphics.h>

@implementation NSColor_whiteDevice

-initWithGray:(float)gray alpha:(float)alpha {
   _white=gray;
   _alpha=alpha;
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   [coder encodeObject:[self colorSpaceName]];
   [coder encodeValuesOfObjCTypes:"ff",&_white,&_alpha];
}

-(BOOL)isEqual:otherObject {
   if(self==otherObject)
    return YES;

   if([otherObject isKindOfClass:[self class]]){
    NSColor_whiteDevice *other=otherObject;

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

-(NSString *)colorSpaceName {
   return NSDeviceWhiteColorSpace;
}

-(void)getWhite:(float *)white alpha:(float *)alpha {
   if(white!=NULL)
    *white = _white;
   if(alpha!=NULL)
    *alpha = _alpha;
}

-(float)alphaComponent {
   return _alpha;
}

-(void)set {
   CGContextSetDeviceGrayColor(NSCurrentGraphicsPort(),_white,_alpha);
}

@end
