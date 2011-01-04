#import <QuartzCore/CALayerContext.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CARenderer.h>
#import <CoreGraphics/CGLPixelSurface.h>
#import <Foundation/NSString.h>

@interface CALayer(private)
-(void)_setContext:(CALayerContext *)context;
@end

@implementation CALayerContext

-initWithFrame:(CGRect)rect {
   CGLError error;
   
   CGLPixelFormatAttribute attributes[1]={
    0,
   };
   GLint numberOfVirtualScreens;
      
   CGLChoosePixelFormat(attributes,&_pixelFormat,&numberOfVirtualScreens);

   if((error=CGLCreateContext(_pixelFormat,NULL,&_glContext))!=kCGLNoError)
    NSLog(@"CGLCreateContext failed with %d in %s %d",error,__FILE__,__LINE__);

   GLint width=rect.size.width;
   GLint height=rect.size.height;
   
   GLint backingSize[2]={width,height};

   CGLSetParameter(_glContext,kCGLCPSurfaceBackingSize,backingSize);

   _pixelSurface=[[CGLPixelSurface alloc] initWithFrame:O2RectMake(0,0,width,height)];
   [_pixelSurface setOpaque:NO];

   _renderer=[[CARenderer rendererWithCGLContext:_glContext options:nil] retain];
      
   return self;
}

-(void)dealloc {
   [_timer invalidate];
   [_timer release];
   [super dealloc];
}

-(CGLPixelSurface *)pixelSurface {
   return _pixelSurface;
}

-(void)setFrame:(CGRect)rect {
   GLint width=rect.size.width;
   GLint height=rect.size.height;
   
   GLint backingSize[2]={width,height};

   CGLSetParameter(_glContext,kCGLCPSurfaceBackingSize,backingSize);
   
   [_pixelSurface setFrame:rect];
}

-(void)setLayer:(CALayer *)layer {
   layer=[layer retain];
   [_layer release];
   _layer=layer;

   [_layer _setContext:self];
   [_renderer setLayer:layer];
}

-(void)invalidate {
}

-(void)renderLayer:(CALayer *)layer intoSurface:(CGLPixelSurface *)pixelSurface {
   CGLSetCurrentContext(_glContext);

   glEnable(GL_DEPTH_TEST);
   glShadeModel(GL_SMOOTH);

   CGRect frame=[_pixelSurface frame];
   GLint width=frame.size.width;
   GLint height=frame.size.height;
   
   glViewport(0,0,width,height);
   glMatrixMode(GL_PROJECTION);                      
   glLoadIdentity();
   glOrtho (0, width, 0, height, -1, 1);
   
   [_renderer render];
   
   [pixelSurface flushBuffer];
}

-(void)render {
   [self renderLayer:_layer intoSurface:_pixelSurface];
}

-(void)timer:(NSTimer *)timer {
   [_renderer beginFrameAtTime:CACurrentMediaTime() timeStamp:NULL];

   [self render];

   [_renderer endFrame];
}

-(void)startTimerIfNeeded {
   if(_timer==nil)
    _timer=[[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES] retain];
}

@end
