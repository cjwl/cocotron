/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSOpenGLContext.h>
#import <AppKit/NSOpenGLPixelFormat.h>
#import <AppKit/NSOpenGLDrawable.h>
#import <Foundation/NSRaise.h>

static NSOpenGLContext *currentContext=nil;

// Platform must define this function
void CGLContextDelete(void *glContext);

@implementation NSOpenGLContext

+(NSOpenGLContext *)currentContext {
   return currentContext;
}

+(void)clearCurrentContext {
   currentContext=nil;
}

-initWithFormat:(NSOpenGLPixelFormat *)pixelFormat shareContext:(NSOpenGLContext *)shareContext {
   _pixelFormat=[pixelFormat retain];
   return self;
}

-(void)dealloc {
   if(currentContext==self)
      currentContext=nil;
   [_pixelFormat release];
   _view=nil;
   [_drawable invalidate];
   [_drawable release];
   CGLContextDelete(_glContext);
   [super dealloc];
}

-(NSView *)view {
   return _view;
}

-(NSOpenGLPixelBuffer *)pixelBuffer {
   NSUnimplementedMethod();
   return nil;
}

-(unsigned long)pixelBufferCubeMapFace {
   NSUnimplementedMethod();
   return 0;
}

-(long)pixelBufferMipMapLevel {
   NSUnimplementedMethod();
   return 0;
}

-(void *)CGLContextObj {
   return _glContext;
}

-(void)getValues:(long *)vals forParameter:(NSOpenGLContextParameter)parameter {
   NSUnimplementedMethod();
}

-(void)setValues:(const long *)vals forParameter:(NSOpenGLContextParameter)parameter {
   NSUnimplementedMethod();
}

-(void)setView:(NSView *)view {
   _view=view;
}

-(void)makeCurrentContext {
   if(_drawable==nil){
    _drawable=[[NSOpenGLDrawable alloc] initWithPixelFormat:_pixelFormat view:_view];
      
    if((_glContext=[_drawable createGLContext])==NULL){
     NSLog(@"unable to create _glContext");
     return;
    }
   }
   [_drawable makeCurrentWithGLContext:_glContext];
   currentContext=self;
}

-(int)currentVirtualScreen {
   NSUnimplementedMethod();
   return 0;
}

-(void)setCurrentVirtualScreen:(int)screen {
   NSUnimplementedMethod();
}

-(void)setFullScreen {
   if(_view!=nil)
    NSLog(@"NSOpenGLContext has view, full-screen not allowed");
    
   NSUnimplementedMethod();
}

-(void)setOffscreen:(void *)bytes width:(long)width height:(long)height rowbytes:(long)rowbytes {
   NSUnimplementedMethod();
}

-(void)setPixelBuffer:(NSOpenGLPixelBuffer *)pixelBuffer cubeMapFace:(unsigned long)cubeMapFace mipMapLeve:(long)mipMapLevel currentVirtualScreen:(int)screen {
   NSUnimplementedMethod();
}

-(void)setTextureImageToPixelBuffer:(NSOpenGLPixelBuffer *)pixelBuffer colorBuffer:(unsigned long)source {
   NSUnimplementedMethod();
}

-(void)update {
   [_drawable updateWithView:_view];
}

-(void)clearDrawable {
   _view=nil;
   [_drawable invalidate];
   [_drawable release];
   _drawable=nil;
}

-(void)copyAttributesFromContext:(NSOpenGLContext *)context withMask:(unsigned long)mask {
   NSUnimplementedMethod();
}

-(void)createTexture:(unsigned long)identifier fromView:(NSView *)view internalFormat:(unsigned long)internalFormat {
   NSUnimplementedMethod();
}

-(void)flushBuffer {
   // fix, check if doublebuffered
   [_drawable swapBuffers];
}

@end
