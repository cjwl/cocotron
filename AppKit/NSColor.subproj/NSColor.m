/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSColor-Private.h>
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

@interface NSDisplay(revelation)
-(void) _addSystemColor: (NSColor *) color forName: (NSString *) name;
@end

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
      NSLog(@"-[%@ %s] unknown color space %d",isa,sel_getName(_cmd),colorSpace);
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

+(NSColor *)alternateSelectedControlColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"alternateSelectedControlColor"];
}

+(NSColor *)alternateSelectedControlTextColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"alternateSelectedControlTextColor"];
}

+ (NSColor *)keyboardFocusIndicatorColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"keyboardFocusIndicatorColor"];
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

+(NSColor *)secondarySelectedControlColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"secondarySelectedControlColor"];
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
    [NSColor controlBackgroundColor],
    [NSColor controlHighlightColor], // FIXME:
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

+(NSColor *)windowFrameColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"windowFrameColor"];
}

+ (NSColor *)selectedMenuItemColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"selectedMenuItemColor"];
}

+ (NSColor *)selectedMenuItemTextColor {
    return [NSColor colorWithCatalogName:@"System" colorName:@"selectedMenuItemTextColor"];
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

+(NSColor *)colorWithPatternImage:(NSImage *)image
{
   NSUnimplementedMethod();
   return [self lightGrayColor];
}

-(NSString *)colorSpaceName {
   NSInvalidAbstractInvocation();
   return nil;
}

-(NSInteger)numberOfComponents {
   CGColorRef colorRef=[self createCGColorRef]; 
   NSInteger result=CGColorGetNumberOfComponents(colorRef);
   CGColorRelease(colorRef);
   return result;
}

-(void)getComponents:(CGFloat *)components {
   CGColorRef colorRef=[self createCGColorRef];
   NSInteger  i,count=CGColorGetNumberOfComponents(colorRef);
   const CGFloat *comps=CGColorGetComponents(colorRef);
   
   for(i=0;i<count;i++)
    components[i]=comps[i];
    
   CGColorRelease(colorRef);
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
    float white;

    [self getWhite:&white alpha:NULL];
    return white;
}

-(float)redComponent {
   float red;

   [self getRed:&red green:NULL blue:NULL alpha:NULL];

   return red;
}

-(float)greenComponent {
   float green;

   [self getRed:NULL green:&green blue:NULL alpha:NULL];

   return green;
}

-(float)blueComponent {
   float blue;

   [self getRed:NULL green:NULL blue:&blue alpha:NULL];

   return blue;
}

-(float)hueComponent {
   float hue;

   [self getHue:&hue saturation:NULL brightness:NULL alpha:NULL];

   return hue;
}

-(float)saturationComponent {
   float saturation;

   [self getHue:NULL saturation:&saturation brightness:NULL alpha:NULL];

   return saturation;
}

-(float)brightnessComponent {
   float brightness;

   [self getHue:NULL saturation:NULL brightness:&brightness alpha:NULL];

   return brightness;
}

-(float)cyanComponent {
    float cyan;

    [self getCyan:&cyan magenta:NULL yellow:NULL black:NULL alpha:NULL];
    return cyan;
}

-(float)magentaComponent {
    float magenta;

    [self getCyan:NULL magenta:&magenta yellow:NULL black:NULL alpha:NULL];
    return magenta;
}

-(float)yellowComponent {
    float yellow;

    [self getCyan:NULL magenta:NULL yellow:&yellow black:NULL alpha:NULL];
    return yellow;
}

-(float)blackComponent {
    float black;

    [self getCyan:NULL magenta:NULL yellow:NULL black:&black alpha:NULL];
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

   //NSLog(@"Warning, ignoring differences between color space %@ and %@", colorSpace, [self colorSpaceName]);
   return self;
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
    [self setStroke];
    [self setFill];
}

-(void)setFill {
    NSInvalidAbstractInvocation();
}

-(void)setStroke {
    NSInvalidAbstractInvocation();
}

-(void)drawSwatchInRect:(NSRect)rect {
    [self setFill];
    NSRectFill(rect);
}

-(void)writeToPasteboard:(NSPasteboard *)pasteboard {
   NSData *data=[NSArchiver archivedDataWithRootObject:self];

   [pasteboard setData:data forType:NSColorPboardType];
}

@end
