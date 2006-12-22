/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSNibLoading.h>
#import "NSNibKeyedUnarchiver.h"
#import <AppKit/NSMenu.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSTableCornerView.h>
#import "NSIBObjectData.h"
#import "NSNibHelpConnector.h"

@implementation NSObject(NSNibLoading)

-(void)awakeFromNib {
   // do nothing
}

@end
@implementation NSBundle(NSNibLoading)

+(BOOL)loadNibFile:(NSString *)path externalNameTable:(NSDictionary *)nameTable withZone:(NSZone *)zone {
   NSString *keyedArchive=[[path stringByAppendingPathComponent:@"keyedobjects"] stringByAppendingPathExtension:@"nib"];
   NSData   *keyedData=[NSData dataWithContentsOfFile:keyedArchive];
   
  // NSLog(@"LOADING %@",path);
   
   if(keyedData==nil)
    return NO;
   else {
    NSNibKeyedUnarchiver *unarchiver=[[NSNibKeyedUnarchiver alloc] initForReadingWithData:keyedData externalNameTable:nameTable];
    NSIBObjectData    *objectData;
    NSArray           *allObjects;
    int                i,count;
    NSMenu            *menu;
    
    /*
    TO DO:
     - utf8 in the multinational panel
     - misaligned objects in boxes everywhere
    */
    [unarchiver setClass:[NSTableCornerView class] forClassName:@"_NSCornerView"];
    [unarchiver setClass:[NSNibHelpConnector class] forClassName:@"NSIBHelpConnector"];
    
    objectData=[unarchiver decodeObjectForKey:@"IB.objectdata"];
    
    [objectData buildConnectionsWithNameTable:nameTable];
    if((menu=[objectData mainMenu])!=nil)
     [NSApp setMainMenu:menu];
     
    allObjects=[[unarchiver allObjects] arrayByAddingObjectsFromArray:[nameTable allValues]];
    count=[allObjects count];

    for(i=0;i<count;i++){
     id object=[allObjects objectAtIndex:i];

     if([object respondsToSelector:@selector(awakeFromNib)])
      [object awakeFromNib];
    }
    for(i=0;i<count;i++){
     id object=[allObjects objectAtIndex:i];

     if([object respondsToSelector:@selector(postAwakeFromNib)])
      [object performSelector:@selector(postAwakeFromNib)];
    }

    [[objectData visibleWindows] makeObjectsPerformSelector:@selector(makeKeyAndOrderFront:) withObject:nil];
    
    return (objectData!=nil);
   }
}

+(BOOL)loadNibNamed:(NSString *)name owner:owner {
   NSDictionary *nameTable=[NSDictionary dictionaryWithObject:owner forKey:@"NSOwner"];
   NSString     *path;
   NSBundle     *bundle=[NSBundle bundleForClass:[owner class]];

   path=[bundle pathForResource:name ofType:@"nib"];
   if(path==nil)
    path=[[NSBundle mainBundle] pathForResource:name ofType:@"nib"];

   if(path==nil)
    return NO;

   return [NSBundle loadNibFile:path externalNameTable:nameTable withZone:NULL];
}

-(BOOL)loadNibFile:(NSString *)path externalNameTable:(NSDictionary *)nameTable withZone:(NSZone *)zone {
   NSUnimplementedMethod();
   return NO;
}

@end

