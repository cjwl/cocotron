/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSAnimation.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSArray.h>

NSString *NSAnimationProgressMarkNotification=@"NSAnimationProgressMarkNotification";

@implementation NSAnimation

-initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)curve {
   _duration=duration;
   _curve=curve;
   _frameRate=30;
   _blockingMode=NSAnimationBlocking;
   _delegate=nil;
   _progressMarks=nil;
   _currentValue=0;
   _runLoopModes=nil; // nil== default, modal and event tracking
   return self;
}

-(void)dealloc {
   [_progressMarks release];
   [_runLoopModes release];
   [super dealloc];
}

-(NSTimeInterval)duration {
   return _duration;
}

-(NSAnimationCurve)animationCurve {
   return _curve;
}

-(float)frameRate {
   return _frameRate;
}

-(NSAnimationBlockingMode)animationBlockingMode {
   return _blockingMode;
}

-delegate {
   return _delegate;
}

-(NSArray *)progressMarks {
   return _progressMarks;
}

-(void)setDuration:(NSTimeInterval)interval {
   _duration=interval;
}

-(void)setAnimationCurve:(NSAnimationCurve)curve {
   _curve=curve;
}

-(void)setFrameRate:(float)fps {
   _frameRate=fps;
}

-(void)setAnimationBlockingMode:(NSAnimationBlockingMode)mode {
   _blockingMode=mode;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setProgressMarks:(NSArray *)marks {
   marks=[marks copy];
   [_progressMarks release];
   _progressMarks=marks;
}

-(void)addProgressMark:(NSAnimationProgress)mark {
   NSUnimplementedMethod();
}

-(void)removeProgressMark:(NSAnimationProgress)mark {
   NSUnimplementedMethod();
}

-(NSAnimationProgress)currentProgress {
   NSUnimplementedMethod();
   return 0;
}

-(float)currentValue {
   return _currentValue;
}

-(BOOL)isAnimating {
   NSUnimplementedMethod();
   return NO;
} 

-(NSArray *)runLoopModesForAnimating {
   return _runLoopModes;
}

-(void)setCurrentProgress:(NSAnimationProgress)progress {
   NSUnimplementedMethod();
}

-(void)clearStartAnimation {
   NSUnimplementedMethod();
}

-(void)clearStopAnimation {
   NSUnimplementedMethod();
}

-(void)startAnimation {
   NSUnimplementedMethod();
}

-(void)stopAnimation {
   NSUnimplementedMethod();
}

-(void)startWhenAnimation:(NSAnimation *)animation reachesProgress:(NSAnimationProgress)progress {
   NSUnimplementedMethod();
}

-(void)stopWhenAnimation:(NSAnimation *)animation reachesProgress:(NSAnimationProgress)progress {
   NSUnimplementedMethod();
}

@end
