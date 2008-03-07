/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGRenderController.h"
#import "KGRenderView.h"
#import "KGRender_cg.h"
#import "KGRender_baseline.h"

@implementation KGRenderController

-(void)awakeFromNib {
   [_cgView setRender:[[[KGRender_cg alloc] init] autorelease]];
   [_kgView setRender:[[[KGRender_baseline alloc] init] autorelease]];
   [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

-(void)selectDestinationColor:sender {
   [_cgView setDestinationColor:[sender color]];
   [_kgView setDestinationColor:[sender color]];
}

-(void)setectSourceColor:sender {
   [_cgView setSourceColor:[sender color]];
   [_kgView setSourceColor:[sender color]];
}

-(void)selectBlendMode:sender {
   [_cgView setBlendMode:(CGBlendMode)[sender selectedTag]];
   [_kgView setBlendMode:(CGBlendMode)[sender selectedTag]];
}

-(void)selectPathDrawingMode:sender {
   [_cgView setPathDrawingMode:(CGPathDrawingMode)[sender selectedTag]];
   [_kgView setPathDrawingMode:(CGPathDrawingMode)[sender selectedTag]];
}

-(void)selectLineWidth:sender {
   [_cgView setLineWidth:[sender floatValue]];
   [_kgView setLineWidth:[sender floatValue]];
}

-(void)selectDashPhase:sender {
   [_cgView setDashPhase:[sender floatValue]];
   [_kgView setDashPhase:[sender floatValue]];
}

-(void)selectDashLength:sender {
   [_cgView setDashLength:[sender floatValue]];
   [_kgView setDashLength:[sender floatValue]];
}

-(void)selectScaleX:sender {
   [_cgView setScaleX:[sender floatValue]];
   [_kgView setScaleX:[sender floatValue]];
}

-(void)selectScaleY:sender {
   [_cgView setScaleY:[sender floatValue]];
   [_kgView setScaleY:[sender floatValue]];
}

-(void)selectRotation:sender {
   [_cgView setRotation:[sender floatValue]];
   [_kgView setRotation:[sender floatValue]];
}

@end
