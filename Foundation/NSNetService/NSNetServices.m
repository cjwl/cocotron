/* Copyright (c) 2006 Chris B. Vetter
   Copyright (c) 2008 Dirk Theisen, Christopher J. W. Lloyd

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */
#import <Foundation/NSNetServices.h>

#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSStream.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSSelectInputSource.h>
#import <Foundation/NSSocket.h>

#import "bonjour.h"

NSString *NSNetServicesErrorCode = @"NSNetServicesErrorCode";
NSString *NSNetServicesErrorDomain = @"NSNetServicesErrorDomain";


@interface NSNetService(forward)
- (void) resolverCallback: (bonjour_DNSServiceRef) sdRef
                    flags: (bonjour_DNSServiceFlags) flags
                interface: (uint32_t) interfaceIndex
                    error: (bonjour_DNSServiceErrorType) errorCode
                 fullname: (const char *) fullname
                   target: (const char *) hosttarget
                     port: (uint16_t) port
                   length: (uint16_t) txtLen
                   record: (const char *) txtRecord;
- (void) registerCallback: (bonjour_DNSServiceRef) sdRef
                    flags: (bonjour_DNSServiceFlags) flags
                    error: (bonjour_DNSServiceErrorType) errorCode
                     name: (const char *) name
                     type: (const char *) regtype
                   domain: (const char *) domain;
- (void) queryCallback: (bonjour_DNSServiceRef) sdRef
                 flags: (bonjour_DNSServiceFlags) flags
             interface: (uint32_t) interfaceIndex
                 error: (bonjour_DNSServiceErrorType) errorCode
              fullname: (const char *) fullname
                  type: (uint16_t) rrtype
                 class: (uint16_t) rrclass
                length: (uint16_t) rdlen
                  data: (const void *) rdata
                   ttl: (uint32_t) ttl;
@end

static void ResolverCallback(bonjour_DNSServiceRef sdRef, bonjour_DNSServiceFlags flags,uint32_t interfaceIndex,bonjour_DNSServiceErrorType errorCode,const char *fullname,const char *hosttarget,uint16_t port,uint16_t txtLen,const char *txtRecord,void *context){
   [(NSNetService *) context resolverCallback: sdRef flags: flags interface: interfaceIndex error: errorCode fullname: fullname target: hosttarget port: port length: txtLen record: txtRecord];
}

static void RegistrationCallback(bonjour_DNSServiceRef sdRef,bonjour_DNSServiceFlags flags,bonjour_DNSServiceErrorType errorCode,const char *name,const char *regtype,const char *domain,void *context){
   [(NSNetService *) context registerCallback: sdRef flags: flags error: errorCode name: name type: regtype domain: domain];
}

static void QueryCallback(bonjour_DNSServiceRef sdRef,bonjour_DNSServiceFlags flags,uint32_t interfaceIndex,bonjour_DNSServiceErrorType errorCode,const char *fullname,uint16_t rrtype,uint16_t rrclass,uint16_t rdlen,const void *rdata,uint32_t ttl,void *context){
   [(NSNetService *) context queryCallback: sdRef flags: flags interface: interfaceIndex error: errorCode fullname: fullname type: rrtype class: rrclass length: rdlen data: rdata ttl: ttl];
}

@implementation NSNetService

-(void)_willPublish {
  if( [_delegate respondsToSelector:@selector(netServiceWillPublish:)] )
    [_delegate netServiceWillPublish: self];
}

-(void)_didPublish {
  if( [_delegate respondsToSelector:@selector(netServiceDidPublish:)])
    [_delegate netServiceDidPublish: self];
}

-(void)_didNotPublish: (NSDictionary *) errorDict {
  if( [_delegate respondsToSelector:@selector(netService:didNotPublish:)])
    [_delegate netService: self didNotPublish: errorDict];
}

-(void)_willResolve {
  if( [_delegate respondsToSelector:@selector(netServiceWillResolve:)])
   [_delegate netServiceWillResolve: self];
}

-(void)_didResolveAddress {
  if( [_delegate respondsToSelector:@selector(netServiceDidResolveAddress:)])
   [_delegate netServiceDidResolveAddress: self];
}

-(void)_didNotResolve: (NSDictionary *) errorDict {
  if( [_delegate respondsToSelector:@selector(netService:didNotResolve:)])
   [_delegate netService: self didNotResolve: errorDict];
}

-(void)_netServiceDidStop {
  if( [_delegate respondsToSelector:@selector(netServiceDidStop:)])
   [_delegate netServiceDidStop: self];  
}

-(void)_didUpdateTXTRecordData: (NSData *) data {
  if( [_delegate respondsToSelector:@selector(netService:didUpdateTXTRecordData:)])
   [_delegate   netService: self didUpdateTXTRecordData: data];
}


- (void) executeWithError: (bonjour_DNSServiceErrorType) err {  
   if( kDNSServiceErr_NoError != err ) {
    if(_isPublishing )
     [self _didNotPublish: CreateError(self, err)];
    else
     [self _didNotResolve: CreateError(self, err)];

    return;
   }

   NSSocket *socket=[[NSSocket alloc] initWithFileDescriptor:bonjour_DNSServiceRefSockFD(_netService)];
      
   _inputSource=[[NSSelectInputSource alloc] initWithSocket:socket];
   [socket release];
      
   [_inputSource setDelegate:self];
   [_inputSource setSelectEventMask:NSSelectReadEvent];
      
   [[NSRunLoop currentRunLoop] addInputSource:_inputSource forMode:NSDefaultRunLoopMode];

   if(_isPublishing )
    [self _willPublish];
   else
    [self _willResolve];      
}

- (void) _invalidate {  
   [_inputSource invalidate];
   [_inputSource release];
   _inputSource=nil;   
    
    if( _netService ){
      bonjour_DNSServiceRefDeallocate(_netService);
      _netService = NULL;
    }
    
    [_info removeAllObjects];
  
}

- (void) stopResolving: (NSTimer *) timer {  
   [_resolverTimeout invalidate];
   [_resolverTimeout release];
   _resolverTimeout=nil;
    
   [_inputSource invalidate];
    
   [self _didNotResolve: CreateError(self, NSNetServicesTimeoutError)];
}

- (void) resolverCallback: (bonjour_DNSServiceRef) sdRef
                    flags: (bonjour_DNSServiceFlags) flags
                interface: (uint32_t) interfaceIndex
                    error: (bonjour_DNSServiceErrorType) errorCode
                 fullname: (const char *) fullname
                   target: (const char *) hosttarget
                     port: (uint16_t) port
                   length: (uint16_t) txtLen
                   record: (const char *) txtRecord
{  
   if(_netService==NULL)
    return;

   if( kDNSServiceErr_NoError != errorCode ){
    [self _invalidate];
      
    [self _didNotResolve: CreateError(self, errorCode)];
    return;
   }

      // Add the port
   _port = ntohs(port);
      
      // Remove the old entries
   [_info removeObjectForKey: @"TXT"];
   [_info removeObjectForKey: @"Host"];

   if( txtRecord!=NULL ){
    NSData *txt = [[NSData alloc] initWithBytes: txtRecord length: txtLen];
    [_info setObject: txt forKey: @"TXT"];
    [txt release];
   }
      
   if( hosttarget!=NULL ) {
    NSString *target = [[NSString alloc] initWithUTF8String: hosttarget];
    [_info setObject: target forKey: @"Host"];
    [target release];
   }
      
      // Add the interface so all subsequent queries are on the same interface
   _interfaceIndex = interfaceIndex;
            
      // Prepare query for A and/or AAAA record
   errorCode = bonjour_DNSServiceQueryRecord((bonjour_DNSServiceRef *) &_netService,
                                        flags,
                                        interfaceIndex,
                                        hosttarget,
                                        kDNSServiceType_ANY,
                                        kDNSServiceClass_IN,
                                        QueryCallback,
                                        self);
      
      // No error? Then create a new timer
   if( kDNSServiceErr_NoError == errorCode ){
// FIXME: implement ?
   }
  
}

- (void) addAddress: (const void *) rdata
             length: (uint16_t) rdlen
               type: (uint16_t) rrtype
          interface: (uint32_t) interfaceIndex
{  
    NSMutableArray      *addresses = [_info objectForKey: @"Addresses"];
    const unsigned char *rd = rdata;
    NSData              *data = nil;
        
    if( nil == addresses ){
      addresses = [NSMutableArray array];
    }
    
    switch( rrtype ){
    
      case kDNSServiceType_A:		// AF_INET
        data=NSSocketAddressDataForNetworkOrderAddressBytesAndPort(rd,4,_port);
        break;
      
      case kDNSServiceType_AAAA:	// AF_INET6
      case kDNSServiceType_A6:		// deprecates AAAA
        data=NSSocketAddressDataForNetworkOrderAddressBytesAndPort(rd,16,_port);
        break;
      
      default:
        LOG(@"Unkown type of length <%d>", rdlen);
        break;
    }
    
    if( data!=nil ){
      [addresses addObject: data];
      [_info setObject: addresses forKey: @"Addresses"];
      
      [self _didResolveAddress];
      
      [_resolverTimeout invalidate];
      [_resolverTimeout release];
      _resolverTimeout = nil;
    }
}

- (void) queryCallback: (bonjour_DNSServiceRef) sdRef
                 flags: (bonjour_DNSServiceFlags) flags
             interface: (uint32_t) interfaceIndex
                 error: (bonjour_DNSServiceErrorType) errorCode
              fullname: (const char *) fullname
                  type: (uint16_t) rrtype
                 class: (uint16_t) rrclass
                length: (uint16_t) rdlen
                  data: (const void *) rdata
                   ttl: (uint32_t) ttl
{  
  
   if(_netService==NULL)
    return;
    
   if(errorCode!=kDNSServiceErr_NoError){
      [self _invalidate];
      
      [self _didNotResolve: CreateError(self, errorCode)];
            
      return;
    }
    
    switch( rrtype ){
    
      case kDNSServiceType_A:		// 1 -- AF_INET
        [self addAddress: rdata length: rdlen type: rrtype interface: interfaceIndex];
        break;
      
      case kDNSServiceType_NS:
      case kDNSServiceType_MD:
      case kDNSServiceType_MF:
      case kDNSServiceType_CNAME:	// 5
      case kDNSServiceType_SOA:
      case kDNSServiceType_MB:
      case kDNSServiceType_MG:
      case kDNSServiceType_MR:
      case kDNSServiceType_NULL:	// 10
      case kDNSServiceType_WKS:
      case kDNSServiceType_PTR:
      case kDNSServiceType_HINFO:
      case kDNSServiceType_MINFO:
      case kDNSServiceType_MX:		// 15
        // not handled (yet)
        break;
      
      case kDNSServiceType_TXT:
        {
          NSData *data = [NSData dataWithBytes: rdata length: rdlen];
          
          [_info setObject: data forKey: @"TXT"];
          
          [self _didUpdateTXTRecordData: data];
        
        }
        break;
      
      case kDNSServiceType_RP:
      case kDNSServiceType_AFSDB:
      case kDNSServiceType_X25:
      case kDNSServiceType_ISDN:	// 20
      case kDNSServiceType_RT:
      case kDNSServiceType_NSAP:
      case kDNSServiceType_NSAP_PTR:
      case kDNSServiceType_SIG:
      case kDNSServiceType_KEY:		// 25
      case kDNSServiceType_PX:
      case kDNSServiceType_GPOS:
        // not handled (yet)
        break;
      
      case kDNSServiceType_AAAA:	// 28 -- AF_INET6
        [self addAddress: rdata length: rdlen type: rrtype interface: interfaceIndex];
        break;
      
      case kDNSServiceType_LOC:
      case kDNSServiceType_NXT:		// 30
      case kDNSServiceType_EID:
      case kDNSServiceType_NIMLOC:
      case kDNSServiceType_SRV:
      case kDNSServiceType_ATMA:
      case kDNSServiceType_NAPTR:	// 35
      case kDNSServiceType_KX:
      case kDNSServiceType_CERT:
        // not handled (yet)
        break;
      
      case kDNSServiceType_A6:		// 38 -- AF_INET6, deprecates AAAA
        [self addAddress: rdata length: rdlen type: rrtype interface: interfaceIndex];
        break;
      
      case kDNSServiceType_DNAME:
      case kDNSServiceType_SINK:	// 40
      case kDNSServiceType_OPT:
        // not handled (yet)
        break;
      
      case kDNSServiceType_TKEY:	// 249
      case kDNSServiceType_TSIG:	// 250
      case kDNSServiceType_IXFR:
      case kDNSServiceType_AXFR:
      case kDNSServiceType_MAILB:
      case kDNSServiceType_MAILA:
        // not handled (yet)
        break;
      
      case kDNSServiceType_ANY:
        LOG(@"Oops, got the wildcard match...");
        break;
      
      default:
        LOG(@"Don't know how to handle rrtype <%d>", rrtype);
        break;
    }
  
}

- (void) registerCallback: (bonjour_DNSServiceRef) sdRef
                    flags: (bonjour_DNSServiceFlags) flags
                    error: (bonjour_DNSServiceErrorType) errorCode
                     name: (const char *) name
                     type: (const char *) regtype
                   domain: (const char *) domain
{  
   if( _netService==NULL)
    return;
    
   if(errorCode!=kDNSServiceErr_NoError){
    [self _invalidate];
      
    [self _didNotPublish: CreateError(self, errorCode)];
    return;
   }
    
   [self _didPublish];
}

-(void)selectInputSource:(NSSelectInputSource *)inputSource selectEvent:(unsigned)selectEvent {
	
   if(selectEvent&NSSelectReadEvent){
    
    bonjour_DNSServiceErrorType err= bonjour_DNSServiceProcessResult(_netService);
    
    if( kDNSServiceErr_NoError != err ){		
		if(  _isPublishing )
			[self _didNotPublish: CreateError(self, err)];
		else
			[self _didNotResolve: CreateError(self, err)];
	}
   }
}

+ (NSData *) dataFromTXTRecordDictionary: (NSDictionary *) txtDictionary {
   NSUInteger i,count = [txtDictionary count];
  
   if( count==0){
    LOG(@"Dictionary seems empty");
    return nil;
   }
   
   NSArray *keys = [txtDictionary allKeys];

   bonjour_TXTRecordRef txt;
   char keyCString[256];
      
   bonjour_bonjour_TXTRecordCreate(&txt, 0, NULL);
      
   for(i=0 ; i < count; i++ ){
    id key=[keys objectAtIndex:i];
    id value=[txtDictionary objectForKey:key];
    int length = 0, used = 0;
    bonjour_DNSServiceErrorType err = kDNSServiceErr_Unknown;
        
    if( ! [key isKindOfClass: [NSString class]] ){
     LOG(@"%@ is not a string", key);
     break;
    }
        
    length = [key length];
    [key getCString: keyCString maxLength: sizeof keyCString];
    used = strlen(keyCString);
        
    if( ! length || (used >= sizeof keyCString) ){
     LOG(@"incorrect length %d - %d - %d", length, used, sizeof keyCString);
     break;
    }
        
    strcat(keyCString, "\0");
        
    if( [value isKindOfClass: [NSString class]] ){
      char cString[256];
          
          length = [value length];
          [value getCString: cString maxLength: sizeof cString];
          used = strlen(cString);
          
          if( used >= sizeof cString ){
            LOG(@"incorrect length %d - %d - %d", length, used, sizeof cString);
            break;
          }
          
          err = bonjour_TXTRecordSetValue(&txt,(const char *) keyCString,used,cString);
        }
        else if( [value isKindOfClass: [NSData class]] && [value length] < 256){
          err = bonjour_TXTRecordSetValue(&txt,(const char *) keyCString,[value length],[value bytes]);
          
        }
        else if( value == [NSNull null] ){
          err = bonjour_TXTRecordSetValue(&txt,(const char *) keyCString,0,NULL);
        }
        else {
          LOG(@"unknown value type");
          break;
        }
        
        if( err != kDNSServiceErr_NoError )
        {
          LOG(@"error creating data type");
          break;
        }
      }
      
   NSData *result=(i<count)?nil:[NSData dataWithBytes: bonjour_TXTRecordGetBytesPtr(&txt) length: bonjour_TXTRecordGetLength(&txt)];
      
   bonjour_TXTRecordDeallocate(&txt);
      
   return result;
}

+ (NSDictionary *) dictionaryFromTXTRecordData: (NSData *) txtData
{
  NSMutableDictionary
    *result = nil;
  int
    len = 0;
  const void
    *txt = 0;
  
  
  len = [txtData length];
  txt = [txtData bytes];
  
  //
  // A TXT record cannot exceed 65535 bytes, see Chapter 6.1 of
  // http://files.dns-sd.org/draft-cheshire-dnsext-dns-sd.txt
  //
  if( (len > 0) && (len < 65536) )
  {
    uint16_t
      i = 0,
      count = 0;
    
    // get number of keys
    count = bonjour_TXTRecordGetCount(len, txt);
    result = [NSMutableDictionary dictionaryWithCapacity: 1];
    
    if( result )
    {
      // go through all keys
      for( ; i < count; i++ )
      {
        char
          keyCString[256];
        uint8_t
          valLen = 0;
        const void
          *value = NULL;
        bonjour_DNSServiceErrorType
          err = kDNSServiceErr_NoError;
        
        err = bonjour_TXTRecordGetItemAtIndex(len, txt, i,
                                      sizeof keyCString, keyCString,
                                      &valLen, &value);
        
        // only if we can get the keyCString and value...
        if( kDNSServiceErr_NoError == err )
        {
          NSString *str = [NSString stringWithUTF8String: keyCString];
          NSData
            *data = nil;
                    
          if( value ){
           data = [NSData dataWithBytes: value length: valLen];
          }
          // only add if keyCString and value were created and keyCString doesn't exist yet
          if( data && str && [str length] && ! [result objectForKey: str] )
          {
            [result setObject: data
					   forKey: str];
          }
          // I'm not exactly sure what to do if there is a keyCString WITHOUT a value
          // Theoretically '<6>foobar' should be identical to '<7>foobar='
          // i.e. the value would be [NSNull null]
          else
          {
            [result setObject: [NSNull null] forKey: str];
          }
        }
        else
        {
          LOG(@"Couldn't get TXTRecord item");
        }
      }
    }
    else
    {
      LOG(@"Couldn't create dictionary");
    }
  }
  else
  {
    LOG(@"Incorrect length %d", len);
  }
  
}

- (id) init
{
  
  return nil;
}


-initWithDomain: (NSString *) domain type: (NSString *) type name: (NSString *) name {
   return [self initWithDomain: domain type: type name: name port: -1]; // -1 to indicate resolution, not publish
}

/** <init />
 * Initializes the receiver for service publication. Use this method to create
 * an object if you intend to -publish a service.
 *
 */

- (id) initWithDomain: (NSString *) domain
                 type: (NSString *) type
                 name: (NSString *) name
                 port: (int) port
{
   [super init];
   _resolverTimeout = nil;
    
    _info = [[NSMutableDictionary alloc] init];
    [_info setObject: domain forKey: @"Domain"];
    [_info setObject: name forKey: @"Name"];
    [_info setObject: type forKey: @"Type"];
    
    _interfaceIndex = 0;
    _port = port;
    
    _isPublishing = ( -1 == port ) ? NO : YES;
        
    _netService = NULL;
    _delegate = nil;
    
    return self;
}

- (void) dealloc {
   [self stopMonitoring];
   [self _invalidate];
      
   [_info release];
   _info = nil;
      
   _delegate = nil;
  [super dealloc];
}


- (void) scheduleInRunLoop: (NSRunLoop *) runLoop forMode: (NSString *) mode {  
   [runLoop addInputSource:_inputSource forMode:mode];
}

- (void) removeFromRunLoop: (NSRunLoop *) runLoop forMode: (NSString *) mode {  
   [runLoop removeInputSource:_inputSource forMode:mode];
  
}

-(void)publishWithOptions:(NSNetServiceOptions)options {
   bonjour_DNSServiceErrorType err = kDNSServiceErr_NoError;
   bonjour_DNSServiceFlags flags = 0;
  
   // cannot -publish on a service that's init'd for resolving
   if( NO == _isPublishing )
    err = NSNetServicesBadArgumentError;
   else if( ! _delegate )
    err = NSNetServicesInvalidError;
      
   else if( _inputSource!=nil )
    err = NSNetServicesActivityInProgress;
   else {      
    if( _resolverTimeout ) {
     [_resolverTimeout invalidate];
     [_resolverTimeout release];
     _resolverTimeout = nil;
    }
      
    err = bonjour_DNSServiceRegister((bonjour_DNSServiceRef *) &_netService,
                               flags, _interfaceIndex,
                               [[_info objectForKey: @"Name"] UTF8String],
                               [[_info objectForKey: @"Type"] UTF8String],
                               [[_info objectForKey: @"Domain"] UTF8String],
                               NULL, htons(_port), 0, NULL,
                               RegistrationCallback, self);
   }
  
   [self executeWithError: err];
}

-(void)publish {
   [self publishWithOptions:0];
}

-(void)resolve {
   [self resolveWithTimeout: 5];
}

- (void) resolveWithTimeout: (NSTimeInterval) timeout {
   bonjour_DNSServiceErrorType err = kDNSServiceErr_NoError;
   bonjour_DNSServiceFlags flags = 0;

      // cannot -resolve on a service that's init'd for publishing
   if(_isPublishing )
    err = NSNetServicesBadArgumentError;
      
   else if( ! _delegate )
    err = NSNetServicesInvalidError;
   else if( _inputSource )
    err = NSNetServicesActivityInProgress;
   else  {
    if( _resolverTimeout ){
        [_resolverTimeout invalidate];
        [_resolverTimeout release];
        _resolverTimeout = nil;
      }

      err = bonjour_DNSServiceResolve((bonjour_DNSServiceRef *) &_netService,
                              flags, _interfaceIndex,
                              [[_info objectForKey: @"Name"] UTF8String],
                              [[_info objectForKey: @"Type"] UTF8String],
                              [[_info objectForKey: @"Domain"] UTF8String],
                              ResolverCallback, self);
                              
      if(err==kDNSServiceErr_NoError){        
        _resolverTimeout=[[NSTimer scheduledTimerWithTimeInterval: timeout
                                    target: self
                                  selector: @selector(stopResolving:)
                                  userInfo: nil
                                   repeats: NO] retain];
      }
   }
   
   [self executeWithError: err];
}

-(void)stop {  
   [self _invalidate];
    
   [self _netServiceDidStop];
}

-(void)startMonitoring {  
    // Obviously this will only work on a resolver
   if(_isPublishing )
    return;
   if(_isMonitoring)
    return;
    
   bonjour_DNSServiceErrorType err = kDNSServiceErr_NoError;
    
   if( ! _delegate )
    err = NSNetServicesInvalidError;
   else if( _inputSource!=nil )
    err = NSNetServicesActivityInProgress;
   else {
    NSString *fullname = [NSString stringWithFormat: @"%@.%@%@", [self name], [self type], [self domain]];
      
    err = bonjour_DNSServiceQueryRecord((bonjour_DNSServiceRef *) &_netService,
                                  kDNSServiceFlagsLongLivedQuery,
                                  0,
                                  [fullname UTF8String],
                                  kDNSServiceType_TXT,
                                  kDNSServiceClass_IN,
                                  QueryCallback,
                                  self);
      
    if( kDNSServiceErr_NoError == err ){
     NSSocket *socket=[[NSSocket alloc] initWithFileDescriptor:bonjour_DNSServiceRefSockFD(_netService)];
      
     _inputSource=[[NSSelectInputSource alloc] initWithSocket:socket];
     [socket release];
     [_inputSource setDelegate:self];
     [_inputSource setSelectEventMask:NSSelectReadEvent];
      
     [[NSRunLoop currentRunLoop] addInputSource:_inputSource forMode:NSDefaultRunLoopMode];
      _isMonitoring = YES;
     }
        
    }
}

-(void)stopMonitoring {
   if(_isPublishing)
    return;
   if(!_isMonitoring)
    return;
    
   [_inputSource invalidate];
   [_inputSource release];
   _inputSource=nil;
 
   if( _netService ){
    bonjour_DNSServiceRefDeallocate(_netService);
    _netService = NULL;
   }
        
   _isMonitoring = NO;
}

-delegate {  
  return _delegate;
}

-(void)setDelegate: (id) delegate {
    _delegate = delegate;
}

-(NSArray *)addresses {
  return [_info objectForKey: @"Addresses"];
}

-(NSString *)domain {
  return [_info objectForKey: @"Domain"];
}

-(NSString *)hostName {
  return [_info objectForKey: @"Host"];
}

-(NSString *)name {
   return [_info objectForKey: @"Name"];
}

-(NSString *)type {
    return [_info objectForKey: @"Type"];
}

- (NSString *) protocolSpecificInformation {
   NSMutableArray *array = nil;
  
  // I must admit, the following may not be entirely correct...

   NSDictionary *dictionary = [NSNetService dictionaryFromTXTRecordData:[self TXTRecordData]];
    
   if( dictionary ){
    NSEnumerator *keys = [dictionary keyEnumerator];
    id key = nil;
      
    array = [NSMutableArray arrayWithCapacity: [dictionary count]];
      
    while( (key = [keys nextObject])!=nil ) {
     id value = [dictionary objectForKey: key];
        
     if( value !=  [NSNull null] ){
      [array addObject: [NSString stringWithFormat: @"%@=%@", key,
                              [NSString stringWithCString: [value bytes] 
                                                   length: [value length]]]];
     }
     else if( [key length] ) {
      [array addObject: [NSString stringWithFormat: @"%@", key]];
     }
    }
   }
  
   return ( [array count] ? [array componentsJoinedByString: @"\001"] :  (NSString *)nil );
}

- (void) setProtocolSpecificInformation: (NSString *) specificInformation {  
  // Again, the following may not be entirely correct...

   NSArray   *array  = [specificInformation componentsSeparatedByString: @"\001"];
   NSUInteger i,count=[array count];
   
   if(count>0){
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity: count];
   
    for(i=0;i<count;i++){
     NSArray *parts = [[array objectAtIndex:i] componentsSeparatedByString:@"="];
        
     [dictionary setObject: [[parts objectAtIndex: 1] dataUsingEncoding: NSUTF8StringEncoding] forKey: [parts objectAtIndex: 0]];
    }
   
    [self setTXTRecordData:[NSNetService dataFromTXTRecordDictionary: dictionary]];
   }
}

- (NSData *) TXTRecordData {  
  return [_info objectForKey: @"TXT"];
}

- (BOOL) setTXTRecordData: (NSData *) recordData
{
  BOOL
    result = NO;
  
    // Not allowed on a resolver...
    if( _isPublishing )
    {
      bonjour_DNSServiceErrorType
        err = kDNSServiceErr_NoError;
      
      // Set the value, or remove it if empty
      if( recordData )
      {
        [_info setObject: recordData forKey: @"TXT"];
      }
      else
      {
        [_info removeObjectForKey: @"TXT"];
      }
      
      // Assume it worked
      result = YES;
      
      // Now update the record so others can pick it up
      err = bonjour_DNSServiceUpdateRecord(_netService,
                                   NULL,
                                   0,
                                   recordData ? [recordData length] : 0,
                                   recordData ? [recordData bytes] : NULL,
                                   0);
      if( err )
      {
        result = NO;
      }
    }
    
   return result;
}

- (BOOL) getInputStream: (NSInputStream **) inputStream outputStream: (NSOutputStream **) outputStream {  

   [NSStream getStreamsToHost: [_info objectForKey: @"Host"] port:_port inputStream: inputStream outputStream: outputStream];
    
   return ((*inputStream!=nil) && (*outputStream!=nil))?YES:NO;
}

@end


@interface NSNetServiceBrowser(forward)
-(void)enumCallback: (bonjour_DNSServiceRef) sdRef flags: (bonjour_DNSServiceFlags) flags interface: (uint32_t) interfaceIndex error: (bonjour_DNSServiceErrorType) errorCode domain: (const char *) replyDomain;

-(void)browseCallback: (bonjour_DNSServiceRef) sdRef flags: (bonjour_DNSServiceFlags) flags interface: (uint32_t) interfaceIndex error: (bonjour_DNSServiceErrorType) errorCode name: (const char *) replyName type: (const char *) replyType domain: (const char *) replyDomain;
@end

static void EnumerationCallback(bonjour_DNSServiceRef sdRef,bonjour_DNSServiceFlags flags,uint32_t interfaceIndex,bonjour_DNSServiceErrorType  errorCode,const char *replyDomain,void *context) {
  [(id) context enumCallback: sdRef flags: flags interface: interfaceIndex error: errorCode domain: replyDomain];
}

static void BrowserCallback(bonjour_DNSServiceRef sdRef,bonjour_DNSServiceFlags flags,uint32_t interfaceIndex,bonjour_DNSServiceErrorType errorCode,const char *replyName,const char *replyType,const char *replyDomain,void *context){
  [(id) context browseCallback: sdRef flags: flags interface: interfaceIndex error: errorCode name: replyName type: replyType domain: replyDomain];
}

@implementation NSNetServiceBrowser

-init {
   [super init];
  
   _netServiceBrowser = NULL;
   _delegate = nil;
   _services = [[NSMutableDictionary alloc] init];
   _interfaceIndex = 0;
    
    return self;
}

- (void) invalidate {
   [_inputSource invalidate];
   [_inputSource release];
   _inputSource=nil;
        
   if( _netServiceBrowser ){
    bonjour_DNSServiceRefDeallocate(_netServiceBrowser);
    _netServiceBrowser = NULL;
   }
    
   [_services removeAllObjects];
}

- (void) dealloc {
   [self invalidate];
      
   [_services release];
   _services = nil;
      
   _delegate = nil;
   [super dealloc];
}

-  delegate {
  return _delegate;
}


- (void) setDelegate:delegate {
    _delegate = delegate;
}

-(void)_willSearch {
   if( [_delegate respondsToSelector:@selector(netServiceBrowserWillSearch:)])
    [_delegate netServiceBrowserWillSearch: self];
}

-(void)_didNotSearch: (NSDictionary *) errorDict {
  if( [_delegate respondsToSelector:@selector(netServiceBrowser:didNotSearch:)])
    [_delegate netServiceBrowser: self didNotSearch: errorDict];
}

- (void)_didStopSearch {
  if( [_delegate respondsToSelector:@selector(netServiceBrowserDidStopSearch:)])
    [_delegate netServiceBrowserDidStopSearch: self];  
}

- (void)_didFindDomain: (NSString *) domainString moreComing: (BOOL) moreComing {
  
  if( [_delegate respondsToSelector:@selector(netServiceBrowser:didFindDomain:moreComing:)])
    [_delegate netServiceBrowser: self didFindDomain: domainString moreComing: moreComing];
}

- (void)_didRemoveDomain: (NSString *) domainString moreComing: (BOOL) moreComing {
  
  if( [_delegate respondsToSelector:@selector(netServiceBrowser:didRemoveDomain:moreComing:) ])
    [_delegate netServiceBrowser: self didRemoveDomain: domainString moreComing: moreComing];
  
}

- (void)_didFindService: (NSNetService *) aService moreComing: (BOOL) moreComing {
  if( [_delegate respondsToSelector:@selector(netServiceBrowser:didFindService:moreComing:)])
    [_delegate netServiceBrowser: self didFindService: aService moreComing: moreComing];
  
}

- (void)_didRemoveService: (NSNetService *) aService
                moreComing: (BOOL) moreComing {
  if( [_delegate respondsToSelector:@selector(netServiceBrowser:didRemoveService:moreComing:)])
    [_delegate netServiceBrowser: self didRemoveService: aService moreComing: moreComing];
}

- (void) executeWithError: (bonjour_DNSServiceErrorType) err
{  
    if( kDNSServiceErr_NoError == err )
    {
     [self _willSearch];
           
      NSSocket *socket=[[NSSocket alloc] initWithFileDescriptor:bonjour_DNSServiceRefSockFD(_netServiceBrowser)];
      
      _inputSource=[[NSSelectInputSource alloc] initWithSocket:socket];
      [socket release];
      
      [_inputSource setDelegate:self];
      [_inputSource setSelectEventMask:NSSelectReadEvent];
            
      [[NSRunLoop currentRunLoop] addInputSource:_inputSource forMode:NSDefaultRunLoopMode];
    }
    else // notify the delegate of the error
    {
      [self _didNotSearch: CreateError(self, err)];
    }
}

- (void) searchForDomain: (int) aFlag {
   bonjour_DNSServiceErrorType err;
  
   if( ! _delegate )
    err = NSNetServicesInvalidError;
   else if( _inputSource )
    err = NSNetServicesActivityInProgress;
   else {
    err = bonjour_DNSServiceEnumerateDomains((bonjour_DNSServiceRef *)&_netServiceBrowser,
                                       aFlag,
                                       _interfaceIndex,
                                       EnumerationCallback,
                                       self);
   }
  
   [self executeWithError: err];
}

- (void) enumCallback: (bonjour_DNSServiceRef) sdRef
                flags: (bonjour_DNSServiceFlags) flags
            interface: (uint32_t) interfaceIndex
                error: (bonjour_DNSServiceErrorType) errorCode
               domain: (const char *) replyDomain {  
   if( _netServiceBrowser==NULL)
    return;

   if( errorCode ){
    [self invalidate];
      
    [self _didNotSearch: CreateError(self, errorCode)];
    return;
   }
      
   if(replyDomain==NULL)
    return;

   BOOL more = (flags & kDNSServiceFlagsMoreComing)?YES:NO;
        
   _interfaceIndex = interfaceIndex;
        
   if( flags & kDNSServiceFlagsAdd ){
    LOG(@"Found domain <%s>", replyDomain);
          
    [self _didFindDomain: [NSString stringWithUTF8String: replyDomain] moreComing: more];
   }
   else { // kDNSServiceFlagsRemove
    LOG(@"Removed domain <%s>", replyDomain);
          
    [self _didRemoveDomain: [NSString stringWithUTF8String: replyDomain] moreComing: more];
   }
}

- (void) browseCallback: (bonjour_DNSServiceRef) sdRef
                  flags: (bonjour_DNSServiceFlags) flags
              interface: (uint32_t) interfaceIndex
                  error: (bonjour_DNSServiceErrorType) errorCode
                   name: (const char *) replyName
                   type: (const char *) replyType
                 domain: (const char *) replyDomain
{
    
   if( _netServiceBrowser==NULL)
    return;
   
   if(errorCode!=kDNSServiceErr_NoError){
    [self invalidate];
            
    [self _didNotSearch: CreateError(self, errorCode)];
    return;
   }

   BOOL          more = (flags & kDNSServiceFlagsMoreComing)?YES:NO;
   NSString     *domain=[NSString stringWithUTF8String: replyDomain];
   NSString     *type=[NSString stringWithUTF8String: replyType];
   NSString     *name=[NSString stringWithUTF8String: replyName];
   NSString     *key=[NSString stringWithFormat: @"%@%@%@", name, type, domain];
   NSNetService *service = nil;
      
   _interfaceIndex = interfaceIndex;
      
   if( flags & kDNSServiceFlagsAdd ){
    service = [[NSNetService alloc] initWithDomain: domain type: type name: name];
        
    if( service ){
     LOG(@"Found service <%s>", replyName);
          
     [_services setObject: service forKey: key];
          
     [service autorelease];

     [self _didFindService: service moreComing: more];
    }
    else {
     LOG(@"WARNING: Could not create an NSNetService for <%s>", replyName);
    }
   }
   else { // kDNSServiceFlagsRemove
    service = [_services objectForKey: key];
        
    if( service ){
     LOG(@"Removed service <%@>", [service name]);
          
     [self _didRemoveService: service moreComing: more];
    }
    else {
     LOG(@"WARNING: Could not find <%@> in list", key);
    }
   }  
}

-(void)selectInputSource:(NSSelectInputSource *)inputSource selectEvent:(unsigned)selectEvent {
	
   if(selectEvent&NSSelectReadEvent){
    bonjour_DNSServiceErrorType err = bonjour_DNSServiceProcessResult(_netServiceBrowser);
	
    if( kDNSServiceErr_NoError != err ){
     [self _didNotSearch: CreateError(self, err)];
    }
   }
}

- (void) scheduleInRunLoop: (NSRunLoop *) runLoop forMode: (NSString *) mode {  
   [runLoop addInputSource:_inputSource forMode:mode];
}

- (void) removeFromRunLoop: (NSRunLoop *) runLoop forMode: (NSString *) mode {  
   [runLoop removeInputSource:_inputSource forMode:mode];
}

// Search for all visible domains. This method is deprecated.

- (void) searchForAllDomains {
  [self searchForDomain: kDNSServiceFlagsBrowseDomains|kDNSServiceFlagsRegistrationDomains];
}

- (void) searchForBrowsableDomains {
  [self searchForDomain: kDNSServiceFlagsBrowseDomains];
}

// Search for all registration domains. These domains can be used to register a service.

- (void) searchForRegistrationDomains {
  [self searchForDomain: kDNSServiceFlagsRegistrationDomains];
}

- (void) searchForServicesOfType: (NSString *) serviceType inDomain: (NSString *) domainName {
   bonjour_DNSServiceErrorType err = kDNSServiceErr_NoError;
  
   if( ! _delegate )
    err = NSNetServicesInvalidError;
   else if( _inputSource )
    err = NSNetServicesActivityInProgress;
   else {
    err = bonjour_DNSServiceBrowse((bonjour_DNSServiceRef *) &_netServiceBrowser,
                             0,
                             _interfaceIndex,
                             [serviceType UTF8String],
                             [domainName UTF8String],
                             BrowserCallback,
                             self);
   }
  
   [self executeWithError: err];
}

-(void) stop {  
   [self invalidate];
    
   [self _didStopSearch];  
}

@end


