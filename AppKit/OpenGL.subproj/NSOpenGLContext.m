/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSOpenGLContext.h>
#import <Foundation/NSRaise.h>

@implementation NSOpenGLContext

+(NSOpenGLContext *)currentContext {
   NSUnimplementedMethod();
   return nil;
}

+(void)clearCurrentContext {
   NSUnimplementedMethod();
}

-initWithFormat:(NSOpenGLPixelFormat *)pixelFormat shareContext:(NSOpenGLContext *)shareContext {
   NSUnimplementedMethod();
   return self;
}

-(NSView *)view {
   NSUnimplementedMethod();
   return nil;
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
   NSUnimplementedMethod();
   return NULL;
}

-(void)getValues:(long *)vals forParameter:(NSOpenGLContextParameter)parameter {
   NSUnimplementedMethod();
}

-(void)setValues:(const long *)vals forParameter:(NSOpenGLContextParameter)parameter {
   NSUnimplementedMethod();
}

-(void)setView:(NSView *)view {
   NSUnimplementedMethod();
}

-(void)makeCurrentContext {
   NSUnimplementedMethod();
}

-(int)currentVirtualScreen {
   NSUnimplementedMethod();
}

-(void)setCurrentVirtualScreen:(int)screen {
   NSUnimplementedMethod();
}

-(void)setFullScreen {
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
   NSUnimplementedMethod();
}

-(void)clearDrawable {
   NSUnimplementedMethod();
}

-(void)copyAttributesFromContext:(NSOpenGLContext *)context withMask:(unsigned long)mask {
   NSUnimplementedMethod();
}

-(void)createTexture:(unsigned long)identifier fromView:(NSView *)view internalFormat:(unsigned long)internalFormat {
   NSUnimplementedMethod();
}

-(void)flushBuffer {
   NSUnimplementedMethod();
}

@end
