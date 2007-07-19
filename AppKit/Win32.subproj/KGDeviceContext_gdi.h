#import <AppKit/KGDeviceContext.h>

@class Win32DeviceContextWindow;

@interface KGDeviceContext_gdi : KGDeviceContext {
   HDC _dc;
}

-initWithDC:(HDC)dc;

-(HDC)dc;

-(Win32DeviceContextWindow *)windowDeviceContext;

@end
