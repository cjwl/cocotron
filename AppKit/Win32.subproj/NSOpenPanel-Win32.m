/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSOpenPanel-Win32.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow-Private.h>
#import <AppKit/Win32Display.h>
#import <AppKit/Win32Window.h>

#import <windows.h>
#import <commdlg.h>
#import <shlobj.h>
#import <malloc.h>

@implementation NSOpenPanel(Win32)

-(int)_SHBrowseForFolder:(NSArray *)types {
   BROWSEINFO  browseInfo;
   ITEMIDLIST *itemIdList;
   LPMALLOC    mallocInterface;
   char        displayName[MAX_PATH+1];

   browseInfo.hwndOwner=[(Win32Window *)[[NSApp keyWindow] platformWindow] windowHandle];
   browseInfo.pidlRoot=NULL;
   browseInfo.pszDisplayName=displayName;
   browseInfo.lpszTitle=[_dialogTitle cString];
   browseInfo.ulFlags=0;
   browseInfo.lpfn=NULL;
   browseInfo.lParam=0;
   browseInfo.iImage=0;

   [(Win32Display *)[NSDisplay currentDisplay] stopWaitCursor];
   itemIdList=SHBrowseForFolder(&browseInfo);
   [(Win32Display *)[NSDisplay currentDisplay] startWaitCursor];

   if(itemIdList==NULL)
    return NSCancelButton;

   if(SHGetMalloc(&mallocInterface)!=NOERROR)
    NSLog(@"SHGetMalloc failed");

   if(!SHGetPathFromIDList(itemIdList,displayName))
    NSLog(@"SHGetPathFromIDList failed");

   mallocInterface->lpVtbl->Free(mallocInterface,itemIdList);
   mallocInterface->lpVtbl->Release(mallocInterface);

   [_filenames release];
   _filenames=[[NSArray arrayWithObject:[NSString stringWithCString:displayName]] retain];   

   if([_filenames count]>0){
    [_filename release];
    _filename=[[_filenames objectAtIndex:0] copy];
    [_directory release];
    _directory=[[_filename stringByDeletingLastPathComponent] copy];
   }

   return NSOKButton;
}

// I haven't figured out a way to distinguish between double-clicking a folder and
// clicking the Open button, so we are stuck with SHBrowseForFolder() for opening folders
// The hook works fine when there are file types to check against

static unsigned *openFileHook(HWND hdlg,UINT uiMsg,WPARAM wParam,LPARAM lParam) {
   static BOOL pastInitialFolderChange;

   if(uiMsg==WM_INITDIALOG)
    pastInitialFolderChange=NO;

   if(uiMsg==WM_NOTIFY){
    OFNOTIFY *notify=(void *)lParam;

    if(notify->hdr.code==CDN_FOLDERCHANGE){
     if(pastInitialFolderChange){ // we get one FOLDERCHANGE right after init, ignore it
      NSArray  *types=(NSArray *)notify->lpOFN->lCustData;
      char      folder[MAX_PATH+1];
      int       length=SendMessage(GetParent(hdlg),CDM_GETFOLDERPATH,MAX_PATH,(LPARAM)folder)-1;

      if(length>0){
       NSString *file=[NSString stringWithCString:folder length:length];
       NSString *extension=[file pathExtension];

       if([types containsObject:extension]){
        notify->lpOFN->lCustData=0xFFFFFFFF;
        strcpy(notify->lpOFN->lpstrFile,folder);
        PostMessage(GetParent(hdlg),WM_SYSCOMMAND,SC_CLOSE,0); 
       }
      }
     }
     pastInitialFolderChange=YES;
    }
   }

   return NULL;
}

-(int)_GetOpenFileNameForTypes:(NSArray *)types {
   OPENFILENAME openFileName;
   char         filename[MAX_PATH+1];
   char        *fileTypes,*ptr;
   int          i,count=[types count],fileTypesLength,check;

   fileTypesLength=0;
   for(i=0;i<count;i++){
    int typeLength=[[types objectAtIndex:i] cStringLength];

    fileTypesLength+=strlen("Document (*.")+typeLength+1+1+strlen("*.");
    fileTypesLength+=typeLength +1;
   }
   fileTypesLength++;

   fileTypes=alloca(sizeof(char)*fileTypesLength);
   ptr=fileTypes;
   for(i=0;i<count;i++){
    int typeLength=[[types objectAtIndex:i] cStringLength];

    strcpy(ptr,"Document (*.");
    ptr+=strlen("Document (*.");
    [[types objectAtIndex:i] getCString:ptr];
    ptr+=typeLength;
    strcpy(ptr,")");
    ptr+=2;

    strcpy(ptr,"*.");
    ptr+=strlen("*.");
    
    [[types objectAtIndex:i] getCString:ptr];
    ptr+=typeLength+1;
   }
   *ptr='\0';

   openFileName.lStructSize=sizeof(OPENFILENAME);
   openFileName.hwndOwner=[(Win32Window *)[[NSApp keyWindow] platformWindow] windowHandle];
   openFileName.hInstance=NULL;
   openFileName.lpstrFilter=fileTypes;
   openFileName.lpstrCustomFilter=NULL;
   openFileName.nMaxCustFilter=0;
   openFileName.nFilterIndex=1;
   strncpy(filename,[_filename fileSystemRepresentation],MAX_PATH);
   openFileName.lpstrFile=filename;
   openFileName.nMaxFile=1024;
   openFileName.lpstrFileTitle=NULL;
   openFileName.nMaxFileTitle=0;
   openFileName.lpstrInitialDir=[_directory fileSystemRepresentation];
   openFileName.lpstrTitle=[_dialogTitle cString];
   openFileName.Flags=
    (_allowsMultipleSelection?OFN_ALLOWMULTISELECT:0)|
    OFN_NOTESTFILECREATE|
    OFN_EXPLORER|
    OFN_HIDEREADONLY|
    OFN_ENABLEHOOK
    ;
   openFileName.nFileOffset=0;
   openFileName.nFileExtension=0;
   openFileName.lpstrDefExt=NULL;
   openFileName.lCustData=(LPARAM)types;
   openFileName.lpfnHook=(void *)openFileHook;
   openFileName.lpTemplateName=NULL;

   [(Win32Display *)[NSDisplay currentDisplay] stopWaitCursor];
   check=GetOpenFileName(&openFileName);
   [(Win32Display *)[NSDisplay currentDisplay] startWaitCursor];

   if(!check && openFileName.lCustData!=0xFFFFFFFF)
    return NSCancelButton;

   [_filenames release];
   {
    NSString *firstFile=[NSString stringWithCString:openFileName.lpstrFile];
    int       offset=openFileName.nFileOffset;

    if(offset<[firstFile length])
     _filenames=[[NSArray arrayWithObject:firstFile] retain];
    else {
     NSMutableArray *list=[NSMutableArray array];

     while(YES){
      NSString *next=[NSString stringWithCString:openFileName.lpstrFile+offset];

      if([next length]==0)
       break;

      [list addObject:[firstFile stringByAppendingPathComponent:next]];
      offset+=[next length]+1;
     }
     _filenames=[list retain];
    }
   }
   if([_filenames count]>0){
    [_filename release];
    _filename=[[_filenames objectAtIndex:0] copy];
    [_directory release];
    _directory=[[_filename stringByDeletingLastPathComponent] copy];
   }

   
   return NSOKButton;
}


@end
