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

@implementation NSDocument

-init {
   static int nextUntitledNumber=1;

   _windowControllers=[NSMutableArray new];
   _path=nil;
   _type=nil;
   _changeCount=0;
   _untitledNumber=nextUntitledNumber++;
   _hasUndoManager=YES;

   return self;
}

-initWithContentsOfFile:(NSString *)path ofType:(NSString *)type {
   _windowControllers=[NSMutableArray new];
   _path=nil;
   _type=nil;
   _changeCount=0;
   _untitledNumber=0;
   _hasUndoManager=YES;

   if(![self readFromFile:path ofType:type]){
    NSRunAlertPanel(nil,@"Can't open file '%@'.",@"Ok",nil,nil,path);
    [self dealloc];
    return nil;
   }
   else {
    [self setFileName:path];
    [self setFileType:type];
   }

   return self;
}

-(NSData *)dataRepresentationOfType:(NSString *)type {
   [NSException raise:NSInternalInconsistencyException format:@"-[%@ %s]",isa,SELNAME(_cmd)];
   return nil;
}

-(BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
   [NSException raise:NSInternalInconsistencyException format:@"-[%@ %s]",isa,SELNAME(_cmd)];
   return NO;
}

-(void)makeWindowControllers {
   NSString *nibName=[self windowNibName];

   if(nibName!=nil){
    NSWindowController *controller=[[[NSWindowController alloc] initWithWindowNibName:nibName owner:self] autorelease];

    [self addWindowController:controller];
   }
}

-(NSString *)windowNibName {
   return nil;
}

-(void)windowControllerDidLoadNib:(NSWindowController *)controller {
   // do nothing
}

-(void)windowControllerWillLoadNib:(NSWindowController *)controller {
   // do nothing
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

-(void)showWindows {
   [_windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:self];
}

-(NSString *)displayName {
   if(_path==nil)
    return [NSString stringWithFormat:@"Untitled-%d",_untitledNumber];
   else
    return [_path lastPathComponent];
}

-(void)setWindow:(NSWindow *)window {
   [[_windowControllers objectAtIndex:0] setWindow:window];
   [window release];
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

-(BOOL)writeToFile:(NSString *)path ofType:(NSString *)type {
   NSData *data=[self dataRepresentationOfType:type];

   return [data writeToFile:path atomically:YES];
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

-(NSString *)fileName {
   return _path;
}

-(void)setFileName:(NSString *)path {
   path=[path copy];
   [_path release];
   _path=path;
   [_windowControllers makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

-(BOOL)keepBackupFile {
   return NO;
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

-(NSUndoManager *)undoManager {
    if (_undoManager == nil && _hasUndoManager == YES) {
        [self setUndoManager:[NSUndoManager new]];
        [_undoManager beginUndoGrouping];
    }

    return _undoManager;
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

-(BOOL)hasUndoManager {
    return _hasUndoManager;
}

-(void)setHasUndoManager:(BOOL)flag {
    _hasUndoManager = flag;
    if (flag == YES && _undoManager == nil)
        [self undoManager];
    else if (flag == NO && _undoManager != nil)
        [self setUndoManager:nil];
}

-(BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
   return YES;
}

-(void)saveToFile:(NSString *)path saveOperation:(NSSaveOperationType)operation delegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)context {
   if(path!=nil){
    BOOL success=[self writeWithBackupToFile:path ofType:_type saveOperation:operation];

    if(success){
     if(operation!=NSSaveToOperation)
      [self setFileName:path];
    }

    // send delegate message with success

    [self updateChangeCount:NSChangeCleared];
   }
}

-(void)runModalSavePanelForSaveOperation:(NSSaveOperationType)operation delegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)context {
   NSString    *directory=[_path stringByDeletingLastPathComponent];
   NSString    *file=[_path lastPathComponent];
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

-(void)printDocument:sender {
}

-(void)runPageLayout:sender {
}

-(void)revertDocumentToSaved:sender {
   int result=NSRunAlertPanel(nil,@"%@ has been edited. Are you sure you want to undo changes?",
    @"Revert",@"Cancel",nil,[self displayName]);

   if(result==NSAlertDefaultReturn)
    [self revertToSavedFromFile:[self fileName] ofType:[self fileType]];
}

-(void)saveDocument:sender {
   if(_path!=nil){
    [self saveToFile:_path saveOperation:NSSaveOperation 
       delegate:nil didSaveSelector:NULL contextInfo:NULL];
   }
   else {
    [self runModalSavePanelForSaveOperation:NSSaveOperation
       delegate:nil didSaveSelector:NULL contextInfo:NULL];
   }
}

-(void)saveDocumentAs:sender {
   [self runModalSavePanelForSaveOperation:NSSaveAsOperation
       delegate:nil didSaveSelector:NULL contextInfo:NULL];
}

-(void)saveDocumentTo:sender {
   [self runModalSavePanelForSaveOperation:NSSaveToOperation
       delegate:nil didSaveSelector:NULL contextInfo:NULL];
}

-(BOOL)revertToSavedFromFile:(NSString *)path ofType:(NSString *)type {
   if([self readFromFile:path ofType:type]){
    [self updateChangeCount:NSChangeCleared];
    return YES;
   }

   return NO;
}

-(void)setFileType:(NSString *)type {
   type=[type copy];
   [_type release];
   _type=type;
}

-(NSString *)fileType {
   return _type;
}

-(BOOL)validateMenuItem:(NSMenuItem *)item {
   return YES;
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
     if([controller shouldCloseDocument]){
     }

     [_windowControllers removeObjectAtIndex:count];
     return;
    }
   }
}

@end
