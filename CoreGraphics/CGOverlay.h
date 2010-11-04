#import <Foundation/NSObject.h>
#import <Onyx2D/O2Geometry.h>

@class O2Surface,CGWindow;

@interface CGOverlay : NSObject {
   CGWindow  *_window;
   O2Rect     _frame;
   BOOL       _isOpaque;
   O2Surface *_surface;
}

-initWithFrame:(O2Rect)frame;

-(CGWindow *)window;
-(BOOL)isOpaque;
-(O2Rect)frame;
-(O2Surface *)surface;

-(void)setWindow:(CGWindow *)window;
-(void)setFrame:(O2Rect)frame;
-(void)setOpaque:(BOOL)value;
-(void)setSurface:(O2Surface *)value;

-(void)flushBuffer;

@end

