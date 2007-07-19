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

@end
