/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2DeviceContext_gdiDIBSection.h>
#import <Onyx2D/O2Context_gdi.h>

@implementation O2DeviceContext_gdiDIBSection

-initWithWidth:(size_t)width height:(size_t)height deviceContext:(O2DeviceContext_gdi *)compatible bitsPerPixel:(int)bpp {
   HDC compatibleDC=(compatible!=nil)?[compatible dc]:GetDC(NULL);
   
   [self initWithDC:CreateCompatibleDC(compatibleDC)];
    _compatible=[compatible retain];

    struct {
     BITMAPV4HEADER bitmapInfo;
     RGBQUAD        colors[256+3];
    } dibInfo;
    HBITMAP    probe=CreateCompatibleBitmap(compatibleDC,1,1);

    memset(&dibInfo,0,sizeof(dibInfo));
    dibInfo.bitmapInfo.bV4Size=sizeof(BITMAPV4HEADER);

    if(!GetDIBits(compatibleDC,probe,0,1,NULL,(BITMAPINFO *)&dibInfo,DIB_RGB_COLORS))
     NSLog(@"GetDIBits failed");
    if(!GetDIBits(compatibleDC,probe,0,1,NULL,(BITMAPINFO *)&dibInfo,DIB_RGB_COLORS))
     NSLog(@"GetDIBits failed");
    
    if((_bitsPerPixel=bpp)==0)
     _bitsPerPixel=dibInfo.bitmapInfo.bV4BitCount;

    _bitsPerComponent=8;
    _bytesPerRow=4*width;
    
    DeleteObject(probe);

    dibInfo.bitmapInfo.bV4Width=width;
    dibInfo.bitmapInfo.bV4Height=-(int)height;
    dibInfo.bitmapInfo.bV4BitCount=32;
    dibInfo.bitmapInfo.bV4V4Compression=BI_RGB;

    _bitmap=CreateDIBSection(compatibleDC,(BITMAPINFO *)&dibInfo,DIB_RGB_COLORS,&_bits,NULL,0);

   SelectObject(_dc,_bitmap);

   if(_compatible==nil)
    ReleaseDC(NULL,compatibleDC);
    
   return self;
}

-initARGB32WithWidth:(size_t)width height:(size_t)height deviceContext:(O2DeviceContext_gdi *)compatible {
   return [self initWithWidth:width height:height deviceContext:compatible bitsPerPixel:0];
}

-initGray8WithWidth:(size_t)width height:(size_t)height deviceContext:(O2DeviceContext_gdi *)compatible {
   HDC compatibleDC=(compatible!=nil)?[compatible dc]:GetDC(NULL);
   
   [self initWithDC:CreateCompatibleDC(compatibleDC)];
   _compatible=[compatible retain];
   _bitsPerPixel=8;
   _bitsPerComponent=8;
   _bytesPerRow=width;

   struct {
    BITMAPV4HEADER bitmapInfo;
    RGBQUAD        colors[256+3];
   } dibInfo;

   memset(&dibInfo,0,sizeof(dibInfo));

   dibInfo.bitmapInfo.bV4Size=sizeof(BITMAPV4HEADER);
   dibInfo.bitmapInfo.bV4Width=width;
   dibInfo.bitmapInfo.bV4Height=-(int)height;
   dibInfo.bitmapInfo.bV4Planes=1;
   dibInfo.bitmapInfo.bV4BitCount=8;
   dibInfo.bitmapInfo.bV4V4Compression=BI_RGB;
   int i;
   for(i=0;i<256;i++){
    dibInfo.colors[i].rgbRed=i;
    dibInfo.colors[i].rgbGreen=i;
    dibInfo.colors[i].rgbBlue=i;
   }
   
   _bitmap=CreateDIBSection(compatibleDC,(BITMAPINFO *)&dibInfo,DIB_RGB_COLORS,&_bits,NULL,0);

   SelectObject(_dc,_bitmap);

   if(_compatible==nil)
    ReleaseDC(NULL,compatibleDC);
    
   return self;
}

-(void)dealloc {
   [_compatible release];
   DeleteObject(_bitmap);
   DeleteDC(_dc);
   [super dealloc];
}

-(void *)bitmapBytes {
   return _bits;
}

-(size_t)bitsPerComponent {
   return _bitsPerComponent;
}

-(size_t)bytesPerRow {
   return _bytesPerRow;
}

-(int)bitsPerPixel {
   return _bitsPerPixel;
}

-(Win32DeviceContextWindow *)windowDeviceContext {
   return [_compatible windowDeviceContext];
}

@end
