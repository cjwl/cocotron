#import <AppKit/KGGraphicsState.h>

@class KGRenderingContext;

@interface KGGraphicsState_gdi : KGGraphicsState {
   KGRenderingContext *_renderingContext;
   id                  _deviceState;
}

-initWithRenderingContext:(KGRenderingContext *)context transform:(CGAffineTransform)deviceTransform;

-(KGRenderingContext *)renderingContext;

-(void)strokeRect:(NSRect)rect width:(float)width;

-(void)fillRects:(const NSRect *)rects count:(unsigned)count;

-(void)drawPath:(KGPath *)path mode:(CGPathDrawingMode)mode;

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count;

-(void)drawShading:(KGShading *)shading;
-(void)drawImage:(KGImage *)image inRect:(NSRect)rect;
-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect;

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point;

@end
