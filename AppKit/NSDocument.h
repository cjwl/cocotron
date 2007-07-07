/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>

@class NSWindow,NSWindowController,NSSavePanel, NSMenuItem,NSFileWrapper;

typedef enum {
   NSChangeDone,
   NSChangeUndone,
   NSChangeCleared
} NSDocumentChangeType;

typedef enum {
   NSSaveOperation,
   NSSaveAsOperation,
   NSSaveToOperation
} NSSaveOperationType;

@interface NSDocument : NSObject {
   NSMutableArray *_windowControllers;
   NSString       *_path;
   NSString       *_type;
   int             _changeCount;
   unsigned        _untitledNumber;
   NSUndoManager  *_undoManager;
   BOOL            _hasUndoManager;
}

-init;
-initWithContentsOfFile:(NSString *)path ofType:(NSString *)type;

-(NSData *)dataRepresentationOfType:(NSString *)type;
-(BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type;

-(void)makeWindowControllers;

-(NSString *)windowNibName;
-(void)windowControllerDidLoadNib:(NSWindowController *)controller;
-(void)windowControllerWillLoadNib:(NSWindowController *)controller;

-(NSArray *)windowControllers;
-(void)addWindowController:(NSWindowController *)controller;
-(void)removeWindowController:(NSWindowController *)controller;

-(void)showWindows;
-(NSString *)displayName;
-(void)setWindow:(NSWindow *)window;

-(BOOL)readFromData:(NSData *)data ofType:(NSString *)type error:(NSError **)error;
-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)type error:(NSError **)error;
-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error;

-(BOOL)readFromFile:(NSString *)path ofType:(NSString *)type;
-(BOOL)writeToFile:(NSString *)path ofType:(NSString *)type;
-(BOOL)writeWithBackupToFile:(NSString *)path ofType:(NSString *)type saveOperation:(NSSaveOperationType)operation;
-(NSString *)fileName;
-(void)setFileName:(NSString *)path;
-(BOOL)keepBackupFile;

-(BOOL)isDocumentEdited;
-(void)updateChangeCount:(NSDocumentChangeType)changeType;

-(NSUndoManager *)undoManager;
-(void)setUndoManager:(NSUndoManager *)undoManager;
-(BOOL)hasUndoManager;
-(void)setHasUndoManager:(BOOL)flag;

-(BOOL)prepareSavePanel:(NSSavePanel *)savePanel;
-(void)runModalSavePanelForSaveOperation:(NSSaveOperationType)operation delegate:delegate didSaveSelector:(SEL)selector contextInfo:(void *)context;

-(void)printDocument:sender;
-(void)runPageLayout:sender;
-(void)revertDocumentToSaved:sender;
-(void)saveDocument:sender;
-(void)saveDocumentAs:sender;
-(void)saveDocumentTo:sender;

-(BOOL)revertToSavedFromFile:(NSString *)path ofType:(NSString *)type;

-(void)setFileType:(NSString *)type;
-(NSString *)fileType;

-(BOOL)validateMenuItem:(NSMenuItem *)item;

// private
-(void)_setUntitledNumber:(int)number;
@end
