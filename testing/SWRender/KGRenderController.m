/* Copyright (c) 2008 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "KGRenderController.h"
#import "KGImageView.h"

@implementation KGRenderController

-init {
   [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CGEnableBuiltin"];

   _cgContext=[[NSClassFromString(@"DemoCGContext") alloc] init];
   _kgContext=[[NSClassFromString(@"DemoKGContext") alloc] init];

   return self;

}

-(void)performTest:(SEL)selector withObject:object {
   double start=[NSDate timeIntervalSinceReferenceDate];
   
   [_cgContext performSelector:selector withObject:object];
   [_cgTime setDoubleValue:[NSDate timeIntervalSinceReferenceDate]-start];
   start=[NSDate timeIntervalSinceReferenceDate];
   [_kgContext performSelector:selector withObject:object];
   [_kgTime setDoubleValue:[NSDate timeIntervalSinceReferenceDate]-start];
}

-(void)setNeedsDisplay {

   switch([_testPopUp selectedTag]){
    case 0:
     [self performTest:@selector(drawClassic)  withObject:nil];
     break;

    case 1:
     [self performTest:@selector(drawStraightLines)  withObject:nil];
     break;
    
    case 2:
     [self performTest:@selector(drawBlending) withObject:nil];
     break;
     
    case 3:
     [self performTest:@selector(drawBitmapImageRep) withObject:nil];
     break;

    case 4:
     [self performTest:@selector(drawAxialGradient) withObject:nil];
     
     break;
     
    case 5:
     [self performTest:@selector(drawRadialGradient) withObject:nil];
     break;
     
    case 6:
     [self performTest:@selector(drawGlyphs) withObject:nil];
     break;
     
    case 7:
     [self performTest:@selector(drawPDF) withObject:nil];
     break;
     
    case 8:
     [self performTest:@selector(drawLayers) withObject:nil];
     break;
     
    case 9:
     [self performTest:@selector(drawPattern) withObject:nil];
     break;
   }
   
   CGDataProviderRef provider;
   CGImageRef        image;
   
   if(_cgContext!=nil){
    provider=CGDataProviderCreateWithData(NULL,[_cgContext bytes],[_cgContext bytesPerRow]*[_cgContext pixelsHigh],NULL);
  image=CGImageCreate([_cgContext pixelsWide],[_cgContext pixelsHigh],[_cgContext bitsPerComponent],[_cgContext bitsPerPixel],[_cgContext bytesPerRow],CGColorSpaceCreateDeviceRGB(),[_cgContext bitmapInfo],provider,NULL,NO,kCGRenderingIntentDefault);
     CGDataProviderRelease(provider);
    [_cgView setImageRef:image];
    CGImageRelease(image);
   }
   
   if(_kgContext!=nil){
   provider=CGDataProviderCreateWithData(NULL,[_kgContext bytes],[_kgContext bytesPerRow]*[_kgContext pixelsHigh],NULL);
  image=CGImageCreate([_kgContext pixelsWide],[_kgContext pixelsHigh],[_kgContext bitsPerComponent],[_kgContext bitsPerPixel],[_kgContext bytesPerRow],CGColorSpaceCreateDeviceRGB(),[_kgContext bitmapInfo],provider,NULL,NO,kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    [_kgView setImageRef:image];
    CGImageRelease(image);
   }
   
   if(_cgContext!=nil && _kgContext!=nil){
    unsigned char *cgData=[_cgContext bytes];
    unsigned char *kgData=[_kgContext bytes];
    
    NSMutableData *diffData=[NSMutableData dataWithLength:[_kgContext bytesPerRow]*[_kgContext pixelsHigh]];
   char *diff=[diffData mutableBytes];

int i,max=[_kgContext bytesPerRow]*[_kgContext pixelsHigh];

  for(i=0;i<max;i++){
    int d1=cgData[i];
    int d2=kgData[i];
    
    if((i+1)%4==0)
     diff[i]=0xff;
    else
     diff[i]=(d1!=d2)?ABS(d1-d2):00;
  }
  CGDataProviderRef provider=CGDataProviderCreateWithCFData((CFDataRef)diffData);
   CGImageRef diffImage=CGImageCreate([_cgContext pixelsWide],[_cgContext pixelsHigh],[_cgContext bitsPerComponent],[_cgContext bitsPerPixel],[_cgContext bytesPerRow],CGColorSpaceCreateDeviceRGB(),
     [_kgContext bitmapInfo],provider,NULL,NO,kCGRenderingIntentDefault);
   [_diffView setImageRef:diffImage];
   CGDataProviderRelease(provider);
   CGImageRelease(diffImage);
   }

   
}

-(void)awakeFromNib {

  [self setNeedsDisplay];
}

-(void)selectTest:sender {
   [self setNeedsDisplay];
}

-(void)setFillColor:(NSColor *)color {
   [_cgContext setFillColor:[color redComponent]:[color greenComponent]:[color blueComponent]:[color alphaComponent]];
   [_kgContext setFillColor:[color redComponent]:[color greenComponent]:[color blueComponent]:[color alphaComponent]];
}

-(void)setSourceColor:(NSColor *)color {
   [_cgContext setStrokeColor:[color redComponent]:[color greenComponent]:[color blueComponent]:[color alphaComponent]];
   [_kgContext setStrokeColor:[color redComponent]:[color greenComponent]:[color blueComponent]:[color alphaComponent]];
}

-(void)setBlendMode:(CGBlendMode)blendMode {
   [_cgContext setBlendMode:blendMode];
   [_kgContext setBlendMode:blendMode];
}

-(void)setShadowBlur:(float)value {
   [_cgContext setShadowBlur:value];
   [_kgContext setShadowBlur:value];
}

-(void)setShadowOffsetX:(float)value {
   [_cgContext setShadowOffsetX:value];
   [_kgContext setShadowOffsetX:value];
}

-(void)setShadowOffsetY:(float)value {
   [_cgContext setShadowOffsetY:value];
   [_kgContext setShadowOffsetY:value];
}

-(void)setShadowColor:(NSColor *)color {
   [_cgContext setShadowColor:[color redComponent]:[color greenComponent]:[color blueComponent]:[color alphaComponent]];
   [_kgContext setShadowColor:[color redComponent]:[color greenComponent]:[color blueComponent]:[color alphaComponent]];
}

-(void)setPathDrawingMode:(CGPathDrawingMode)pathDrawingMode {
   [_cgContext setPathDrawingMode:pathDrawingMode];
   [_kgContext setPathDrawingMode:pathDrawingMode];
}

-(void)setLineWidth:(float)width {
   [_cgContext setLineWidth:width];
   [_kgContext setLineWidth:width];
}

-(void)setDashPhase:(float)value {
   [_cgContext setDashPhase:value];
   [_kgContext setDashPhase:value];
}

-(void)setDashLength:(float)value {
   [_cgContext setDashLength:value];
   [_kgContext setDashLength:value];
}

-(void)setFlatness:(float)value {
   [_cgContext setFlatness:value];
   [_kgContext setFlatness:value];
}

-(void)setScaleX:(float)value {
   [_cgContext setScaleX:value];
   [_kgContext setScaleX:value];
}

-(void)setScaleY:(float)value {
   [_cgContext setScaleY:value];
   [_kgContext setScaleY:value];
}

-(void)setRotation:(float)value {
   [_cgContext setRotation:value];
   [_kgContext setRotation:value];
}

-(void)setShouldAntialias:(BOOL)value {
   [_cgContext setShouldAntialias:value];
   [_kgContext setShouldAntialias:value];
}

-(void)setInterpolationQuality:(CGInterpolationQuality)value {
   [_cgContext setInterpolationQuality:value];
   [_kgContext setInterpolationQuality:value];
}


-(void)selectFillColor:sender {
   [self setFillColor:[sender color]];
   [self setNeedsDisplay];
}

-(void)setectSourceColor:sender {
   [self setSourceColor:[sender color]];
   [self setNeedsDisplay];
}

-(void)selectBlendMode:sender {
   [self setBlendMode:(CGBlendMode)[sender selectedTag]];
   [self setNeedsDisplay];
}

-(void)selectShadowColor:sender {
   [self setShadowColor:[sender color]];
   [self setNeedsDisplay];
}

-(void)selectShadowBlur:sender {
   [self setShadowBlur:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectShadowOffsetX:sender {
   [self setShadowOffsetX:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectShadowOffsetY:sender {
   [self setShadowOffsetY:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectPathDrawingMode:sender {
   [self setPathDrawingMode:(CGPathDrawingMode)[sender selectedTag]];
   [self setNeedsDisplay];
}

-(void)selectLineWidth:sender {
   [self setLineWidth:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectDashPhase:sender {
   [self setDashPhase:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectDashLength:sender {
   [self setDashLength:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectFlatness:sender {
   [self setFlatness:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectScaleX:sender {
   [self setScaleX:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectScaleY:sender {
   [self setScaleY:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectRotation:sender {
   [self setRotation:[sender floatValue]];
   [self setNeedsDisplay];
}

-(void)selectAntialias:sender {
   [self setShouldAntialias:[sender intValue]];
   [self setNeedsDisplay];
}

-(void)selectInterpolationQuality:sender {
   [self setInterpolationQuality:(CGInterpolationQuality)[sender selectedTag]];
   [self setNeedsDisplay];
}

-(void)selectImagePath:sender {
   NSOpenPanel *openPanel=[NSOpenPanel openPanel];
   
   if([openPanel runModalForTypes:[NSImage imageFileTypes]]){
    NSData *data=[NSData dataWithContentsOfFile:[openPanel filename]];
   [_cgContext setImageData:data];
   [_kgContext setImageData:data];
   [self setNeedsDisplay];
   }
   
}

-(void)selectPDFPath:sender {
   NSOpenPanel *openPanel=[NSOpenPanel openPanel];
   
   if([openPanel runModalForTypes:[NSArray arrayWithObject:@"pdf"]]){
    NSData *data=[NSData dataWithContentsOfFile:[openPanel filename]];
   [_cgContext setPDFData:data];
   [_kgContext setPDFData:data];
   [self setNeedsDisplay];
   }
   
}

-(void)applicationDidFinishLaunching:(NSNotification *)note {

   [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
   if([item isEqual:@"expand"])
    return @"leaf";
   return @"expand";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
   return [item isEqual:@"expand"];
}

 -(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
   return 10;
  }
 
-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return @"bar";
}

@end
