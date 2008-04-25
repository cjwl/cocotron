#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

@interface DemoContext : NSObject

@end

@interface DemoContext(subclass)

-(size_t)pixelsWide;
-(size_t)pixelsHigh;
-(size_t)bitsPerComponent;
-(size_t)bitsPerPixel;
-(size_t)bytesPerRow;
-(CGBitmapInfo)bitmapInfo;
-(void *)bytes;

-(void)setStrokeColor:(NSColor *)color;
-(void)setFillColor:(NSColor *)color;
-(void)setBlendMode:(CGBlendMode)mode;
-(void)setShadowBlur:(float)value;
-(void)setShadowOffsetX:(float)value;
-(void)setShadowOffsetY:(float)value;
-(void)setShadowColor:(NSColor *)color;
-(void)setPathDrawingMode:(CGPathDrawingMode)mode;
-(void)setLineWidth:(float)width;
-(void)setDashPhase:(float)phase;
-(void)setDashLength:(float)value;
-(void)setFlatness:(float)value;
-(void)setScaleX:(float)value;
-(void)setScaleY:(float)value;
-(void)setRotation:(float)value;
-(void)setShouldAntialias:(BOOL)value;
-(void)setInterpolationQuality:(CGInterpolationQuality)value;

-(void)drawClassic;
-(void)drawBitmapImageRep;


@end
