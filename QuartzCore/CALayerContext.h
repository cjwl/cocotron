#import <Foundation/NSObject.h>
#import <OpenGL/OpenGL.h>
#import <CoreGraphics/CGGeometry.h>

@class CARenderer,CALayer,CGLPixelSurface,NSTimer,NSMutableArray,NSNumber;

@interface CALayerContext : NSObject {
   CGLPixelFormatObj _pixelFormat;
   CGLContextObj     _glContext;
   CGLPixelSurface  *_pixelSurface;
   CALayer          *_layer;
   CARenderer       *_renderer;
   
   NSMutableArray   *_deleteTextureIds;
   
   NSTimer          *_timer;
}

-initWithFrame:(CGRect)rect;

-(CGLPixelSurface *)pixelSurface;
-(void)setFrame:(CGRect)value;
-(void)setLayer:(CALayer *)layer;

-(void)invalidate;

-(void)render;

-(void)startTimerIfNeeded;

-(void)deleteTextureId:(NSNumber *)textureId;

@end
