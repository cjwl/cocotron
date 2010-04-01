//
//  SecKeychain.m
//  Security
//
//  Created by Christopher Lloyd on 2/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SecKeychain.h"
#import "SecKeychainItem.h"
#import "SecKeychainCursor.h"
#import <windows.h>
#import <wincrypt.h>
#import <rpc.h>

#define PERFORM_CRYPT 1

/*
  Keychain items are stored in the registry under
     HKEY_CURRENT_USER/Software/Cocotron/Keychains/login/<item class>/<GUID>
  
  Each entry under the GUID has all the attribute values and data.
  
  There is no index, so to find an item you have to scan down the list of GUID's.
 */

@implementation SecKeychain

-initWithRegistryPath:(NSArray *)path {
   _registryPath=[path copy];
   return self;
}

-(void)dealloc {
   [_registryPath release];
   [super dealloc];
}

+(SecKeychain *)defaultUserKeychain {
   NSArray *path=[NSArray arrayWithObjects:@"Software",@"Cocotron",@"Keychains",@"login",nil];
   
   return [[[SecKeychain alloc] initWithRegistryPath:path] autorelease];
}

static inline int unicodeLength(const unichar *unicode){
   int result;
   
   for(result=0;unicode[result]!=0;result++)
    ;
   
   return result;
}

-(NSString *)createGUID {
   UUID guid;
   unsigned short *uString;
   
   UuidCreate(&guid);
   
   RPC_STATUS error;
   if((error=UuidToStringW(&guid,&uString))!=RPC_S_OK)
    NSLog(@"UuidToStringW failed with %d",error);
   
   NSString *result=[NSString stringWithCharacters:uString length:unicodeLength(uString)];
   
   RpcStringFreeW(&uString);
      
   return result;
}

static const unichar *ZeroTerminatedString(NSString *string){
   NSInteger length=[string length];
   unichar   buffer[length+1];
   
   [string getCharacters:buffer];
   buffer[length]=0;
   
   return [[NSData dataWithBytes:buffer length:(length+1)*2] bytes];
}

static NSString *stringForFourCharCode(uint32_t value){
   unichar buffer[4];
   int     i;
   
   for(i=0;i<4;i++){
    buffer[3-i]=value&0xFF;
    value>>=8;
   }
   
   return [NSString stringWithCharacters:buffer length:4];
}

static HKEY handleToPath(NSArray *path){
   NSInteger i,count=[path count];
   HKEY      previous=HKEY_CURRENT_USER;
   HKEY      current=NULL;
   LONG      error;
   unichar   zero={0};
   
   for(i=0;i<count;i++){
    error=RegCreateKeyExW(previous,ZeroTerminatedString([path objectAtIndex:i]),0,&zero,REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,NULL,&current,NULL);

    if(error!=ERROR_SUCCESS)
     NSLog(@"RegCreateKeyExW failed at index %d in path=%@",i,path);

    if(previous!=HKEY_CURRENT_USER)
     RegCloseKey(previous);

    previous=current;
   }

   return current;
}

-(SecKeychainCursor *)createCursorForItemClass:(SecItemClass)itemClass {
   NSMutableArray *path=[NSMutableArray array];
   
   [path addObjectsFromArray:_registryPath];
   [path addObject:stringForFourCharCode(itemClass)];
   
   HKEY handle=handleToPath(path);
   SecKeychainCursor *result=[[SecKeychainCursor alloc] initWithRegistryPath:path itemClass:itemClass handle:handle];
   
   return result;
}

static uint32_t fourByteCodeFromUnicode(unichar *unicode){
   uint32_t result=0;
   
   result=unicode[0];
   result<<=8;
   result|=unicode[1];
   result<<=8;
   result|=unicode[2];
   result<<=8;
   result|=unicode[3];
   
   return result;
}

static uint32_t *createFourByteCodeFromString(NSString *string){
   uint32_t *result=NSZoneMalloc(NULL,4);
   unichar   unicode[4];
   
   [string getCharacters:unicode range:NSMakeRange(0,4)];
   
   *result=fourByteCodeFromUnicode(unicode);
   
   return result;
}

static BOOL is_BLOB_(unichar *buffer,DWORD length){
   if(length!=6)
    return NO;
   if(buffer[0]!='_')
    return NO;
   if(buffer[1]!='B')
    return NO;
   if(buffer[2]!='L')
    return NO;
   if(buffer[3]!='O')
    return NO;
   if(buffer[4]!='B')
    return NO;
   if(buffer[5]!='_')
    return NO;
    
   return YES;
}

static void *encryptData(void *bytes,unsigned length,unsigned *resultLength){
#ifndef PERFORM_CRYPT
   *resultLength=length;
   void *result=NSZoneMalloc(NULL,*resultLength);
   SecByteCopy(bytes,result,length);
   return result;
#else
   DATA_BLOB plaintext;
   DATA_BLOB crypted;
   
   plaintext.pbData=bytes;
   plaintext.cbData=length;
   
   if(!CryptProtectData(&plaintext,L"Keychain encrypted data",NULL,NULL,NULL,0,&crypted)){
    *resultLength=0;
    return NULL;
   }

   *resultLength=crypted.cbData;
   void *result=NSZoneMalloc(NULL,*resultLength);
   
   SecByteCopy(crypted.pbData,result,*resultLength);
   LocalFree(crypted.pbData);
   
   return result;
#endif
}

static void *decryptData(void *bytes,unsigned length,unsigned *resultLength){
#ifndef PERFORM_CRYPT
   *resultLength=length;
   void *result=NSZoneMalloc(NULL,*resultLength);
   SecByteCopy(bytes,result,length);
   return result;
#else
   DATA_BLOB crypted;
   unichar  *description;
   DATA_BLOB plaintext;
   
   crypted.pbData=bytes;
   crypted.cbData=length;
   
   if(!CryptUnprotectData(&crypted,&description,NULL,NULL,NULL,0,&plaintext)){
    NSLog(@"CryptUnprotectData failed");
    *resultLength=0;
    return NULL;
   }

   *resultLength=plaintext.cbData;
   void *result=NSZoneMalloc(NULL,*resultLength);
   
   SecByteCopy(plaintext.pbData,result,plaintext.cbData);
   LocalFree(plaintext.pbData);
   LocalFree(description);
   
   return result;
#endif
}

-(SecKeychainItemRef)createItemAtHandle:(HKEY)handle itemClass:(SecItemClass)itemClass {
   SecKeychainAttributeList *list=NSZoneMalloc(NULL,sizeof(SecKeychainAttributeList));
   UInt32 blobLength=0;
   void  *blobBytes=NULL;
   int    i,listCapacity=1;
   
   list->count=0;
   list->attr=NSZoneMalloc(NULL,sizeof(SecKeychainAttribute)*listCapacity);
   
   for(i=0;;i++){
    unichar nameBuffer[256];
    DWORD   nameLength=256;
    DWORD   type;
    BYTE   *data;
    DWORD   dataLength=0;
    DWORD   error;
    
    error=RegEnumValueW(handle,i,nameBuffer,&nameLength,NULL,&type,NULL,&dataLength);
    if(error==ERROR_NO_MORE_ITEMS)
     break;
     
    if(!(error==ERROR_MORE_DATA || error==ERROR_SUCCESS)){
     SecKeychainItemFreeAttributesAndData(list,blobBytes);

     return nil;
    }
      
    data=__builtin_alloca(dataLength);
    nameLength=256;
    if(RegEnumValueW(handle,i,nameBuffer,&nameLength,NULL,&type,data,&dataLength)!=ERROR_SUCCESS){
     SecKeychainItemFreeAttributesAndData(list,blobBytes);
     return nil;
    }
    
    if(nameLength==4 && type==REG_SZ && (dataLength%2==0)){
     SecKeychainAttrType tag=fourByteCodeFromUnicode(nameBuffer);
     NSString           *string=[NSString stringWithCharacters:(unichar *)data length:dataLength/2-1];

     if(list->count+1>=listCapacity){
      listCapacity*=2;
      list->attr=NSZoneRealloc(NULL,list->attr,sizeof(SecKeychainAttribute)*listCapacity);
     }
     
     list->attr[list->count].tag=tag;
     list->attr[list->count].length=0;
     list->attr[list->count].data=NULL;
     
     switch(tag){
      case kSecDescriptionItemAttr: // utf8
      case kSecLabelItemAttr: // utf8
      case kSecAccountItemAttr: // utf8
      case kSecServerItemAttr: // utf8
      case kSecServiceItemAttr: // utf8
       ;
       const char *utf8=[string UTF8String];
       
       list->attr[list->count].length=strlen(utf8);
       list->attr[list->count].data=NSZoneMalloc(NULL,list->attr[list->count].length);
       SecByteCopy(utf8,list->attr[list->count].data,list->attr[list->count].length);
       break;

      case kSecCreatorItemAttr:// four byte code
      case kSecTypeItemAttr: // four byte code
      case kSecProtocolItemAttr: // four byte code
       ;
       if(dataLength==10){ // four byte code stored as unicode with terminating zero        
        list->attr[list->count].length=4;
        list->attr[list->count].data=createFourByteCodeFromString(string);
       }
       break;

      case kSecCustomIconItemAttr: // ignore
       break;
     
      default:
       SecKeychainItemFreeAttributesAndData(list,blobBytes);
       return nil;

     }
     list->count++;
     
    }
    else if(is_BLOB_(nameBuffer,nameLength) && type==REG_BINARY){     
     blobLength=0;
     blobBytes=decryptData(data,dataLength,&blobLength);
    }
    else {
     SecKeychainItemFreeAttributesAndData(list,blobBytes);
     return nil;
    }
   }
  
   SecKeychainItem *result=[[SecKeychainItem alloc] initWithItemClass:itemClass attributeList:list length:blobLength bytes:blobBytes];
  
   [result setKeychain:self];
   
   SecKeychainItemFreeAttributesAndData(list,blobBytes);
  
   return result;

}

-(SecKeychainItemRef)createNextItemAtCursor:(SecKeychainCursor *)cursor attributeList:(const SecKeychainAttributeList *)attributeList {
   SecKeychainItemRef result=nil;
   
   while(result==nil){
    unichar nameBuffer[1024];
    DWORD   nameBufferLength=1024;
   
    if(RegEnumKeyExW([cursor handle],[cursor index],nameBuffer,&nameBufferLength,NULL,NULL,NULL,NULL)!=ERROR_SUCCESS)
     return nil;
    
    [cursor incrementIndex];
    NSString *guid=[NSString stringWithCharacters:nameBuffer length:nameBufferLength];
    NSMutableArray *path=[NSMutableArray array];
    
    [path addObjectsFromArray:[cursor registryPath]];
    [path addObject:guid];
    
    HKEY checkHandle=handleToPath(path);

    SecKeychainItemRef item=[self createItemAtHandle:checkHandle itemClass:[cursor itemClass]];
    
    [item setGUID:guid];
    
    if(item==nil)
     return nil;
     
    if([item isMatchToAttributeList:attributeList])
     result=item;
    else
     [item release];
   }
   
   return result;
}


-(void)_writeItem:(SecKeychainItemRef)item handle:(HKEY)handle {
   SecKeychainAttributeList *attributeList=[item attributeList];
   LONG error;
   int  i;
   
   for(i=0;i<attributeList->count;i++){
    SecKeychainAttrType tag=attributeList->attr[i].tag;
    const unichar      *key=ZeroTerminatedString(stringForFourCharCode(tag));
    UInt32              length=attributeList->attr[i].length;
    void               *data=attributeList->attr[i].data;
    
    switch(tag){
     case kSecDescriptionItemAttr: // utf8
     case kSecLabelItemAttr: // utf8
     case kSecAccountItemAttr: // utf8
     case kSecServerItemAttr: // utf8
     case kSecServiceItemAttr: // utf8
      ;
      NSString *string=[[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
      const unichar  *unicode=ZeroTerminatedString(string);
      
      if((error=RegSetValueExW(handle,key,0,REG_SZ,(const BYTE *)unicode,([string length]+1)*2))!=ERROR_SUCCESS)
       NSLog(@"RegSetValueExW failed with %d",error);
       
      [string release];
      break;

     case kSecCreatorItemAttr:// four byte code
     case kSecTypeItemAttr: // four byte code
     case kSecProtocolItemAttr: // four byte code
      ;
      if(length==4){
       NSString *string=stringForFourCharCode(*(uint32_t *)data);
       const unichar  *unicode=ZeroTerminatedString(string);
       
       if((error=RegSetValueExW(handle,key,0,REG_SZ,(const BYTE *)unicode,([string length]+1)*2))!=ERROR_SUCCESS)
        NSLog(@"RegSetValueExW failed with %d",error);
      }
      break;

     case kSecCustomIconItemAttr: // ignore
      break;
     
     default:
      break;
    }
    
   }
   
   const unichar *key=ZeroTerminatedString(@"_BLOB_");
   unsigned encryptedLength=0;
   void    *encrypted=encryptData([item blobBytes],[item blobLength],&encryptedLength);
   
   if((error=RegSetValueExW(handle,key,0,REG_BINARY,encrypted,encryptedLength))!=ERROR_SUCCESS)
    NSLog(@"RegSetValueExW failed with %d",error);
   
}

-(void)addKeychainItem:(SecKeychainItemRef)item {
   NSMutableArray *path=[NSMutableArray array];
   
   [path addObjectsFromArray:_registryPath];
   [path addObject:stringForFourCharCode([item itemClass])];
   [path addObject:[item GUID]];
   
   HKEY handle=handleToPath(path);
   
   [self _writeItem:item handle:handle];
   
   RegFlushKey(handle);
   RegCloseKey(handle);
}

-(void)removeKeychainItem:(SecKeychainItemRef)item {
   NSString *guid=[item GUID];
   
   if(guid!=nil){
    NSMutableArray *path=[NSMutableArray array];
   
    [path addObjectsFromArray:_registryPath];
    [path addObject:stringForFourCharCode([item itemClass])];
    
    HKEY handle=handleToPath(path);
    
    RegDeleteKeyW(handle,ZeroTerminatedString(guid));
    
    RegFlushKey(handle);
    RegCloseKey(handle);
   }
}

-(void)modifyKeychainItem:(SecKeychainItemRef)item {
   NSMutableArray *path=[NSMutableArray array];
   
   [path addObjectsFromArray:_registryPath];
   [path addObject:stringForFourCharCode([item itemClass])];
   [path addObject:[item GUID]];
   
   HKEY handle=handleToPath(path);
   
   [self _writeItem:item handle:handle];
   
   RegFlushKey(handle);
   RegCloseKey(handle);
}

@end
