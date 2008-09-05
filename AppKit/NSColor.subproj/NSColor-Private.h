#import <AppKit/NSColor.h>
#import <ApplicationServices/ApplicationServices.h>

@interface NSColor(NSAppKitPrivate)
-(CGColorRef)createCGColorRef;
@end
