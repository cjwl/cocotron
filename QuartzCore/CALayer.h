
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzCore/CATransform3D.h>

enum {
   kCALayerNotSizable   = 0x00,
   kCALayerMinXMargin   = 0x01,
   kCALayerWidthSizable = 0x02,
   kCALayerMaxXMargin   = 0x04,
   kCALayerMinYMargin   = 0x08,
   kCALayerHeightSizable= 0x10,
   kCALayerMaxYMargin   = 0x20,
};

@interface CALayer : NSObject {
   CALayer      *_superLayer;
   NSArray      *_sublayers;
   id            _delegate;
   CGRect        _frame;
   CGRect        _bounds;
   float         _opacity;
   BOOL          _opaque;
   id            _contents;
   CATransform3D _transform;
   CATransform3D _sublayerTransform;
   BOOL          _needsDisplay;
}

+layer;

@property(readonly) CALayer *superLayer;
@property(copy) NSArray *sublayers;
@property(assign) id delegate;
@property CGRect frame;
@property CGRect bounds;
@property float opacity;
@property BOOL opaque;
@property(retain) id contents;
//@property CATransform3D transform;
@property CATransform3D sublayerTransform;

-init;

-(void)addSublayer:(CALayer *)layer;
-(void)display;
-(void)displayIfNeeded;
-(void)drawInContext:(CGContextRef)context;
-(BOOL)needsDisplay;
-(void)removeFromSuperlayer;
-(void)setNeedsDisplay;
-(void)setNeedsDisplayInRect:(CGRect)rect;

@end

@interface NSObject(CALayerDelegate)

-(void)displayLayer:(CALayer *)layer;
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context;

@end
