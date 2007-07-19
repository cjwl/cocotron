#import <Foundation/NSObject.h>

@class NSMutableDictionary;

@interface NSPrintPanel : NSObject {
   NSMutableDictionary *_attributes;
}

+(NSPrintPanel *)printPanel;

-(int)runModal;

-(void)updateFromPrintInfo;
-(void)finalWritePrintInfo;

@end
