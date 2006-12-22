/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSSavePanel.h>
#import <AppKit/NSView.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSDisplay.h>

@implementation NSSavePanel

+(NSSavePanel *)savePanel {
   return [[self new] autorelease];
}

-init {
   [super initWithContentRect:NSMakeRect(0,0,1,1) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES];

   _dialogTitle=@"Save";
   _filename=@"";
   _directory=[NSHomeDirectory() copy];
   _requiredFileType=@"";
   _treatsFilePackagesAsDirectories=NO;
   _accessoryView=nil;
   return self;
}

-(void)dealloc {
   [_dialogTitle release];
   [_filename release];
   [_directory release];
   [_requiredFileType release];
   [_accessoryView release];
   [super dealloc];
}

-(NSString *)filename {
   return _filename;
}

-(int)runModalForDirectory:(NSString *)directory file:(NSString *)file {
   return [[NSDisplay currentDisplay] savePanel:self runModalForDirectory:directory file:file];
}

-(int)runModal {
   return [[NSDisplay currentDisplay] savePanel:self runModalForDirectory:@"" file:@""];
}

-(NSString *)directory {
   return _directory;
}

-(BOOL)treatsFilePackagesAsDirectories {
   return _treatsFilePackagesAsDirectories;
}

-(NSView *)accessoryView {
   return _accessoryView;
}

-(void)setTitle:(NSString *)title {
   title=[title copy];
   [_dialogTitle release];
   _dialogTitle=title;
}

-(void)setDirectory:(NSString *)directory {
   directory=[directory copy];
   [_directory release];
   _directory=directory;
}

-(void)setRequiredFileType:(NSString *)type {
   type=[type copy];
   [_requiredFileType release];
   _requiredFileType=type;
}

-(void)setTreatsFilePackagesAsDirectories:(BOOL)flag {
   _treatsFilePackagesAsDirectories=flag;
}

-(void)setAccessoryView:(NSView *)view {
   view=[view retain];
   [_accessoryView release];
   _accessoryView=view;
}

@end
