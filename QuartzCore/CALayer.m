#import <QuartzCore/CALayer.h>

@implementation CALayer

+layer {
   return [[[self alloc] init] autorelease];
}

@synthesize superLayer=_superLayer;
@synthesize sublayers=_sublayers;
@synthesize delegate=_delegate;
@synthesize frame=_frame;
@synthesize bounds=_bounds;
@synthesize opacity=_opacity;
@synthesize opaque=_opaque;
@synthesize contents=_contents;
@synthesize transform=_transform;
@synthesize sublayerTransform=_sublayerTransform;

-init {
   _superLayer=nil;
   _sublayers=[NSMutableArray new];
   _delegate=nil;
   _frame=CGRectZero;
   _bounds=CGRectZero;
   _opacity=1.0;
   _opaque=YES;
   _contents=nil;
   _transform=CATransform3DIdentity;
   _sublayerTransform=CATransform3DIdentity;
   return self;
}

-(void)_setSuperLayer:(CALayer *)parent {
   _superLayer=parent;
}

-(void)_removeSublayer:(CALayer *)child {
   [_sublayers removeObjectIdenticalTo:child];
}

-(void)addSublayer:(CALayer *)layer {
   [_sublayers addObject:layer];
   [layer _setSuperLayer:self];
}

-(void)display {
}

-(void)displayIfNeeded {
}

-(void)drawInContext:(CGContextRef)context {
}

-(BOOL)needsDisplay {
   return _needsDisplay;
}

-(void)removeFromSuperlayer {
   [_superLayer _removeSublayer:self];
   _superLayer=nil;
}

-(void)setNeedsDisplay {
   _needsDisplay=YES;
}

-(void)setNeedsDisplayInRect:(CGRect)rect {
   _needsDisplay=YES;
}

@end
