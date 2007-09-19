/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSDocument.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSApplication.h>

@interface NSDocumentController(forward)
-(void)_updateRecentDocumentsMenu;
@end

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

   [self _updateRecentDocumentsMenu];
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

-documentForURL:(NSURL *)url {
   int i,count=[_documents count];
   
   for(i=0;i<count;i++){
    NSDocument *document=[_documents objectAtIndex:i];
    NSURL      *check=[document fileURL];
    
    if(check!=nil && [check isEqual:url])
     return document;
   }
   
   return nil;
}

-makeDocumentWithContentsOfFile:(NSString *)path ofType:(NSString *)type {
   id    result;
   Class class=[self documentClassForType:type];

   result=[[[class alloc] initWithContentsOfFile:path ofType:type] autorelease];
   [result setFileType:type];

   return result;
}

-makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error {
   id    result;
   Class class=[self documentClassForType:type];

   result=[[[class alloc] initWithContentsOfURL:url ofType:type] autorelease];
   [result setFileType:type];

   return result;
}

-makeUntitledDocumentOfType:(NSString *)type {
   static int nextUntitledNumber=1;
   id    result;
   Class class=[self documentClassForType:type];

   result=[[[class alloc] init] autorelease];
   [result setFileType:type];
   [result _setUntitledNumber:nextUntitledNumber++];
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

   [self noteNewRecentDocument:result];

   return result;
}

-openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)display error:(NSError **)error {
   IMP mine=[NSDocumentController instanceMethodForSelector:@selector(openDocumentWithContentsOfFile:display:)];
   IMP theirs=[self methodForSelector:@selector(openDocumentWithContentsOfFile:display:)];
      
   if([url isFileURL] && mine!=theirs)
    return [self openDocumentWithContentsOfFile:[url path] display:display];
   else {
    NSDocument *result=[self documentForURL:url];

    if(result==nil){
     NSString   *extension=[[url path] pathExtension];
     NSString   *type=[self typeFromFileExtension:extension];
     
     result=[self makeDocumentWithContentsOfURL:url ofType:type error:error];

     if(result!=nil){
      [self addDocument:result];
      [result makeWindowControllers];
      [self noteNewRecentDocument:result];
     }
    }
    if(display)
     [result showWindows];
     
    return result;
   }
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

   extension=[extension lowercaseString];
   for(i=0;i<count;i++){
    NSDictionary *check=[_fileTypes objectAtIndex:i];
    NSArray      *names=[check objectForKey:@"CFBundleTypeExtensions"];
    int           count=[names count];
    
    while(--count>=0)
     if([[[names objectAtIndex:count] lowercaseString] isEqual:extension])
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
    NSError *error=nil;
    NSURL   *url=[NSURL fileURLWithPath:[files objectAtIndex:i]];

    [self openDocumentWithContentsOfURL:url display:YES error:&error];
   }
}

-(void)saveAllDocuments:sender {
}

-(NSArray *)_recentDocumentPaths {
   return [[NSUserDefaults standardUserDefaults] arrayForKey:@"NSRecentDocumentPaths"];
}

-(void)_openRecentDocument:sender {
   NSArray    *paths=[self _recentDocumentPaths];
   NSMenuItem *item=sender;
   int         tag=[item tag];

   if(tag>=0 && tag<[paths count]){
    NSError *error=nil;
    NSURL   *url=[NSURL fileURLWithPath:[paths objectAtIndex:tag]];
    
    [self openDocumentWithContentsOfURL:url display:YES error:&error];
   }
}

-(void)_removeAllRecentDocumentsFromMenu:(NSMenu *)menu {
   NSArray *items=[menu itemArray];
   int      count=[items count];

   while(--count>=0){
    NSMenuItem *check=[items objectAtIndex:count];
    
    if([check action]==@selector(_openRecentDocument:))
     [menu removeItemAtIndex:count];
   }
}


-(void)_updateRecentDocumentsMenu {
   NSMenu  *menu=[[NSApp mainMenu] _menuWithName:@"_NSRecentDocumentsMenu"];
   NSArray *array=[self _recentDocumentPaths];
   int      count=[array count];
 
   [self _removeAllRecentDocumentsFromMenu:menu];
   
   if([[menu itemArray] count]>0){
    if([array count]==0){
     if([[[menu itemArray] objectAtIndex:0] isSeparatorItem])
      [menu removeItemAtIndex:0];
    }
    else {
     if(![[[menu itemArray] objectAtIndex:0] isSeparatorItem])
      [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
    }
   }
   while(--count>=0){
    NSString   *path=[array objectAtIndex:count];
    NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:path action:@selector(_openRecentDocument:) keyEquivalent:nil] autorelease];
    
    [item setTag:count];
    [menu insertItem:item atIndex:0];
   }
}

-(NSArray *)recentDocumentURLs {
   NSArray        *paths=[self _recentDocumentPaths];
   int             i,count=[paths count];
   NSMutableArray *result=[NSMutableArray arrayWithCapacity:count];
   
   for(i=0;i<count;i++)
    [result addObject:[NSURL fileURLWithPath:[paths objectAtIndex:i]]];
    
   return result;
}

-(void)noteNewRecentDocumentURL:(NSURL *)url {
   NSString       *path=[url path];
   NSMutableArray *array=[NSMutableArray arrayWithArray:[self _recentDocumentPaths]];

   [array removeObject:path];
   [array insertObject:path atIndex:0];
   
   while([array count]>[self maximumRecentDocumentCount])
    [array removeLastObject];
    
   [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"NSRecentDocumentPaths"];
   [self _updateRecentDocumentsMenu];
}

-(void)noteNewRecentDocument:(NSDocument *)document {
   NSURL *url=[document fileURL];
  
   if(url!=nil)
    [self noteNewRecentDocumentURL:url];
}

-(unsigned)maximumRecentDocumentCount {
   NSString *value=[[NSUserDefaults standardUserDefaults] stringForKey:@"NSRecentDocumentMaximum"];
   
   return (value==nil)?10:[value intValue];
}

-(void)clearRecentDocuments:sender {
   NSArray *array=[NSArray array];
   
   [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"NSRecentDocumentPaths"];
   [self _updateRecentDocumentsMenu];
}

-(BOOL)application:sender openFile:(NSString *)path {
   NSError    *error=nil;
   NSURL      *url=[NSURL fileURLWithPath:path];
   NSDocument *document=[self openDocumentWithContentsOfURL:url display:YES error:&error];

   return (document!=nil)?YES:NO;
}

@end
