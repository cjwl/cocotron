/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSToolbarItem.h>

@class NSString;

@interface NSToolbarItem (NSStandardToolbarItems)

+ (NSToolbarItem *)standardToolbarItemWithIdentifier:(NSString *)identifier;

// return preconfigured prototypes for the standard items...
+ (NSToolbarItem *)separatorToolbarItem;
+ (NSToolbarItem *)spaceToolbarItem;
+ (NSToolbarItem *)flexibleSpaceToolbarItem;

+ (NSToolbarItem *)showColorsToolbarItem;
+ (NSToolbarItem *)showFontsToolbarItem;
+ (NSToolbarItem *)customizeToolbarToolbarItem;
+ (NSToolbarItem *)printToolbarItem;

// private
+ (NSToolbarItem *)overflowToolbarItem;

- (BOOL)isFlexibleSpaceToolbarItem;
- (BOOL)isSpaceToolbarItem;
- (BOOL)isSeparatorToolbarItem;

@end

APPKIT_EXPORT NSString *NSToolbarOverflowItemIdentifier;
