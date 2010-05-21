#import <QuartzCore/CALayer.h>

@implementation CALayer

+layer {
   return [[[self alloc] init] autorelease];
}

-(CALayer *)superLayer {
   return _superLayer;
}

-(NSArray *)sublayers {
   return _sublayers;
}

-(void)setSublayers:(NSArray *)sublayers {
   sublayers=[sublayers copy];
   [_sublayers release];
   _sublayers=sublayers;
   [_sublayers makeObjectsPerformSelector:@selector(_setSuperLayer:) withObject:self];
}

-(id)delegate {
   return _delegate;
}

-(void)setDelegate:value {
   _delegate=value;
}

-(CGRect)frame {
   return _frame;
}

-(void)setFrame:(CGRect)value {
   _frame=value;
}

-(CGRect)bounds {
   return _bounds;
}

-(void)setBounds:(CGRect)value {
   _bounds=value;
}

-(float)opacity {
   return _opacity;
}

-(void)setOpacity:(float)value {
   _opacity=value;
}

-(BOOL)opaque {
   return _opaque;
}

-(void)setOpaque:(BOOL)value {
   _opaque=value;
}

-(id)contents {
   return _contents;
}

-(void)setContents:(id)value {
   value=[value retain];
   [_contents release];
   _contents=value;
}

-(CATransform3D)transform {
   return _transform;
}

-(void)setTransform:(CATransform3D)value {
   _transform=value;
}

-(CATransform3D)sublayerTransform {
   return _sublayerTransform;
}

-(void)setSublayerTransform:(CATransform3D)value {
   _sublayerTransform=value;
}

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
   NSMutableArray *layers=[_sublayers mutableCopy];
   [layers removeObjectIdenticalTo:child];
   [self setSublayers:layers];
}

-(void)addSublayer:(CALayer *)layer {
   [self setSublayers:[_sublayers arrayByAddingObject:layer]];
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
