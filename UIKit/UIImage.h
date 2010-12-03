#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

typedef enum {
   UIImageOrientationUp=0,
   UIImageOrientationDown=1,
   UIImageOrientationLeft=2,
   UIImageOrientationRight=3,
   UIImageOrientationUpMirrored=4,
   
   UIImageOrientationDownMirrored=5,
   UIImageOrientationLeftMirrored=6,
   UIImageOrientationRightMirrored=7,
} UIImageOrientation;

@interface UIImage : NSObject {
   CGImageRef _cgImage;
   UIImageOrientation _orientation;
   CGSize    _size;
   CGFloat   _scale;
   NSInteger _leftCapWidth;
   NSInteger _topCapHeight;
}

@property(nonatomic,readonly) CGImageRef CGImage;
@property(nonatomic,readonly) UIImageOrientation imageOrientation;
@property(nonatomic,readonly) CGSize size;
@property(nonatomic,readonly) CGFloat scale;
@property(nonatomic,readonly) NSInteger leftCapWidth;
@property(nonatomic,readonly) NSInteger topCapHeight;

+(UIImage *)imageNamed:(NSString *)name;
+(UIImage *)imageWithCGImage:(CGImageRef)cgImage;
+(UIImage *)imageWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
+(UIImage *)imageWithContentsOfFile:(NSString *)path;
+(UIImage *)imageWithData:(NSData *)data;

-(void)drawAsPatternInRect:(CGRect)rect;
-(void)drawAtPoint:(CGPoint)point;
-(void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha;
-(void)drawInRect:(CGRect)rect;
-(void)drawInRect:(CGRect)rect blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha;
-initWithCGImage:(CGImageRef)cgImage;
-initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
-initWithContentsOfFile:(NSString *)path;
-initWithData:(NSData *)data;
-(UIImage *)stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight;

@end
