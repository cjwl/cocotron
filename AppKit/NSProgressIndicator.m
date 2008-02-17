/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsStyle.h>
#import <AppKit/NSNibKeyedUnarchiver.h>
#import <AppKit/NSGraphicsContextFunctions.h>
#import <AppKit/CoreGraphics.h>

@implementation NSProgressIndicator

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   [super initWithCoder:coder];

   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    unsigned           flags=[keyed decodeIntForKey:@"NSpiFlags"];

    _minValue=[keyed decodeDoubleForKey:@"NSMinValue"];
    _maxValue=[keyed decodeDoubleForKey:@"NSMaxValue"];
    _value=_minValue;
    _animationDelay=5.0/60.0;
    _animationTimer=nil;
    _animationValue=0;
    _style=(flags&0x1000)?NSProgressIndicatorSpinningStyle:NSProgressIndicatorBarStyle;
    _size=(flags&0x100)?NSSmallControlSize:NSRegularControlSize;
    _displayWhenStopped=(flags&0x2000)?YES:NO;
    _isBezeled=YES;    
    _isIndeterminate=(flags&0x02)?YES:NO;
    _usesThreadedAnimation=NO;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,SELNAME(_cmd),coder];
   }
   return self;
}


-initWithFrame:(NSRect)frame {
   [super initWithFrame:frame];
   _value=0;
   _minValue=0;
   _maxValue=100;
   _animationDelay=5.0/60.0;
   _animationTimer=nil;
   _animationValue=0;
   _style=NSProgressIndicatorBarStyle;
   _size=NSRegularControlSize;
   _tint=0;
   _displayWhenStopped=NO;
   _isBezeled=YES;
   _isIndeterminate=YES;
   _usesThreadedAnimation=NO;
   
   return self;
}

-(void)_invalidateTimer {
    [_animationTimer invalidate];
    [_animationTimer release];
    _animationTimer=nil;
}

-(void)_buildTimer {
    _animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_animationDelay
                                                        target:self
                                                      selector:@selector(animate:)
                                                      userInfo:nil
                                                       repeats:YES] retain];
}

-(void)dealloc {
   [self _invalidateTimer];
   
   [super dealloc];
}

-(BOOL)isFlipped {
    return YES;
}

void evaluate(void *info,const float *in, float *output) {
   float                x=in[0];
   float                _C0[4]={1,1,1,0};
   float                _C1[4]={0,0,1,0};
   int                  i;
      
    for(i=0;i<4;i++)
     output[i]=_C0[i]+x*(_C1[i]-_C0[i]);
}

-(void)drawRect:(NSRect)clipRect {
   if(_style==NSProgressIndicatorBarStyle){
    if(_isIndeterminate){
     [[self graphicsStyle] drawProgressIndicatorIndeterminate:_bounds clipRect:clipRect bezeled:_isBezeled animation:_animationValue];
    }
    else {
     double value=(_value-_minValue)/(_maxValue-_minValue);

     [[self graphicsStyle] drawProgressIndicatorDeterminate:_bounds clipRect:clipRect bezeled:_isBezeled value:value];
    }
   }
   else {
    CGFunctionRef function;
    CGShadingRef  shading;
    float         domain[2]={0,1};
    float         range[8]={0,1,0,1,0,1,0,1};
    CGFunctionCallbacks callbacks={0,evaluate,NULL};

    CGContextRef graphicsPort=NSCurrentGraphicsPort();
    CGContextSaveGState(graphicsPort);
    CGContextBeginPath(graphicsPort);
    CGContextAddEllipseInRect(graphicsPort,[self bounds]);
    CGContextClip(graphicsPort);

    CGContextTranslateCTM(graphicsPort,[self bounds].size.width/2,[self bounds].size.height/2);
    CGContextRotateCTM(graphicsPort,M_PI*(_animationValue*360.0)/180.0);

    function=CGFunctionCreate(self,1,domain,4,range,&callbacks);
    
    float radius=[self bounds].size.width/2;
    shading=CGShadingCreateRadial(CGColorSpaceCreateDeviceRGB(),CGPointMake(0,0),1,
       CGPointMake(radius *2,radius*2),radius,function,YES,NO);

    CGContextDrawShading(graphicsPort,shading);
    CGContextRotateCTM(graphicsPort,M_PI*(120)/180.0);
    CGContextDrawShading(graphicsPort,shading);
    CGContextRotateCTM(graphicsPort,M_PI*(120)/180.0);
    CGContextDrawShading(graphicsPort,shading);
   
    CGFunctionRelease(function);
    CGShadingRelease(shading);

    CGContextRestoreGState(graphicsPort);
   }   
}

-(NSProgressIndicatorStyle)style {
   return _style;
}

-(NSControlSize)controlSize {
   return _size;
}

-(NSControlTint)controlTint {
   return _tint;
}

-(BOOL)isDisplayedWhenStopped {
   return _displayWhenStopped;
}

-(BOOL)usesThreadedAnimation {
   return _usesThreadedAnimation;
}

-(double)minValue {
    return _minValue;
}

-(double)maxValue {
    return _maxValue;
}

-(double)doubleValue {
    return _value;
}

-(NSTimeInterval)animationDelay {
    return _animationDelay;
}

-(BOOL)isIndeterminate {
    return _isIndeterminate;
}

-(BOOL)isBezeled {
    return _isBezeled;
}

-(void)setStyle:(NSProgressIndicatorStyle)value {
   _style=value;
   [self sizeToFit];
   [self setNeedsDisplay:YES];
}

-(void)setControlSize:(NSControlSize)value {
   _size=value;
   [self sizeToFit];
   [self setNeedsDisplay:YES];
}

-(void)setControlTint:(NSControlTint)value {
   _tint=value;
   [self setNeedsDisplay:YES];
}

-(void)setDisplayedWhenStopped:(BOOL)value {
   _displayWhenStopped=value;
   [self setNeedsDisplay:YES];
}

-(void)setUsesThreadedAnimation:(BOOL)value {
   _usesThreadedAnimation=value;
}

-(void)setMinValue:(double)value {
    _minValue = value;
    [self setNeedsDisplay:YES];
}

-(void)setMaxValue:(double)value {
    _maxValue = value;
    [self setNeedsDisplay:YES];
}

-(void)setDoubleValue:(double)value {
   if(value<_minValue)
    value=_minValue;
   if(value>_maxValue)
    value=_maxValue;
     
   _value = value;
   [self setNeedsDisplay:YES];
}

-(void)setAnimationDelay:(double)delay {
    _animationDelay = delay;
   [self _invalidateTimer];
   [self _buildTimer];
}

-(void)setIndeterminate:(BOOL)flag {
   _isIndeterminate = flag;
   [self setNeedsDisplay:YES];
}

-(void)setBezeled:(BOOL)flag {
   _isBezeled = flag;
   [self setNeedsDisplay:YES];
}

-(void)incrementBy:(double)value {
   [self setDoubleValue:_value+value];
}

-(void)sizeToFit {
}

-(void)startAnimation:sender {
   if (!_isIndeterminate)
    [NSException raise:NSInternalInconsistencyException format:@"startAnimation: called on determinate NSProgressIndicator"];

   if(_animationTimer!=nil)
    return;
   
   [self _buildTimer];
}

-(void)stopAnimation:sender {
   if (!_isIndeterminate)
    [NSException raise:NSInternalInconsistencyException format:@"stopAnimation: called on determinate NSProgressIndicator"];

   [self _invalidateTimer];
}

-(void)animate:sender {
   _animationValue+=1.0/[self bounds].size.width;
    
   if(_animationValue>1)
    _animationValue=0;
    
   [self setNeedsDisplay:YES];
}

@end
