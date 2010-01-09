#import <QuartzCore/CARenderer.h>
#import <OpenGL/OpenGL.h>
#import <CoreGraphics/O2Surface.h>

@implementation CARenderer

@synthesize bounds=_bounds;
@synthesize layer=_rootLayer;

-initWithCGLContext:(void *)cglContext options:(NSDictionary *)options {
   _cglContext=cglContext;
   _bounds=CGRectZero;
   _rootLayer=nil;
   return self;
}

+(CARenderer *)rendererWithCGLContext:(void *)cglContext options:(NSDictionary *)options {
   return [[[self alloc] initWithCGLContext:cglContext options:options] autorelease];
}

-(void)render {
}

-(void)renderWithSurface:(O2Surface *)surface {
   CGLError error;

   if((error=CGLSetCurrentContext(_cglContext))!=kCGLNoError)
    NSLog(@"CGLSetCurrentContext failed with %d in %s %d",error,__FILE__,__LINE__);

// render
   glMatrixMode(GL_MODELVIEW);                                           
   glLoadIdentity();

   glClearColor(0, 0, 0, 0);
   glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
   
   glEnable( GL_TEXTURE_2D );
   glEnableClientState(GL_VERTEX_ARRAY);
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);

   glEnable (GL_BLEND);
   glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

   size_t width=O2ImageGetWidth(surface);
   size_t height=O2ImageGetHeight(surface);

   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, [surface pixelBytes]);

   glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

   GLfloat vertices[4*2];
   GLfloat texture[4*2];
   
   vertices[0]=0;
   vertices[1]=0;
   vertices[2]=width;
   vertices[3]=0;
   vertices[4]=0;
   vertices[5]=height;
   vertices[6]=width;
   vertices[7]=height;
   
   texture[0]=0;
   texture[1]=1;
   texture[2]=1;
   texture[3]=1;
   texture[4]=0;
   texture[5]=0;
   texture[6]=1;
   texture[7]=0;

   glPushMatrix();
 //  glTranslatef(width/2,height/2,0);
   glTexCoordPointer(2, GL_FLOAT, 0, texture);
   glVertexPointer(2, GL_FLOAT, 0, vertices);
 //  glTranslatef(center.x,center.y,0);
 //  glRotatef(1,0,0,1);
   glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
   glPopMatrix();
}

@end
