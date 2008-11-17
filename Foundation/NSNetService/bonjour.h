#import <Foundation/NSDictionary.h>
#import <Foundation/NSNumber.h>

// We want to provide a level of indirection to the bonjour interfaces which allows us to compile and link against
// NSNetService/NSNetServiceBrowser but still have them behave reasonably even if mDNS isn't installed

// Also need to make this optional, or maybe include it in the dev. tools
//#import <dns_sd.h>		// Apple's DNS Service Discovery

typedef void *bonjour_DNSServiceRef;
typedef void *bonjour_TXTRecordRef;
typedef int bonjour_DNSServiceFlags;
typedef int bonjour_DNSServiceErrorType;

enum {
kDNSServiceClass_IN,
};

enum {
kDNSServiceErr_NoError,

kDNSServiceErr_Unknown,
kDNSServiceErr_NoSuchName,
kDNSServiceErr_NoMemory,
kDNSServiceErr_BadParam,
kDNSServiceErr_BadReference,
kDNSServiceErr_BadState,
kDNSServiceErr_BadFlags,
kDNSServiceErr_Unsupported,
kDNSServiceErr_NotInitialized,
kDNSServiceErr_AlreadyRegistered,
kDNSServiceErr_NameConflict,
kDNSServiceErr_Invalid,
kDNSServiceErr_Firewall,
kDNSServiceErr_Incompatible,
kDNSServiceErr_BadInterfaceIndex,
kDNSServiceErr_Refused,
kDNSServiceErr_NoSuchRecord,
kDNSServiceErr_NoAuth,
kDNSServiceErr_NoSuchKey,
kDNSServiceErr_NATTraversal,
kDNSServiceErr_DoubleNAT,
kDNSServiceErr_BadTime,
};

enum {
kDNSServiceFlagsLongLivedQuery,
kDNSServiceFlagsMoreComing,
kDNSServiceFlagsAdd,
kDNSServiceFlagsBrowseDomains,
kDNSServiceFlagsRegistrationDomains,
};

enum {
kDNSServiceType_ANY,
kDNSServiceType_A,
kDNSServiceType_AAAA,
kDNSServiceType_A6,
kDNSServiceType_NS,
kDNSServiceType_MD,
kDNSServiceType_MF,
kDNSServiceType_CNAME,
kDNSServiceType_SOA,
kDNSServiceType_MB,
kDNSServiceType_MG,
kDNSServiceType_MR,
kDNSServiceType_NULL,
kDNSServiceType_WKS,
kDNSServiceType_PTR,
kDNSServiceType_HINFO,
kDNSServiceType_MINFO,
kDNSServiceType_MX,
kDNSServiceType_TXT,
kDNSServiceType_RP,
kDNSServiceType_AFSDB,
kDNSServiceType_X25,
kDNSServiceType_ISDN,
kDNSServiceType_RT,
kDNSServiceType_NSAP,
kDNSServiceType_NSAP_PTR,
kDNSServiceType_SIG,
kDNSServiceType_KEY,
kDNSServiceType_PX,
kDNSServiceType_GPOS,

kDNSServiceType_LOC,
kDNSServiceType_NXT,
kDNSServiceType_EID,
kDNSServiceType_NIMLOC,
kDNSServiceType_SRV,
kDNSServiceType_ATMA,
kDNSServiceType_NAPTR,
kDNSServiceType_KX,
kDNSServiceType_CERT,

kDNSServiceType_DNAME,
kDNSServiceType_SINK,
kDNSServiceType_OPT,
kDNSServiceType_TKEY,
kDNSServiceType_TSIG,
kDNSServiceType_IXFR,
kDNSServiceType_AXFR,
kDNSServiceType_MAILB,
kDNSServiceType_MAILA,

};

static inline bonjour_DNSServiceErrorType bonjour_bonjour_TXTRecordCreate(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_TXTRecordSetValue(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_TXTRecordDeallocate(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_TXTRecordGetCount(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_TXTRecordGetItemAtIndex(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceRefDeallocate(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceEnumerateDomains(){
   return kDNSServiceErr_Unknown;
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceBrowse(){
   return kDNSServiceErr_Unknown;
}

static inline void *bonjour_TXTRecordGetBytesPtr(bonjour_TXTRecordRef *txtRef) {
   return NULL;
}

static inline unsigned bonjour_TXTRecordGetLength(bonjour_TXTRecordRef *txtRef) {
   return 0;
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceQueryRecord(){
}

static inline int bonjour_DNSServiceRefSockFD(){
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceProcessResult(){
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceRegister(){
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceResolve(){
}

static inline bonjour_DNSServiceErrorType bonjour_DNSServiceUpdateRecord(){
}

static int
  ConvertError(int errorCode)
{
  
  switch( errorCode )
  {
    case kDNSServiceErr_Unknown:
      return NSNetServicesUnknownError;
    
    case kDNSServiceErr_NoSuchName:
      return NSNetServicesNotFoundError;
    
    case kDNSServiceErr_NoMemory:
      return NSNetServicesUnknownError;
    
    case kDNSServiceErr_BadParam:
    case kDNSServiceErr_BadReference:
    case kDNSServiceErr_BadState:
    case kDNSServiceErr_BadFlags:
      return NSNetServicesBadArgumentError;
    
    case kDNSServiceErr_Unsupported:
      return NSNetServicesUnknownError;
    
    case kDNSServiceErr_NotInitialized:
      return NSNetServicesInvalidError;
    
    case kDNSServiceErr_AlreadyRegistered:
    case kDNSServiceErr_NameConflict:
      return NSNetServicesCollisionError;
    
    case kDNSServiceErr_Invalid:
      return NSNetServicesInvalidError;
    
    case kDNSServiceErr_Firewall:
      return NSNetServicesUnknownError;
    
    case kDNSServiceErr_Incompatible:
      // The client library is incompatible with the daemon
      return NSNetServicesInvalidError;
    
    case kDNSServiceErr_BadInterfaceIndex:
    case kDNSServiceErr_Refused:
      return NSNetServicesUnknownError;
    
    case kDNSServiceErr_NoSuchRecord:
    case kDNSServiceErr_NoAuth:
    case kDNSServiceErr_NoSuchKey:
      return NSNetServicesNotFoundError;
    
    case kDNSServiceErr_NATTraversal:
    case kDNSServiceErr_DoubleNAT:
    case kDNSServiceErr_BadTime:
      return NSNetServicesUnknownError;
  }

  return errorCode;
}


static NSDictionary
  * CreateError(id sender,
                int errorCode)
{
  NSMutableDictionary
    *dictionary = nil;
  int
    error = 0;
  
  
  dictionary = [NSMutableDictionary dictionary];
  error = ConvertError(errorCode);
  
  LOG(@"%@ says error <%d> - <%d>", [sender description], errorCode, error);
  
  [dictionary setObject: [NSNumber numberWithInt: error]
                 forKey: NSNetServicesErrorCode];
  [dictionary setObject: sender
                 forKey: NSNetServicesErrorDomain];

  return dictionary; // autorelease'd
}
