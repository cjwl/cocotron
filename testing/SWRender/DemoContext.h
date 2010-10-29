#import <Foundation/Foundation.h>

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

-(void)setStrokeColor:(float)r:(float)g:(float)b:(float)a;
-(void)setFillColor:(float)r:(float)g:(float)b:(float)a;
-(void)setBlendMode:(CGBlendMode)mode;
-(void)setShadowBlur:(float)value;
-(void)setShadowOffsetX:(float)value;
-(void)setShadowOffsetY:(float)value;
-(void)setShadowColor:(float)r:(float)g:(float)b:(float)a;
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
-(void)setImageData:(NSData *)data;
-(void)setPDFData:(NSData *)data;

-(void)drawClassic;
-(void)drawBitmapImageRep;
-(void)drawPDF;

@end
