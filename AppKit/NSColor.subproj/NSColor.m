/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSColor.h>
#import <AppKit/NSColor_whiteCalibrated.h>
#import <AppKit/NSColor_rgbCalibrated.h>
#import <AppKit/NSColor_whiteDevice.h>
#import <AppKit/NSColor_rgbDevice.h>
#import <AppKit/NSColor_cmykDevice.h>
#import <AppKit/NSColor_catalog.h>

#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContext.h>

#import <AppKit/NSPasteboard.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

#import <AppKit/NSDisplay.h>

@implementation NSColor

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    int                colorSpace=[keyed decodeIntForKey:@"NSColorSpace"];
    NSColor           *result;

    switch(colorSpace){
    
     case 1:{
// NSComponents data
// NSCustomColorSpace NSColorSpace
       unsigned    length;
       const char *rgb=[keyed decodeBytesForKey:@"NSRGB" returnedLength:&length];
       NSString   *string=[NSString stringWithCString:rgb length:length];
       NSArray    *components=[string componentsSeparatedByString:@" "];
       float       values[4]={0,0,0,1};
       int         i,count=[components count];
       
       for(i=0;i<count && i<4;i++)
        values[i]=[[components objectAtIndex:i] floatValue];
       
       result=[NSColor colorWithCalibratedRed:values[0] green:values[1] blue:values[2] alpha:values[3]];
      }
      break;
      
     case 2:{
       unsigned    length;
       const char *rgb=[keyed decodeBytesForKey:@"NSRGB" returnedLength:&length];
       NSString   *string=[NSString stringWithCString:rgb length:length];
       NSArray    *components=[string componentsSeparatedByString:@" "];
       float       values[4]={0,0,0,1};
       int         i,count=[components count];
       
       for(i=0;i<count && i<4;i++)
        values[i]=[[components objectAtIndex:i] floatValue];

       result=[NSColor colorWithDeviceRed:values[0] green:values[1] blue:values[2] alpha:values[3]];
      }
      break;
      
     case 3:{
       unsigned    length;
       const char *white=[keyed decodeBytesForKey:@"NSWhite" returnedLength:&length];
       NSString   *string=[NSString stringWithCString:white length:length-1];
       NSArray    *components=[string componentsSeparatedByString:@" "];
       float       values[2]={0,1};
       int         i,count=[components count];
              
       for(i=0;i<count && i<2;i++)
        values[i]=[[components objectAtIndex:i] floatValue];

       result=[NSColor colorWithCalibratedWhite:values[0] alpha:values[1]];
      }
      break;
      
     case 4:{
       unsigned    length;
       const char *white=[keyed decodeBytesForKey:@"NSWhite" returnedLength:&length];
       NSString   *string=[NSString stringWithCString:white length:length];
       NSArray    *components=[string componentsSeparatedByString:@" "];
       float       values[2]={0,1};
       int         i,count=[components count];
       
       for(i=0;i<count && i<2;i++)
        values[i]=[[components objectAtIndex:i] floatValue];

       result=[NSColor colorWithDeviceWhite:values[0] alpha:values[1]];
      }
      break;
      
     case 5:{
// NSComponents data
// NSCustomColorSpace NSColorSpace
       unsigned    length;
       const char *cmyk=[keyed decodeBytesForKey:@"NSCMYK" returnedLength:&length];
       NSString   *string=[NSString stringWithCString:cmyk length:length];
       NSArray    *components=[string componentsSeparatedByString:@" "];
       float       values[5]={0,0,0,0,1};
       int         i,count=[components count];
       
       for(i=0;i<count && i<5;i++)
        values[i]=[[components objectAtIndex:i] floatValue];

       result=[NSColor colorWithDeviceCyan:values[0] magenta:values[1] yellow:values[2] black:values[3] alpha:values[4]];
      }
      break;
      
     case 6:{
       NSString *catalogName=[keyed decodeObjectForKey:@"NSCatalogName"];
       NSString *colorName=[keyed decodeObjectForKey:@"NSColorName"];
       NSColor  *color=[keyed decodeObjectForKey:@"NSColor"];
       
       if([catalogName isEqualToString: @"System"]) {
	   NSDisplay *display = [NSDisplay currentDisplay];
	   result = [display colorWithName: colorName];
	   if(!result) {
	       result = color;
	       [display _addSystemColor: result forName: colorName];
	   }
       } else {
	   result = [NSColor colorWithCatalogName: catalogName colorName: colorName];
	   if(!result) {
	       result=color;
	   }
       }
      }
      break;

     default:
      NSLog(@"-[%@ %s] unknown color space %d",isa,SELNAME(_cmd),colorSpace);
      result=[NSColor blackColor];
      break;
    }
    
    return [result retain];
   }

   
   else {
    [NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
    return nil;
   }
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

+(NSColor *)highlightColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"highlightColor"];
}

+(NSColor *)shadowColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"shadowColor"];
}

+(NSColor *)gridColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"gridColor"];
}

+(NSColor *)controlColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlColor"];
}

+(NSColor *)selectedControlColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"selectedControlColor"];
}

+(NSColor *)controlTextColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlTextColor"];
}

+(NSColor *)selectedControlTextColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"selectedControlTextColor"];
}

+(NSColor *)disabledControlTextColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"disabledControlTextColor"];
}

+(NSColor *)controlBackgroundColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlBackgroundColor"];
}

+(NSColor *)controlDarkShadowColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlDarkShadowColor"];
}

+(NSColor *)controlHighlightColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlHighlightColor"];
}

+(NSColor *)controlLightHighlightColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlLightHighlightColor"];
}

+(NSColor *)controlShadowColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"controlShadowColor"];
}

+(NSArray *)controlAlternatingRowBackgroundColors {
   return [NSArray arrayWithObjects:
    [NSColor whiteColor],
    [NSColor whiteColor],
    nil];
}

+(NSColor *)textColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"textColor"];
}

+(NSColor *)textBackgroundColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"textBackgroundColor"];
}

+(NSColor *)selectedTextColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"selectedTextColor"];
}

+(NSColor *)selectedTextBackgroundColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"selectedTextBackgroundColor"];
}

+(NSColor *)headerColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"headerColor"];
}

+(NSColor *)headerTextColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"headerTextColor"];
}

+(NSColor *)scrollBarColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"scrollBarColor"];
}

+(NSColor *)knobColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"knobColor"];
}

+(NSColor *)selectedKnobColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"selectedKnobColor"];
}

+(NSColor *)windowBackgroundColor {
   return [NSColor controlColor];
}

+(NSColor *)menuBackgroundColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"menuBackgroundColor"];
}

+(NSColor *)menuItemTextColor {
   return [NSColor colorWithCatalogName:@"System" colorName:@"menuItemTextColor"];
}

+(NSColor *)clearColor {
   return [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0];
}

+(NSColor *)blackColor {
   return [NSColor_whiteCalibrated blackColor];
}

+(NSColor *)blueColor {
   return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
}

+(NSColor *)brownColor {
   return [NSColor colorWithCalibratedRed:0.6 green:0.4 blue:0.2 alpha:1.0];
}

+(NSColor *)cyanColor {
   return [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:1.0];
}

+(NSColor *)darkGrayColor {
   return [NSColor_whiteCalibrated darkGrayColor];
}

+(NSColor *)grayColor {
   return [NSColor_whiteCalibrated grayColor];
}

+(NSColor *)greenColor {
   return [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0];
}

+(NSColor *)lightGrayColor {
   return [NSColor_whiteCalibrated lightGrayColor];
}

+(NSColor *)magentaColor {
   return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:1.0 alpha:1.0];
}

+(NSColor *)orangeColor {
   return [NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.0 alpha:1.0];
}

+(NSColor *)purpleColor {
   return [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:0.5 alpha:1.0];
}

+(NSColor *)redColor {
   return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
}

+(NSColor *)whiteColor {
   return [NSColor_whiteCalibrated whiteColor];
}

+(NSColor *)yellowColor {
   return [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0];
}

+(NSColor *)colorWithDeviceWhite:(float)white alpha:(float)alpha {
   return [NSColor_whiteDevice colorWithGray:white alpha:alpha];
}

+(NSColor *)colorWithDeviceRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   return [NSColor_rgbDevice colorWithRed:red green:green blue:blue alpha:alpha];
}

+(NSColor *)colorWithDeviceHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha {
   return [NSColor_rgbDevice colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

+(NSColor *)colorWithDeviceCyan:(float)cyan magenta:(float)magenta yellow:(float)yellow black:(float)black alpha:(float)alpha {
   return [NSColor_cmykDevice colorWithCyan:cyan magenta:magenta yellow:yellow black:black alpha:alpha];
}

+(NSColor *)colorWithCalibratedWhite:(float)white alpha:(float)alpha {
   return [NSColor_whiteCalibrated colorWithGray:white alpha:alpha];
}

+(NSColor *)colorWithCalibratedRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   return [NSColor_rgbCalibrated colorWithRed:red green:green blue:blue alpha:alpha];
}

+(NSColor *)colorWithCalibratedHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha {
   return [NSColor_rgbCalibrated colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

+(NSColor *)colorWithCatalogName:(NSString *)catalogName colorName:(NSString *)colorName {
   return [NSColor_catalog colorWithCatalogName:catalogName colorName:colorName];
}

+(NSColor *)colorFromPasteboard:(NSPasteboard *)pasteboard {
   NSData *data=[pasteboard dataForType:NSColorPboardType];

   return [NSUnarchiver unarchiveObjectWithData:data];
}

-(NSString *)colorSpaceName {
   NSInvalidAbstractInvocation();
   return nil;
}

-(void)getWhite:(float *)white alpha:(float *)alpha {
    NSInvalidAbstractInvocation();
}

-(void)getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha {
   NSInvalidAbstractInvocation();
}

-(void)getHue:(float *)hue saturation:(float *)saturation brightness:(float *)brightness alpha:(float *)alpha {
   NSInvalidAbstractInvocation();
}

-(void)getCyan:(float *)cyan magenta:(float *)magenta yellow:(float *)yellow black:(float *)black alpha:(float *)alpha {
    NSInvalidAbstractInvocation();
}

-(float)whiteComponent {
    float white, alpha;

    [self getWhite:&white alpha:&alpha];
    return white;
}

-(float)redComponent {
   float red,green,blue,alpha;

   [self getRed:&red green:&green blue:&blue alpha:&alpha];

   return red;
}

-(float)greenComponent {
   float red,green,blue,alpha;

   [self getRed:&red green:&green blue:&blue alpha:&alpha];

   return green;
}

-(float)blueComponent {
   float red,green,blue,alpha;

   [self getRed:&red green:&green blue:&blue alpha:&alpha];

   return blue;
}

-(float)hueComponent {
   float hue,saturation,brightness,alpha;

   [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

   return hue;
}

-(float)saturationComponent {
   float hue,saturation,brightness,alpha;

   [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

   return saturation;
}

-(float)brightnessComponent {
   float hue,saturation,brightness,alpha;

   [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

   return brightness;
}

-(float)cyanComponent {
    float cyan, magenta, yellow, black, alpha;

    [self getCyan:&cyan magenta:&magenta yellow:&yellow black:&black alpha:&alpha];
    return cyan;
}

-(float)magentaComponent {
    float cyan, magenta, yellow, black, alpha;

    [self getCyan:&cyan magenta:&magenta yellow:&yellow black:&black alpha:&alpha];
    return magenta;
}

-(float)yellowComponent {
    float cyan, magenta, yellow, black, alpha;

    [self getCyan:&cyan magenta:&magenta yellow:&yellow black:&black alpha:&alpha];
    return yellow;
}

-(float)blackComponent {
    float cyan, magenta, yellow, black, alpha;

    [self getCyan:&cyan magenta:&magenta yellow:&yellow black:&black alpha:&alpha];
    return black;
}

-(float)alphaComponent {
    return 1.0;
}

-(NSColor *)colorWithAlphaComponent:(float)alpha {
   if (alpha >= 1.0) return self; 
   return nil; 
}

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace {
    return [self colorUsingColorSpaceName:colorSpace device:nil];
}

-(NSColor *)colorUsingColorSpaceName:(NSString *)colorSpace device:(NSDictionary *)device {
   if([[self colorSpaceName] isEqualToString:colorSpace])
    return self;

   return nil;
}

-(NSColor *)blendedColorWithFraction:(float)fraction ofColor:(NSColor *)color {
   NSColor *primary=[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
   NSColor *secondary=[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

   if(primary==nil || secondary==nil)
    return nil;
   else {
    float pr,pg,pb,pa;
    float sr,sg,sb,sa;
    float rr,rg,rb,ra;

    [primary getRed:&pr green:&pg blue:&pb alpha:&pa];
    [secondary getRed:&sr green:&sg blue:&sb alpha:&sa];

    rr=pr*fraction+sr*(1-fraction);
    rg=pg*fraction+sg*(1-fraction);
    rb=pb*fraction+sb*(1-fraction);
    ra=pa*fraction+sa*(1-fraction);

    return [NSColor colorWithCalibratedRed:rr green:rg blue:rb alpha:ra];
   }
}

-(void)set {
   NSInvalidAbstractInvocation();
}

-(void)drawSwatchInRect:(NSRect)rect {
    [self set];
    NSRectFill(rect);
}

-(void)writeToPasteboard:(NSPasteboard *)pasteboard {
   NSData *data=[NSArchiver archivedDataWithRootObject:self];

   [pasteboard setData:data forType:NSColorPboardType];
}

@end
