/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSOpenGLContext.h>
#import <AppKit/NSOpenGLPixelFormat.h>
#import <AppKit/NSOpenGLDrawable.h>
#import <AppKit/NSRaise.h>
#import <OpenGL/OpenGL.h>
#import <Foundation/NSThread-Private.h>

@interface NSOpenGLContext(private)
-(void)_clearCurrentContext;
@end

@implementation NSOpenGLContext

static inline NSOpenGLContext *_currentContext(){
   return (NSOpenGLContext *)NSThreadSharedInstanceDoNotCreate(@"NSOpenGLContext");
}

static void _setCurrentContext(NSOpenGLContext *context){
   [NSCurrentThread() setSharedObject:context forClassName:@"NSOpenGLContext"];
}

static inline void _clearCurrentContext(){
   [_currentContext() _clearCurrentContext];
   _setCurrentContext(nil);
}

+(NSOpenGLContext *)currentContext {
   return _currentContext();
}

+(void)clearCurrentContext {
   _clearCurrentContext();
}

-initWithFormat:(NSOpenGLPixelFormat *)pixelFormat shareContext:(NSOpenGLContext *)shareContext {
   _pixelFormat=[pixelFormat retain];
   return self;
}

-(void)dealloc {
// FIXME: this doesn't actually work because if we are the current context we're retained by the thread shared object dict
   if(_currentContext()==self)
      _clearCurrentContext();
   [_pixelFormat release];
   _view=nil;
   [_drawable invalidate];
   [_drawable release];
   CGLDestroyContext(_glContext);
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

-(void)_createContextIfNeeded {
   if(_drawable==nil){
    _drawable=[[NSOpenGLDrawable alloc] initWithPixelFormat:_pixelFormat view:_view];
      
    if((_glContext=[_drawable createGLContext])==NULL){
     NSLog(@"unable to create _glContext");
     return;
    }
   }
}

-(void *)CGLContextObj {
   [self _createContextIfNeeded];
   return _glContext;
}

-(void)getValues:(long *)vals forParameter:(NSOpenGLContextParameter)parameter {   
   CGLGetParameter([self CGLContextObj],parameter,(GLint *)&vals);
}

-(void)setValues:(const long *)vals forParameter:(NSOpenGLContextParameter)parameter {   
   CGLSetParameter([self CGLContextObj],parameter,(const GLint *)vals);
}

-(void)setView:(NSView *)view {
   _view=view;
}

-(void)makeCurrentContext {
   [self _createContextIfNeeded];
   [_drawable makeCurrentWithGLContext:_glContext];
   _setCurrentContext(self);
}

-(void)_clearCurrentContext {
  if (_drawable!=nil)
    [_drawable clearCurrentWithGLContext:_glContext];
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
