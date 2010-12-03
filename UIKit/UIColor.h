#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIImage;

@interface UIColor : NSObject {
   CGColorRef _cgColor;
}

@property(nonatomic,readonly) CGColorRef CGColor;

+(UIColor *)colorWithCGColor:(CGColorRef)cgColor;
+(UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;
+(UIColor *)colorWithPatternImage:(UIImage *)image;
+(UIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+(UIColor *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;

+(UIColor *)blackColor;
+(UIColor *)blueColor;
+(UIColor *)brownColor;
+(UIColor *)clearColor;
+(UIColor *)cyanColor;
+(UIColor *)darkGrayColor;
+(UIColor *)grayColor;
+(UIColor *)greenColor;
+(UIColor *)lightGrayColor;
+(UIColor *)magentaColor;
+(UIColor *)orangeColor;
+(UIColor *)purpleColor;
+(UIColor *)redColor;
+(UIColor *)whiteColor;
+(UIColor *)yellowColor;

+(UIColor *)lightTextColor;
+(UIColor *)darkTextColor;
+(UIColor *)groupTableViewBackgroundColor;
+(UIColor *)scrollViewTexturedBackgroundColor;
+(UIColor *)viewFlipsideBackgroundColor;

-(UIColor *)initWithCGColor:(CGColorRef)cgColor;
-(UIColor *)initWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;
-(UIColor *)initWithPatternImage:(UIImage *)image;
-(UIColor *)initWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
-(UIColor *)initWithWhite:(CGFloat)white alpha:(CGFloat)alpha;

-(UIColor *)colorWithAlphaComponent:(CGFloat)alpha;

-(void)set;
-(void)setFill;
-(void)setStroke;

@end
