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
   _C1[1]=0;
   _C1[2]=0;
   _C1[3]=1;
   _startPoint=NSMakePoint(0,0);
   _endPoint=NSMakePoint(frame.size.width,frame.size.height);
   _extendStart=NO;
   _extendEnd=NO;
   _startRadius=10;
   _endRadius=100;
   _mouseFirst=YES;
   return self;
}

-(void)updateRadius {
   [_innerRadius setFloatValue:_startRadius];
   [_innerRadiusSlider setFloatValue:_startRadius];
   [_outerRadius setFloatValue:_endRadius];
   [_outerRadiusSlider setFloatValue:_endRadius];
}

-(void)updatePointFields {
   [_startXTextField setFloatValue:_startPoint.x];
   [_startYTextField setFloatValue:_startPoint.y];
   [_endXTextField setFloatValue:_endPoint.x];
   [_endYTextField setFloatValue:_endPoint.y];
}

-(void)awakeFromNib {
   [self updatePointFields];
   [self updateRadius];
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

   if([_shadingType selectedTag]==0)
    shading=CGShadingCreateAxial(CGColorSpaceCreateDeviceRGB(),CGPointMake(_startPoint.x,_startPoint.y),
      CGPointMake(_endPoint.x,_endPoint.y),function,_extendStart,_extendEnd);
   else 
    shading=CGShadingCreateRadial(CGColorSpaceCreateDeviceRGB(),CGPointMake(_startPoint.x,_startPoint.y),_startRadius,
       CGPointMake(_endPoint.x,_endPoint.y),_endRadius,function,_extendStart,_extendEnd);
    
   CGContextDrawShading(context,shading);
   
   CGFunctionRelease(function);
   CGShadingRelease(shading);
}

-(void)mouseDown:(NSEvent *)event {
  NSPoint *dest=(_mouseFirst)?&_startPoint:&_endPoint;
  
  do {
   NSPoint point=[self convertPoint:[event locationInWindow] fromView:nil];
   
   *dest=point;
   
   [self updatePointFields];
   [self setNeedsDisplay:YES];
   event=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
  }while([event type]!=NSLeftMouseUp);
  
  _mouseFirst=!_mouseFirst;
}

-(IBAction)selectType:sender {
   [self setNeedsDisplay:YES];
}

-(IBAction)takeStartXFromSender:sender {
   _startPoint.x=[sender floatValue];
   [self setNeedsDisplay:YES];
}

-(IBAction)takeStartYFromSender:sender {
   _startPoint.y=[sender floatValue];
   [self setNeedsDisplay:YES];
}

-(IBAction)takeEndXFromSender:sender {
   _endPoint.x=[sender floatValue];
   [self setNeedsDisplay:YES];
}

-(IBAction)takeEndYFromSender:sender {
   _endPoint.y=[sender floatValue];
   [self setNeedsDisplay:YES];
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

-(IBAction)takeInnerRadiusFromSender:sender {
   _startRadius=[sender floatValue];
   [self updateRadius];
   [self setNeedsDisplay:YES];
}

-(IBAction)takeOuterRadiusFromSender:sender {
   _endRadius=[sender floatValue];
   [self updateRadius];
   [self setNeedsDisplay:YES];
}

@end
