/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#define _WIN32_WINNT 0x0501

#import <AppKit/NSSavePanel-Win32.h>
#import <AppKit/NSApplication.h>
#import <AppKit/Win32Display.h>
#import <AppKit/Win32Window.h>
#import <AppKit/NSWindow-Private.h>
#import <malloc.h>

@implementation NSSavePanel(Win32)

static unsigned *saveFileHook(HWND hdlg,UINT uiMsg,WPARAM wParam,LPARAM lParam) {
   static BOOL pastInitialFolderChange;

   if(uiMsg==WM_INITDIALOG)
    pastInitialFolderChange=NO;

   if(uiMsg==WM_NOTIFY){
    OFNOTIFY *notify=(void *)lParam;

    if(notify->hdr.code==CDN_FOLDERCHANGE){
     if(pastInitialFolderChange){ // we get one FOLDERCHANGE right after init, ignore it
      NSString *type=(NSString *)notify->lpOFN->lCustData;
      char      folder[MAX_PATH+1];
      int       length=SendMessage(GetParent(hdlg),CDM_GETFOLDERPATH,MAX_PATH,(LPARAM)folder)-1;

      if(length>0){
       NSString *file=[NSString stringWithCString:folder length:length];
       NSString *extension=[file pathExtension];

       if([type length]>0 && [type isEqualToString:extension]){
        int result=NSRunAlertPanel(nil,@"%@ already exists. Do you want to replace it?",@"Yes",@"No",nil,file);

        if(result==NSAlertDefaultReturn){
         notify->lpOFN->lCustData=0xFFFFFFFF;
         strcpy(notify->lpOFN->lpstrFile,folder);
         PostMessage(GetParent(hdlg),WM_SYSCOMMAND,SC_CLOSE,0); 
        }
       }
      }
     }
     pastInitialFolderChange=YES;
    }
   }

   return NULL;
}

-(int)_GetOpenFileName {
   OPENFILENAME openFileName={0};
	int          check;

	@synchronized(self)
	{
		char         filename[1025]="";
		char        *fileTypes,*ptr;
		int          fileTypesLength;
		int          typeLength=[_requiredFileType cStringLength];
		
		fileTypesLength=0;
		fileTypesLength+=strlen("Document (*.")+typeLength+1+1+strlen("*.");
		fileTypesLength+=typeLength +1;
		fileTypesLength++;
		
		fileTypes=alloca(sizeof(char)*fileTypesLength);
		ptr=fileTypes;
		strcpy(ptr,"Document (*.");
		ptr+=strlen("Document (*.");
		[_requiredFileType getCString:ptr];
		ptr+=typeLength;
		strcpy(ptr,")");
		ptr+=2;
		
		strcpy(ptr,"*.");
		ptr+=strlen("*.");
		
		[_requiredFileType getCString:ptr];
		ptr+=typeLength+1;
		*ptr='\0';
		
		openFileName.lStructSize=sizeof(OPENFILENAME);
		openFileName.hwndOwner=[(Win32Window *)[[NSApp keyWindow] platformWindow] windowHandle];
		openFileName.hInstance=NULL;
		openFileName.lpstrFilter=fileTypes;
		openFileName.lpstrCustomFilter=NULL;
		openFileName.nMaxCustFilter=0;
		openFileName.nFilterIndex=1;
		strncpy(filename,[_filename fileSystemRepresentation],1024);
		openFileName.lpstrFile=filename;
		openFileName.nMaxFile=1024;
		openFileName.lpstrFileTitle=NULL;
		openFileName.nMaxFileTitle=0;
		openFileName.lpstrInitialDir=[_directory fileSystemRepresentation];
		openFileName.lpstrTitle=[_dialogTitle cString];
		openFileName.Flags=
		OFN_CREATEPROMPT|
		OFN_NOTESTFILECREATE|
		OFN_EXPLORER|
		OFN_HIDEREADONLY|
		OFN_OVERWRITEPROMPT|
		OFN_ENABLEHOOK|
      OFN_ENABLESIZING
		;
		openFileName.nFileOffset=0;
		openFileName.nFileExtension=0;
		openFileName.lpstrDefExt=NULL;
		openFileName.lCustData=(LPARAM)_requiredFileType;
		openFileName.lpfnHook=(void *)saveFileHook;
		openFileName.lpTemplateName=NULL;
	}

   [(Win32Display *)[NSDisplay currentDisplay] stopWaitCursor];
   check=GetSaveFileName(&openFileName);
   [(Win32Display *)[NSDisplay currentDisplay] startWaitCursor];

	@synchronized(self)
	{
		if(!check && openFileName.lCustData!=0xFFFFFFFF){
			return NSCancelButton;
		}
		
		[_filename release];
		_filename=[[NSString stringWithCString:openFileName.lpstrFile] copy];
		if(![[_filename pathExtension] isEqualToString:_requiredFileType]){
			[_filename autorelease];
			_filename=[[_filename stringByAppendingPathExtension:_requiredFileType] copy];
		}
	}

   return NSOKButton;
}

@end
