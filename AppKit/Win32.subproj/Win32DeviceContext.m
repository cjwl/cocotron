/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32DeviceContext.h>
#import <AppKit/Win32DeviceContextWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/KGPath.h>
#import <AppKit/KGColor.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/Win32Font.h>
#import <AppKit/Win32Application.h>
#import <AppKit/Win32Region.h>
#import <AppKit/KGImage.h>
#import <AppKit/KGGraphicsState.h>
#import <AppKit/KGContext.h>
#import <AppKit/KGImage_context.h>

static COLORREF RGBFromColor(KGColor *color){
   int    count=[color numberOfComponents];
   float *components=[color components];
   
   if(count==2)
    return RGB(components[0]*255,components[0]*255,components[0]*255);
   if(count==4)
    return RGB(components[0]*255,components[1]*255,components[2]*255);
    
   return RGB(0,0,0);
}

static inline BOOL transformIsFlipped(CGAffineTransform matrix){
   return (matrix.d<0)?YES:NO;
}

static inline NSRect transformRect(CGAffineTransform matrix,NSRect rect) {
   NSPoint point1=CGPointApplyAffineTransform(rect.origin,matrix);
   NSPoint point2=CGPointApplyAffineTransform(NSMakePoint(NSMaxX(rect),NSMaxY(rect)),matrix);

   if(point2.y<point1.y){
    float temp=point2.y;
    point2.y=point1.y;
    point1.y=temp;
   }

  return NSMakeRect(point1.x,point1.y,point2.x-point1.x,point2.y-point1.y);
}


@implementation Win32DeviceContext

-(KGContext *)graphicsContextWithSize:(NSSize)size {
   CGAffineTransform flip={1,0,0,-1,0,size.height};
   KGGraphicsState *initialState=[[[KGGraphicsState alloc] initWithRenderingContext:self transform:flip userSpaceSize:NSMakeSize(size.width,size.height)] autorelease];
   
   return [[[KGContext alloc] initWithGraphicsState:initialState] autorelease];
}

+(Win32DeviceContext *)deviceContextForWindowHandle:(HWND)handle {
   return [[[Win32DeviceContextWindow alloc] initWithWindowHandle:handle] autorelease];
}

-initWithDC:(HDC)dc {
   _dc=dc;

   if(SetMapMode(_dc,MM_ANISOTROPIC)==0)
    NSLog(@"SetMapMode failed");

   //SetICMMode(_dc,ICM_ON); MSDN says only available on 2000, not NT.

   SetBkMode(_dc,TRANSPARENT);
   SetTextAlign(_dc,TA_BASELINE);

#if 0
    if(SetGraphicsMode(_dc,GM_ADVANCED)==0)
     NSLog(@"SetGraphicsMode(_dc,GM_ADVANCED) failed");
#endif

   _font=nil;
   return self;
}

-(void)dealloc {
   [_font release];
   [super dealloc];
}

-(HDC)dc {
   return _dc;
}

-(void)selectFontWithName:(const char *)name pointSize:(float)pointSize antialias:(BOOL)antialias {
   int height=(pointSize*GetDeviceCaps(_dc,LOGPIXELSY))/72.0;

   [_font release];
   _font=[[Win32Font alloc] initWithName:name size:NSMakeSize(0,height) antialias:antialias];
   SelectObject(_dc,[_font fontHandle]);
}

-(void)selectFontWithName:(const char *)name pointSize:(float)pointSize {
   [self selectFontWithName:name pointSize:pointSize antialias:NO];
}

-(Win32Font *)currentFont {
   return _font;
}


-(BOOL)isPrinter {
   return NO;
}

-(void)beginPage {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(void)beginDocument {
   // do nothing
}

-(void)endDocument {
   // do nothing
}

-(NSSize)size {
   NSSize result;

   result.width=GetDeviceCaps(_dc,HORZRES);
   result.height=GetDeviceCaps(_dc,VERTRES);

   return result;
}

-(void)copyColorsToContext:(Win32DeviceContext *)other size:(NSSize)size toPoint:(NSPoint)toPoint  {
   BitBlt([other dc],toPoint.x,toPoint.y,size.width,size.height,_dc,0,0,SRCCOPY);
}

-(void)copyColorsToContext:(Win32DeviceContext *)other size:(NSSize)size {
   [self copyColorsToContext:other size:size toPoint:NSMakePoint(0,0)];
}

-(void)scalePage:(float)scalex:(float)scaley {
   HDC colorDC=_dc;
   int xmul=scalex*1000;
   int xdiv=1000;
   int ymul=scaley*1000;
   int ydiv=1000;

   int width=GetDeviceCaps(colorDC,HORZRES);
   int height=GetDeviceCaps(colorDC,VERTRES);

   SetWindowExtEx(colorDC,width,height,NULL);
   SetViewportExtEx(colorDC,width,height,NULL);

   ScaleWindowExtEx(colorDC,xdiv,xmul,ydiv,ymul,NULL);
}

-(id)saveCopyOfDeviceState {
   return [[NSNumber alloc] initWithInt:SaveDC(_dc)];
}

-(void)restoreDeviceState:(id)state {
   RestoreDC(_dc,[state intValue]);
}

-(id)copyDeviceClipState {
   HRGN clip=CreateRectRgn(0,0,20000,20000); //  lame, fix

   if(!GetClipRgn(_dc,clip)==-1)
    NSLog(@"GetClipRgn failed");
   
   return [[Win32Region alloc] initWithHandle:clip];
}

-(void)setDeviceClipState:(id)region {
   if(![self isPrinter])
    SelectClipRgn(_dc,[(Win32Region *)region regionHandle]);
}

-(void)clipInUserSpace:(CGAffineTransform)ctm rects:(const NSRect *)userRects count:(unsigned)count {
   Win32Region *clip=[self copyDeviceClipState];
   NSRect       rects[count];
   int          i;

   for(i=0;i<count;i++)
    rects[i]=transformRect(ctm,userRects[i]);
    
   [clip intersectWithRects:rects count:count];
   [self setDeviceClipState:clip];
   [clip release];
}

static RECT NSRectToRECT(NSRect rect) {
   RECT result;

   if(rect.size.height<0)
    rect=NSZeroRect;
   if(rect.size.width<0)
    rect=NSZeroRect;

   result.top=rect.origin.y;
   result.left=rect.origin.x;
   result.bottom=rect.origin.y+rect.size.height;
   result.right=rect.origin.x+rect.size.width;

   return result;
}

-(void)fillInUserSpace:(CGAffineTransform)ctm rects:(const NSRect *)rects count:(unsigned)count color:(KGColor *)color {
   HDC         dc=_dc;
   HBRUSH      handle=CreateSolidBrush(RGBFromColor(color));
   RECT        tlbr[count];
   int         i;

   for(i=0;i<count;i++)
    tlbr[i]=NSRectToRECT(transformRect(ctm,rects[i]));

   for(i=0;i<count;i++)
    FillRect(dc,tlbr+i,handle);
    
   DeleteObject(handle);
}

-(void)strokeInUserSpace:(CGAffineTransform)ctm rect:(NSRect)rect width:(float)width color:(KGColor *)color {
   HDC         dc=_dc;
   HBRUSH      handle=CreateSolidBrush(RGBFromColor(color));
   RECT        tlbr=NSRectToRECT(transformRect(ctm,rect));

   if(width<=1.0)
    FrameRect(dc,&tlbr,handle);
   else {
    POINT  points[5];
   
    points[0].x=tlbr.left;
    points[0].y=tlbr.top;
    points[1].x=tlbr.right;
    points[1].y=tlbr.top;
    points[2].x=tlbr.right;
    points[2].y=tlbr.bottom;
    points[3].x=tlbr.left;
    points[3].y=tlbr.bottom;
    points[4].x=tlbr.left;
    points[4].y=tlbr.top;

    Polyline(dc,points,5);
   }
   DeleteObject(handle);
}

-(void)copyBitsInUserSpace:(CGAffineTransform)ctm rect:(NSRect)rect toPoint:(NSPoint)point {
   HDC     dc=_dc;
   NSRect  srcRect=transformRect(ctm,rect);
   NSRect  dstRect=transformRect(ctm,NSMakeRect(point.x,point.y,rect.size.width,rect.size.height));
   NSRect  scrollRect=NSUnionRect(srcRect,dstRect);
   int     dx=dstRect.origin.x-srcRect.origin.x;
   int     dy=dstRect.origin.y-srcRect.origin.y;
   RECT    winScrollRect=NSRectToRECT(scrollRect);
   int     di;

   ScrollDC(dc,dx,dy,&winScrollRect,&winScrollRect,NULL,NULL);
}

-(void)showInUserSpace:(CGAffineTransform)ctm text:(const char *)text count:(unsigned)count atPoint:(float)x:(float)y color:(KGColor *)color {
   HDC     dc=_dc;
   NSPoint point=CGPointApplyAffineTransform(NSMakePoint(x,y),ctm);

   SetTextColor(dc,RGBFromColor(color));
   ExtTextOut(dc,point.x,point.y,0,NULL,text,count,NULL);
}

-(void)showInUserSpace:(CGAffineTransform)ctm glyphs:(const CGGlyph *)glyphs count:(unsigned)count atPoint:(float)x:(float)y color:(KGColor *)color {
   HDC     dc=_dc;
   NSPoint point=CGPointApplyAffineTransform(NSMakePoint(x,y),ctm);

   SetTextColor(dc,RGBFromColor(color));
   ExtTextOutW(dc,point.x,point.y,ETO_GLYPH_INDEX,NULL,(void *)glyphs,count,NULL);
}

-(void)drawPathInDeviceSpace:(KGPath *)path drawingMode:(int)mode ctm:(CGAffineTransform)ctm lineWidth:(float)lineWidth fillColor:(KGColor *)fillColor strokeColor:(KGColor *)strokeColor {
   HDC                  dc=_dc;
   unsigned             opCount=[path numberOfOperators];
   const unsigned char *operators=[path operators];
   unsigned             pointCount=[path numberOfPoints];
   const NSPoint       *points=[path points];
   unsigned             i,pointIndex;
       
   BeginPath(dc);
   
   pointIndex=0;
   for(i=0;i<opCount;i++){
    switch(operators[i]){

     case KGPathOperatorMoveToPoint:{
       NSPoint point=points[pointIndex++];
        
       MoveToEx(dc,point.x,point.y,NULL);
      }
      break;
       
     case KGPathOperatorLineToPoint:{
       NSPoint point=points[pointIndex++];
        
       LineTo(dc,point.x,point.y);
      }
      break;

     case KGPathOperatorCurveToPoint:{
       NSPoint cp1=points[pointIndex++];
       NSPoint cp2=points[pointIndex++];
       NSPoint end=points[pointIndex++];
       POINT   points[3]={
        { cp1.x, cp1.y },
        { cp2.x, cp2.y },
        { end.x, end.y },
       };
        
       PolyBezierTo(dc,points,3);
      }
      break;

     case KGPathOperatorQuadCurveToPoint:{
       NSPoint cp1=points[pointIndex++];
       NSPoint cp2=points[pointIndex++];
       NSPoint end=cp2;
       POINT   points[3]={
        { cp1.x, cp1.y },
        { cp2.x, cp2.y },
        { end.x, end.y },
       };
        
       PolyBezierTo(dc,points,3);
      }
      break;

     case KGPathOperatorCloseSubpath:
      CloseFigure(dc);
      break;
    }
   }
   EndPath(dc);
   {
    HBRUSH fillBrush=CreateSolidBrush(RGBFromColor(fillColor));

    SelectObject(dc,fillBrush);

   if(mode==KGPathFill || mode==KGPathFillStroke){
    SetPolyFillMode(dc,WINDING);
    FillPath(dc);
   }
   if(mode==KGPathEOFill || mode==KGPathEOFillStroke){
    SetPolyFillMode(dc,ALTERNATE);
    FillPath(dc);
   }
    DeleteObject(fillBrush);
   }
   
   if(mode==KGPathStroke || mode==KGPathFillStroke || mode==KGPathEOFillStroke){
    NSSize lineSize=CGSizeApplyAffineTransform(NSMakeSize(lineWidth,lineWidth),ctm);
    HPEN   pen=CreatePen(PS_SOLID,(lineSize.width+lineSize.height)/2,RGBFromColor(strokeColor));
    HPEN   oldpen=SelectObject(dc,pen);

    StrokePath(dc);
    SelectObject(dc,oldpen);
   }
}

#if 1
-(void)drawBitmapImage:(KGImage *)image inRect:(NSRect)rect ctm:(CGAffineTransform)ctm fraction:(float)fraction  {
   int            width=[image width];
   int            height=[image height];
   const unsigned int *data=[image bytes];
   BOOL           viewIsFlipped=!transformIsFlipped(ctm);
   HDC            sourceDC=_dc;
   HDC            combineDC;
   int            combineWidth=width;
   int            combineHeight=height;
   NSPoint        point=CGPointApplyAffineTransform(rect.origin,ctm);
   HBITMAP        bitmap;
   BITMAPINFO     info;
   void          *bits;
   unsigned char *combineBGRX;
   unsigned char *imageRGBA=(void *)data;

   if(!viewIsFlipped)
    point.y-=rect.size.height;

   if((combineDC=CreateCompatibleDC(sourceDC))==NULL){
    NSLog(@"CreateCompatibleDC failed");
    return;
   }

   info.bmiHeader.biSize=sizeof(BITMAPINFO);
   info.bmiHeader.biWidth=combineWidth;
   info.bmiHeader.biHeight=combineHeight;
   info.bmiHeader.biPlanes=1;
   info.bmiHeader.biBitCount=32;
   info.bmiHeader.biCompression=BI_RGB;
   info.bmiHeader.biSizeImage=0;
   info.bmiHeader.biXPelsPerMeter=0;
   info.bmiHeader.biYPelsPerMeter=0;
   info.bmiHeader.biClrUsed=0;
   info.bmiHeader.biClrImportant=0;

   if((bitmap=CreateDIBSection(sourceDC,&info,DIB_RGB_COLORS,&bits,NULL,0))==NULL){
    NSLog(@"CreateDIBSection failed");
    return;
   }
   combineBGRX=bits;
   SelectObject(combineDC,bitmap);

   BitBlt(combineDC,0,0,combineWidth,combineHeight,sourceDC,point.x,point.y,SRCCOPY);
   GdiFlush();

   CGGraphicsSourceOver_rgba32_onto_bgrx32(imageRGBA,combineBGRX,width,height,fraction);

   BitBlt(sourceDC,point.x,point.y,combineWidth,combineHeight,combineDC,0,0,SRCCOPY);
   DeleteObject(bitmap);
   DeleteDC(combineDC);
}

#else
// a work in progress
static void zeroBytes(void *bytes,int size){
   int i;
   
   for(i=0;i<size;i++)
    ((char *)bytes)[i]=0;
}

-(void)drawBitmapImage:(KGImage *)image inRect:(NSRect)rect ctm:(CGAffineTransform)ctm fraction:(float)fraction  {
   int            width=[image width];
   int            height=[image height];
   const unsigned char *bytes=[image bytes];
   HDC            sourceDC;
   BITMAPV4HEADER header;
   HBITMAP        bitmap;
   HGDIOBJ        oldBitmap;
   BLENDFUNCTION  blendFunction;
   
   if((sourceDC=CreateCompatibleDC(_dc))==NULL){
    NSLog(@"CreateCompatibleDC failed");
    return;
   }
   
   zeroBytes(&header,sizeof(header));
 
   header.bV4Size=sizeof(BITMAPINFOHEADER);
   header.bV4Width=width;
   header.bV4Height=height;
   header.bV4Planes=1;
   header.bV4BitCount=32;
   header.bV4V4Compression=BI_RGB;
   header.bV4SizeImage=width*height*4;
   header.bV4XPelsPerMeter=0;
   header.bV4YPelsPerMeter=0;
   header.bV4ClrUsed=0;
   header.bV4ClrImportant=0;
#if 0
   header.bV4RedMask=0xFF000000;
   header.bV4GreenMask=0x00FF0000;
   header.bV4BlueMask=0x0000FF00;
   header.bV4AlphaMask=0x000000FF;
#else
//   header.bV4RedMask=  0x000000FF;
//   header.bV4GreenMask=0x0000FF00;
//   header.bV4BlueMask= 0x00FF0000;
//   header.bV4AlphaMask=0xFF000000;
#endif
   header.bV4CSType=0;
  // header.bV4Endpoints;
  // header.bV4GammaRed;
  // header.bV4GammaGreen;
  // header.bV4GammaBlue;
   
   {
    char *bits;
    int  i;
    
   if((bitmap=CreateDIBSection(sourceDC,&header,DIB_RGB_COLORS,&bits,NULL,0))==NULL){
    NSLog(@"CreateDIBSection failed");
    return;
   }
   for(i=0;i<width*height*4;i++){
    bits[i]=0x00;
   }
   }
   if((oldBitmap=SelectObject(sourceDC,bitmap))==NULL)
    NSLog(@"SelectObject failed");

   rect=transformRect(ctm,rect);

   blendFunction.BlendOp=AC_SRC_OVER;
   blendFunction.BlendFlags=0;
   blendFunction.SourceConstantAlpha=0xFF;
   blendFunction.BlendOp=AC_SRC_ALPHA;
   {
    typedef WINGDIAPI BOOL WINAPI (*alphaType)(HDC,int,int,int,int,HDC,int,int,int,int,BLENDFUNCTION);

    HANDLE library=LoadLibrary("MSIMG32");
    alphaType alphaBlend=(alphaType)GetProcAddress(library,"AlphaBlend");

    if(alphaBlend==NULL)
     NSLog(@"Unable to get AlphaBlend",alphaBlend);
    else {
     if(!alphaBlend(_dc,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height,sourceDC,0,0,width,height,blendFunction))
      NSLog(@"AlphaBlend failed");
    }
   }

   DeleteObject(bitmap);
   SelectObject(sourceDC,oldBitmap);
   DeleteDC(sourceDC);
}
#endif

-(void)drawImage:(KGImage *)image inRect:(CGRect)rect ctm:(CGAffineTransform)ctm fraction:(float)fraction {
   if([image isKindOfClass:[KGImage_context class]]){
    Win32DeviceContext *other=[(KGImage_context *)image renderingContext];
   
    rect.origin=CGPointApplyAffineTransform(rect.origin,ctm);

    if(transformIsFlipped(ctm))
     rect.origin.y-=rect.size.height;

    [other copyColorsToContext:self size:rect.size toPoint:rect.origin];
   }
   else {
    if([image bitsPerComponent]!=8){
     NSLog(@"Does not support bitsPerComponent=%d",[image bitsPerComponent]);
     return;
    }
    if([image bitsPerPixel]!=32){
     NSLog(@"Does not support bitsPerPixel=%d",[image bitsPerPixel]);
     return;
    }
   
    [self drawBitmapImage:image inRect:rect ctm:ctm fraction:fraction ];
   }
}


@end
