/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSView.h>

@class NSToolbar;

// Hm. A view to support drag and drop toolbar customization.

// n.b.: arrange icons for dragging in a 4 x 4 grid. some icons seem to occupy two "slots", e.g.
// Mail.app's "search" toolbar item--how is this determined? If minSize > threshold... etc.

APPKIT_EXPORT NSString *NSToolbarItemIdentifierPboardType;

@interface NSToolbarCustomizationView : NSView
{
    NSToolbar *_toolbar;
    BOOL _isDefaultSetView;
}

- (id)initWithFrame:(NSRect)frame toolbar:(NSToolbar *)toolbar isDefaultSetView:(BOOL)isDefaultSetView;

- (NSToolbar *)toolbar;

- (void)setDefaultSetView:(BOOL)flag;
- (BOOL)isDefaultSetView;

- (void)sizeToFit;

@end

