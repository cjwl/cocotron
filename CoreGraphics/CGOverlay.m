#import <CoreGraphics/CGOverlay.h>
#import <CoreGraphics/CGWindow.h>

@implementation CGOverlay

-initWithFrame:(O2Rect)frame {
   _frame=frame;
   return self;
}

-(void)dealloc {
   [_surface release];
   [super dealloc];
}

-(CGWindow *)window {
   return _window;
}

-(BOOL)isOpaque {
   return _isOpaque;
}

-(O2Rect)frame {
   return _frame;
}

-(O2Surface *)surface {
   return _surface;
}

-(void)setWindow:(CGWindow *)window {
   _window=window;
}

-(void)setFrame:(O2Rect)frame {
   _frame=frame;
}

-(void)setOpaque:(BOOL)value {
   _isOpaque=value;
}

-(void)setSurface:(O2Surface *)value {
   value=[value retain];
   [_surface release];
   _surface=value;
}

-(void)flushBuffer {
   [_window flushOverlay:self];
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@ %p:frame=%@ surface=%@",isa,self,NSStringFromRect(_frame),_surface];
}

@end
