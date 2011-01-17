#import <CoreFoundation/CoreFoundation.h>

#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(SECURITY_INSIDE_BUILD)
#define SECURITY_EXPORT extern "C" __declspec(dllexport)
#else
#define SECURITY_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define SECURITY_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(SECURITY_INSIDE_BUILD)
#define SECURITY_EXPORT __declspec(dllexport) extern
#else
#define SECURITY_EXPORT __declspec(dllimport) extern
#endif
#else
#define SECURITY_EXPORT extern
#endif

#endif

typedef OSType SecKeychainAttrType;

typedef struct SecKeychainAttribute {
   SecKeychainAttrType tag;
   UInt32              length;
   void               *data;
} SecKeychainAttribute;

typedef struct SecKeychainAttributeList {
   UInt32                count;
   SecKeychainAttribute *attr;
} SecKeychainAttributeList;

typedef struct SecKeychainAttributeInfo {
   UInt32 count;
   UInt32 *tag;
   UInt32 *format;
} SecKeychainAttributeInfo;

// objc for now
@class SecKeychainItem,SecKeychainSearch,SecAccess,SecKeychain,SecTrustedApplication;

typedef SecKeychainItem *SecKeychainItemRef;
typedef SecKeychainSearch *SecKeychainSearchRef;
typedef SecAccess *SecAccessRef;
typedef SecKeychain *SecKeychainRef;
typedef SecTrustedApplication *SecTrustedApplicationRef;

// Keychain Item Attributes
typedef OSType SecItemClass;

enum {
   kSecDescriptionItemAttr=/* 'desc' */ 1684370275,
   kSecCreatorItemAttr=/* 'crtr' */ 1668445298,
   kSecTypeItemAttr=/* 'type' */ 1954115685,
   kSecLabelItemAttr=/* 'labl' */ 1818321516,
   kSecCustomIconItemAttr=/* 'cusi' */ 1668641641,
   kSecAccountItemAttr=/* 'acct' */ 1633903476,
   kSecServerItemAttr=/* 'srvr' */ 1936881266,
   kSecProtocolItemAttr=/* 'ptcl' */ 1886675820,
   kSecServiceItemAttr=/* 'svce' */ 1937138533,
   kSecGenericPasswordItemClass=/* 'genp' */ 1734700656   
};

// Keychain Item Class
enum {
   kSecInternetPasswordItemClass='inet',
};

enum {
 errSecItemNotFound=-25300
};

SECURITY_EXPORT OSStatus SecKeychainFindGenericPassword (CFTypeRef keychainOrArray, UInt32 serviceNameLength, const char *serviceName, UInt32 accountNameLength, const char *accountName, UInt32 *passwordLength, void **passwordData, SecKeychainItemRef *itemRef);
SECURITY_EXPORT OSStatus SecKeychainAddGenericPassword (SecKeychainRef keychain, UInt32 serviceNameLength, const char *serviceName, UInt32 accountNameLength, const char *accountName, UInt32 passwordLength, void *passwordData, SecKeychainItemRef *itemRef);

SECURITY_EXPORT OSStatus SecKeychainSearchCreateFromAttributes(CFTypeRef keychainOrArray,SecItemClass itemClass,const SecKeychainAttributeList *attributeList,SecKeychainSearchRef *resultSearch);
SECURITY_EXPORT OSStatus SecKeychainSearchCopyNext(SecKeychainSearchRef search,SecKeychainItemRef *resultItem);

SECURITY_EXPORT OSStatus SecKeychainItemCopyAttributesAndData(SecKeychainItemRef item,SecKeychainAttributeInfo *info,SecItemClass *itemClass,SecKeychainAttributeList **attributeList,UInt32 *length,void **resultBytes);
SECURITY_EXPORT OSStatus SecKeychainItemModifyAttributesAndData(SecKeychainItemRef item,const SecKeychainAttributeList *attributeList,UInt32 length,const void *bytes);
SECURITY_EXPORT OSStatus SecKeychainItemFreeAttributesAndData(SecKeychainAttributeList *attributeList,void *data);
SECURITY_EXPORT OSStatus SecKeychainItemFreeContent(SecKeychainAttributeList *attributeList,void *data);

SECURITY_EXPORT OSStatus SecTrustedApplicationCreateFromPath(const char *path,SecTrustedApplicationRef *resultApplication);
SECURITY_EXPORT OSStatus SecAccessCreate(CFStringRef descriptor,CFArrayRef trustedlist,SecAccessRef *resultAccess);
SECURITY_EXPORT OSStatus SecKeychainItemCreateFromContent(SecItemClass itemClass,SecKeychainAttributeList *attributeList,UInt32 length,const void *bytes,SecKeychainRef keychain,SecAccessRef initialAccess,SecKeychainItemRef *resultItem);
SECURITY_EXPORT OSStatus SecKeychainItemDelete(SecKeychainItemRef item);

// Internal, do not use
void SecByteCopy(const void *srcVoid,void *dstVoid,size_t length);
void SecFreeAttributeList(SecKeychainAttributeList *list);
SecKeychainAttributeList *SecCopyAttributeList(const SecKeychainAttributeList *attributeList);

