/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/Win32GraphicsState.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/Win32RenderingContext.h>
#import <AppKit/Win32DeviceContext.h>
#import <AppKit/Win32Brush.h>
#import <AppKit/Win32Font.h>
#import <AppKit/Win32Region.h>
#import <AppKit/Win32GraphicsContext.h>

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

@implementation Win32GraphicsState

-initWithRenderingContext:(CGRenderingContext *)context
  transform:(CGAffineTransform)deviceTransform clipRect:(NSRect)clipRect {
   [super initWithRenderingContext:context transform:deviceTransform clipRect:clipRect];

   _dcs[0]=[[(Win32RenderingContext *)_renderingContext colorContext] dc];
   _dcs[1]=[[(Win32RenderingContext *)_renderingContext alphaContext] dc];
   _colorDC=_dcs[0];

   _clipRegion=[[Win32Region alloc] initWithDeviceContext:[(Win32RenderingContext *)_renderingContext colorContext] rect:clipRect];
   _colorRef=RGB(0,0,0);
   _brush=[[Win32Brush alloc] initWithCOLORREF:_colorRef];

   _lineWidth=1.0;
   return self;
}

-(void)dealloc {
   [_clipRegion release];
   [_brush release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   Win32GraphicsState *copy=[super copyWithZone:zone];

   copy->_clipRegion=[self->_clipRegion copy];
   copy->_brush=[self->_brush retain];

   return copy;
}

static inline BOOL transformIsFlipped(Win32GraphicsState *self){
   return (self->_deviceTransform.d<0)?YES:NO;
}

static inline NSPoint transformPoint(Win32GraphicsState *self,NSPoint point) {
   return CGPointApplyAffineTransform(point,self->_deviceTransform);
}

static inline NSRect transformRect(Win32GraphicsState *self,NSRect rect) {
   NSPoint point1=transformPoint(self,rect.origin);
   NSPoint point2=transformPoint(self,NSMakePoint(NSMaxX(rect),NSMaxY(rect)));

   if(point2.y<point1.y){
    float temp=point2.y;
    point2.y=point1.y;
    point1.y=temp;
   }

  return NSMakeRect(point1.x,point1.y,point2.x-point1.x,point2.y-point1.y);
}

-(void)selectColorInDC {
   SetTextColor(_colorDC,_colorRef);
   SetBkColor(_colorDC,_colorRef);
   SelectObject(_colorDC,[_brush brushHandle]);
}

-(void)save {
   _savedState=SaveDC(_colorDC);
}

-(void)restore {
   RestoreDC(_colorDC,_savedState);
}

-(void)abort {
// The sequence SaveGState, BeginPath, RestoreGState will leave an
// outstanding path, so we need to cancel it before restore'ing.
// How does OS X deal with this condition ?
// The type3 procedure may need to be changed
   int    di;

   for(di=0;_dcs[di]!=NULL;di++)
    AbortPath(_dcs[di]);
}

-(void)clipToRect:(NSRect)clipRect {
   [_clipRegion intersectWithRect:transformRect(self,clipRect)];
   [_clipRegion selectInDeviceContext];
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   NSRect translated[count];
   int    i;

   for(i=0;i<count;i++)
    translated[i]=transformRect(self,rects[i]);

   [_clipRegion intersectWithRects:translated count:count];
   [_clipRegion selectInDeviceContext];
}

-(void)scaleCTM:(float)scalex:(float)scaley {
   _deviceTransform=CGAffineTransformScale(_deviceTransform,scalex,scaley);
}

-(void)translateCTM:(float)tx:(float)ty {
   _deviceTransform=CGAffineTransformTranslate(_deviceTransform,tx,ty);
}

-(void)concatCTM:(CGAffineTransform)transform {
   _deviceTransform=CGAffineTransformConcat(_deviceTransform,transform);
}

-(void)beginPath {
   int di;

   for(di=0;_dcs[di]!=NULL;di++)
    BeginPath(_dcs[di]);
}

-(void)moveToPoint:(float)x:(float)y {
   NSPoint point=transformPoint(self,NSMakePoint(x,y));
   int     di;

   for(di=0;_dcs[di]!=NULL;di++)
    MoveToEx(_dcs[di],point.x,point.y,NULL);
}

-(void)addLineToPoint:(float)x:(float)y {
   NSPoint point=transformPoint(self,NSMakePoint(x,y));
   int     di;

   for(di=0;_dcs[di]!=NULL;di++)
    LineTo(_dcs[di],point.x,point.y);
}

-(void)addCurveToPoint:(float)cx1:(float)cy1:(float)cx2:(float)cy2:(float)x:(float)y {
   NSPoint cp1=transformPoint(self,NSMakePoint(cx1,cy1));
   NSPoint cp2=transformPoint(self,NSMakePoint(cx2,cy2));
   NSPoint end=transformPoint(self,NSMakePoint(x,y));
   POINT   points[3];
   int     di;

   points[0].x=cp1.x;
   points[0].y=cp1.y;
   points[1].x=cp2.x;
   points[1].y=cp2.y;
   points[2].x=end.x;
   points[2].y=end.y;

   for(di=0;_dcs[di]!=NULL;di++)
    PolyBezierTo(_dcs[di],points,3);
}

-(void)closePath {
   int     di;

   for(di=0;_dcs[di]!=NULL;di++)
    CloseFigure(_dcs[di]);
}

#if 0
-(void)addArc:(float)x:(float)y:(float)radius:(float)startRadian:(float)endRadian:(int)clockwise {
   CGPoint center=transformPoint(self,NSMakePoint(x,y));
   CGSize  rsizes=CGSizeApplyAffineTransform(NSMakeSize(radius,radius),_deviceTransform);
   float   ravg=(ABS(rsizes.width)+ABS(rsizes.height))/2;
   float   startDegree=startRadian*57.2957795786;
   float   endDegree=endRadian*57.2957795786;
   int     di;

// GDI start point is 0,0 instead of undefined, so if there should be no current point, we calculate and move to where we need to be as if there was none
   if(1/* no current point */){
    CGPoint           start=NSMakePoint(ravg,0);
    CGAffineTransform rotate=CGAffineTransformMakeRotation(startRadian);

    start=CGPointApplyAffineTransform(start,rotate);
    start.x+=x;
    start.y+=y;
    start=transformPoint(self,start);

    for(di=0;_dcs[di]!=NULL;di++)
     MoveToEx(_dcs[di],start.x,start.y,NULL);
   }
   for(di=0;_dcs[di]!=NULL;di++){
    SetArcDirection(_dcs[di],clockwise?AD_CLOCKWISE:AD_COUNTERCLOCKWISE);
    AngleArc(_dcs[di],center.x,center.y,ravg,startDegree,endDegree-startDegree);
   }
}
#endif

-(void)addArcToPoint:(float)x1:(float)y1:(float)x2:(float)y2:(float)radius {
}

-(void)fillPath {
   int     di;

   for(di=0;_dcs[di]!=NULL;di++){
    EndPath(_dcs[di]);
    FillPath(_dcs[di]);
   }
}

-(void)strokePath {
   NSSize lineSize=CGSizeApplyAffineTransform(NSMakeSize(_lineWidth,_lineWidth),_deviceTransform);
   float  lineWidth=(lineSize.width+lineSize.height)/2;
   HPEN   pen=CreatePen(PS_SOLID,lineWidth,_colorRef);
   int    di;

   for(di=0;_dcs[di]!=NULL;di++){
    HPEN oldpen=SelectObject(_dcs[di],pen);

    EndPath(_dcs[di]);
    StrokePath(_dcs[di]);
    SelectObject(_dcs[di],oldpen);
   }
   DeleteObject(pen);
}

-(void)setDeviceColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
   _colorRef=RGB(red*255,green*255,blue*255);
   [_brush release];
   _brush=[[Win32Brush alloc] initWithCOLORREF:_colorRef];

   [self selectColorInDC];
}

-(void)selectFontWithName:(NSString *)name pointSize:(float)pointSize {
   [(Win32RenderingContext *)_renderingContext selectFontWithName:name pointSize:pointSize];
}

-(void)setTextMatrix:(CGAffineTransform)transform {
   _textTransform=transform;
}

-(CGAffineTransform)textMatrix {
   return _textTransform;
}

-(void)moveto:(float)x:(float)y ashow:(const char *)cString:(int)length:(float)dx:(float)dy {
   NSPoint point=transformPoint(self,NSMakePoint(x,y));
   int     di;

   for(di=0;_dcs[di]!=NULL;di++)
    ExtTextOut(_dcs[di],point.x,point.y,0,NULL,cString,length,NULL);
}

-(void)showGlyphs:(const CGGlyph *)glyphs:(unsigned)numberOfGlyphs atPoint:(NSPoint)point {
   int     di;

   point=transformPoint(self,point);

   for(di=0;_dcs[di]!=NULL;di++)
    ExtTextOutW(_dcs[di],point.x,point.y,ETO_GLYPH_INDEX,NULL,(void *)glyphs,numberOfGlyphs,NULL);
}

-(void)showGlyphs:(const CGGlyph *)glyphs advances:(const CGSize *)advances count:(unsigned)count {
#if 0
   int     di;

   for(di=0;_dcs[di]!=NULL;di++){
    POINT   winOrigin;
    NSPoint origin;

    GetCurrentPositionEx,_dcs[di],&winOrigin);
    origin.x=winOrigin.x;
    origin.y=winOrigin.y;

    origin=CGPointApplyAffineTransform(origin,CGAffineTransformInvert(self->_deviceTransform));

    for(i=0;i<count;i++){
     origin.x+=advances.width;
     origin.y+=advances.height;

     point=transformPoint(self,origin);

     ExtTextOutW(_dcs[di],point.x,point.y,ETO_GLYPH_INDEX,NULL,(void *)(glyphs+i),1,NULL);
    }
   }
#endif
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point {
   NSRect  srcRect=transformRect(self,rect);
   NSRect  dstRect=transformRect(self,NSMakeRect(point.x,point.y,rect.size.width,rect.size.height));
   NSRect  scrollRect=NSUnionRect(srcRect,dstRect);
   int     dx=dstRect.origin.x-srcRect.origin.x;
   int     dy=dstRect.origin.y-srcRect.origin.y;
   RECT    winScrollRect=NSRectToRECT(scrollRect);
   int     di;

   for(di=0;_dcs[di]!=NULL;di++){
    ScrollDC(_dcs[di],dx,dy,&winScrollRect,&winScrollRect,NULL,NULL);
   }
}

-(void)fillRects:(const CGRect *)rects count:(unsigned)count {
   HBRUSH brush=[_brush brushHandle];
   RECT   tlbr[count];
   int    i,di;

   for(i=0;i<count;i++)
    tlbr[i]=NSRectToRECT(transformRect(self,rects[i]));

   for(di=0;_dcs[di]!=NULL;di++){
    for(i=0;i<count;i++){
#if 0
// This is faster, but doesn't offer dithering
     ExtTextOut(_dcs[di],0,0,ETO_OPAQUE,tlbr+i,"",0,NULL);
#else
     FillRect(_dcs[di],tlbr+i,brush);
#endif
    }
   }
}

-(void)strokeRect:(CGRect)strokeRect width:(float)width {
   HDC    dc=_colorDC;
   HBRUSH brush=[_brush brushHandle];
   NSRect rect=transformRect(self,strokeRect);
   RECT   tlbr=NSRectToRECT(rect);

   if(width<=1.0)
    FrameRect(dc,&tlbr,brush);
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
}

-(float)lineWidth {
   return _lineWidth;
}

-(void)setLineWidth:(float)width {
   _lineWidth=width;
}

-(void)drawRGBAImageInRect:(NSRect)rect width:(int)width height:(int)height data:(unsigned int *)data fraction:(float)fraction {
   BOOL           viewIsFlipped=!transformIsFlipped(self);
   HDC            sourceDC=_colorDC;
   HDC            combineDC;
   int            combineWidth=width;
   int            combineHeight=height;
   NSPoint        point=transformPoint(self,rect.origin);
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

-(void)bitCopyToPoint:(NSPoint)dstOrigin renderingContext:(Win32RenderingContext *)otherRenderingContext fromPoint:(NSPoint)srcOrigin size:(NSSize)size {
   dstOrigin=transformPoint(self,dstOrigin);

   if(transformIsFlipped(self))
    dstOrigin.y-=size.height;

   [otherRenderingContext copyColorsToContext:(Win32RenderingContext *)_renderingContext size:size toPoint:dstOrigin fromPoint:srcOrigin];
}

@end
