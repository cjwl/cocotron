#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIFont : NSObject {
}

@property(nonatomic,readonly,retain) NSString *fontName;
@property(nonatomic,readonly,retain) NSString *familyName;
@property(nonatomic,readonly) CGFloat pointSize;
@property(nonatomic,readonly) CGFloat ascender;
@property(nonatomic,readonly) CGFloat descender;
@property(nonatomic,readonly) CGFloat lineHeight;
@property(nonatomic,readonly) CGFloat capHeight;
@property(nonatomic,readonly) CGFloat xHeight;

+(NSArray *)familyNames;
+(NSArray *)fontNamesForFamilyName:(NSString *)familyName;

+(UIFont *)fontWithName:(NSString *)name size:(CGFloat)pointSize;

+(UIFont *)boldSystemFontOfSize:(CGFloat)pointSize;

+(UIFont *)italicSystemFontOfSize:(CGFloat)pointSize;

+(CGFloat)buttonFontSize;
+(CGFloat)labelFontSize;
+(CGFloat)smallSystemFontSize;
+(UIFont *)systemFontOfSize:(CGFloat)pointSize;
+(CGFloat)systemFontSize;

-(UIFont *)fontWithSize:(CGFloat)pointSize;

@end
