#import "GradientView.h"
#import <ApplicationServices/ApplicationServices.h>

@implementation GradientView

-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _C0[0]=0;
   _C0[1]=0;
   _C0[2]=0;
   _C0[3]=1;

   _C1[0]=1;
   _C1[1]=1;
   _C1[2]=1;
   _C1[3]=1;
   _startPoint=NSMakePoint(0,0);
   _endPoint=NSMakePoint(frame.size.width,frame.size.height);
   _extendStart=NO;
   _extendEnd=NO;
   _mouseFirst=YES;
   return self;
}

void evaluate(void *info,const float *in, float *output) {
   float         x=in[0];
   GradientView *self=info;
   int           i;
   
    for(i=0;i<4;i++)
     output[i]=self->_C0[i]+x*(self->_C1[i]-self->_C0[i]);
}

-(void)drawRect:(NSRect)rect {
   CGContextRef  context=[[NSGraphicsContext currentContext] graphicsPort];
   CGFunctionRef function;
   CGShadingRef  shading;
   float         domain[2]={0,1};
   float         range[8]={0,1,0,1,0,1,0,1};
   CGFunctionCallbacks callbacks={0,evaluate,NULL};
   
   [[NSColor whiteColor] set];
   NSRectFill([self bounds]);
      
   function=CGFunctionCreate(self,1,domain,4,range,&callbacks);
   shading=CGShadingCreateAxial(CGColorSpaceCreateDeviceRGB(),CGPointMake(_startPoint.x,_startPoint.y),
      CGPointMake(_endPoint.x,_endPoint.y),function,_extendStart,_extendEnd);
    
   CGContextDrawShading(context,shading);
   
   CGFunctionRelease(function);
   CGShadingRelease(shading);
}

-(void)mouseDown:(NSEvent *)event {
  NSPoint *dest=(_mouseFirst)?&_startPoint:&_endPoint;
  
  do {
   NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];
   
   *dest=point;
   
   [self setNeedsDisplay:YES];
   event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
  }while([event type]!=NSLeftMouseUp);
  
  _mouseFirst=!_mouseFirst;
}

-(IBAction)takeStartColorFromSender:sender {
   NSColor *color=[[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
   
   [color getRed:_C0 green:_C0+1 blue:_C0+2 alpha:_C0+3];
   [self setNeedsDisplay:YES];
}

-(IBAction)takeEndColorFromSender:sender {
   NSColor *color=[[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
   
   [color getRed:_C1 green:_C1+1 blue:_C1+2 alpha:_C1+3];
   [self setNeedsDisplay:YES];
}

-(IBAction)takeExtendStartFromSender:sender {
   _extendStart=[sender intValue]?YES:NO;
   [self setNeedsDisplay:YES];
}

-(IBAction)takeExtendEndFromSender:sender {
   _extendEnd=[sender intValue]?YES:NO;
   [self setNeedsDisplay:YES];
}

@end
