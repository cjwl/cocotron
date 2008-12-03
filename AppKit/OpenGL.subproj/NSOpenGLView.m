/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSOpenGLView.h>
#import <AppKit/NSOpenGLContext.h>
#import <AppKit/NSOpenGLPixelFormat.h>
#import <Foundation/NSRaise.h>
#import <AppKit/NSNibKeyedUnarchiver.h>

@implementation NSOpenGLView

+(NSOpenGLPixelFormat *)defaultPixelFormat {
   NSOpenGLPixelFormatAttribute attributes[]={
   
    0
   };
      
   return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

-initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)pixelFormat {
   [super initWithFrame:frame];
   _pixelFormat=[pixelFormat retain];
   _context=nil;
   return self;
}

-initWithFrame:(NSRect)frame  {
   [super initWithFrame:frame];
   _pixelFormat=[isa defaultPixelFormat];
   _context=nil;
   return self;
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];
   
   if([coder allowsKeyedCoding])
    _pixelFormat=[[coder decodeObjectForKey:@"NSPixelFormat"] retain];
   else
    NSUnimplementedMethod();
    
   return self;
}


-(void)dealloc {
   [_pixelFormat release];
   [_context release];
   [super dealloc];
}

-(NSOpenGLPixelFormat *)pixelFormat {
   return _pixelFormat;
}

-(NSOpenGLContext *)openGLContext {
   if(_context==nil){
    _context=[[NSOpenGLContext alloc] initWithFormat:_pixelFormat shareContext:nil];
    [_context setView:self];
    _needsPrepare=YES;
   }
   
   return _context;
}

-(void)setPixelFormat:(NSOpenGLPixelFormat *)pixelFormat {
   pixelFormat=[pixelFormat retain];
   [_pixelFormat release];
   _pixelFormat=pixelFormat;
}

-(void)setOpenGLContext:(NSOpenGLContext *)context {
   [_context clearDrawable];
   context=[context retain];
   [_context release];
   _context=context;
   [_context setView:self];
}

-(void)update {
// we don't want to create the context if it doesn't exist
   [_context update];
}

-(void)reshape {
// do nothing
}

-(void)prepareOpenGL {
// do nothing
}

-(BOOL)isOpaque {
   return YES;
}

-(void)lockFocus {  
   [super lockFocus];
   
   [[self openGLContext] makeCurrentContext];
   if(_needsPrepare){
    [self prepareOpenGL];
    _needsPrepare=NO;
   }
   if(_needsReshape)
    [self reshape];
}

-(void)unlockFocus {
   [[self openGLContext] flushBuffer];
   [super unlockFocus];
}

-(void)clearGLContext {
   [_context clearDrawable];
   [_context release];
   _context=nil;
}

-(void)setFrame:(NSRect)frame {
   [super setFrame:frame];
   _needsReshape=YES;
   [self update];
}

@end
