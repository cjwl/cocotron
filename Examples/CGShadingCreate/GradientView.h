/* GradientView, not exactly MVC but you get the idea */

#import <Cocoa/Cocoa.h>

@interface GradientView : NSView {
   float    _C0[4];
   float    _C1[4];
   NSPoint  _startPoint;
   NSPoint  _endPoint;
   BOOL     _extendStart;
   BOOL     _extendEnd;
   float    _startRadius;
   float    _endRadius;
   BOOL     _mouseFirst;
   
   IBOutlet NSMatrix    *_shadingType;
   IBOutlet NSTextField *_startXTextField;
   IBOutlet NSTextField *_startYTextField;
   IBOutlet NSColorWell *_startColor;
   IBOutlet NSButton    *_startExtend;
   
   IBOutlet NSTextField *_endXTextField;
   IBOutlet NSTextField *_endYTextField;
   IBOutlet NSColorWell *_endColor;
   IBOutlet NSButton    *_endExtend;
   
   IBOutlet NSFormCell *_innerRadius;
   IBOutlet NSSlider   *_innerRadiusSlider;
   IBOutlet NSFormCell *_outerRadius;
   IBOutlet NSSlider   *_outerRadiusSlider;
}

-(IBAction)selectType:sender;

-(IBAction)takeStartXFromSender:sender;
-(IBAction)takeStartYFromSender:sender;
-(IBAction)takeEndXFromSender:sender;
-(IBAction)takeEndYFromSender:sender;

-(IBAction)takeStartColorFromSender:sender;
-(IBAction)takeEndColorFromSender:sender;

-(IBAction)takeExtendStartFromSender:sender;
-(IBAction)takeExtendEndFromSender:sender;

-(IBAction)takeInnerRadiusFromSender:sender;
-(IBAction)takeOuterRadiusFromSender:sender;

@end
