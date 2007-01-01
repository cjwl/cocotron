/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSBitmapImageRep.h>

@implementation NSImageRep

+(NSArray *)imageUnfilteredFileTypes {
   return [NSArray arrayWithObjects:@"tiff",@"tif",nil];
}

+(NSArray *)imageRepsWithContentsOfFile:(NSString *)path {
   NSString *type=[path pathExtension];

   if([type isEqualToString:@"tif"] || [type isEqualToString:@"tiff"]){
    NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithContentsOfFile:path] autorelease];

    if(bitmap!=nil)
     return [NSArray arrayWithObject:bitmap];
   }

   return nil;
}

-(NSSize)size {
   return _size;
}

-(BOOL)drawAtPoint:(NSPoint)point {
   NSInvalidAbstractInvocation();
   return NO;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@[0x%lx] size: { %f, %f } colorSpace: %@ (%dx%d @ %d bps) alpha: %@ opaque: %@>", 
        [self class], self, _size.width, _size.height, _colorSpaceName, _pixelsWide, _pixelsHigh, _bitsPerSample,
        _hasAlpha ? @"YES" : @"NO", _isOpaque ? @"YES" : @"NO"];
}

@end
