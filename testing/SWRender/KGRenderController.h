/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

#import "DemoContext.h"

@class KGImageView;

@interface KGRenderController : NSObject {
   NSDictionary           *_tests;
   IBOutlet NSOutlineView *_outlineView;
   
   IBOutlet NSPopUpButton *_testPopUp;
   
   DemoContext *_cgContext;
   DemoContext *_kgContext;
   
   IBOutlet NSTextField *_cgTime;
   IBOutlet NSTextField *_kgTime;
   
   IBOutlet KGImageView *_cgView;
   IBOutlet KGImageView *_kgView;
   IBOutlet KGImageView *_diffView;
}

-(void)selectTest:sender;

-(void)selectFillColor:sender;
-(void)setectSourceColor:sender;
-(void)selectBlendMode:sender;

-(void)selectShadowColor:sender;
-(void)selectShadowBlur:sender;
-(void)selectShadowOffsetX:sender;
-(void)selectShadowOffsetY:sender;

-(void)selectPathDrawingMode:sender;
-(void)selectLineWidth:sender;
-(void)selectDashPhase:sender;
-(void)selectDashLength:sender;
-(void)selectFlatness:sender;

-(void)selectScaleX:sender;
-(void)selectScaleY:sender;
-(void)selectRotation:sender;
-(void)selectAntialias:sender;
-(void)selectInterpolationQuality:sender;

-(void)selectImagePath:sender;
-(void)selectPDFPath:sender;

-(void)selectFillColor:sender;
-(void)selectShadowColor:sender;

@end
