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

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpaceName device:(NSDictionary *)device {
   CGColorSpaceRef   colorSpace=CGColorGetColorSpace(_colorRef);
   CGColorSpaceModel model=CGColorSpaceGetModel(colorSpace);
   
   if([colorSpaceName isEqualToString:NSDeviceBlackColorSpace])
    return nil;
   if([colorSpaceName isEqualToString:NSDeviceWhiteColorSpace])
    return nil;
    
   if([colorSpaceName isEqualToString:NSDeviceRGBColorSpace]){
    if(model==kCGColorSpaceModelRGB)
     return self;
     
    return nil;
   }
   
   if([colorSpaceName isEqualToString:NSDeviceCMYKColorSpace]){
    return nil;
   }

   if([colorSpaceName isEqualToString:NSCalibratedBlackColorSpace])
    return nil;
   if([colorSpaceName isEqualToString:NSCalibratedWhiteColorSpace])
    return nil;
   if([colorSpaceName isEqualToString:NSCalibratedRGBColorSpace]){
    if(model==kCGColorSpaceModelRGB)
     return self;
     
    return nil;
   }
    
   return nil;
}

-(NSString *)colorSpaceName {
   CGColorSpaceRef   colorSpace=CGColorGetColorSpace(_colorRef);
   CGColorSpaceModel model=CGColorSpaceGetModel(colorSpace);

   switch(model){
   
    case kCGColorSpaceModelMonochrome:
     return NSDeviceWhiteColorSpace;
     
    case kCGColorSpaceModelRGB:
     return NSCalibratedRGBColorSpace;
     
    case kCGColorSpaceModelCMYK:
     return NSDeviceCMYKColorSpace;
     
    default:
     return nil;
   }
   
   return nil;
}

-(void)getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha {
   CGColorSpaceRef   colorSpace=CGColorGetColorSpace(_colorRef);
   CGColorSpaceModel model=CGColorSpaceGetModel(colorSpace);
   const CGFloat    *components=CGColorGetComponents(_colorRef);
   
   if(model!=kCGColorSpaceModelRGB){
    NSLog(@"-[%@ %s] failed",isa,_cmd);
    return;
   }
   
   if(red!=NULL)
    *red = components[0];
   if(green!=NULL)
    *green = components[1];
   if(blue!=NULL)
    *blue = components[2];
   if(alpha!=NULL)
    *alpha = components[3];
}

-(CGColorRef)createCGColorRef {
   return CGColorRetain(_colorRef);
}

-(void)setStroke {
   CGContextSetStrokeColorWithColor(NSCurrentGraphicsPort(),_colorRef);
}

-(void)setFill {
   CGContextSetFillColorWithColor(NSCurrentGraphicsPort(),_colorRef);
}

@end
