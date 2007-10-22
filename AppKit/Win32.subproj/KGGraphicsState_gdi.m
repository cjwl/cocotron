#import "KGGraphicsState_gdi.h"
#import <AppKit/KGRenderingContext_gdi.h>
#import <AppKit/KGColor.h>
#import <AppKit/KGFont.h>

@implementation KGGraphicsState_gdi

-initWithRenderingContext:(KGRenderingContext_gdi *)context transform:(CGAffineTransform)deviceTransform {
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

-(KGRenderingContext_gdi *)renderingContext {
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
