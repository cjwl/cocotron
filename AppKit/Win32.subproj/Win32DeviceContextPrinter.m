/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32DeviceContextPrinter.h>

@implementation Win32DeviceContextPrinter

-(void)dealloc {
   DeleteDC(_dc);
   [super dealloc];
}

-(NSSize)pageSize {
   return NSMakeSize(72*8.5,72*11);
}

-(BOOL)isPrinter {
   return YES;
}

-(void)beginDocument {
   DOCINFO info;

   info.cbSize=sizeof(DOCINFO);
   info.lpszDocName="TEST.XYZ";
   info.lpszOutput=NULL;
   info.lpszDatatype=NULL;
   info.fwType=0;

   if(StartDoc(_dc,&info)==SP_ERROR)
    return;

   return;
}

-(void)endDocument {
   if(EndDoc(_dc)==SP_ERROR)
    NSLog(@"EndDoc failed");
}


-(void)beginPage {
   if(StartPage(_dc)==SP_ERROR)
    NSLog(@"StartPage failed");
}

-(void)endPage {
   if(EndPage(_dc)==SP_ERROR)
    NSLog(@"EndPage failed");
}

-(void)abortDocument {
   if(AbortDoc(_dc)==SP_ERROR)
    NSLog(@"AbortDoc failed");
}

@end
