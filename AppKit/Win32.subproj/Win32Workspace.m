/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/Win32Workspace.h>
#import <Foundation/NSString_win32.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <windows.h>
#import <shellapi.h>

@implementation Win32Workspace

-(BOOL)openURL:(NSURL *)url 
{
	return ((int)ShellExecute(GetDesktopWindow(),"open",[[url 
absoluteString] cString],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

-(BOOL)openFile:(NSString *)path {
   return ((int)ShellExecute(GetDesktopWindow(),"open",[path fileSystemRepresentation],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

-(BOOL)openFile:(NSString *)path withApplication:(NSString *)appName {
#if 1
   NSBundle *bundle=[NSBundle bundleForClass:isa];
   NSString *bundlePath=[bundle bundlePath];
   NSString *app=[[[[[[[bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Applications"] stringByAppendingPathComponent:appName] stringByAppendingPathExtension:@"app"] stringByAppendingPathComponent:appName] stringByAppendingPathExtension:@"exe"];
   NSMutableData *args=[NSMutableData data];

   [args appendData:NSTaskArgumentDataFromString(@"-NSOpen")];
   [args appendBytes:" " length:1];
   [args appendData:NSTaskArgumentDataFromString(path)];
   [args appendBytes:"\0" length:1];

   return ((int)ShellExecute(GetDesktopWindow(),"open",[app fileSystemRepresentation],[args bytes],NULL,SW_SHOWNORMAL)<=32)?NO:YES;
#else
   return ((int)ShellExecute(GetDesktopWindow(),"open",[path fileSystemRepresentation],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
#endif
}

-(BOOL)openTempFile:(NSString *)path {
   return ((int)ShellExecute(GetDesktopWindow(),"open",[path fileSystemRepresentation],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

-(BOOL)selectFile:(NSString *)path inFileViewerRootedAtPath:(NSString *)rootFullpath {
   NSMutableData *args=[NSMutableData data];
   [args appendBytes:"/select," length:8];
   [args appendData:NSTaskArgumentDataFromString(path)];
   [args appendBytes:"\0" length:1];
   return ((int)ShellExecute(GetDesktopWindow(),"open","explorer",[args bytes],NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

-(int)extendPowerOffBy:(int)seconds {
   NSUnimplementedMethod ();
   return 0;
}

-(void)slideImage:(NSImage *)image from:(NSPoint)fromPoint to:(NSPoint)toPoint {
   NSUnimplementedMethod();
}

static NSImageRep *imageRepForIcon(SHFILEINFO * fileInfo) {
   NSBitmapImageRep *bitmap;
   ICONINFO iconInfo;
   BITMAP bmp;
   size_t masklen;
   unsigned char *mask;
   size_t pixelslen;
   unsigned char *pixels;
   int i, x, y, bit, hasAlpha;

   GetIconInfo(fileInfo->hIcon, &iconInfo);

   GetObject(iconInfo.hbmMask, sizeof(BITMAP), (void *) &bmp);
   masklen = bmp.bmWidth * bmp.bmHeight * bmp.bmBitsPixel / 8;
   mask = malloc(masklen);
   GetBitmapBits(iconInfo.hbmMask, masklen, mask);

   GetObject(iconInfo.hbmColor, sizeof(BITMAP), (void *) &bmp);
   pixelslen = bmp.bmWidth * bmp.bmHeight * bmp.bmBitsPixel / 8;
   pixels = malloc(pixelslen);
   GetBitmapBits(iconInfo.hbmColor, pixelslen, pixels);

   hasAlpha = 0;
   for (i = 0; i < pixelslen; i+=4) {
    if (pixels[i+3]) {
     hasAlpha = 1;
     break;
    }
   }

#define BIT_SET(x,y) (((x) >> (7-(y))) & 1)

   if (!hasAlpha) {
    for (i = 0; i < masklen; i++) {
     for (bit = 0; bit < 8; bit++) {
      if (BIT_SET(mask[i], bit)) {
       pixels[(i*8+bit)*4+3] = 0;
      } else {
       pixels[(i*8+bit)*4+3] = 255;
      }
     }
    }
   }

   bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
    pixelsWide:bmp.bmWidth
    pixelsHigh:bmp.bmHeight
    bitsPerSample:8
    samplesPerPixel:4
    hasAlpha:YES
    isPlanar:NO
    colorSpaceName:NSCalibratedRGBColorSpace
    bytesPerRow:bmp.bmWidth*4
    bitsPerPixel:32] autorelease];

   for (y = 0; y < bmp.bmHeight; y++)
   {
    for (x = 0; x < bmp.bmWidth; x++)
    {
     float b = (float) pixels[4*(y*bmp.bmWidth + x)+0] / 255.0f;
     float g = (float) pixels[4*(y*bmp.bmWidth + x)+1] / 255.0f;
     float r = (float) pixels[4*(y*bmp.bmWidth + x)+2] / 255.0f;
     float a = (float) pixels[4*(y*bmp.bmWidth + x)+3] / 255.0f;
     NSColor *color = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
     [bitmap setColor:color atX:x y:y];
    }
   }

   free(mask);
   free(pixels);
   DeleteObject(iconInfo.hbmMask);
   DeleteObject(iconInfo.hbmColor);

   return bitmap;
}

-(NSImage *)iconForFile:(NSString *)path {
   const char *pathCString=[path fileSystemRepresentation];
   SHFILEINFO fileInfo;

   NSImage *icon=[[[NSImage alloc] init] autorelease];

   if(SHGetFileInfo(pathCString,0,&fileInfo,sizeof(SHFILEINFO),SHGFI_ICON|SHGFI_SMALLICON))
    [icon addRepresentation:imageRepForIcon(&fileInfo)];
   if(SHGetFileInfo(pathCString,0,&fileInfo,sizeof(SHFILEINFO),SHGFI_ICON|SHGFI_LARGEICON))
    [icon addRepresentation:imageRepForIcon(&fileInfo)];

   if([[icon representations] count]==0)
    return nil;
   
   return icon;
}

@end
