#import <AppKit/KGContext.h>

@class KGDeviceContext_gdi,Win32Font;

@interface KGContext_gdi : KGContext {
   KGDeviceContext_gdi *_deviceContext;
   HDC  _dc;
   BOOL _isAdvanced;
   Win32Font *_gdiFont;
}

-initWithGraphicsState:(KGGraphicsState *)state deviceContext:(KGDeviceContext_gdi *)deviceContext;
-initWithHWND:(HWND)handle;
-initWithPrinterDC:(HDC)printer;
-initWithSize:(NSSize)size context:(KGContext *)otherX useDIB:(BOOL)useDIB;

-(NSSize)pointSize;

-(HDC)dc;
-(HWND)windowHandle;
-(HFONT)fontHandle;

-(KGDeviceContext_gdi *)deviceContext;

@end

