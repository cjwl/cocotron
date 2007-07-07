/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSPDFImageRep.h>

@implementation NSImageRep

static NSMutableArray *_registeredClasses=nil;

+(void)initialize {
   if(self==[NSImageRep class]){
    _registeredClasses=[NSMutableArray new];
    [_registeredClasses addObject:[NSBitmapImageRep class]];
    [_registeredClasses addObject:[NSPDFImageRep class]];
   }
}

+(NSArray *)registeredImageRepClasses {
   return _registeredClasses;
}

+(void)registerImageRepClass:(Class)class {
   [_registeredClasses addObject:class];
}

+(void)unregisterImageRepClass:(Class)class {
   [_registeredClasses removeObjectIdenticalTo:class];
}

+(Class)imageRepClassForFileType:(NSString *)type {
   int count=[_registeredClasses count];
   
   while(--count>=0){
    Class    checkClass=[_registeredClasses objectAtIndex:count];
    NSArray *types=[checkClass imageUnfilteredFileTypes];
    
    if([types containsObject:type])
     return checkClass;
   }
   
   return nil;
}

+(NSArray *)imageUnfilteredFileTypes {
   return nil;
}

+(NSArray *)imageRepsWithContentsOfFile:(NSString *)path {
   NSString *type=[path pathExtension];
   Class     class=[self imageRepClassForFileType:type];
   
   return [class imageRepsWithContentsOfFile:path];
}

-(NSSize)size {
   return _size;
}

-(BOOL)drawAtPoint:(NSPoint)point {
   NSSize size=[self size];
   
   return [self drawInRect:NSMakeRect(point.x,point.y,size.width,size.height)];
}

-(BOOL)drawInRect:(NSRect)rect {
   NSInvalidAbstractInvocation();
   return NO;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] size: { %f, %f } colorSpace: %@ (%dx%d @ %d bps) alpha: %@ opaque: %@>", 
        [self class], self, _size.width, _size.height, _colorSpaceName, _pixelsWide, _pixelsHigh, _bitsPerSample,
        _hasAlpha ? @"YES" : @"NO", _isOpaque ? @"YES" : @"NO"];
}

@end
