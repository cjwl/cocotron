#import <AppKit/KGDeviceContext_gdi.h>

@implementation KGDeviceContext_gdi

-initWithDC:(HDC)dc {
   _dc=dc;
   return self;
}

-(HDC)dc {
   return _dc;
}

-(Win32DeviceContextWindow *)windowDeviceContext {
   return nil;
}

-(void)beginPrintingWithDocumentName:(NSString *)name {
   // do nothing
}

-(void)endPrinting {
   // do nothing
}

-(void)beginPage {
   // do nothing
}

-(void)endPage {
   // do nothing
}

-(NSSize)pixelsPerInch {
   [self doesNotRecognizeSelector:_cmd];
   return NSMakeSize(0,0);
}

-(NSSize)pixelSize {
   [self doesNotRecognizeSelector:_cmd];
   return NSMakeSize(0,0);
}

-(NSSize)pointSize {
   NSSize pixelPerInch=[self pixelsPerInch];
   NSSize pixelSize=[self pixelSize];

   float pointsWide=(pixelSize.width/pixelPerInch.width)*72.0;
   float pointsHigh=(pixelSize.height/pixelPerInch.height)*72.0;
   
   return NSMakeSize(pointsWide,pointsHigh);
}

-(NSRect)paperRect {
   NSRect result;
   
   result.size=[self pointSize];
   result.origin=NSMakePoint(0,0);
   
   return result;
}

-(NSRect)imageableRect {
   return [self paperRect];
}


@end
