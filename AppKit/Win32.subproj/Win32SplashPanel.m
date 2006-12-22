/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32SplashPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSScreen.h>
#import <AppKit/Win32Application.h>

@implementation Win32SplashPanel

-(void)draw {
   HDC    winDC=GetDC(_window);
   HDC    memDC=CreateCompatibleDC(winDC);

   SelectObject(memDC,_bmp);

   BitBlt(winDC,0,0,_frame.size.width,_frame.size.height,memDC,0,0,SRCCOPY);

   DeleteDC(memDC);
}

-init {
   NSString *path=[[NSBundle mainBundle] pathForResource:@"splash" ofType:@"bmp"];
   NSRect    screenFrame=[[[NSScreen screens] objectAtIndex:0] frame];
   BITMAP    bm;

   if(path==nil){
    [self dealloc];
    return nil;
   }

   _bmp=LoadImage(NULL,[path fileSystemRepresentation],
     IMAGE_BITMAP,0,0,LR_DEFAULTCOLOR|LR_LOADFROMFILE);

   if(_bmp==NULL){
    [self dealloc];
    return nil;
   }

   GetObject(_bmp,sizeof(BITMAP),&bm);

   _frame.size.width=bm.bmWidth;
   _frame.size.height=bm.bmHeight;

   _frame.origin.x=
      floor(screenFrame.origin.x+screenFrame.size.width/2-_frame.size.width/2);
   _frame.origin.y=
      floor(screenFrame.origin.y+screenFrame.size.height/2-_frame.size.height/2);

   _window=CreateWindowEx(0,"STATIC","",WS_POPUP|WS_VISIBLE|WS_DISABLED,
     _frame.origin.x,_frame.origin.y,_frame.size.width,_frame.size.height,
     NULL,NULL,Win32ApplicationHandle(),NULL);

   [self draw];

   return self;
}

-(void)dealloc {
   if(_window!=NULL){
    ShowWindow(_window,SW_HIDE);
    DestroyWindow(_window);
   }
   DeleteObject(_bmp);
   [super dealloc];
}

@end
