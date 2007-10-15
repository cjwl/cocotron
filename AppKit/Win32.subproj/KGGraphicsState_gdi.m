#import "KGGraphicsState_gdi.h"
#import <AppKit/KGRenderingContext.h>
#import <AppKit/KGColor.h>
#import <AppKit/KGFont.h>

@implementation KGGraphicsState_gdi

-initWithRenderingContext:(KGRenderingContext *)context transform:(CGAffineTransform)deviceTransform {
   [super initWithTransform:deviceTransform];
   _renderingContext=[context retain];
   _deviceState=nil;
   return self;
}

-(void)dealloc {
   [_renderingContext release];
   [_deviceState release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   KGGraphicsState_gdi *copy=[super copyWithZone:zone];
   
   copy->_renderingContext=[_renderingContext retain];
   copy->_deviceState=nil;
   
   return copy;
}

-(KGRenderingContext *)renderingContext {
   return _renderingContext;
}

-(void)save {
   _deviceState=[_renderingContext saveCopyOfDeviceState];
}

-(void)restore {
   [_renderingContext restoreDeviceState:_deviceState];
   [_deviceState release];
   _deviceState=nil;
}

-(void)clipToPath:(KGPath *)path {
   [_renderingContext clipToDeviceSpacePath:path];
}

-(void)evenOddClipToPath:(KGPath *)path {
   [_renderingContext evenOddClipToDeviceSpacePath:path];
}

-(void)clipToRects:(const NSRect *)rects count:(unsigned)count {
   [_renderingContext clipInUserSpace:_ctm rects:rects count:count];
}

-(void)setFont:(KGFont *)font {
   [super setFont:font];
   [_renderingContext setFont:_font];
}

-(void)strokeRect:(NSRect)rect width:(float)width {
   [_renderingContext strokeInUserSpace:_ctm rect:rect width:width color:_strokeColor];
}

-(void)fillRects:(const NSRect *)rects count:(unsigned)count {
   [_renderingContext fillInUserSpace:_ctm rects:rects count:count color:_fillColor];
}

-(void)drawPath:(KGPath *)path mode:(CGPathDrawingMode)mode {
   [_renderingContext drawPathInDeviceSpace:path drawingMode:mode ctm:_ctm lineWidth:_lineWidth fillColor:_fillColor strokeColor:_strokeColor];
}

-(void)drawShading:(KGShading *)shading {
   [_renderingContext drawInUserSpace:_ctm shading:shading];
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect {
   [_renderingContext drawImage:image inRect:rect ctm:_ctm fraction:[_fillColor alpha]];
}

-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect {
   [_renderingContext drawLayer:layer inRect:rect ctm:_ctm];
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point {
   [_renderingContext copyBitsInUserSpace:_ctm rect:rect toPoint:point];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)numberOfGlyphs {
   [_renderingContext showInUserSpace:_ctm textSpace:_textTransform glyphs:glyphs count:numberOfGlyphs color:_fillColor];
   
   NSSize advancement;
   
   advancement=[_font advancementForNominalGlyphs:glyphs count:numberOfGlyphs];
   
   _textTransform.tx+=advancement.width;
   _textTransform.ty+=advancement.height;
}

-(void)beginPage:(const NSRect *)mediaBox {
   [_renderingContext beginPage];
}

-(void)endPage {
   [_renderingContext endPage];
}

-(void)resetClip {
   [_renderingContext resetClip];
}

@end
