/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSDocument.h>
#import <AppKit/NSOpenPanel.h>

@implementation NSDocumentController

static NSDocumentController *shared=nil;

+sharedDocumentController {
   if(shared==nil)
    [[NSDocumentController alloc] init];

   return shared;
}

-init {
   if(shared==nil)
    shared=self;

   _documents=[NSMutableArray new];
   _fileTypes=[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDocumentTypes"] retain];

   return self;
}

-(NSArray *)documents {
   return _documents;
}

-(void)addDocument:(NSDocument *)document {
   [_documents addObject:document];
}

-(void)removeDocument:(NSDocument *)document {
   [_documents removeObjectIdenticalTo:document];
}

-makeDocumentWithContentsOfFile:(NSString *)path ofType:(NSString *)type {
   id    result;
   Class class=[self documentClassForType:type];

   result=[[[class alloc] initWithContentsOfFile:path ofType:type] autorelease];
   [result setFileType:type];

   return result;
}

-makeUntitledDocumentOfType:(NSString *)type {
   id    result;
   Class class=[self documentClassForType:type];

   result=[[[class alloc] init] autorelease];
   [result setFileType:type];

   return result;
}

-openUntitledDocumentOfType:(NSString *)type display:(BOOL)display {
   NSDocument *result=[self makeUntitledDocumentOfType:type];

   if(result!=nil)
    [self addDocument:result];

   [result makeWindowControllers];

   if(display)
    [result showWindows];

   return result;
}

-openDocumentWithContentsOfFile:(NSString *)path display:(BOOL)display {
   NSString   *extension=[path pathExtension];
   NSString   *type=[self typeFromFileExtension:extension];
   NSDocument *result=[self makeDocumentWithContentsOfFile:path ofType:type];

   if(result!=nil)
    [self addDocument:result];

   [result makeWindowControllers];

   if(display)
    [result showWindows];

   return result;
}

-(NSString *)currentDirectory {
   NSUnimplementedMethod();
   return nil;
}

-(id)currentDocument {
   NSUnimplementedMethod();
   return nil;
}

-(NSDictionary *)_infoForType:(NSString *)type {
   int i,count=[_fileTypes count];

   for(i=0;i<count;i++){
    NSDictionary *check=[_fileTypes objectAtIndex:i];
    NSString     *name=[check objectForKey:@"CFBundleTypeName"];

    if([name isEqualToString:type])
     return check;
   }
   return nil;
}

-(NSString *)displayNameForType:(NSString *)type {
   NSDictionary *info=[self _infoForType:type];
   NSString     *result=[info objectForKey:@"CFBundleTypeName"];

   return (result==nil)?type:result;
}

-(Class)documentClassForType:(NSString *)type {
   NSDictionary *info=[self _infoForType:type];
   NSString     *result=[info objectForKey:@"NSDocumentClass"];

   return (result==nil)?Nil:NSClassFromString(result);
}

-(NSArray *)fileExtensionsFromType:(NSString *)type {
   NSDictionary *info=[self _infoForType:type];

   return [info objectForKey:@"CFBundleTypeExtensions"];
}

-(NSArray *)_allFileExtensions {
   NSMutableSet *set=[NSMutableSet set];
   int           i,count=[_fileTypes count];

   for(i=0;i<count;i++){
    NSArray *add=[(NSDictionary *)[_fileTypes objectAtIndex:i] objectForKey:@"CFBundleTypeExtensions"];
    [set addObjectsFromArray:add];
   }

   return [set allObjects];
}

-(NSString *)typeFromFileExtension:(NSString *)extension {
   int i,count=[_fileTypes count];

   for(i=0;i<count;i++){
    NSDictionary *check=[_fileTypes objectAtIndex:i];
    NSArray      *names=[check objectForKey:@"CFBundleTypeExtensions"];

    if([names containsObject:extension])
     return [check objectForKey:@"CFBundleTypeName"];
   }
   return nil;
}

-(int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions {

   return [openPanel runModalForTypes:extensions];
}

-(NSArray *)fileNamesFromRunningOpenPanel {
   NSOpenPanel *openPanel=[NSOpenPanel openPanel];

   [openPanel setAllowsMultipleSelection:YES];

   if([self runModalOpenPanel:openPanel forTypes:[self _allFileExtensions]])
    return [openPanel filenames];

   return nil;
}

-(void)newDocument:sender {
   NSString *type=[(NSDictionary *)[_fileTypes objectAtIndex:0] objectForKey:@"CFBundleTypeName"];

   [self openUntitledDocumentOfType:type display:YES];
}

-(void)openDocument:sender {
   NSArray *files=[self fileNamesFromRunningOpenPanel];
   int      i,count=[files count];

   for(i=0;i<count;i++){
    NSString *path=[files objectAtIndex:i];

    [self openDocumentWithContentsOfFile:path display:YES];
   }
}

-(void)saveAllDocuments:sender {
}

-(BOOL)application:sender openFile:(NSString *)path {
   return ([self openDocumentWithContentsOfFile:path display:YES]!=nil)?YES:NO;
}

@end
