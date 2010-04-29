#import <Security/Security.h>
#import "SecAccess.h"
#import "SecKeychain.h"
#import "SecKeychainItem.h"
#import "SecKeychainSearch.h"
#import "SecTrustedApplication.h"

OSStatus SecKeychainFindGenericPassword(CFTypeRef keychainOrArray, UInt32 serviceNameLength, const char *serviceName, UInt32 accountNameLength, const char *accountName, UInt32 *passwordLength, void **passwordData, SecKeychainItemRef *itemRef)
{
	SecKeychainAttributeList attributeList;
	attributeList.count = 2;
	attributeList.attr = malloc(sizeof(SecKeychainAttribute) * attributeList.count);
	attributeList.attr[0].tag = kSecAccountItemAttr;
	attributeList.attr[0].length = accountNameLength;
	attributeList.attr[0].data = (void *)accountName;
	attributeList.attr[1].tag = kSecServiceItemAttr;
	attributeList.attr[1].length = serviceNameLength;
	attributeList.attr[1].data = (void *)serviceName;

	SecKeychainSearchRef search;
	OSStatus status = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &attributeList, &search);
	if (status != 0)
	{
		free(attributeList.attr);
		return status;
	}
	
	status = SecKeychainSearchCopyNext(search, itemRef);
	if (status == 0 && *itemRef)
	{
		status = SecKeychainItemCopyAttributesAndData(*itemRef, NULL, NULL, NULL, passwordLength, passwordData);
	}
	else
	{
		status = errSecItemNotFound;
		*itemRef = NULL;
		*passwordData = NULL;
		*passwordLength = 0;
	}

	free(attributeList.attr);
	return status;
}

OSStatus SecKeychainAddGenericPassword (SecKeychainRef keychain, UInt32 serviceNameLength, const char *serviceName, UInt32 accountNameLength, const char *accountName, UInt32 passwordLength, void *passwordData, SecKeychainItemRef *itemRef)
{
	SecKeychainAttributeList attributeList;
	attributeList.count = 2;
	attributeList.attr = malloc(sizeof(SecKeychainAttribute) * attributeList.count);
	attributeList.attr[0].tag = kSecAccountItemAttr;
	attributeList.attr[0].length = accountNameLength;
	attributeList.attr[0].data = (void *)accountName;
	attributeList.attr[1].tag = kSecServiceItemAttr;
	attributeList.attr[1].length = serviceNameLength;
	attributeList.attr[1].data = (void *)serviceName;

	OSStatus status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &attributeList, passwordLength, passwordData, keychain, NULL, itemRef);
	free(attributeList.attr);
	return status;
}

OSStatus SecKeychainSearchCreateFromAttributes(CFTypeRef keychainOrArray,SecItemClass itemClass,const SecKeychainAttributeList *attributeList,SecKeychainSearchRef *resultSearch) {
   *resultSearch=[[SecKeychainSearch alloc] initWithKeychainOrArray:keychainOrArray itemClass:itemClass attributeList:attributeList];
   return 0;
}

OSStatus SecKeychainSearchCopyNext(SecKeychainSearchRef search,SecKeychainItemRef *resultItem) {
   *resultItem=[search copyNextItem];
   return 0;
}

OSStatus SecKeychainItemCopyAttributesAndData(SecKeychainItemRef item,SecKeychainAttributeInfo *info,SecItemClass *itemClass,SecKeychainAttributeList **attributeList,UInt32 *length,void **resultBytes) {
   [item copyAttributeInfo:info itemClass:itemClass attributeList:attributeList length:length bytes:resultBytes];
   return 0;
}

OSStatus SecKeychainItemModifyAttributesAndData(SecKeychainItemRef item,const SecKeychainAttributeList *attributeList,UInt32 length,const void *bytes) {
   [item modifyAttributeList:attributeList length:length bytes:bytes];
   [[item keychain] modifyKeychainItem:item];
   return 0;
}

OSStatus SecKeychainItemFreeAttributesAndData(SecKeychainAttributeList *attributeList,void *data) {
   SecFreeAttributeList(attributeList);
   
   if(data!=NULL)
    NSZoneFree(NULL,data);
    
   return 0;
}

OSStatus SecKeychainItemFreeContent(SecKeychainAttributeList *attributeList,void *data) {
   SecFreeAttributeList(attributeList);
   
   if(data!=NULL)
    NSZoneFree(NULL,data);
    
   return 0;
}

OSStatus SecTrustedApplicationCreateFromPath(const char *path,SecTrustedApplicationRef *resultApplication) {
  *resultApplication=[[SecTrustedApplication alloc] init];
   return 0;
}

OSStatus SecAccessCreate(CFStringRef descriptor,CFArrayRef trustedList,SecAccessRef *resultAccess) {
   *resultAccess=[[SecAccess alloc] initWithDescriptor:descriptor trustedList:trustedList];
   return 0;
}

OSStatus SecKeychainItemCreateFromContent(SecItemClass itemClass,SecKeychainAttributeList *attributeList,UInt32 length,const void *bytes,SecKeychainRef keychain,SecAccessRef initialAccess,SecKeychainItemRef *resultItem) {
   SecKeychainItemRef item=[[SecKeychainItem alloc] initWithItemClass:itemClass attributeList:attributeList length:length bytes:bytes];
   
   if(keychain==NULL)
    keychain=[SecKeychain defaultUserKeychain];
   
   [item setGUID:[keychain createGUID]];
   [item setKeychain:keychain];
   [item setAccess:initialAccess];
   
   [keychain addKeychainItem:item];
   
   if(resultItem!=NULL)
    *resultItem=item;
    
   return 0;
}


OSStatus SecKeychainItemDelete(SecKeychainItemRef item) {
   [[item keychain] removeKeychainItem:item];
   return 0;
}

void SecByteCopy(const void *srcVoid,void *dstVoid,size_t length){
   const uint8_t *src=srcVoid;
   uint8_t *dst=dstVoid;
   size_t i;
   
   for(i=0;i<length;i++)
    dst[i]=src[i];
}

SecKeychainAttributeList *SecCopyAttributeList(const SecKeychainAttributeList *attributeList){
   SecKeychainAttributeList *result=NSZoneMalloc(NULL,sizeof(SecKeychainAttributeList));
   
   result->count=attributeList->count;
   result->attr=NSZoneMalloc(NULL,sizeof(SecKeychainAttribute)*result->count);
   
   int i;
   for(i=0;i<result->count;i++){
    result->attr[i].tag=attributeList->attr[i].tag;
    result->attr[i].length=attributeList->attr[i].length;
    result->attr[i].data=NSZoneMalloc(NULL,result->attr[i].length);
    SecByteCopy(attributeList->attr[i].data,result->attr[i].data,result->attr[i].length);
   }

   return result;
}

void SecFreeAttributeList(SecKeychainAttributeList *list){
   if(list!=NULL){
    int i;
   
    if(list->attr!=NULL){
     for(i=0;i<list->count;i++)
      if(list->attr[i].data!=NULL)
       NSZoneFree(NULL,list->attr[i].data);
    
     NSZoneFree(NULL,list->attr);
    }
    
    NSZoneFree(NULL,list);
   }
}

