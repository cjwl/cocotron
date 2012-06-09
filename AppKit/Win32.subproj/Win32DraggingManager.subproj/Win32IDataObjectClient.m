/* Copyright (c) 2006-2007 Christopher J. W. Lloyd - <cjwl@objc.net>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/Win32IDataObjectClient.h>
#import <AppKit/Win32IStreamClient.h>
#import <AppKit/Win32FORMATETC.h>
#import <Foundation/NSString_win32.h>
#import <Foundation/NSUnicodeCaseMapping.h>

#import <AppKit/NSPasteboard.h>

@implementation Win32IDataObjectClient

-initWithIDataObject:(struct IDataObject *)dataObject {
   _dataObject=dataObject;
   _dataObject->lpVtbl->AddRef(_dataObject);
   return self;
}

-initWithClipboard {
   struct IDataObject *data;

   if(OleGetClipboard(&data)!=S_OK){
#if DEBUG
    NSLog(@"OleGetClipboard(&data) failed");
#endif
    [self dealloc];
    return nil;
   }

   return [self initWithIDataObject:data];
}

-(void)dealloc {
   if(_dataObject!=NULL)
    _dataObject->lpVtbl->Release(_dataObject);

   [super dealloc];
}


-(NSArray *)availableTypes {
   NSMutableArray        *result=[NSMutableArray array];
   struct IEnumFORMATETC *enumerator;

   if(_dataObject->lpVtbl->EnumFormatEtc(_dataObject,DATADIR_GET,&enumerator)!=S_OK){
#if DEBUG
    NSLog(@"EnumFormatEtc failed");
#endif
    return nil;
   }

   while(YES){
    FORMATETC format;
    NSString *type=nil;

    if(enumerator->lpVtbl->Next(enumerator,1,&format,NULL)!=S_OK)
     break;

    switch(format.cfFormat){
     case CF_TEXT:
      type=NSStringPboardType;
      break;

     case CF_BITMAP: 
      break;

     case CF_METAFILEPICT:
      break;

     case CF_SYLK:
      break;

     case CF_DIF:
      break;

     case CF_TIFF:
      break;

     case CF_OEMTEXT:
      break;

     case CF_DIB:
      break;

     case CF_PALETTE:
      break;

     case CF_PENDATA:
      break;

     case CF_RIFF:
      break;

     case CF_WAVE:
      break;

     case CF_UNICODETEXT:
      type=NSStringPboardType;
      break;

     case CF_ENHMETAFILE:
      break;

     case CF_HDROP:
      type=NSFilenamesPboardType;
      break;

     case CF_LOCALE:
      break;

    default:{
      char      name[2048];
      int       length;

      if((length=GetClipboardFormatName(format.cfFormat,name,2048))>0)
       type=[NSString stringWithCString:name length:length];
     }
     break;
    }
    if(type!=nil)
     [result addObject:type];

    if(format.ptd!=NULL)
     CoTaskMemFree(format.ptd);

    switch(format.dwAspect){
     case DVASPECT_CONTENT:
      break;

     case DVASPECT_THUMBNAIL:
      break;

     case DVASPECT_ICON:
      break;

     case DVASPECT_DOCPRINT:
      break;

     default:
      break;
    }

    // format.lindex

    if(format.tymed&TYMED_HGLOBAL)
     ;
    if(format.tymed&TYMED_FILE)
     ;
    if(format.tymed&TYMED_ISTREAM)
     ;
    if(format.tymed&TYMED_ISTORAGE)
     ;
    if(format.tymed&TYMED_GDI)
     ;
    if(format.tymed&TYMED_MFPICT)
     ;
    if(format.tymed&TYMED_ENHMF)
     ;
    if(format.tymed&TYMED_NULL)
     ;
   }

   enumerator->lpVtbl->Release(enumerator);

   return result;
}

-(NSData *)dataForType:(NSString *)type {
   NSData   *result=nil;
   BOOL      copyData=YES;
   FORMATETC formatEtc;
   STGMEDIUM storageMedium;

   if([type isEqualToString:NSStringPboardType])
    formatEtc.cfFormat=CF_UNICODETEXT;
   else if([type isEqualToString:NSFilenamesPboardType])
    formatEtc.cfFormat=CF_HDROP;
   else {
    if((formatEtc.cfFormat=RegisterClipboardFormat([type cString]))==0){
#if DEBUG
     NSLog(@"RegisterClipboardFormat failed for type: %@", type);
#endif
     return nil;
    }
   }

   formatEtc.ptd=NULL;
   formatEtc.dwAspect=DVASPECT_CONTENT;
   formatEtc.lindex=-1;
   formatEtc.tymed=TYMED_HGLOBAL|TYMED_ISTREAM;

   if((_dataObject->lpVtbl->QueryGetData(_dataObject,&formatEtc))!=S_OK){
#if DEBUG
    NSLog(@"QueryGetData failed for type: %@", type);
#endif
    return nil;
   }

   _dataObject->lpVtbl->GetData(_dataObject,&formatEtc,&storageMedium);

   switch(storageMedium.tymed){

    case TYMED_GDI: // hBitmap
     break;

    case TYMED_MFPICT: // hMetaFilePict
     break;

    case TYMED_ENHMF: // hEnhMetaFile
     break;

    case TYMED_HGLOBAL: 
           { // hGlobal 
           uint8_t  *bytes=GlobalLock(storageMedium.hGlobal); 
           NSUInteger byteLength=GlobalSize(storageMedium.hGlobal); 
           if(formatEtc.cfFormat==CF_UNICODETEXT && (byteLength > 0)) { 
                if(byteLength % 2)  { // odd data length. WTF? 
                    uint8_t lastbyte = bytes[byteLength-1]; 
                    if(lastbyte != 0) { // not a null oddbyte, log it. 
                        NSLog(@"%s:%u[%s] -- \n*****CF_UNICODETEXT byte count not even and odd byte (%0X,'%c') not null",__FILE__, __LINE__, __PRETTY_FUNCTION__,(unsigned)lastbyte, 
lastbyte); 
                    } 
                        --byteLength; // truncate regardless 
                }  
                     
                while(byteLength>0)  { // zortch any terminating null unichars 
                    if(((unichar *) bytes)[(byteLength-2)/2] != 0) { 
                        break; 
                    } 
                    else { 
                        byteLength -= 2; 
                    } 
                }; 

/* check for BOM, if not it is big endian. */
                if(byteLength>=2){
                 if(bytes[0]==0xFE && bytes[1]==0xFF){
                  copyData=NO;
                  bytes=(uint8_t *)NSUnicodeFromBytesUTF16BigEndian(bytes+2, byteLength-2, &byteLength);
                  byteLength*=2;
                 }
                 else if(bytes[0]==0xFF && bytes[1]==0xFE){
                  copyData=NO;
                  bytes=(uint8_t *)NSUnicodeFromBytesUTF16LittleEndian(bytes+2, byteLength-2, &byteLength);
                  byteLength*=2;
                 }
                }
                if(copyData){
                  copyData=NO;
                  bytes=(uint8_t *)NSUnicodeFromBytesUTF16BigEndian(bytes, byteLength, &byteLength);
                  byteLength*=2;
                }
                
            } 
            if(copyData)
             result=[NSData dataWithBytes:bytes length:byteLength]; 
            else
             result=[NSData dataWithBytesNoCopy:bytes length:byteLength freeWhenDone:YES]; 
             
            GlobalUnlock(storageMedium.hGlobal); 
           } 
        break; 

    case TYMED_FILE: // lpszFileName
     break;

    case TYMED_ISTREAM:{ // pstm
      Win32IStreamClient *stream=[[Win32IStreamClient alloc] initWithIStream:storageMedium.pstm release:NO];

      result=[stream readDataToEndOfFile];

      [stream release];
     }
     break;

    case TYMED_ISTORAGE: // pstg
     break;
   }

   ReleaseStgMedium(&storageMedium);

   return result;
}

-(NSArray *)filenamesFromDROPFILES:(const DROPFILES *)dropFiles {
   NSMutableArray *result=[NSMutableArray array];
   const void     *fileBytes=((char *)dropFiles)+dropFiles->pFiles;
   BOOL            unicode=dropFiles->fWide;

   if(unicode){
    const unichar *ptr=fileBytes;
    unsigned length=0;

    while(ptr[length]!='\0'){
     while(ptr[length]!='\0')
      length++;

     [result addObject:[NSString stringWithCharacters:ptr length:length]];
     length++;
     ptr+=length;
     length=0;
    }
   }
   else {
    const char *ptr=fileBytes;
    unsigned length=0;

    while(ptr[length]!='\0'){
     while(ptr[length]!='\0')
      length++;

     [result addObject:[NSString stringWithCString:ptr length:length]];
     length++;
     ptr+=length;
     length=0;
    }
   }

   return result;
}

-(NSArray *)filenames {
   NSData *data=[self dataForType:NSFilenamesPboardType];

   if(data==nil)
    return nil;

   return [self filenamesFromDROPFILES:[data bytes]];
}

@end
