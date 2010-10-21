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
#import <AppKit/NSRaise.h>

@implementation NSWorkspace(windows)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([Win32Workspace class],0,NULL);
}

@end

@implementation Win32Workspace

-(NSArray *)mountedLocalVolumePaths {
   NSMutableArray *result=[NSMutableArray array];
   DWORD           driveMask=GetLogicalDrives();
   unichar         drive='A';
   
   for(;driveMask!=0;driveMask>>=1,drive++){
    if(driveMask&0x1)
     [result addObject:[NSString stringWithFormat:@"%C:",drive]];
   }
   
   return result;
}

-(BOOL)openURL:(NSURL *)url {
   return ((int)ShellExecuteW(GetDesktopWindow(),L"open",(const unichar *)[[url absoluteString] cStringUsingEncoding:NSUnicodeStringEncoding],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

-(BOOL)openFile:(NSString *)path {
   NSString *extension=[path pathExtension];
   
   if([extension isEqualToString:@"app"]){
    NSString *name=[[path lastPathComponent] stringByDeletingPathExtension];
    
    path=[path stringByAppendingPathComponent:@"Contents"];
    path=[path stringByAppendingPathComponent:@"Windows"];
    path=[path stringByAppendingPathComponent:name];
    path=[path stringByAppendingPathExtension:@"exe"];
   }
   
   return ((int)ShellExecuteW(GetDesktopWindow(),L"open",[path fileSystemRepresentationW],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

static BOOL openFileWithHelpViewer(const char *helpFilePath)
{
   char buf[1024];
   snprintf(buf, sizeof(buf), "hh.exe %s", helpFilePath);
   return ((int)WinExec(buf, SW_SHOWNORMAL)<=32)?NO:YES;
}

-(BOOL)openFile:(NSString *)path withApplication:(NSString *)appName {
#if 1
   if(!strcmp([appName UTF8String], "Help Viewer"))
   {
		return openFileWithHelpViewer([path fileSystemRepresentation]);
   }
   else
   {
    NSBundle *bundle=[NSBundle bundleForClass:isa];
    NSString *bundlePath=[bundle bundlePath];
    NSString *app=[[[[[[[bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Applications"] stringByAppendingPathComponent:appName] stringByAppendingPathExtension:@"app"] stringByAppendingPathComponent:appName] stringByAppendingPathExtension:@"exe"];
    NSMutableData *args=[NSMutableData data];

    [args appendData:NSTaskArgumentDataFromStringW(@"-NSOpen")];
    [args appendBytes:L" " length:2];
    [args appendData:NSTaskArgumentDataFromStringW(path)];
    [args appendBytes:L"\0" length:2];

    return ((int)ShellExecuteW(GetDesktopWindow(),L"open",[app fileSystemRepresentationW],[args bytes],NULL,SW_SHOWNORMAL)<=32)?NO:YES;
   }
#else
   return ((int)ShellExecuteW(GetDesktopWindow(),L"open",[path fileSystemRepresentationW],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
#endif
}

-(BOOL)openTempFile:(NSString *)path {
   return ((int)ShellExecuteW(GetDesktopWindow(),L"open",[path fileSystemRepresentationW],NULL,NULL,SW_SHOWNORMAL)<=32)?NO:YES;
}

-(BOOL)selectFile:(NSString *)path inFileViewerRootedAtPath:(NSString *)rootFullpath {
	BOOL isDir = NO;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
	{
		NSMutableData *args=[NSMutableData data];
		[args appendBytes:L"/select," length:16];
		[args appendData:NSTaskArgumentDataFromStringW(path)];
		[args appendBytes:L"\0" length:2];

		return ((int)ShellExecuteW(GetDesktopWindow(),L"open",L"explorer",[args bytes],NULL,SW_SHOWNORMAL)<=32)?NO:YES;
	}
	return NO;
}

-(int)extendPowerOffBy:(int)seconds {
   NSUnimplementedMethod ();
   return 0;
}

-(void)slideImage:(NSImage *)image from:(NSPoint)fromPoint to:(NSPoint)toPoint {
   NSUnimplementedMethod();
}

static void FixBitmapAlpha(HBITMAP bitmap)
{
  BITMAP bmp;

  GetObject(bitmap, sizeof(bmp), &bmp);
  if (bmp.bmBitsPixel == 32)
  {
    DWORD length = bmp.bmWidth * bmp.bmHeight * (bmp.bmBitsPixel / 8);
    BYTE *buf = (BYTE *) calloc(1, length);

    if (buf)
    {
      int x, y;

      GetBitmapBits(bitmap, length, buf);

      for (y = 0; y < bmp.bmHeight; ++y)
      {
        BYTE *pixel = buf + bmp.bmWidth * 4 * y;
        for (x = 0; x < bmp.bmWidth; ++x)
        {
          if (pixel[3])
          {
            // Already has alpha, don't need to do anything.
            free(buf);
            return;
          }
          if (pixel[0] || pixel[1] || pixel[2])
            pixel[3] = 255;
          pixel += 4;
        }
      }

      SetBitmapBits(bitmap, length, buf);
      free(buf);
    }
  }
}

static HBITMAP ConvertBitmap(HBITMAP bitmap)
{
  HBITMAP convertedBitmap;
  BITMAP bmp;
  DWORD length;
  BYTE *buf;

  GetObject(bitmap, sizeof(bmp), &bmp);

  length = bmp.bmWidth * bmp.bmHeight * 4;
  buf = (BYTE *) calloc(1, length);
  if (buf)
  {
    BITMAPINFO bi;
    BYTE * pixels;

    memset(&bi, 0, sizeof(BITMAPINFO));
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = bmp.bmWidth;
    bi.bmiHeader.biHeight = bmp.bmHeight;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biPlanes = 1;

    convertedBitmap = CreateDIBSection(NULL, &bi, DIB_RGB_COLORS, (void **) &pixels, NULL, 0);
    if (convertedBitmap)
    {
      if (bmp.bmBitsPixel != 32)
      {
        HDC from, to;
        HBITMAP oldFrom, oldTo;

        from = CreateCompatibleDC(NULL);
        oldFrom = (HBITMAP) SelectObject(from, bitmap);

        to = CreateCompatibleDC(NULL);
        oldTo = (HBITMAP) SelectObject(to, convertedBitmap);

        BitBlt(to, 0, 0, bmp.bmWidth, bmp.bmHeight, from, 0, 0, SRCCOPY);

        SelectObject(to, oldTo);
        DeleteObject(to);
        SelectObject(from, oldFrom);
        DeleteObject(from);

        FixBitmapAlpha(convertedBitmap);
      }
      else
      {
        GetBitmapBits(bitmap, length, buf);
        SetBitmapBits(convertedBitmap, length, buf);
      }
    }

    free(buf);
  }

  return convertedBitmap;
}

static NSImageRep *imageRepForIcon(SHFILEINFOW * fileInfo) {
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
   if (bmp.bmBitsPixel != 32)
   {
    HBITMAP hbmColor32 = ConvertBitmap(iconInfo.hbmColor);
    if (hbmColor32)
    {
      DeleteObject(iconInfo.hbmColor);
      iconInfo.hbmColor = hbmColor32;
      GetObject(iconInfo.hbmColor, sizeof(BITMAP), (void *) &bmp);
    }
   }
   FixBitmapAlpha(iconInfo.hbmColor);
   pixelslen = bmp.bmWidth * bmp.bmHeight * bmp.bmBitsPixel / 8;
   pixels = malloc(pixelslen);
   GetBitmapBits(iconInfo.hbmColor, pixelslen, pixels);

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
   const unichar *pathCString=[path fileSystemRepresentationW];
   SHFILEINFOW fileInfo;

   NSImage *icon=[[[NSImage alloc] init] autorelease];

   if(SHGetFileInfoW(pathCString,0,&fileInfo,sizeof(SHFILEINFOW),SHGFI_ICON|SHGFI_SMALLICON))
    [icon addRepresentation:imageRepForIcon(&fileInfo)];
   if(SHGetFileInfoW(pathCString,0,&fileInfo,sizeof(SHFILEINFOW),SHGFI_ICON|SHGFI_LARGEICON))
    [icon addRepresentation:imageRepForIcon(&fileInfo)];

   if([[icon representations] count]==0)
    return nil;
    
   return icon;
}

@end
