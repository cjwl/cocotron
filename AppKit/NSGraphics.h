/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>
#import <AppKit/AppKitExport.h>
#import <ApplicationServices/ApplicationServices.h>

@class NSColor;

typedef enum {
   NSCompositeClear,
   NSCompositeCopy,
   NSCompositeSourceOver,
   NSCompositeSourceIn,
   NSCompositeSourceOut,
   NSCompositeSourceAtop,
   NSCompositeDestinationOver,
   NSCompositeDestinationIn,
   NSCompositeDestinationOut,
   NSCompositeDestinationAtop,
   NSCompositeXOR,
   NSCompositePlusDarker,
   NSCompositeHighlight,
   NSCompositePlusLighter
} NSCompositingOperation;

typedef enum {
   NSWindowBelow=-1,
   NSWindowOut=0,
   NSWindowAbove=1
} NSWindowOrderingMode;

typedef enum {
   NSFocusRingOnly,
   NSFocusRingBelow,
   NSFocusRingAbove
} NSFocusRingPlacement;

typedef enum {
   NSFocusRingTypeDefault,
   NSFocusRingTypeNone,
   NSFocusRingTypeExterior
} NSFocusRingType;

typedef int NSWindowDepth;

APPKIT_EXPORT const float NSBlack;
APPKIT_EXPORT const float NSDarkGray;
APPKIT_EXPORT const float NSLightGray;
APPKIT_EXPORT const float NSWhite;

APPKIT_EXPORT NSString *NSDeviceBlackColorSpace;
APPKIT_EXPORT NSString *NSDeviceWhiteColorSpace;
APPKIT_EXPORT NSString *NSDeviceRGBColorSpace;
APPKIT_EXPORT NSString *NSDeviceCMYKColorSpace;
APPKIT_EXPORT NSString *NSCalibratedBlackColorSpace;
APPKIT_EXPORT NSString *NSCalibratedWhiteColorSpace;
APPKIT_EXPORT NSString *NSCalibratedRGBColorSpace;
APPKIT_EXPORT NSString *NSNamedColorSpace;

APPKIT_EXPORT NSString *NSDeviceIsScreen;
APPKIT_EXPORT NSString *NSDeviceIsPrinter;
APPKIT_EXPORT NSString *NSDeviceSize;
APPKIT_EXPORT NSString *NSDeviceResolution;
APPKIT_EXPORT NSString *NSDeviceColorSpaceName;
APPKIT_EXPORT NSString *NSDeviceBitsPerSample;

APPKIT_EXPORT void NSRectClipList(const NSRect *rects,int count);
APPKIT_EXPORT void NSRectClip(NSRect rect);

APPKIT_EXPORT void NSRectFillListWithColors(const NSRect *rects,NSColor **colors,int count);
APPKIT_EXPORT void NSRectFillListWithGrays(const NSRect *rects,const float *grays,int count);
APPKIT_EXPORT void NSRectFillList(const NSRect *rects,int count);
APPKIT_EXPORT void NSRectFill(NSRect rect);

APPKIT_EXPORT void NSRectFillListUsingOperation(const NSRect *rects,int count,NSCompositingOperation operation);
APPKIT_EXPORT void NSRectFillUsingOperation(NSRect rect,NSCompositingOperation operation);

APPKIT_EXPORT void NSFrameRectWithWidth(NSRect rect,float width);
APPKIT_EXPORT void NSFrameRect(NSRect rect);
APPKIT_EXPORT void NSDottedFrameRect(NSRect rect);

APPKIT_EXPORT void NSDrawButton(NSRect rect,NSRect clipRect);
APPKIT_EXPORT void NSDrawGrayBezel(NSRect rect,NSRect clipRect);
APPKIT_EXPORT void NSDrawWhiteBezel(NSRect rect,NSRect clipRect);
APPKIT_EXPORT void NSDrawDarkBezel(NSRect rect,NSRect clipRect);
APPKIT_EXPORT void NSDrawLightBezel(NSRect rect,NSRect clipRect);
APPKIT_EXPORT void NSDrawGroove(NSRect rect,NSRect clipRect);

APPKIT_EXPORT void NSDrawWindowBackground(NSRect rect);

APPKIT_EXPORT NSRect NSDrawTiledRects(NSRect bounds,NSRect clip,const NSRectEdge *sides,const float *grays,int count);

APPKIT_EXPORT void NSHighlightRect(NSRect rect);
APPKIT_EXPORT void NSCopyBits(int gState,NSRect rect,NSPoint point);

APPKIT_EXPORT void NSBeep();

APPKIT_EXPORT void NSEnableScreenUpdates(void);
APPKIT_EXPORT void NSDisableScreenUpdates(void);
