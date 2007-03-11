/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/NSView.h>
#import <AppKit/CoreGraphics.h>
#import <AppKit/CGColorSpace.h>
#import <AppKit/NSTIFFReader.h>

@implementation NSBitmapImageRep

-initWithData:(NSData *)data {
   NSTIFFReader  *reader=[[NSTIFFReader alloc] initWithData:data];
   int            width=[reader pixelsWide];
   int            height=[reader pixelsHigh];
   int            npixels=width*height;
   unsigned char *bytes;
   
   if(reader==nil){
    [self dealloc];
    return nil;
   }

   npixels=width*height;
   bytes=NSZoneMalloc([self zone],(npixels*4*sizeof(unsigned char)));
   if(![reader getRGBAImageBytes:bytes width:width height:height]){
    [reader release];
    NSZoneFree([self zone],bytes);
    [self dealloc];
    return nil;
   }

   _size.width=width;
   _size.height=height;

   _bitsPerPixel=32;
   _bytesPerRow=_bitsPerPixel/sizeof(char)*width;

   _bitmap=[[NSData alloc] initWithBytesNoCopy:bytes length:_bytesPerRow*_size.height];

   [reader release];    

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
   [_bitmap release];
   [super dealloc];
}

+imageRepWithData:(NSData *)data {
   return [[[self alloc] initWithData:data] autorelease];
}

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation fraction:(float)fraction {
   CGContextRef      context=NSCurrentGraphicsPort();
   CGDataProviderRef provider=CGDataProviderCreateWithCFData(_bitmap);
   CGColorSpaceRef   colorSpace=CGColorSpaceCreateDeviceRGB();
   CGImageRef        image=CGImageCreate(_size.width,_size.height,8,_bitsPerPixel,_bytesPerRow,
      colorSpace,0/*kCGImageAlphaLast|kCGBitmapByteOrder32Little*/,provider,NULL,NO,kCGRenderingIntentDefault);
   
   CGContextSaveGState(context);
   CGContextSetAlpha(context,fraction);
   CGContextDrawImage(context,NSMakeRect(point.x,point.y,_size.width,_size.height),image);
   CGContextRestoreGState(context);
   
   CGImageRelease(image);
   CGColorSpaceRelease(colorSpace);
   CGDataProviderRelease(provider);
}

@end
