#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@interface KGDeviceContext : NSObject

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
