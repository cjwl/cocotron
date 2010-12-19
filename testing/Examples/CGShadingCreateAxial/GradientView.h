/* GradientView */

#import <Cocoa/Cocoa.h>

@interface GradientView : NSView {
   float    _C0[4];
   float    _C1[4];
   NSPoint  _startPoint;
   NSPoint  _endPoint;
   BOOL     _extendStart;
   BOOL     _extendEnd;
   BOOL     _mouseFirst;
}

-(IBAction)takeStartColorFromSender:sender;
-(IBAction)takeEndColorFromSender:sender;

-(IBAction)takeExtendStartFromSender:sender;
-(IBAction)takeExtendEndFromSender:sender;

@end
