/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Undo support - David Young <daver@geeks.org>
// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSDocument.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSWindowController.h>
#import <AppKit/NSSavePanel.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSFileWrapper.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSPageLayout.h>
#import <AppKit/NSPrintInfo.h>

@implementation NSDocument

+(NSArray *)readableTypes {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)writableTypes {
   NSUnimplementedMethod();
   return 0;
}

+(BOOL)isNativeType:(NSString *)type {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)_isSelectorOverridden:(SEL)selector {
   IMP mine=[NSDocument instanceMethodForSelector:selector];
   IMP theirs=[self methodForSelector:selector];
   
   return (mine!=theirs)?YES:NO;
}

-init {
   _windowControllers=[NSMutableArray new];
   _fileURL=nil;
   _fileType=nil;
   _changeCount=0;
   _untitledNumber=0;
   _hasUndoManager=YES;

   return self;
}

-initWithType:(NSString *)type error:(NSError **)error {
   [self init];
   [self setFileType:type];
   return self;
}

-initWithContentsOfURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error {
   if([self _isSelectorOverridden:@selector(initWithContentsOfFile:ofType:)]){
    if([self initWithContentsOfFile:[url path] ofType:type]==nil)
     return nil;
   }
   else {
    [self init];
    if(![self readFromURL:url ofType:type error:error]){
     [self dealloc];
     return nil;
    }
    [self setFileURL:url];
    [self setFileType:type];
   }
   [self setFileModificationDate:[NSDate date]];
   return self;
}

-initForURL:(NSURL *)url withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)type error:(NSError **)error {
   [self init];
   if(contentsURL!=nil){
    if(![self readFromURL:contentsURL ofType:type error:error]){
     [self dealloc];
     return nil;
    }
   }
   [self setFileURL:url];
   [self setFileType:type];
   [self setFileModificationDate:[NSDate date]];
   return self;
}


-(NSURL *)autosavedContentsFileURL {
   return _autosavedContentsFileURL;
}

-(NSDate *)fileModificationDate {
   return _fileModificationDate;
}

-(NSURL *)fileURL {
   return _fileURL;
}

-(NSPrintInfo *)printInfo {
   return _printInfo;
}

-(NSString *)fileType {
   return _fileType;
}

-(BOOL)hasUndoManager {
    return _hasUndoManager;
}


-(NSUndoManager *)undoManager {
    if (_undoManager == nil && _hasUndoManager == YES) {
        [self setUndoManager:[NSUndoManager new]];
        [_undoManager beginUndoGrouping];
    }

    return _undoManager;
}

-(void)setAutosavedContentsFileURL:(NSURL *)url {
   url=[url copy];
   [_autosavedContentsFileURL release];
   _autosavedContentsFileURL=url;
}

-(void)setFileModificationDate:(NSDate *)value {
   value=[value copy];
   [_fileModificationDate release];
   _fileModificationDate=value;
}

-(void)setFileURL:(NSURL *)url {
   url=[url copy];
   [_fileURL release];
   _fileURL=url;
   [_windowControllers makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

-(void)setPrintInfo:(NSPrintInfo *)value {
   value=[value copy];
   [_printInfo release];
   _printInfo=value;
}

-(void)setFileType:(NSString *)type {
   type=[type copy];
   [_fileType release];
   _fileType=type;
}

-(void)setHasUndoManager:(BOOL)flag {
    _hasUndoManager = flag;
    if (flag == YES && _undoManager == nil)
        [self undoManager];
    else if (flag == NO && _undoManager != nil)
        [self setUndoManager:nil];
}

-(void)setUndoManager:(NSUndoManager *)undoManager {
    if (_undoManager != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUndoManagerDidUndoChangeNotification
                                                      object:_undoManager];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUndoManagerDidRedoChangeNotification
                                                      object:_undoManager];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUndoManagerWillCloseUndoGroupNotification
                                                      object:_undoManager];
        [_undoManager release];
    }
    
    _undoManager = [undoManager retain];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_undoManagerDidUndoChange:)
                                                 name:NSUndoManagerDidUndoChangeNotification
                                               object:_undoManager];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_undoManagerDidRedoChange:)
                                                 name:NSUndoManagerDidRedoChangeNotification
                                               object:_undoManager];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_undoManagerDidCloseGroup:)
                                                 name:NSUndoManagerWillCloseUndoGroupNotification
                                               object:_undoManager];
}

-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    if (_hasUndoManager)
        return [self undoManager];

    return nil;
}

-(BOOL)hasUnautosavedChanges {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)autosavingFileType {
   return [self fileType];
}

-(void)setLastComponentOfFileName:(NSString *)name {
   name=[name copy];
   [_lastComponentOfFileName release];
   _lastComponentOfFileName=name;
}

-(NSString *)windowNibName {
   return nil;
}

-(void)setWindow:(NSWindow *)window {
   [[_windowControllers objectAtIndex:0] setWindow:window];
   [window release];
}

-(void)windowControllerDidLoadNib:(NSWindowController *)controller {
   // do nothing
}

-(void)windowControllerWillLoadNib:(NSWindowController *)controller {
   // do nothing
}

-(void)showWindows {
   [_windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:self];
}

-(void)makeWindowControllers {
   NSString *nibName=[self windowNibName];

   if(nibName!=nil){
    NSWindowController *controller=[[[NSWindowController alloc] initWithWindowNibName:nibName owner:self] autorelease];

    [self addWindowController:controller];
   }
}

-(NSArray *)windowControllers {
   return _windowControllers;
}

-(void)addWindowController:(NSWindowController *)controller {
   [_windowControllers addObject:controller];
   if([controller document]==nil)
    [controller setDocument:self];
}

-(void)removeWindowController:(NSWindowController *)controller {
   [_windowControllers removeObjectIdenticalTo:controller];
}

-(NSString *)displayName {
   if(_fileURL==nil) {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:bundlePath]; 
    if(_untitledNumber > 1)
     return [NSString stringWithFormat:@"Untitled %d - %@",_untitledNumber,appName];
    else
     return [NSString stringWithFormat:@"Untitled - %@",appName];
   } else {
    return [[_fileURL path] lastPathComponent];
   }
}

-(NSWindow *)windowForSheet {
   if([_windowControllers count]>0){
    NSWindow *check=[[_windowControllers objectAtIndex:0] window];
   
    if(check!=nil)
     return check;
   }
    
   return [NSApp mainWindow];
}

-(BOOL)isDocumentEdited {
   return (_changeCount>0)?YES:NO;
}

-(void)updateChangeCount:(NSDocumentChangeType)changeType {
   int count=[_windowControllers count];

   switch(changeType){
    case NSChangeDone:
     _changeCount++;
     break;

    case NSChangeUndone:
     _changeCount--;
     break;

    case NSChangeCleared:
     _changeCount=0;
     break;
   }

   while(--count>=0)
    [[_windowControllers objectAtIndex:count] setDocumentEdited:(_changeCount!=0)?YES:NO];
}

-(BOOL)readFromData:(NSData *)data ofType:(NSString *)type error:(NSError **)error {
   if([self _isSelectorOverridden:@selector(loadDataRepresentation:ofType:)])
    return [self loadDataRepresentation:data ofType:type];
   else {
    [NSException raise:NSInternalInconsistencyException format:@"-[%@ %s]",isa,SELNAME(_cmd)];
    return NO;
   }
}

-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)type error:(NSError **)error {  
   if([self _isSelectorOverridden:@selector(loadFileWrapperRepresentation:ofType:)])
    return [self loadFileWrapperRepresentation:fileWrapper ofType:type];
   else
    return [self readFromData:[fileWrapper regularFileContents] ofType:type error:error];
}

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error {
   if([url isFileURL]){    
    if([self _isSelectorOverridden:@selector(readFromFile:ofType:)]){
     return [self readFromFile:[url path] ofType:type];
    }
    else {
     NSFileWrapper *fileWrapper=[[[NSFileWrapper alloc] initWithPath:[url path]] autorelease];
   
     return [self readFromFileWrapper:fileWrapper ofType:type error:error];
    }
   }
   
   return NO;
}

-(BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error {
   if(![self readFromURL:url ofType:type error:error])
    return NO;

   [self setFileModificationDate:[NSDate date]];
   [self updateChangeCount:NSChangeCleared];
   return YES;
}


-(NSData *)dataOfType:(NSString *)type error:(NSError **)error {
   if([self _isSelectorOverridden:@selector(dataRepresentationOfType:)])
    return [self dataRepresentationOfType:type];
    
   [NSException raise:NSInternalInconsistencyException format:@"-[%@ %s]",isa,SELNAME(_cmd)];
   return nil;
}

-(NSFileWrapper *)fileWrapperOfType:(NSString *)type error:(NSError **)error {
   if([self _isSelectorOverridden:@selector(fileWrapperRepresentationOfType:)])
    return [self fileWrapperRepresentationOfType:type];
   else {
    NSData *data=[self dataOfType:type error:error];
    
    if(data==nil)
     return nil;
 
    return [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
   }
}

-(BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error {
   if([self _isSelectorOverridden:@selector(writeToFile:ofType:)]){
    return [self writeToFile:[url path] ofType:type];
   }
   else {
    NSFileWrapper *wrapper=[self fileWrapperOfType:type error:error];
   
    if(wrapper==nil)
     return NO;
   
    if(![wrapper writeToFile:[url path] atomically:YES updateFilenames:YES])
     return NO;
     
    return YES;
   }
}

-(BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)operation originalContentsURL:(NSURL *)contentsURL error:(NSError **)error {
   if([self _isSelectorOverridden:@selector(writeToFile:ofType:originalFile:saveOperation:)]){
    return [self writeToFile:[url path] ofType:type originalFile:[contentsURL path] saveOperation:operation];
   }
   else {
    return [self writeToURL:url ofType:type error:error];
   }
}

-(BOOL)writeSafelyToURL:(NSURL *)url ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)operation error:(NSError **)error {
   if(![self writeToURL:url ofType:type forSaveOperation:operation originalContentsURL:url error:error])
    return NO;
    
   NSDictionary *attributes=[self fileAttributesToWriteToURL:url ofType:type forSaveOperation:operation originalContentsURL:url error:error];

   if([attributes count])
    [[NSFileManager defaultManager] changeFileAttributes:attributes atPath:[url path]];
    
   return YES;
}

-(NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)operation originalContentsURL:(NSURL *)contentsURL error:(NSError **)error {
   NSMutableDictionary *result=[NSMutableDictionary dictionary];
   

   return result;
}

-(BOOL)keepBackupFile {
   return NO;
}

-(void)autosaveDocumentWithDelegate:delegate didAutosaveSelector:(SEL)selector contextInfo:(void *)info {
   NSError *error;
   
   if(![self writeToURL:[self autosavedContentsFileURL] ofType:[self autosavingFileType] forSaveOperation:NSAutosaveOperation originalContentsURL:[self fileURL] error:&error]){
   }
   
   NSUnimplementedMethod();
}


-(NSError *)willPresentError:(NSError *)error {
// do nothing
   return error;
}

-(BOOL)presentError:(NSError *)error {
   NSUnimplementedMethod();
   return 0;
}

-(void)presentError:(NSError *)error modalForWindow:(NSWindow *)window delegate:delegate didPresentSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}


-(NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)operation {
   NSArray *result=[[self class] writableTypes];
   
   if(operation==NSSaveToOperation){
    NSMutableArray *filtered=[NSMutableArray array];
    int             i,count=[result count];
    
    for(i=0;i<count;i++){
     NSString *check=[result objectAtIndex:i];
     
     if([[self class] isNativeType:check])
      [filtered addObject:check];
    }
    result=filtered;
   }
   
   return result;
}

-(BOOL)shouldRunSavePanelWithAccessoryView {
   return YES;
}

-(BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
   return YES;
}

-(BOOL)fileNameExtensionWasHiddenInLastRunSavePanel {
   NSUnimplementedMethod();
   return 0;
}

-(NSString *)fileTypeFromLastRunSavePanel {
   NSUnimplementedMethod();
   return nil;
}

-(void)runModalSavePanelForSaveOperation:(NSSaveOperationType)operation delegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)context {
   NSString    *path=[_fileURL path];
   NSString    *directory=[path stringByDeletingLastPathComponent];
   NSString    *file=[path lastPathComponent];
   NSString    *extension=[file pathExtension];
   NSSavePanel *savePanel=[NSSavePanel savePanel];
   int          saveResult;

   if([extension length]==0)
    extension=[[[NSDocumentController sharedDocumentController] fileExtensionsFromType:[self fileType]] objectAtIndex:0];

   [savePanel setRequiredFileType:extension];

   if(![self prepareSavePanel:savePanel])
    return;

   if(directory==nil)
    saveResult=[savePanel runModal];
   else
    saveResult=[savePanel runModalForDirectory:directory file:file];

   if(saveResult){
    NSString *savePath=[savePanel filename];

    [self saveToFile:savePath saveOperation:operation delegate:delegate didSaveSelector:selector contextInfo:context];
   }
}

-(void)saveDocumentWithDelegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}

-(BOOL)saveToURL:(NSURL *)url ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)operation error:(NSError **)error {
   if(url==nil)
    return NO;
   else {
    BOOL success=[self writeSafelyToURL:url ofType:type forSaveOperation:operation error:error];

    if(success){
     if(operation!=NSSaveToOperation)
      [self setFileURL:url];
    }

    // send delegate message with success

    [self updateChangeCount:NSChangeCleared];
    return YES;
   }
}

-(void)saveToURL:(NSURL *)url ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)operation delegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)info {
   NSError *error=nil;
   BOOL     success;
   
   if(!(success=[self saveToURL:url ofType:type forSaveOperation:operation error:&error])){
    [self presentError:error];
   }
   if([delegate respondsToSelector:selector]){
    NSUnimplementedMethod();
   }
}


-(BOOL)preparePageLayout:(NSPageLayout *)pageLayout {
// do nothing
   return YES;
}

-(BOOL)shouldChangePrintInfo:(NSPrintInfo *)printInfo {
// do nothing
   return YES;
}

-(void)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo delegate:delegate didRunSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}

-(void)runModalPrintOperation:(NSPrintOperation *)printOperation delegate:delegate didRunSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}

-(NSPrintOperation *)printOperationWithSettings:(NSDictionary *)settings error:(NSError **)error {
   NSLog(@"Implement %s in your subclass %@ of NSDocument to enable printing",SELNAME(_cmd),isa);
   return nil;
}

-(void)printDocumentWithSettings:(NSDictionary *)settings showPrintPanel:(BOOL)showPrintPanel delegate:delegate didPrintSelector:(SEL)selector contextInfo:(void *)contextInfo {
   if([self _isSelectorOverridden:@selector(printShowingPrintPanel:)]){
    [self printShowingPrintPanel:showPrintPanel];
   }
   else {
    NSError          *error=nil;
    NSPrintOperation *operation=[self printOperationWithSettings:settings error:&error];
   
    if(operation==nil){
     return;
    }
   
    [operation setShowsPrintPanel:showPrintPanel];
    [operation runOperation];
   }
// FIX, message delegate
}

-(void)close {
   int count=[_windowControllers count];
   
   while(--count>=0)
    [[_windowControllers objectAtIndex:count] close];

   [[NSDocumentController sharedDocumentController] removeDocument:self];
}

-(void)canCloseDocumentWithDelegate:delegate shouldCloseSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}

-(void)shouldCloseWindowController:(NSWindowController *)controller delegate:delegate shouldCloseSelector:(SEL)selector contextInfo:(void *)info {
   NSUnimplementedMethod();
}


-(void)revertDocumentToSaved:sender {
   int result=NSRunAlertPanel(nil,@"%@ has been edited. Are you sure you want to undo changes?",
    @"Revert",@"Cancel",nil,[self displayName]);

   if(result==NSAlertDefaultReturn)
    [self revertToSavedFromFile:[self fileName] ofType:[self fileType]];
}

-(void)saveDocument:sender {
   if(_fileURL!=nil){
    if([self _isSelectorOverridden:@selector(saveToFile:saveOperation:delegate:didSaveSelector:contextInfo:)]){
     [self saveToFile:[_fileURL path] saveOperation:NSSaveOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
    }
    else {
     [self saveToURL:_fileURL ofType:[self fileType] forSaveOperation:NSSaveOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
    }
   }
   else {
    [self runModalSavePanelForSaveOperation:NSSaveOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
   }
}

-(void)saveDocumentAs:sender {
   [self runModalSavePanelForSaveOperation:NSSaveAsOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
}

-(void)saveDocumentTo:sender {
   [self runModalSavePanelForSaveOperation:NSSaveToOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
}

-(void)printDocument:sender {
   [self printDocumentWithSettings:nil showPrintPanel:YES delegate:nil didPrintSelector:NULL contextInfo:NULL];
}


-(void)runPageLayout:sender {
   [[NSPageLayout pageLayout] runModal];
}

-(BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
   if([item action]==@selector(revertDocumentToSaved:))
    return (_fileURL!=nil)?YES:NO;
   if([item action]==@selector(saveDocument:))
    return YES;
   if([self respondsToSelector:[item action]]) 
    return YES; 

   return NO;
}

-(BOOL)validateMenuItem:(NSMenuItem *)item {
   if([item action]==@selector(revertDocumentToSaved:))
    return (_fileURL!=nil)?YES:NO;
   if([item action]==@selector(saveDocument:))
    return YES;
   if([self respondsToSelector:[item action]]) 
    return YES; 

   return NO;
}

-(BOOL)canCloseDocument {
   return YES;
}

-(NSData *)dataRepresentationOfType:(NSString *)type {
   [NSException raise:NSInternalInconsistencyException format:@"-[%@ %s]",isa,SELNAME(_cmd)];
   return nil;
}

-(NSDictionary *)fileAttributesToWriteToFile:(NSString *)path ofType:(NSString *)type saveOperation:(NSSaveOperationType)operation {
   return [NSDictionary dictionary];
}

-(NSString *)fileName {
   return [_fileURL path];
}

-(NSString *)fileNameFromRunningSavePanelForSaveOperation:(NSSaveOperationType)operation {
   NSUnimplementedMethod();
   return nil;
}

-(NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type {
   NSData *data=[self dataRepresentationOfType:type];
   
   if(data==nil)
    return nil;
    
   return [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
}

-initWithContentsOfFile:(NSString *)path ofType:(NSString *)type {
   NSURL   *url=[NSURL fileURLWithPath:path];
   NSError *error;
   
   [self init];

   error=nil;
   if(![self readFromURL:url ofType:type error:&error]){
    NSRunAlertPanel(nil,@"Can't open file '%@'. Error = %@",@"Ok",nil,nil,path,error);
    [self dealloc];
    return nil;
   }
   [self setFileName:path];
   [self setFileType:type];

   return self;
}


-initWithContentsOfURL:(NSURL *)url ofType:(NSString *)type {
   NSError  *error;
   
   [self init];

   error=nil;
   if(![self readFromURL:url ofType:type error:&error]){
    NSRunAlertPanel(nil,@"Can't open URL '%@'. Error = %@",@"Ok",nil,nil,url,error);
    [self dealloc];
    return nil;
   }
   [self setFileURL:url];
   [self setFileType:type];

   return self;
}

-(BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
   [NSException raise:NSInternalInconsistencyException format:@"-[%@ %s]",isa,SELNAME(_cmd)];
   return NO;
}

-(BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)fileWrapper ofType:(NSString *)type {

   if([fileWrapper isRegularFile])
    return [self loadDataRepresentation:[fileWrapper regularFileContents] ofType:type];

   return NO;
}

-(void)printShowingPrintPanel:(BOOL)flag {
   // do nothing
}

-(BOOL)readFromFile:(NSString *)path ofType:(NSString *)type {
   NSData *data=[[NSData alloc] initWithContentsOfFile:path];

   if(data==nil)
    return NO;

   if(![self loadDataRepresentation:data ofType:type]){
    [data release];
    return NO;
   }

   [data release];
   return YES;
}

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type {
   return [self readFromFile:[url path] ofType:type];
}

-(BOOL)revertToSavedFromFile:(NSString *)path ofType:(NSString *)type {
   if([self readFromFile:path ofType:type]){
    [self updateChangeCount:NSChangeCleared];
    return YES;
   }

   return NO;
}

-(BOOL)revertToSavedFromURL:(NSURL *)url ofType:(NSString *)type {
   if([self readFromURL:url ofType:type]){
    [self updateChangeCount:NSChangeCleared];
    return YES;
   }

   return NO;
}

-(int)runModalSavePanel:(NSSavePanel *)savePanel withAccessoryView:(NSView *)accessoryView {
   NSUnimplementedMethod();
   return 0;
}

-(int)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo {
   return [[NSPageLayout pageLayout] runModalWithPrintInfo:printInfo];
}

-(void)setFileName:(NSString *)path {
   [self setFileURL:[NSURL fileURLWithPath:path]];
}

-(void)saveToFile:(NSString *)path saveOperation:(NSSaveOperationType)operation delegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)context {
   if(path!=nil){
    BOOL success=[self writeWithBackupToFile:path ofType:_fileType saveOperation:operation];

    if(success){
     if(operation!=NSSaveToOperation)
      [self setFileName:path];
    }

    // send delegate message with success

    [self updateChangeCount:NSChangeCleared];
   }
}


-(BOOL)shouldCloseWindowController:(NSWindowController *)controller {
   if(![controller shouldCloseDocument])
    return NO;
   
   [self canCloseDocumentWithDelegate:nil shouldCloseSelector:NULL contextInfo:NULL];
   return YES;
}

-(BOOL)writeToFile:(NSString *)path ofType:(NSString *)type {
   NSData *data=[self dataRepresentationOfType:type];

   return [data writeToFile:path atomically:YES];
}

-(BOOL)writeToFile:(NSString *)path ofType:(NSString *)type originalFile:(NSString *)original saveOperation:(NSSaveOperationType)operation {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type {
   NSUnimplementedMethod();
   return 0;
}

-(BOOL)writeWithBackupToFile:(NSString *)path ofType:(NSString *)type saveOperation:(NSSaveOperationType)operation {
   // move original to backup

   if(![self writeToFile:path ofType:type])
    return NO;

   if(![self keepBackupFile]){
    // delete backup
   }
   return YES;
}

-(void)_setUntitledNumber:(int)number {
   _untitledNumber=number;
}



-(void)_undoManagerDidUndoChange:(NSNotification *)note {
    [self updateChangeCount:NSChangeUndone];
}

-(void)_undoManagerDidRedoChange:(NSNotification *)note {
    [self updateChangeCount:NSChangeDone];
}

-(void)_undoManagerDidCloseGroup:(NSNotification *)note {
    [self updateChangeCount:NSChangeDone];
}


-(BOOL)windowShouldClose:sender {
   if([[NSUserDefaults standardUserDefaults] boolForKey:@"useSheets"]){
    NSBeginAlertSheet(nil,@"Save",@"Don't Save",@"Cancel",sender,self,@selector(didEndShouldCloseSheet:returnCode:contextInfo:),NULL,sender,@"%@ has changed. Save?",[self displayName]);

    return NO;
   }
   else {
    if(![self isDocumentEdited])
     return YES;
    else {
     int result=NSRunAlertPanel(nil,@"%@ has changed. Save?",@"Save",@"Don't Save",@"Cancel",[self displayName]);

     switch(result){
      case NSAlertDefaultReturn:
       [self saveDocument:nil];
       return YES;

      case NSAlertAlternateReturn:
       return YES;

      case NSAlertOtherReturn:
      default:
       return NO;
     }
    }
   }
}

-(void)didEndShouldCloseSheet:(NSWindow *)sheet
        returnCode:(int)returnCode 
        contextInfo:(void *)contextInfo {
   NSWindow *window=(NSWindow *)contextInfo;

   switch(returnCode){
    case NSAlertDefaultReturn:
     [self saveDocument:nil];
     [window close];
     break;

    case NSAlertAlternateReturn:
     [window close];
     break;

    case NSAlertOtherReturn:
    default:
     break;
   }
}

-(void)windowWillClose:(NSNotification *)note {
   NSWindow *window=[note object];
   int       count=[_windowControllers count];

   while(--count>=0){
    NSWindowController *controller=[_windowControllers objectAtIndex:count];

    if([controller isWindowLoaded] && window==[controller window]){
     BOOL closeMe = [controller shouldCloseDocument]; 
     [_windowControllers removeObjectAtIndex:count]; 
     if (closeMe) 
      [self close]; 
     return; 
    }
   }
}

@end
