/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSDisplay.h>

@implementation NSOpenPanel

+(NSOpenPanel *)openPanel {
   return [[self new] autorelease];
}

-init {
   [super init];
   _filenames=[NSArray new];
   [_dialogTitle release];
   _dialogTitle=@"Open";
   _allowsMultipleSelection=NO;
   _canChooseDirectories=NO;
   _canChooseFiles=YES;
   return self;
}

-(void)dealloc {
   [_filenames release];
   [super dealloc];
}

-(NSArray *)filenames {
   return _filenames;
}

-(int)runModalForDirectory:(NSString *)directory file:(NSString *)file types:(NSArray *)types {
   return [[NSDisplay currentDisplay] openPanel:self runModalForDirectory:directory file:file types:types];
}

-(int)runModalForTypes:(NSArray *)types {
   return [self runModalForDirectory:[self directory] file:nil types:types];
}

-(int)runModalForDirectory:(NSString *)directory file:(NSString *)file {
   return [self runModalForDirectory:directory file:file types:nil];
}

-(int)runModal {
   return [self runModalForDirectory:nil file:nil types:nil];
}

-(BOOL)allowsMultipleSelection {
   return _allowsMultipleSelection;
}

-(BOOL)canChooseDirectories {
   return _canChooseDirectories;
}

-(BOOL)canChooseFiles {
   return _canChooseFiles;
}

-(void)setAllowsMultipleSelection:(BOOL)flag {
   _allowsMultipleSelection=flag;
}

-(void)setCanChooseDirectories:(BOOL)flag {
   _canChooseDirectories=flag;
}

-(void)setCanChooseFiles:(BOOL)flag {
   _canChooseFiles=flag;
}

@end
