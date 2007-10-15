#import "KGContext_gdi.h"
#import "KGLayer_gdi.h"
#import "KGRenderingContext_gdi.h"
#import "KGGraphicsState_gdi.h"
#import <AppKit/KGDeviceContext.h>
#import <AppKit/KGMutablePath.h>

@implementation KGContext_gdi

-(KGGraphicsState_gdi *)currentState {
   return [_stateStack lastObject];
}

-(void)strokeRect:(NSRect)rect {
   [self strokeRect:rect width:[self currentState]->_lineWidth];
}

-(void)strokeRect:(NSRect)rect width:(float)width {
   [[self currentState] strokeRect:rect width:width];
}

-(void)fillRects:(const NSRect *)rects count:(unsigned)count {
   [[self currentState] fillRects:rects count:count];
}

-(void)drawPath:(CGPathDrawingMode)pathMode {
   [[self currentState] drawPath:_path mode:pathMode];
   [_path reset];
}

-(void)showGlyphs:(const CGGlyph *)glyphs count:(unsigned)count {
   [[self currentState] showGlyphs:glyphs count:count];
}

-(void)drawShading:(KGShading *)shading {
   [[self currentState] drawShading:shading];
}

-(void)drawImage:(KGImage *)image inRect:(NSRect)rect {
   [[self currentState] drawImage:image inRect:rect];
}

-(void)drawLayer:(KGLayer *)layer inRect:(NSRect)rect {
   [[self currentState] drawLayer:layer inRect:rect];
}

-(void)copyBitsInRect:(NSRect)rect toPoint:(NSPoint)point gState:(int)gState {
   [[self currentState] copyBitsInRect:rect toPoint:point];
}

-(KGRenderingContext_gdi *)renderingContext {
   return [[self->_stateStack lastObject] renderingContext];
}

-(KGLayer *)layerWithSize:(NSSize)size unused:(NSDictionary *)unused {
   return [[[KGLayer_gdi alloc] initRelativeToRenderingContext:[self renderingContext] size:size unused:unused] autorelease];
}

-(void)beginPrintingWithDocumentName:(NSString *)documentName {
   [[self renderingContext] beginPrintingWithDocumentName:documentName];
}

-(void)endPrinting {
   [[self renderingContext] endPrinting];
}

-(BOOL)getImageableRect:(NSRect *)rect {
   KGDeviceContext *deviceContext=[[self renderingContext] deviceContext];
   if(deviceContext==nil)
    return NO;
    
   *rect=[deviceContext imageableRect];
   return YES;
}

-(void)drawContext:(KGContext *)other inRect:(CGRect)rect {
   if(![other isKindOfClass:[KGContext_gdi class]])
    return;
   
   CGAffineTransform ctm;
   
   [self getCTM:&ctm];
      
   [[self renderingContext] drawOther:[(KGContext_gdi *)other renderingContext] inRect:rect ctm:ctm];
 }

-(void)flush {
   GdiFlush();
}

@end
