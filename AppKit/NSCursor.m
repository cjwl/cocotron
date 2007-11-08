/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSCursor.h>
#import <AppKit/NSDisplay.h>
#import <AppKit/NSImage.h>
#import <Foundation/NSNull.h>

@implementation NSCursor

+(NSCursor *)currentCursor {
   NSUnimplementedMethod();
   return 0;
}

-initWithCoder:(NSCoder *)coder {
   [self dealloc];
   return [NSNull null];
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithName:(NSString *)name {
   _cursor=[[[NSDisplay currentDisplay] cursorWithName:name] retain];
   return self;
}

+(NSCursor *)arrowCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)closedHandCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)crosshairCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)disappearingItemCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)IBeamCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)openHandCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)pointingHandCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)resizeDownCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)resizeLeftCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)resizeLeftRightCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)resizeRightCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)resizeUpCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(NSCursor *)resizeUpDownCursor {
   static NSCursor *shared=nil;

   if(shared==nil)
    shared=[[self alloc] initWithName:NSStringFromSelector(_cmd)];

   return shared;
}

+(void)hide {
   [[NSDisplay currentDisplay] hideCursor];
}

+(void)unhide {
   [[NSDisplay currentDisplay] unhideCursor];
}

+(void)setHiddenUntilMouseMoves:(BOOL)flag {
   if(flag)
    [self hide];
   else
    [self unhide];
}

-initWithImage:(NSImage *)image foregroundColorHint:(NSColor *)foregroundHint backgroundColorHint:(NSColor *)backgroundHint hotSpot:(NSPoint)hotSpot {
   NSUnimplementedMethod();
   return nil;
}

-initWithImage:(NSImage *)image hotSpot:(NSPoint)hotSpot {
   _image=[image retain];
   _hotSpot=hotSpot;
   return self;
}

-(void)dealloc {
   [_image release];
   [super dealloc];
}

-(NSImage *)image {
   return _image;
}

-(NSPoint)hotSpot {
   return _hotSpot;
}

-(BOOL)isSetOnMouseEntered {
   return _isSetOnMouseEntered;
}

-(BOOL)isSetOnMouseExited {
   return _isSetOnMouseExited;
}

-(void)setOnMouseEntered:(BOOL)value {
   _isSetOnMouseEntered=value;
}

-(void)setOnMouseExited:(BOOL)value {
   _isSetOnMouseExited=value;
}

-(void)mouseEntered:(NSEvent *)event {
   NSUnimplementedMethod();
}

-(void)mouseExited:(NSEvent *)event {
   NSUnimplementedMethod();
}

-(void)pop {
   NSUnimplementedMethod();
}

-(void)set {
   [[NSDisplay currentDisplay] setCursor:_cursor];
}

-(void)push {
   NSUnimplementedMethod();
}

+(void)pop {
   NSUnimplementedMethod();
}

@end
