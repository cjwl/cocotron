/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSGraphics.h>

@class NSImageRep;

@interface NSImage : NSObject {
   NSString       *_name;
   NSSize          _size;
   NSMutableArray *_representations;
}

+(NSArray *)imageUnfilteredFileTypes;

+imageNamed:(NSString *)name;
-initWithContentsOfFile:(NSString *)path;

-initWithSize:(NSSize)size;

-(NSSize)size;
-(NSArray *)representations;
-(BOOL)isCachedSeparately;

-(BOOL)setName:(NSString *)string;
-(void)addRepresentation:(NSImageRep *)imageRep;
-(void)setScalesWhenResized:(BOOL)flag;
-(void)setCachedSeparately:(BOOL)flag;

-(void)lockFocus;
-(void)unlockFocus;

-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation;
-(void)compositeToPoint:(NSPoint)point operation:(NSCompositingOperation)operation fraction:(float)fraction;

@end

@interface NSBundle(NSImage)
-(NSString *)pathForImageResource:(NSString *)name;
@end
