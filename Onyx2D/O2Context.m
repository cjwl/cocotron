/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Onyx2D/O2Context.h>
#import <Onyx2D/O2BitmapContext.h>
#import <Onyx2D/O2GraphicsState.h>
#import <Onyx2D/O2Color.h>
#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2MutablePath.h>
#import <Onyx2D/O2Layer.h>
#import <Onyx2D/O2PDFPage.h>
#import <Onyx2D/O2ClipPhase.h>
#import <Onyx2D/O2Exceptions.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSArray.h>

@implementation O2Context

static NSMutableArray *possibleContextClasses=nil;

+(void)initialize {
   if(possibleContextClasses==nil){
    possibleContextClasses=[NSMutableArray new];
    
    [possibleContextClasses addObject:@"O2Context_gdi"];
    [possibleContextClasses addObject:@"O2Context_builtin"];
    [possibleContextClasses addObject:@"O2Context_builtin_gdi"];
    [possibleContextClasses addObject:@"O2Context_cairo"];
    [possibleContextClasses addObject:@"O2Context_builtin_FT"];
    
    NSArray *allPaths=[[NSBundle bundleForClass:self] pathsForResourcesOfType:@"cgContext" inDirectory:nil];
    int      i,count=[allPaths count];
    
    for(i=0;i<count;i++){
     NSString *path=[allPaths objectAtIndex:i];
     NSBundle *check=[NSBundle bundleWithPath:path];
     Class     cls=[check principalClass];
     
     if(cls!=Nil)
      [possibleContextClasses addObject:NSStringFromClass([check principalClass])];
    }
   }
}

+(NSArray *)allContextClasses {
   NSMutableArray *result=[NSMutableArray array];
   int             i,count=[possibleContextClasses count];
   
   for(i=0;i<count;i++){
    Class check=NSClassFromString([possibleContextClasses objectAtIndex:i]);
    
    if(check!=Nil)
     [result addObject:check];
   }
   
   return result;
}

+(O2Context *)createContextWithSize:(O2Size)size window:(CGWindow *)window {
   NSArray *array=[self allContextClasses];
   int      count=[array count];
   
   while(--count>=0){
    Class check=[array objectAtIndex:count];
        
    if([check canInitWithWindow:window]){
     O2Context *result=[[check alloc] initWithSize:size window:window];
     
     if(result!=nil)
      return result;
    }
   }
   
   return nil;
}

+(O2Context *)createBackingContextWithSize:(O2Size)size context:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary {
   NSArray *array=[self allContextClasses];
   int      count=[array count];
   
   while(--count>=0){
    Class check=[array objectAtIndex:count];
    
    if([check canInitBackingWithContext:context deviceDictionary:deviceDictionary]){
     O2Context *result=[[check alloc] initWithSize:size context:context];

     if(result!=nil)
      return result;
    }
   }
   
   return nil;
}

-initWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(O2BitmapInfo)bitmapInfo releaseCallback:(O2BitmapContextReleaseDataCallback)releaseCallback releaseInfo:(void *)releaseInfo {
   return nil;
}

+(O2Context *)createWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(O2BitmapInfo)bitmapInfo releaseCallback:(O2BitmapContextReleaseDataCallback)releaseCallback releaseInfo:(void *)releaseInfo {
   NSArray *array=[self allContextClasses];
   int      count=[array count];
   
   while(--count>=0){
    Class check=[array objectAtIndex:count];
    
    if([check canInitBitmap]){
     O2Context *result=[[check alloc] initWithBytes:bytes width:width height:height bitsPerComponent:bitsPerComponent bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo releaseCallback:releaseCallback releaseInfo:releaseInfo];

     if(result!=nil)
      return result;
    }
   }
   
   return nil;
}

+(BOOL)canInitWithWindow:(CGWindow *)window {
   return NO;
}

+(BOOL)canInitBackingWithContext:(O2Context *)context deviceDictionary:(NSDictionary *)deviceDictionary {
   return NO;
}

+(BOOL)canInitBitmap {
   return NO;
}

-initWithSize:(O2Size)size window:(CGWindow *)window {
   O2InvalidAbstractInvocation();
   return nil;
}

-initWithSize:(O2Size)size context:(O2Context *)context {
   O2InvalidAbstractInvocation();
   return nil;
}

-initWithGraphicsState:(O2GState *)state {
   _userToDeviceTransform=state->_deviceSpaceTransform;
   _layerStack=[NSMutableArray new];
   _stateStack=[NSMutableArray new];
   [_stateStack addObject:state];
   _path=[[O2MutablePath alloc] init];
   _allowsAntialiasing=YES;
   return self;
}

-init {
   return [self initWithGraphicsState:[[[O2GState alloc] init] autorelease]];
}

-(void)dealloc {
   [_layerStack release];
   [_stateStack release];
   [_path release];
   [super dealloc];
}

static inline O2GState *currentState(O2Context *self){        
   return [self->_stateStack lastObject];
}

-(O2Surface *)surface {
   return nil;
}

-(O2Surface *)createSurfaceWithWidth:(size_t)width height:(size_t)height {
   return nil;
}

-(void)beginTransparencyLayerWithInfo:(NSDictionary *)unused {
}

-(void)endTransparencyLayer {
}

-(O2ColorRef )strokeColor {
   return O2GStateStrokeColor(currentState(self));
}

O2ColorRef O2ContextFillColor(O2ContextRef self) {
   return O2GStateFillColor(currentState(self));
}

-(void)setStrokeAlpha:(O2Float)alpha {
   O2ColorRef color=O2ColorCreateCopyWithAlpha([self strokeColor],alpha);
   O2ContextSetStrokeColorWithColor(self,color);
   O2ColorRelease(color);
}

-(void)setGrayStrokeColor:(O2Float)gray {
   O2Float alpha=O2ColorGetAlpha([self strokeColor]);
   
   O2ContextSetGrayStrokeColor(self,gray,alpha);
}

-(void)setRGBStrokeColor:(O2Float)r:(O2Float)g:(O2Float)b {
   O2Float alpha=O2ColorGetAlpha([self strokeColor]);
   O2ContextSetRGBStrokeColor(self,r,g,b,alpha);
}

-(void)setCMYKStrokeColor:(O2Float)c:(O2Float)m:(O2Float)y:(O2Float)k {
   O2Float alpha=O2ColorGetAlpha([self strokeColor]);
   O2ContextSetCMYKStrokeColor(self,c,m,y,k,alpha);
}

-(void)setFillAlpha:(O2Float)alpha {
   O2ColorRef color=O2ColorCreateCopyWithAlpha(O2ContextFillColor(self),alpha);
   O2ContextSetFillColorWithColor(self,color);
   O2ColorRelease(color);
}

-(void)setGrayFillColor:(O2Float)gray {
   O2Float alpha=O2ColorGetAlpha(O2ContextFillColor(self));
   O2ContextSetGrayFillColor(self,gray,alpha);
}

-(void)setRGBFillColor:(O2Float)r:(O2Float)g:(O2Float)b {
   O2Float alpha=O2ColorGetAlpha(O2ContextFillColor(self));
   O2ContextSetRGBFillColor(self,r,g,b,alpha);
}

-(void)setCMYKFillColor:(O2Float)c:(O2Float)m:(O2Float)y:(O2Float)k {
   O2Float alpha=O2ColorGetAlpha(O2ContextFillColor(self));
   O2ContextSetCMYKFillColor(self,c,m,y,k,alpha);
}

-(void)drawPath:(O2PathDrawingMode)pathMode {
   O2InvalidAbstractInvocation();
// reset path in subclass
}

-(void)showGlyphs:(const O2Glyph *)glyphs count:(unsigned)count {
   O2InvalidAbstractInvocation();
}

-(void)showText:(const char *)text length:(unsigned)length {
   O2Glyph *encoding=[currentState(self) glyphTableForTextEncoding];
   O2Glyph  glyphs[length];
   int      i;
   
   for(i=0;i<length;i++)
    glyphs[i]=encoding[(uint8_t)text[i]];
    
   [self showGlyphs:glyphs count:length];
}

-(void)drawShading:(O2Shading *)shading {
   O2InvalidAbstractInvocation();
}

-(void)drawImage:(O2Image *)image inRect:(O2Rect)rect {
   O2InvalidAbstractInvocation();
}

-(void)drawLayer:(O2LayerRef)layer inRect:(O2Rect)rect {
   O2InvalidAbstractInvocation();
}
   
-(void)flush {
   // do nothing
}

-(void)synchronize {
   // do nothing
}

-(BOOL)resizeWithNewSize:(O2Size)size {
   return NO;
}

-(void)beginPage:(const O2Rect *)mediaBox {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(void)close {
   // do nothing
}

-(O2Size)size {
   return O2SizeMake(0,0);
}

-(O2ContextRef)createCompatibleContextWithSize:(O2Size)size unused:(NSDictionary *)unused {
   return [[isa alloc] initWithSize:size context:self];
}

-(BOOL)getImageableRect:(O2Rect *)rect {
   return NO;
}

// temporary

-(void)setAntialiasingQuality:(int)value {
   [currentState(self) setAntialiasingQuality:value];
}

-(void)setWordSpacing:(O2Float)spacing {
   [currentState(self) setWordSpacing:spacing];
}

-(void)setTextLeading:(O2Float)leading {
   [currentState(self) setTextLeading:leading];
}

-(void)copyBitsInRect:(O2Rect)rect toPoint:(O2Point)point gState:(int)gState {
   O2InvalidAbstractInvocation();
}

-(NSData *)captureBitmapInRect:(O2Rect)rect {
   O2InvalidAbstractInvocation();
   return nil;
}

/*
  Notes: OSX generates a clip mask at fill time using the current aliasing setting. Once the fill is complete the clip mask persists with the next clip/fill. This means you can turn off AA, create a clip path, fill, turn on AA, create another clip path, fill, and edges from the first path will be aliased, and ones from the second will not. PDF does not dictate aliasing behavior, so while this is not really expected behavior, it is not a bug. 
    
 */
 
-(void)deviceClipReset {
   // do nothing
}

-(void)deviceClipToNonZeroPath:(O2Path *)path {
   // do nothing
}

-(void)deviceClipToEvenOddPath:(O2Path *)path {
   // do nothing
}

-(void)deviceClipToMask:(O2Image *)mask inRect:(O2Rect)rect {
   // do nothing
}

O2ContextRef O2ContextRetain(O2ContextRef self) {
   return (self!=NULL)?(O2ContextRef)CFRetain(self):NULL;
}

void O2ContextRelease(O2ContextRef self) {
   if(self!=NULL)
    CFRelease(self);
}

// context state
void O2ContextSetAllowsAntialiasing(O2ContextRef self,BOOL yesOrNo) {
   self->_allowsAntialiasing=yesOrNo;
}

// layers
void O2ContextBeginTransparencyLayer(O2ContextRef self,NSDictionary *unused) {
   [self beginTransparencyLayerWithInfo:unused];
}

void O2ContextEndTransparencyLayer(O2ContextRef self) {
   [self endTransparencyLayer];
}

// path
BOOL O2ContextIsPathEmpty(O2ContextRef self) {
   return (self->_path==nil)?YES:O2PathIsEmpty(self->_path);
}

O2Point O2ContextGetPathCurrentPoint(O2ContextRef self) {
   return (self->_path==nil)?O2PointZero:O2PathGetCurrentPoint(self->_path);
}

O2Rect  O2ContextGetPathBoundingBox(O2ContextRef self) {
   return (self->_path==nil)?O2RectZero:O2PathGetBoundingBox(self->_path);
}

BOOL    O2ContextPathContainsPoint(O2ContextRef self,O2Point point,O2PathDrawingMode pathMode) {
   O2AffineTransform ctm=currentState(self)->_deviceSpaceTransform;

// FIX  evenOdd
   return O2PathContainsPoint(self->_path,&ctm,point,NO);
}

void O2ContextBeginPath(O2ContextRef self) {
   O2PathReset(self->_path);
}

void O2ContextClosePath(O2ContextRef self) {
   O2PathCloseSubpath(self->_path);
}

/* Path building is affected by the CTM, we transform them here into base coordinates (first quadrant, no transformation)

   A backend can then convert them to where it needs them, base,  current, or device space.
 */

void O2ContextMoveToPoint(O2ContextRef self,O2Float x,O2Float y) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathMoveToPoint(self->_path,&ctm,x,y);
}

void O2ContextAddLineToPoint(O2ContextRef self,O2Float x,O2Float y) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddLineToPoint(self->_path,&ctm,x,y);
}

void O2ContextAddCurveToPoint(O2ContextRef self,O2Float cx1,O2Float cy1,O2Float cx2,O2Float cy2,O2Float x,O2Float y) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddCurveToPoint(self->_path,&ctm,cx1,cy1,cx2,cy2,x,y);
}

void O2ContextAddQuadCurveToPoint(O2ContextRef self,O2Float cx1,O2Float cy1,O2Float x,O2Float y) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddQuadCurveToPoint(self->_path,&ctm,cx1,cy1,x,y);
}

void O2ContextAddLines(O2ContextRef self,const O2Point *points,unsigned count) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddLines(self->_path,&ctm,points,count);
}

void O2ContextAddRect(O2ContextRef self,O2Rect rect) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddRect(self->_path,&ctm,rect);
}

void O2ContextAddRects(O2ContextRef self,const O2Rect *rects,unsigned count) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddRects(self->_path,&ctm,rects,count);
}

void O2ContextAddArc(O2ContextRef self,O2Float x,O2Float y,O2Float radius,O2Float startRadian,O2Float endRadian,BOOL clockwise) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddArc(self->_path,&ctm,x,y,radius,startRadian,endRadian,clockwise);
}

void O2ContextAddArcToPoint(O2ContextRef self,O2Float x1,O2Float y1,O2Float x2,O2Float y2,O2Float radius) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddArcToPoint(self->_path,&ctm,x1,y1,x2,y2,radius);
}

void O2ContextAddEllipseInRect(O2ContextRef self,O2Rect rect) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddEllipseInRect(self->_path,&ctm,rect);
}

void O2ContextAddPath(O2ContextRef self,O2PathRef path) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathAddPath(self->_path,&ctm,path);
}

void O2ContextReplacePathWithStrokedPath(O2ContextRef self) {
   O2UnimplementedFunction();
}

// gstate

void O2ContextSaveGState(O2ContextRef self) {
   O2GState *current=currentState(self),*next;

   next=O2GStateCopyWithZone(current,NULL);
   [self->_stateStack addObject:next];
   [next release];
}

void O2ContextRestoreGState(O2ContextRef self) {
   if(self==nil){
    return;
   }
    
   [self->_stateStack removeLastObject];

   O2GState *gState=currentState(self);

// FIXME, this could be conditional by comparing to previous font
   gState->_fontIsDirty=YES;
   
   NSArray *phases=O2GStateClipPhases(gState);
   int      i,count=[phases count];
   
   [self deviceClipReset];
   
   for(i=0;i<count;i++){
    O2ClipPhase *phase=[phases objectAtIndex:i];
    
    switch(O2ClipPhasePhaseType(phase)){
    
     case O2ClipPhaseNonZeroPath:{
       O2Path *path=O2ClipPhaseObject(phase);
       [self deviceClipToNonZeroPath:path];
      }
      break;
      
     case O2ClipPhaseEOPath:{
       O2Path *path=O2ClipPhaseObject(phase);
       [self deviceClipToEvenOddPath:path];
      }
      break;
      
     case O2ClipPhaseMask:
      break;
    }
    
   }
}

O2AffineTransform      O2ContextGetUserSpaceToDeviceSpaceTransform(O2ContextRef self) {
   return currentState(self)->_deviceSpaceTransform;
}

O2AffineTransform      O2ContextGetCTM(O2ContextRef self){
   return O2GStateUserSpaceTransform(currentState(self));
}

O2Rect                 O2ContextGetClipBoundingBox(O2ContextRef self) {
   return [currentState(self) clipBoundingBox];
}

O2AffineTransform      O2ContextGetTextMatrix(O2ContextRef self) {
   return [currentState(self) textMatrix];
}

O2InterpolationQuality O2ContextGetInterpolationQuality(O2ContextRef self) {
   return [currentState(self) interpolationQuality];
}

O2Point O2ContextGetTextPosition(O2ContextRef self){
   return [currentState(self) textPosition];
}

O2Point O2ContextConvertPointToDeviceSpace(O2ContextRef self,O2Point point) {
   return [currentState(self) convertPointToDeviceSpace:point];
}

O2Point O2ContextConvertPointToUserSpace(O2ContextRef self,O2Point point) {
   return [currentState(self) convertPointToUserSpace:point];
}

O2Size  O2ContextConvertSizeToDeviceSpace(O2ContextRef self,O2Size size) {
   return [currentState(self) convertSizeToDeviceSpace:size];
}

O2Size  O2ContextConvertSizeToUserSpace(O2ContextRef self,O2Size size) {
   return [currentState(self) convertSizeToUserSpace:size];
}

O2Rect  O2ContextConvertRectToDeviceSpace(O2ContextRef self,O2Rect rect) {
   return [currentState(self) convertRectToDeviceSpace:rect];
}

O2Rect  O2ContextConvertRectToUserSpace(O2ContextRef self,O2Rect rect) {
   return [currentState(self) convertRectToUserSpace:rect];
}

void O2ContextConcatCTM(O2ContextRef self,O2AffineTransform matrix) {
   O2GStateConcatCTM(currentState(self),matrix);
}

void O2ContextTranslateCTM(O2ContextRef self,O2Float translatex,O2Float translatey) {
   O2ContextConcatCTM(self,O2AffineTransformMakeTranslation(translatex,translatey));
}

void O2ContextScaleCTM(O2ContextRef self,O2Float scalex,O2Float scaley) {
   O2ContextConcatCTM(self,O2AffineTransformMakeScale(scalex,scaley));
}

void O2ContextRotateCTM(O2ContextRef self,O2Float radians) {
   O2ContextConcatCTM(self,O2AffineTransformMakeRotation(radians));
}

void O2ContextClip(O2ContextRef self) {
   if(O2PathIsEmpty(self->_path))
    return;
   
   O2GStateAddClipToPath(currentState(self),self->_path);
   [self deviceClipToNonZeroPath:self->_path];
   O2PathReset(self->_path);
}

void O2ContextEOClip(O2ContextRef self) {
   if(O2PathIsEmpty(self->_path))
    return;

   [currentState(self) addEvenOddClipToPath:self->_path];
   [self deviceClipToEvenOddPath:self->_path];
   O2PathReset(self->_path);
}

void O2ContextClipToMask(O2ContextRef self,O2Rect rect,O2ImageRef image) {
   [currentState(self) addClipToMask:image inRect:rect];
   [self deviceClipToMask:image inRect:rect];
}

void O2ContextClipToRect(O2ContextRef self,O2Rect rect) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathReset(self->_path);
   O2PathAddRect(self->_path,&ctm,rect);
   O2ContextClip(self);
}

void O2ContextClipToRects(O2ContextRef self,const O2Rect *rects,unsigned count) {
   O2AffineTransform ctm=O2GStateUserSpaceTransform(currentState(self));

   O2PathReset(self->_path);
   O2PathAddRects(self->_path,&ctm,rects,count);
   O2ContextClip(self);
}

void O2ContextSetStrokeColorSpace(O2ContextRef self,O2ColorSpaceRef colorSpace) {
   int   i,length=O2ColorSpaceGetNumberOfComponents(colorSpace);
   O2Float components[length+1];
   
   for(i=0;i<length;i++)
    components[i]=0;
   components[i]=1;

   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetStrokeColorWithColor(self,color);
   
   O2ColorRelease(color);
}

void O2ContextSetFillColorSpace(O2ContextRef self,O2ColorSpaceRef colorSpace) {
   int   i,length=O2ColorSpaceGetNumberOfComponents(colorSpace);
   O2Float components[length+1];
   
   for(i=0;i<length;i++)
    components[i]=0;
   components[i]=1;

   O2ColorRef color=O2ColorCreate(colorSpace,components);

   O2ContextSetFillColorWithColor(self,color);
   
   O2ColorRelease(color);
}

void O2ContextSetStrokeColor(O2ContextRef self,const O2Float *components) {
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace([self strokeColor]);
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetStrokeColorWithColor(self,color);
   
   O2ColorRelease(color);
}

void O2ContextSetStrokeColorWithColor(O2ContextRef self,O2ColorRef color) {
   O2GStateSetStrokeColor(currentState(self),color);
}

void O2ContextSetGrayStrokeColor(O2ContextRef self,O2Float gray,O2Float alpha) {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceGray();
   O2Float         components[2]={gray,alpha};
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetStrokeColorWithColor(self,color);
   
   O2ColorRelease(color);
   O2ColorSpaceRelease(colorSpace);
}

void O2ContextSetRGBStrokeColor(O2ContextRef self,O2Float r,O2Float g,O2Float b,O2Float alpha) {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceRGB();
   O2Float         components[4]={r,g,b,alpha};
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetStrokeColorWithColor(self,color);
   
   O2ColorRelease(color);
   O2ColorSpaceRelease(colorSpace);
}

void O2ContextSetCMYKStrokeColor(O2ContextRef self,O2Float c,O2Float m,O2Float y,O2Float k,O2Float alpha) {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceCMYK();
   O2Float         components[5]={c,m,y,k,alpha};
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetStrokeColorWithColor(self,color);
   
   O2ColorRelease(color);
   O2ColorSpaceRelease(colorSpace);
}

void O2ContextSetCalibratedRGBStrokeColor(O2ContextRef self,O2Float red,O2Float green,O2Float blue,O2Float alpha) {
}

void O2ContextSetCalibratedGrayStrokeColor(O2ContextRef self,O2Float gray,O2Float alpha) {
}

void O2ContextSetFillColor(O2ContextRef self,const O2Float *components) {
   O2ColorSpaceRef colorSpace=O2ColorGetColorSpace(O2ContextFillColor(self));
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetFillColorWithColor(self,color);
   
   O2ColorRelease(color);
}

void O2ContextSetFillColorWithColor(O2ContextRef self,O2ColorRef color) {
   O2GStateSetFillColor(currentState(self),color);
}

void O2ContextSetGrayFillColor(O2ContextRef self,O2Float gray,O2Float alpha) {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceGray();
   O2Float         components[2]={gray,alpha};
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetFillColorWithColor(self,color);
   
   O2ColorRelease(color);
   O2ColorSpaceRelease(colorSpace);
}

void O2ContextSetRGBFillColor(O2ContextRef self,O2Float r,O2Float g,O2Float b,O2Float alpha) {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceRGB();
   O2Float         components[4]={r,g,b,alpha};
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetFillColorWithColor(self,color);
   
   O2ColorRelease(color);
   O2ColorSpaceRelease(colorSpace);
}

void O2ContextSetCMYKFillColor(O2ContextRef self,O2Float c,O2Float m,O2Float y,O2Float k,O2Float alpha) {
   O2ColorSpaceRef colorSpace=O2ColorSpaceCreateDeviceCMYK();
   O2Float         components[5]={c,m,y,k,alpha};
   O2ColorRef color=O2ColorCreate(colorSpace,components);
   
   O2ContextSetFillColorWithColor(self,color);
   
   O2ColorRelease(color);
   O2ColorSpaceRelease(colorSpace);
}

void O2ContextSetCalibratedGrayFillColor(O2ContextRef self,O2Float gray,O2Float alpha) {
}

void O2ContextSetCalibratedRGBFillColor(O2ContextRef self,O2Float red,O2Float green,O2Float blue,O2Float alpha) {
}

void O2ContextSetAlpha(O2ContextRef self,O2Float alpha) {
   [self setStrokeAlpha:alpha];
   [self setFillAlpha:alpha];
}

void O2ContextSetPatternPhase(O2ContextRef self,O2Size phase) {
   [currentState(self) setPatternPhase:phase];
}

void O2ContextSetStrokePattern(O2ContextRef self,O2PatternRef pattern,const O2Float *components) {
   [currentState(self) setStrokePattern:pattern components:components];
}

void O2ContextSetFillPattern(O2ContextRef self,O2PatternRef pattern,const O2Float *components) {
   [currentState(self) setFillPattern:pattern components:components];
}

void O2ContextSetTextMatrix(O2ContextRef self,O2AffineTransform matrix) {
   O2GStateSetTextMatrix(currentState(self),matrix);
}

void O2ContextSetTextPosition(O2ContextRef self,O2Float x,O2Float y) {
   O2GStateSetTextPosition(currentState(self),x,y);
}

void O2ContextSetCharacterSpacing(O2ContextRef self,O2Float spacing) {
   [currentState(self) setCharacterSpacing:spacing];
}

void O2ContextSetTextDrawingMode(O2ContextRef self,O2TextDrawingMode textMode) {
   [currentState(self) setTextDrawingMode:textMode];
}

void O2ContextSetFont(O2ContextRef self,O2FontRef font) {
   O2GStateSetFont(currentState(self),font);
}

void O2ContextSetFontSize(O2ContextRef self,O2Float size) {
   O2GStateSetFontSize(currentState(self),size);
}

void O2ContextSelectFont(O2ContextRef self,const char *name,O2Float size,O2TextEncoding encoding) {
   [currentState(self) selectFontWithName:name size:size encoding:encoding];
}

void O2ContextSetShouldSmoothFonts(O2ContextRef self,BOOL yesOrNo) {
   [currentState(self) setShouldSmoothFonts:yesOrNo];
}

void O2ContextSetLineWidth(O2ContextRef self,O2Float width) {
   O2GStateSetLineWidth(currentState(self),width);
}

void O2ContextSetLineCap(O2ContextRef self,O2LineCap lineCap) {
   O2GStateSetLineCap(currentState(self),lineCap);
}

void O2ContextSetLineJoin(O2ContextRef self,O2LineJoin lineJoin) {
   O2GStateSetLineJoin(currentState(self),lineJoin);
}

void O2ContextSetMiterLimit(O2ContextRef self,O2Float miterLimit) {
   O2GStateSetMiterLimit(currentState(self),miterLimit);
}

void O2ContextSetLineDash(O2ContextRef self,O2Float phase,const O2Float *lengths,unsigned count) {
   O2GStateSetLineDash(currentState(self),phase,lengths,count);
}

void O2ContextSetRenderingIntent(O2ContextRef self,O2ColorRenderingIntent renderingIntent) {
   [currentState(self) setRenderingIntent:renderingIntent];
}

void O2ContextSetBlendMode(O2ContextRef self,O2BlendMode blendMode) {
   O2GStateSetBlendMode(currentState(self),blendMode);
}

void O2ContextSetFlatness(O2ContextRef self,O2Float flatness) {
   [currentState(self) setFlatness:flatness];
}

void O2ContextSetInterpolationQuality(O2ContextRef self,O2InterpolationQuality quality) {
   [currentState(self) setInterpolationQuality:quality];
}

void O2ContextSetShadowWithColor(O2ContextRef self,O2Size offset,O2Float blur,O2ColorRef color) {
   [currentState(self) setShadowOffset:offset blur:blur color:color];
}

void O2ContextSetShadow(O2ContextRef self,O2Size offset,O2Float blur) {
   [currentState(self) setShadowOffset:offset blur:blur];
}

void O2ContextSetShouldAntialias(O2ContextRef self,BOOL yesOrNo) {
   [currentState(self) setShouldAntialias:yesOrNo];
}

// drawing
void O2ContextStrokeLineSegments(O2ContextRef self,const O2Point *points,unsigned count) {
   int i;
   
   O2ContextBeginPath(self);
   for(i=0;i<count;i+=2){
    O2ContextMoveToPoint(self,points[i].x,points[i].y);
    O2ContextAddLineToPoint(self,points[i+1].x,points[i+1].y);
   }
   O2ContextStrokePath(self);
}

void O2ContextStrokeRect(O2ContextRef self,O2Rect rect) {
   O2ContextBeginPath(self);
   O2ContextAddRect(self,rect);
   O2ContextStrokePath(self);
}

void O2ContextStrokeRectWithWidth(O2ContextRef self,O2Rect rect,O2Float width) {
   O2ContextSaveGState(self);
   O2ContextSetLineWidth(self,width);
   O2ContextBeginPath(self);
   O2ContextAddRect(self,rect);
   O2ContextStrokePath(self);
   O2ContextRestoreGState(self);
}

void O2ContextStrokeEllipseInRect(O2ContextRef self,O2Rect rect) {
   O2ContextBeginPath(self);
   O2ContextAddEllipseInRect(self,rect);
   O2ContextStrokePath(self);
}

void O2ContextFillRect(O2ContextRef self,O2Rect rect) {
   O2ContextFillRects(self,&rect,1);
}

void O2ContextFillRects(O2ContextRef self,const O2Rect *rects,unsigned count) {
   O2ContextBeginPath(self);
   O2ContextAddRects(self,rects,count);
   O2ContextFillPath(self);
}

void O2ContextFillEllipseInRect(O2ContextRef self,O2Rect rect) {
   O2ContextBeginPath(self);
   O2ContextAddEllipseInRect(self,rect);
   O2ContextFillPath(self);
}

void O2ContextDrawPath(O2ContextRef self,O2PathDrawingMode pathMode) {
   [self drawPath:pathMode];
}

void O2ContextStrokePath(O2ContextRef self) {
   O2ContextDrawPath(self,kO2PathStroke);
}

void O2ContextFillPath(O2ContextRef self) {
   O2ContextDrawPath(self,kO2PathFill);
}

void O2ContextEOFillPath(O2ContextRef self) {
   O2ContextDrawPath(self,kO2PathEOFill);
}

void O2ContextClearRect(O2ContextRef self,O2Rect rect) {
// doc.s are not clear. tests say O2ContextClearRect resets the path and does not affect gstate color
   O2ContextSaveGState(self);
   O2ContextSetBlendMode(self,kO2BlendModeCopy); // does it set the blend mode?
   O2ContextSetGrayFillColor(self,0,0);
   O2ContextFillRect(self,rect);
   O2ContextRestoreGState(self);
}

void O2ContextShowGlyphs(O2ContextRef self,const O2Glyph *glyphs,unsigned count) {
   [self showGlyphs:glyphs count:count];
}

void O2ContextShowGlyphsAtPoint(O2ContextRef self,O2Float x,O2Float y,const O2Glyph *glyphs,unsigned count) {
   O2ContextSetTextPosition(self,x,y);
   O2ContextShowGlyphs(self,glyphs,count);
}

void O2ContextShowGlyphsWithAdvances(O2ContextRef self,const O2Glyph *glyphs,const O2Size *advances,unsigned count) {
   O2AffineTransform textMatrix=[currentState(self) textMatrix];
   O2Float             x=textMatrix.tx;
   O2Float             y=textMatrix.ty;
   int i;
   
   for(i=0;i<count;i++){
    [self showGlyphs:glyphs+i count:1];
    
    x+=advances[i].width;
    y+=advances[i].height;
    O2ContextSetTextPosition(self,x,y);
   }
}

void O2ContextShowText(O2ContextRef self,const char *text,unsigned count) {
   [self showText:text length:count];
}

void O2ContextShowTextAtPoint(O2ContextRef self,O2Float x,O2Float y,const char *text,unsigned count) {
   O2ContextSetTextPosition(self,x,y);
   O2ContextShowText(self,text,count);
}

void O2ContextDrawShading(O2ContextRef self,O2ShadingRef shading) {
   [self drawShading:shading];
}

void O2ContextDrawImage(O2ContextRef self,O2Rect rect,O2ImageRef image) {
   [self drawImage:image inRect:rect];
}

void O2ContextDrawLayerAtPoint(O2ContextRef self,O2Point point,O2LayerRef layer) {
   O2Size size=O2LayerGetSize(layer);
   O2Rect rect={point,size};
   
   O2ContextDrawLayerInRect(self,rect,layer);
}

void O2ContextDrawLayerInRect(O2ContextRef self,O2Rect rect,O2LayerRef layer) {
   [self drawLayer:layer inRect:rect];
}

void O2ContextDrawPDFPage(O2ContextRef self,O2PDFPageRef page) {
   [page drawInContext:self];
}

void O2ContextFlush(O2ContextRef self) {
   [self flush];
}

void O2ContextSynchronize(O2ContextRef self) {
   [self synchronize];
}

// pagination

void O2ContextBeginPage(O2ContextRef self,const O2Rect *mediaBox) {
   [self beginPage:mediaBox];
}

void O2ContextEndPage(O2ContextRef self) {
   [self endPage];
}

// **PRIVATE** These are private in Apple's implementation as well as ours.

void O2ContextSetCTM(O2ContextRef self,O2AffineTransform matrix) {
   O2AffineTransform deviceTransform=self->_userToDeviceTransform;
   
   deviceTransform=O2AffineTransformConcat(matrix,deviceTransform);
   
   O2GStateSetDeviceSpaceCTM(currentState(self),deviceTransform);

   O2GStateSetUserSpaceCTM(currentState(self),matrix);
}

void O2ContextResetClip(O2ContextRef self) {
   [currentState(self) removeAllClipPhases];
   [self deviceClipReset];
}

// Temporary hacks

NSData *O2ContextCaptureBitmap(O2ContextRef self,O2Rect rect) {
   return [self captureBitmapInRect:rect];
}

void O2ContextCopyBits(O2ContextRef self,O2Rect rect,O2Point point,int gState) {
   [self copyBitsInRect:rect toPoint:point gState:gState];
}


@end
