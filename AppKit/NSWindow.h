/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSResponder.h>
#import <AppKit/AppKitExport.h>
#import <AppKit/NSView.h>

@class NSView, NSEvent, NSColor, NSCursor, NSImage, NSScreen, NSText, NSTextView, CGWindow, NSPasteboard, NSSheetContext, NSUndoManager, NSButtonCell, NSDrawer, NSToolbar, NSWindowAnimationContext, NSTrackingRect, NSWindowBackgroundView;

enum {
   NSBorderlessWindowMask=0x00,
   NSTitledWindowMask=0x01,
   NSClosableWindowMask=0x02,
   NSMiniaturizableWindowMask=0x04,
   NSResizableWindowMask=0x08
};

typedef enum {
   NSBackingStoreRetained=0,
   NSBackingStoreNonretained=1,
   NSBackingStoreBuffered=2
} NSBackingStoreType;

APPKIT_EXPORT NSString *NSWindowDidBecomeKeyNotification;
APPKIT_EXPORT NSString *NSWindowDidResignKeyNotification;
APPKIT_EXPORT NSString *NSWindowDidBecomeMainNotification;
APPKIT_EXPORT NSString *NSWindowDidResignMainNotification;
APPKIT_EXPORT NSString *NSWindowWillMiniaturizeNotification;
APPKIT_EXPORT NSString *NSWindowDidMiniaturizeNotification;
APPKIT_EXPORT NSString *NSWindowDidDeminiaturizeNotification;
APPKIT_EXPORT NSString *NSWindowWillMoveNotification;
APPKIT_EXPORT NSString *NSWindowDidMoveNotification;
APPKIT_EXPORT NSString *NSWindowDidResizeNotification;
APPKIT_EXPORT NSString *NSWindowDidUpdateNotification;
APPKIT_EXPORT NSString *NSWindowWillCloseNotification;

// Hmm. I needed something like this, I think it kind of makes sense, it's not in AppKit 10.3 though.
APPKIT_EXPORT NSString *NSWindowWillAnimateNotification;
APPKIT_EXPORT NSString *NSWindowAnimatingNotification;
APPKIT_EXPORT NSString *NSWindowDidAnimateNotification;

@interface NSWindow : NSResponder {
   NSRect             _frame;
   unsigned           _styleMask;
   NSBackingStoreType _backingType;

   NSSize   _minSize;
   NSSize   _maxSize;

   NSString *_title;
   NSString *_miniwindowTitle;
   NSImage  *_miniwindowImage;

   NSWindowBackgroundView *_backgroundView;
   NSMenu   *_menu;
   NSView   *_menuView;
   NSView   *_contentView;
   NSColor  *_backgroundColor;

   id           _delegate;
   NSResponder *_firstResponder;

   NSTextView  *_fieldEditor;
   NSArray     *_draggedTypes;

   NSMutableArray   *_cursorRects;
   NSHashTable      *_invalidatedCursorRectViews;
   NSMutableArray   *_trackingRects;
   NSTrackingRectTag _nextTrackingRectTag;

   NSSheetContext   *_sheetContext;

   NSSize            _resizeInfo;

   int          _cursorRectsDisabled;
   int          _flushDisabled;

   BOOL      _isVisible;
   BOOL      _isKeyWindow;
   BOOL      _isMainWindow;
   BOOL      _isDocumentEdited;
   BOOL      _makeSureIsOnAScreen;

   BOOL      _acceptsMouseMovedEvents;
   BOOL      _isDeferred;
   BOOL      _isOneShot;
   BOOL      _useOptimizedDrawing;
   BOOL      _releaseWhenClosed;
   BOOL      _hidesOnDeactivate;
   BOOL      _hiddenForDeactivate;
   BOOL      _isActive;
   BOOL      _viewsNeedDisplay;
   BOOL      _flushNeeded;

   BOOL      _useResizeInfo;
   BOOL      _resizeInfoIsRatio;
   BOOL      _defaultButtonCellKeyEquivalentDisabled;

   NSString *_autosaveFrameName;

   CGWindow *_platformWindow;
   NSUndoManager *_undoManager;
   NSView *_initialFirstResponder;
   NSButtonCell *_defaultButtonCell;

   NSMutableArray *_drawers;
   NSToolbar *_toolbar;
   NSWindowAnimationContext *_animationContext;
   NSTrackingRect *_trackedRect;
}

+(NSRect)frameRectForContentRect:(NSRect)contentRect styleMask:(unsigned)styleMask;
+(NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(unsigned)styleMask;

-initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(unsigned)backing defer:(BOOL)defer;

-(NSString *)title;
-contentView;

-delegate;

-(NSRect)frame;
-(NSSize)minSize;
-(NSSize)maxSize;

-(unsigned)styleMask;
-(BOOL)isOneShot;
-(BOOL)isReleasedWhenClosed;
-(BOOL)hidesOnDeactivate;
-(BOOL)worksWhenModal;
-(BOOL)isSheet;
-(BOOL)acceptsMouseMovedEvents;

-(NSResponder *)firstResponder;
-(NSView *)initialFirstResponder;

-(NSImage *)miniwindowImage;
-(NSString *)miniwindowTitle;
-(NSColor *)backgroundColor;

-(NSToolbar *)toolbar;

-(NSButtonCell *)defaultButtonCell;
-(NSWindow *)attachedSheet;

-(NSArray *)drawers;

-(int)windowNumber;
-(NSScreen *)screen;

-(BOOL)isDocumentEdited;
-(BOOL)isVisible;
-(BOOL)isKeyWindow;
-(BOOL)isMainWindow;
-(BOOL)isMiniaturized;
-(BOOL)canBecomeKeyWindow;
-(BOOL)canBecomeMainWindow;

-(NSPoint)convertBaseToScreen:(NSPoint)point;
-(NSPoint)convertScreenToBase:(NSPoint)point;

-(void)setTitle:(NSString *)title;
-(void)setTitleWithRepresentedFilename:(NSString *)filename;
-(void)setContentView:(NSView *)view;

-(void)setDelegate:delegate;

-(void)setFrame:(NSRect)frame display:(BOOL)display;
-(void)setFrame:(NSRect)frame display:(BOOL)display animate:(BOOL)flag;
-(void)setContentSize:(NSSize)contentSize;
-(void)setFrameOrigin:(NSPoint)point;
-(void)setFrameTopLeftPoint:(NSPoint)point;
-(NSPoint)cascadeTopLeftFromPoint:(NSPoint)topLeftPoint;
-(void)setMinSize:(NSSize)size;
-(void)setMaxSize:(NSSize)size;

-(void)setOneShot:(BOOL)flag;
-(void)setReleasedWhenClosed:(BOOL)flag;
-(void)setHidesOnDeactivate:(BOOL)flag;
-(void)setAcceptsMouseMovedEvents:(BOOL)flag;
-(void)setInitialFirstResponder:(NSView *)view;
-(void)setMiniwindowImage:(NSImage *)image;
-(void)setMiniwindowTitle:(NSString *)title;
-(void)setBackgroundColor:(NSColor *)color;
-(void)setToolbar:(NSToolbar*)toolbar;
-(void)setDefaultButtonCell:(NSButtonCell *)buttonCell;
-(void)setDocumentEdited:(BOOL)flag;

-(BOOL)setFrameUsingName:(NSString *)name;
-(BOOL)setFrameAutosaveName:(NSString *)name;

-(BOOL)makeFirstResponder:(NSResponder *)responder;

-(void)makeKeyWindow;
-(void)makeMainWindow;

-(void)becomeKeyWindow;
-(void)resignKeyWindow;
-(void)becomeMainWindow;
-(void)resignMainWindow;

-(NSTimeInterval)animationResizeTime:(NSRect)frame;

-(void)selectNextKeyView:sender;
-(void)selectPreviousKeyView:sender;
-(void)selectKeyViewFollowingView:(NSView *)view;
-(void)selectKeyViewPrecedingView:(NSView *)view;

-(void)disableKeyEquivalentForDefaultButtonCell;
-(void)enableKeyEquivalentForDefaultButtonCell;

-(NSText *)fieldEditor:(BOOL)create forObject:object;
-(void)endEditingFor:object;

-(void)useOptimizedDrawing:(BOOL)flag;
-(BOOL)viewsNeedDisplay;
-(void)setViewsNeedDisplay:(BOOL)flag;
-(void)disableFlushWindow;
-(void)enableFlushWindow;
-(void)flushWindow;
-(void)flushWindowIfNeeded;
-(void)displayIfNeeded;
-(void)display;

-(BOOL)areCursorRectsEnabled;
-(void)disableCursorRects;
-(void)enableCursorRects;

-(void)discardCursorRects;
-(void)resetCursorRects;

-(void)invalidateCursorRectsForView:(NSView *)view;
-(void)close;
-(void)center;
-(void)makeKeyAndOrderFront:sender;
-(void)orderFront:sender;
-(void)orderBack:sender;
-(void)orderOut:sender;
-(void)orderWindow:(NSWindowOrderingMode)place relativeTo:(int)relativeTo;

-(NSEvent *)currentEvent;
-(NSEvent *)nextEventMatchingMask:(unsigned int)mask;
-(NSEvent *)nextEventMatchingMask:(unsigned int)mask untilDate:(NSDate *)untilDate inMode:(NSString *)mode dequeue:(BOOL)dequeue;

-(void)sendEvent:(NSEvent *)event;
-(NSPoint)mouseLocationOutsideOfEventStream;

-(void)registerForDraggedTypes:(NSArray *)types;
-(void)unregisterDraggedTypes;

-(void)dragImage:(NSImage *)image at:(NSPoint)location offset:(NSSize)offset event:(NSEvent *)event pasteboard:(NSPasteboard *)pasteboard source:source slideBack:(BOOL)slideBack;

-(void)update;

-(void)performClose:sender;
-(void)performMiniaturize:sender;
-(void)miniaturize:sender;
-(void)deminiaturize:sender;

-(void)toggleToolbarShown:sender;
-(void)runToolbarCustomizationPalette:sender;

@end

@interface NSObject(NSWindow_delegate)
-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;
-(void)windowDidBecomeKey:(NSNotification *)note;
-(void)windowDidResignKey:(NSNotification *)note;
-(void)windowDidBecomeMain:(NSNotification *)note;
-(void)windowDidResignMain:(NSNotification *)note;
-(void)windowWillMiniaturize:(NSNotification *)note;
-(void)windowDidMiniaturize:(NSNotification *)note;
-(void)windowDidDeminiaturize:(NSNotification *)note;
-(void)windowWillMove:(NSNotification *)note;
-(void)windowDidMove:(NSNotification *)note;
-(NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)size;
-(void)windowDidResize:(NSNotification *)note;
-(void)windowDidUpdate:(NSNotification *)note;
-(BOOL)windowShouldClose:sender;
-(void)windowWillClose:(NSNotification *)note;
@end

