/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSAlert.h>
#import <AppKit/NSImage.h>
#import <Foundation/NSRaise.h>

@implementation NSAlert

+(NSAlert *)alertWithError:(NSError *)error {
   NSUnimplementedMethod();
   return nil;
}

+(NSAlert *)alertWithMessageText:(NSString *)messageText defaultButton:(NSString *)defaultTitle alternateButton:(NSString *)alternateTitle otherButton:(NSString *)otherTitle informativeTextWithFormat:(NSString *)format,... {
   NSUnimplementedMethod();
   return nil;
}

-delegate {
   return _delegate;
}

-(NSAlertStyle)alertStyle {
   return _style;
}

-(NSImage *)icon {
   return _icon;
}

-(NSString *)messageText {
   return _messageText;
}

-(NSString *)informativeText {
   return _informativeText;
}

-(BOOL)showsHelp {
   return _showsHelp;
}

-(NSString *)helpAnchor {
   return _helpAnchor;
}

-(NSArray *)buttons {
   return _buttons;
}

-window {
   return _window;
}

-(void)setDelegate:delegate {
   _delegate=delegate;
}

-(void)setAlertStyle:(NSAlertStyle)style {
   _style=style;
}

-(void)setIcon:(NSImage *)icon {
   icon=[icon copy];
   [_icon release];
   _icon=icon;
}

-(void)setMessageText:(NSString *)string {
   string=[string copy];
   [_messageText release];
   _messageText=string;
}

-(void)setInformativeText:(NSString *)string {
   string=[string copy];
   [_informativeText release];
   _informativeText=string;
}

-(void)setShowsHelp:(BOOL)flag {
   _showsHelp=flag;
}

-(void)setHelpAnchor:(NSString *)anchor {
   anchor=[anchor copy];
   [_helpAnchor release];
   _helpAnchor=anchor;
}

-(NSButton *)addButtonWithTitle:(NSString *)title {
   NSUnimplementedMethod();
   return nil;
}

-(void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:delegate didEndSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}

-(int)runModal {
   NSUnimplementedMethod();
   return 0;
}

@end
