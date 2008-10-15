//
//  X11Display.h
//  AppKit
//
//  Created by Johannes Fortmann on 13.10.08.
//  Copyright 2008 -. All rights reserved.
//

#import <AppKit/NSDisplay.h>
#import <X11/Xlib.h>

@interface X11Display : NSDisplay {
   Display* _display;
   NSMutableDictionary *_windowsByID;
}
-(Display*)display;
-(void)setWindow:(id)window forID:(XID)i;
@end
