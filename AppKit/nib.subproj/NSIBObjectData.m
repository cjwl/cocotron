/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSIBObjectData.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSet.h>
#import "NSNibKeyedUnarchiver.h"
#import "NSCustomObject.h"
#import <AppKit/NSNibConnector.h>
#import <AppKit/NSFontManager.h>

@implementation NSIBObjectData

-initWithCoder:(NSCoder *)coder {
   if([coder isKindOfClass:[NSNibKeyedUnarchiver class]]){
    NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
    NSMutableDictionary  *nameTable=[NSMutableDictionary dictionaryWithDictionary:[keyed externalNameTable]];
    NSArray              *uids=[keyed decodeArrayOfUidsForKey:@"NSNamesKeys"];
    int                   i,count;
    id                    owner;

    if((owner=[nameTable objectForKey:@"NSOwner"])!=nil)
     [nameTable setObject:owner forKey:@"File's Owner"];
    
    [nameTable setObject:[NSFontManager sharedFontManager] forKey:@"Font Manager"];
    
    _namesValues=[[keyed decodeObjectForKey:@"NSNamesValues"] retain];
    count=[_namesValues count];
    for(i=0;i<count;i++){
     NSString *check=[_namesValues objectAtIndex:i];
     id        external=[nameTable objectForKey:check];
          
     if(external!=nil)
      [keyed replaceObject:external atUid:[[uids objectAtIndex:i] intValue]];
    }
    
    _namesKeys=[[keyed decodeObjectForKey:@"NSNamesKeys"] retain];
    _accessibilityConnectors=[[keyed decodeObjectForKey:@"NSAccessibilityConnectors"] retain];
    _accessibilityOidsKeys=[[keyed decodeObjectForKey:@"NSAccessibilityOidsKeys"] retain];
    _accessibilityOidsValues=[[keyed decodeObjectForKey:@"NSAccessibilityOidsValues"] retain];
    _classesKeys=[[keyed decodeObjectForKey:@"NSClassesKeys"] retain];
    _classesValues=[[keyed decodeObjectForKey:@"NSClassesValues"] retain];
    _connections=[[keyed decodeObjectForKey:@"NSConnections"] retain];
    _fontManager=[[keyed decodeObjectForKey:@"NSFontManager"] retain];
    _framework=[[keyed decodeObjectForKey:@"NSFramework"] retain];
    _nextOid=[keyed decodeIntForKey:@"NSNextOid"];
    _objectsKeys=[[keyed decodeObjectForKey:@"NSObjectsKeys"] retain];
    _objectsValues=[[keyed decodeObjectForKey:@"NSObjectsValues"] retain];
    _oidKeys=[[keyed decodeObjectForKey:@"NSOidsKeys"] retain];
    _oidValues=[[keyed decodeObjectForKey:@"NSOidsValues"] retain];
    _fileOwner=[[keyed decodeObjectForKey:@"NSRoot"] retain];
    _visibleWindows=[[keyed decodeObjectForKey:@"NSVisibleWindows"] retain];
    return self;
   }
   
   return nil;
}

-(void)dealloc {
   [_accessibilityConnectors release];
   [_accessibilityOidsKeys release];
   [_accessibilityOidsValues release];
   [_classesKeys release];
   [_classesValues release];
   [_connections release];
   [_fontManager release];
   [_framework release];
   [_namesKeys release];
   [_namesValues release];
   [_objectsKeys release];
   [_objectsValues release];
   [_oidKeys release];
   [_oidValues release];
   [_fileOwner release];
   [_visibleWindows release];
   [super dealloc];
}

-(NSSet *)visibleWindows {
   return _visibleWindows;
}

-(NSMenu *)mainMenu {
   int i,count=[_namesValues count];
   
   for(i=0;i<count;i++){
    NSString *check=[_namesValues objectAtIndex:i];
    
    if([check isEqual:@"MainMenu"])
     return [_namesKeys objectAtIndex:i];
   }
   return nil;
}

-(void)replaceObject:oldObject withObject:newObject {
   int i,count=[_connections count];

   for(i=0;i<count;i++)
    [[_connections objectAtIndex:i] replaceObject:oldObject withObject:newObject];
}

-(void)establishConnections {
   int i,count=[_connections count];

   for(i=0;i<count;i++){
    NS_DURING
     [[_connections objectAtIndex:i] establishConnection];
    NS_HANDLER
     // NSLog(@"Exception during -establishConnection %@",localException);
    NS_ENDHANDLER
   }
}

-(void)buildConnectionsWithNameTable:(NSDictionary *)nameTable {
   id owner=[nameTable objectForKey:@"NSOwner"];

   [self replaceObject:_fileOwner withObject:owner];
   [_fileOwner autorelease];
   _fileOwner=[owner retain];

   [self establishConnections];
}

@end
