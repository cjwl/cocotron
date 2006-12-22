/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/AppKitExport.h>

@class NSPasteboard;

@interface NSColor : NSObject <NSCopying> 

+(NSColor *)highlightColor;
+(NSColor *)shadowColor;
+(NSColor *)gridColor;

+(NSColor *)controlColor;
+(NSColor *)selectedControlColor;
+(NSColor *)controlTextColor;
+(NSColor *)selectedControlTextColor;
+(NSColor *)disabledControlTextColor;
+(NSColor *)controlBackgroundColor;
+(NSColor *)controlDarkShadowColor;
+(NSColor *)controlHighlightColor;
+(NSColor *)controlLightHighlightColor;
+(NSColor *)controlShadowColor;

+(NSColor *)textColor;
+(NSColor *)textBackgroundColor;
+(NSColor *)selectedTextColor;
+(NSColor *)selectedTextBackgroundColor;

+(NSColor *)headerColor;
+(NSColor *)headerTextColor;

+(NSColor *)scrollBarColor;
+(NSColor *)knobColor;
+(NSColor *)selectedKnobColor;

+(NSColor *)windowBackgroundColor;

// private
+(NSColor *)menuBackgroundColor;
+(NSColor *)menuItemTextColor;

+(NSColor *)clearColor;

+(NSColor *)blackColor;
+(NSColor *)blueColor;
+(NSColor *)brownColor;
+(NSColor *)cyanColor;
+(NSColor *)darkGrayColor;
+(NSColor *)grayColor;
+(NSColor *)greenColor;
+(NSColor *)lightGrayColor;
+(NSColor *)magentaColor;
+(NSColor *)orangeColor;
+(NSColor *)purpleColor;
+(NSColor *)redColor;
+(NSColor *)whiteColor;
+(NSColor *)yellowColor;

+(NSColor *)colorWithDeviceWhite:(float)white alpha:(float)alpha;
+(NSColor *)colorWithDeviceRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
+(NSColor *)colorWithDeviceHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha;
+(NSColor *)colorWithDeviceCyan:(float)cyan magenta:(float)magenta yellow:(float)yellow black:(float)black alpha:(float)alpha;

+(NSColor *)colorWithCalibratedWhite:(float)white alpha:(float)alpha;
+(NSColor *)colorWithCalibratedRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
+(NSColor *)colorWithCalibratedHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha;

+(NSColor *)colorWithCatalogName:(NSString *)catalogName colorName:(NSString *)colorName;

+(NSColor *)colorFromPasteboard:(NSPasteboard *)pasteboard;

-(NSString *)colorSpaceName;

-(void)getWhite:(float *)white alpha:(float *)alpha;
-(void)getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha;
-(void)getHue:(float *)hue saturation:(float *)saturation brightness:(float *)brightness alpha:(float *)alpha;
-(void)getCyan:(float *)cyan magenta:(float *)magenta yellow:(float *)yellow black:(float *)black alpha:(float *)alpha;

-(float)whiteComponent;

-(float)redComponent;
-(float)greenComponent;
-(float)blueComponent;

-(float)hueComponent;
-(float)saturationComponent;
-(float)brightnessComponent;

-(float)cyanComponent;
-(float)magentaComponent;
-(float)yellowComponent;
-(float)blackComponent;

-(float)alphaComponent;

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace;
-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace device:(NSDictionary *)device;

-(NSColor *)blendedColorWithFraction:(float)fraction ofColor:(NSColor *)color;

-(void)set;

-(void)drawSwatchInRect:(NSRect)rect;

-(void)writeToPasteboard:(NSPasteboard *)pasteboard;

@end
