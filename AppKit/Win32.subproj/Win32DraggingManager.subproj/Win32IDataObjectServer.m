/* Copyright (c) 2006-2007 Christopher J. W. Lloyd <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/Win32IDataObjectServer.h>
#import <AppKit/Win32IEnumFORMATETCServer.h>
#import <AppKit/Win32FORMATETC.h>
#import <AppKit/Win32Pasteboard.h>
#import <Foundation/NSString_win32.h>
#import <AppKit/NSRaise.h>

#import <windows.h>

@implementation Win32IDataObjectServer

-initWithPasteboard:(Win32Pasteboard *)pasteboard {
   [super initAsIDataObject];
   _pasteboard=[pasteboard retain];
   [_pasteboard incrementServerCount];
   return self;
}

-(void)dealloc {
   [_pasteboard decrementServerCount];
   [_pasteboard release];
   [super dealloc];
}

-(Win32Pasteboard *)pasteboard {
   return _pasteboard;
}

-(BOOL)setOnClipboard {
   if(OleSetClipboard([self iUknown])!=S_OK){
    NSLog(@"OleSetClipboard failed");
    return NO;
   }

   return YES;
}

-(NSArray *)formatEtcs {
   NSArray        *types=[_pasteboard types];
   NSMutableArray *result=[NSMutableArray array];
   int             i,count=[types count];
   FORMATETC format;

   format.ptd=NULL;
   format.dwAspect=DVASPECT_CONTENT;
   format.lindex=-1;
   format.tymed=TYMED_HGLOBAL;

   for(i=0;i<count;i++){
    NSString *type=[types objectAtIndex:i];

    if([type isEqualToString:NSStringPboardType]){
     format.cfFormat=CF_UNICODETEXT;
     [result addObject:[Win32FORMATETC formatEtcWithFORMATETC:format]];
     format.cfFormat=CF_TEXT;
     [result addObject:[Win32FORMATETC formatEtcWithFORMATETC:format]];
    }
    else if([type isEqualToString:NSRTFPboardType]){
     format.cfFormat=RegisterClipboardFormat("Rich Text Format");
     [result addObject:[Win32FORMATETC formatEtcWithFORMATETC:format]];
    }
    else if([type isEqualToString:NSFilenamesPboardType]){
     format.cfFormat=CF_HDROP;
     [result addObject:[Win32FORMATETC formatEtcWithFORMATETC:format]];
    }
    else {
     format.cfFormat=RegisterClipboardFormat([type cString]);
     [result addObject:[Win32FORMATETC formatEtcWithFORMATETC:format]];
    }
   }

   return result;
}

-(HRESULT)formatIsValid:(FORMATETC *)format {
   NSArray *formats=[self formatEtcs]; 
   int      i,count=[formats count];

   if(format->dwAspect!=DVASPECT_CONTENT)
    return DV_E_DVASPECT;
   if(format->lindex!=-1)
    return DV_E_LINDEX;
   if(!(format->tymed&TYMED_HGLOBAL))
    return TYMED_HGLOBAL;

   for(i=0;i<count;i++){
    if([[formats objectAtIndex:i] FORMATETC].cfFormat==format->cfFormat)
     return S_OK;
   }

   return DV_E_FORMATETC;
}

-(HRESULT)GetData:(FORMATETC *)format:(STGMEDIUM *)storageMediump {
   HRESULT   result;

   if((result=[self formatIsValid:format])!=S_OK)
    return result;

   storageMediump->tymed=TYMED_HGLOBAL;

   if(format->cfFormat==CF_TEXT){
    NSString *string=[_pasteboard stringForType:NSStringPboardType];
    char     *buffer;

    storageMediump->hGlobal=GlobalAlloc(GMEM_FIXED,([string cStringLength]+1)*sizeof(char));
    buffer=GlobalLock(storageMediump->hGlobal);

    [string getCString:buffer];

    GlobalUnlock(storageMediump->hGlobal);
   }
   else if(format->cfFormat==CF_UNICODETEXT){
    NSString *string=[_pasteboard stringForType:NSStringPboardType];
    unichar  *buffer;

    storageMediump->hGlobal=GlobalAlloc(GMEM_FIXED,([string length]+1)*sizeof(unichar));
    buffer=GlobalLock(storageMediump->hGlobal);

    [string getCharacters:buffer];
    buffer[[string length]]=0x0000;

    GlobalUnlock(storageMediump->hGlobal);
   }
   else if(format->cfFormat==CF_HDROP){
    NSArray   *files=[_pasteboard propertyListForType:NSFilenamesPboardType];
    int        filesSize=sizeof(DROPFILES),i,count=[files count];
    DROPFILES *dropFiles;
    unichar   *buffer;

    for(i=0;i<count;i++){
     NSString *file=[files objectAtIndex:i];

     filesSize+=([file length]+1)*sizeof(unichar);
    }
    filesSize+=sizeof(unichar);

    storageMediump->hGlobal=GlobalAlloc(GMEM_FIXED,filesSize);
    dropFiles=GlobalLock(storageMediump->hGlobal);
    dropFiles->pFiles=sizeof(DROPFILES);
    dropFiles->pt.x=0;
    dropFiles->pt.y=0;
    dropFiles->fNC=0;
    dropFiles->fWide=YES;

    buffer=((void *)dropFiles)+sizeof(DROPFILES);
    for(i=0;i<count;i++){
     NSString *file=[files objectAtIndex:i];

     [file getCharacters:buffer];
     buffer[[file length]]=0x0000;
     buffer+=[file length]+1;
    }
    *buffer=0x0000;
   }
   else {
    char      name[2048];
    int       length;

    if((length=GetClipboardFormatName(format->cfFormat,name,2048))==0)
     return DV_E_FORMATETC;
    else {
     NSString *type=[NSString stringWithCString:name length:length];
     NSData   *data;

     if([type isEqualToString:@"Rich Text Format"])
      type=NSRTFPboardType;
  
     data=[_pasteboard dataForType:type];

     if(data!=nil){
      void     *buffer;

      storageMediump->hGlobal=GlobalAlloc(GMEM_FIXED,[data length]);
      buffer=GlobalLock(storageMediump->hGlobal);

      [data getBytes:buffer];

      GlobalUnlock(storageMediump->hGlobal);
     }
    }
   }
   
   storageMediump->pUnkForRelease=NULL;
   return S_OK;
}

-(HRESULT)GetDataHere:(FORMATETC *)format:(STGMEDIUM *)storageMedium {
   NSUnimplementedMethod();
   return DV_E_FORMATETC;
}

-(HRESULT)QueryGetData:(FORMATETC *)format {
   return [self formatIsValid:format];
}

-(HRESULT)GetCanonicalFormatEtc:(FORMATETC *)format:(FORMATETC *)pformatetcOut {
   NSUnimplementedMethod();
   return S_OK;
}

-(HRESULT)SetData:(FORMATETC *)format:(STGMEDIUM *)pmedium:(BOOL)fRelease {
   NSUnimplementedMethod();
   return S_OK;
}

-(HRESULT)EnumFormatEtc:(DWORD)dwDirection:(IEnumFORMATETC  **)ppenumFormatEtc {
   Win32IEnumFORMATETCServer *server=[[Win32IEnumFORMATETCServer alloc] initAsIEnumFORMATETC];

   [server setFormatEtcs:[self formatEtcs]];

   *ppenumFormatEtc=[server iUknown];

   return S_OK;
}

-(HRESULT)DAdvise:(FORMATETC *)pformatetc:(DWORD)advf:(IAdviseSink *)pAdvSink:(DWORD *)pdwConnection {
   NSUnimplementedMethod();
   return E_NOTIMPL;
}

-(HRESULT)DUnadvise:(DWORD)dwConnection {
   NSUnimplementedMethod();
   return E_NOTIMPL;
}

-(HRESULT)EnumDAdvise:(IEnumSTATDATA **)ppenumAdvise {
   NSUnimplementedMethod();
   return E_NOTIMPL;
}

@end
