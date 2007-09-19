/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSView.h>
#import <AppKit/CoreGraphics.h>
#import <AppKit/KGImageSource.h>
#import <AppKit/KGImage.h>

@implementation NSBitmapImageRep

+(NSArray *)imageUnfilteredFileTypes {
   return [NSArray arrayWithObjects:@"tiff",@"tif",@"png",@"jpg",@"bmp",nil];
}

+(NSArray *)imageRepsWithContentsOfFile:(NSString *)path {
   NSMutableArray *result=[NSMutableArray array];
   
   [result addObject:[[[NSBitmapImageRep alloc] initWithContentsOfFile:path] autorelease]];
   
   return result;
}

-initWithData:(NSData *)data {
   KGImageSource *imageSource=[KGImageSource newImageSourceWithData:data options:nil];
   
   _image=[imageSource imageAtIndex:0 options:nil];
   _size.width=CGImageGetWidth(_image);
   _size.height=CGImageGetHeight(_image);
   
   [imageSource release];
   return self;
}

-initWithContentsOfFile:(NSString *)path {
   NSData *data=[NSData dataWithContentsOfFile:path];
   
   if(data==nil){
    [self dealloc];
    return nil;
   }
   
   return [self initWithData:data];
}

-(void)dealloc {
   [_image release];
   [super dealloc];
}

+imageRepWithData:(NSData *)data {
   return [[[self alloc] initWithData:data] autorelease];
}

-(BOOL)drawInRect:(NSRect)rect {
   CGContextRef context=NSCurrentGraphicsPort();
   
   CGContextSaveGState(context);
   CGContextDrawImage(context,rect,_image);
   CGContextRestoreGState(context);
}

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation fraction:(float)fraction {
   CGContextRef context=NSCurrentGraphicsPort();
   
   CGContextSaveGState(context);
   CGContextSetAlpha(context,fraction);
   CGContextDrawImage(context,NSMakeRect(point.x,point.y,_size.width,_size.height),_image);
   CGContextRestoreGState(context);
}

@end
