#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class Win32DeviceContextWindow;

@interface KGDeviceContext_gdi : NSObject {
   HDC _dc;
}

-initWithDC:(HDC)dc;

-(HDC)dc;

-(Win32DeviceContextWindow *)windowDeviceContext;

-(void)beginPrintingWithDocumentName:(NSString *)name;
-(void)endPrinting;

-(void)beginPage;
-(void)endPage;

-(NSSize)pixelsPerInch;
-(NSSize)pixelSize;
-(NSSize)pointSize;
-(NSRect)paperRect;
-(NSRect)imageableRect;

@end
