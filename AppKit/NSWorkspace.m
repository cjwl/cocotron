/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSWorkspace.h>
#import <AppKit/NSPlatform.h>

NSString *NSWorkspaceWillPowerOffNotification=@"NSWorkspaceWillPowerOffNotification";

@implementation NSWorkspace

+(NSWorkspace *)sharedWorkspace {
   return NSThreadSharedInstance([[NSPlatform currentPlatform] workspaceClassName]);
}

-init {
   _notificationCenter=[[NSNotificationCenter alloc] init];
   return self;
}

-(NSNotificationCenter *)notificationCenter {
   return _notificationCenter;
}

-(BOOL)selectFile:(NSString *)path inFileViewerRootedAtPath:(NSString *)rootedAtPath {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)openFile:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)openFile:(NSString *)path withApplication:(NSString *)application {
   NSInvalidAbstractInvocation();
   return NO;
}

-(BOOL)openTempFile:(NSString *)path {
   NSInvalidAbstractInvocation();
   return NO;
}

-(int)extendPowerOffBy:(int)seconds {
   NSInvalidAbstractInvocation();
   return 0;
}

-(void)slideImage:(NSImage *)image from:(NSPoint)fromPoint to:(NSPoint)toPoint {
   NSInvalidAbstractInvocation();
}

@end
