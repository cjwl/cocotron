/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/Win32Workspace.h>
#import <Foundation/NSString_win32.h>
#import <windows.h>
#import <shellapi.h>

@implementation Win32Workspace

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

-(NSImage *)iconForFile:(NSString *)path {
   const char *pathCString=[path fileSystemRepresentation];
   SHFILEINFO fileInfo;
   
   if(!SHGetFileInfo(pathCString,0,&fileInfo,sizeof(SHFILEINFO),SHGFI_ICON|SHGFI_LARGEICON))
    return nil;

/*
  get dimensions of icon, draw icon, put result in NSImage
 */
   DestroyIcon(fileInfo.hIcon);
   
   return nil;
}

@end
