#import <Foundation/NSObject.h>
#import <Onyx2D/O2Geometry.h>
#import <OpenGL/OpenGL.h>

@class O2Surface,CGWindow;

@interface CGLPixelSurface : NSObject {
   CGWindow  *_window;
   int        _x,_y,_width,_height;
   BOOL       _isOpaque,_validBuffers;
   int        _numberOfBuffers;
   int        _rowsPerBuffer;
   GLuint    *_bufferObjects;
   void     **_readPixels;
   void     **_staticPixels;
   
   O2Surface *_surface;
}

-initWithFrame:(O2Rect)frame;

-(CGWindow *)window;
-(BOOL)isOpaque;
-(O2Rect)frame;

-(void)setWindow:(CGWindow *)window;
-(void)setFrame:(O2Rect)frame;
-(void)setFrameSize:(O2Size)value;

-(void)setOpaque:(BOOL)value;

-(void)readBuffer;
-(O2Surface *)validSurface;

@end

