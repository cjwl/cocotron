/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSNib.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSRaise.h>
#import "NSNibKeyedUnarchiver.h"
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSTableCornerView.h>
#import "NSIBObjectData.h"
#import "NSNibHelpConnector.h"

NSString *NSNibOwner=@"NSOwner";
NSString *NSNibTopLevelObjects=@"NSNibTopLevelObjects";

@implementation NSNib

-initWithContentsOfFile:(NSString *)path {
   NSString *keyedobjects=[[path stringByAppendingPathComponent:@"keyedobjects"] stringByAppendingPathExtension:@"nib"];
   
   if((_data=[[NSData alloc] initWithContentsOfFile:keyedobjects])==nil){
    [self dealloc];
    return nil;
   }

   return self;
}

-initWithContentsOfURL:(NSURL *)url {
   if(![url isFileURL]){
    [self dealloc];
    return nil;
   }
   
   return [self initWithContentsOfFile:[url path]];
}

-initWithNibNamed:(NSString *)name bundle:(NSBundle *)bundle {
   NSString *path=[bundle pathForResource:name ofType:@"nib"];
   
   if(path==nil){
    [self dealloc];
    return nil;
   }
   
   return [self initWithContentsOfFile:path];
}

-(void)dealloc {
   [_data release];
   [super dealloc];
}

-(BOOL)instantiateNibWithExternalNameTable:(NSDictionary *)nameTable {
    NSNibKeyedUnarchiver *unarchiver=[[[NSNibKeyedUnarchiver alloc] initForReadingWithData:_data externalNameTable:nameTable] autorelease];
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

-(BOOL)instantiateNibWithOwner:owner topLevelObjects:(NSArray **)objects {
   NSDictionary *nameTable=[NSDictionary dictionaryWithObject:owner forKey:NSNibOwner];

   if(objects!=NULL){
    NSLog(@"-[%@ %s] specifying non-NULL for topLevelObjects not implemented",isa,SELNAME(_cmd));
   }
   
   return [self instantiateNibWithExternalNameTable:nameTable];
}

@end
