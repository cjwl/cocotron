/* FILE: CTNetServices.h
 *
 * Creation Mon Sep 11 14:46:24 CEST 2006 by Chris B. Vetter
 *
 * Copyright (c) 2006 Chris B. Vetter
 * Bugfixing 2007 by D. Theisen
 *
 */

/*
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */


//
// Include
//

#import "NSNetServices.h"

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
#include <libc.h>

#import <dns_sd.h>		// Apple's DNS Service Discovery

#import <sys/types.h>
#import <sys/socket.h>		// AF_INET / AF_INET6

#import <netinet/in.h>		// struct sockaddr_in / sockaddr_in6
#import <arpa/inet.h>		// inet_pton(3)

#if defined( _REENTRANT )
#  import <pthread.h>		// pthread_spin_lock(3)
#endif

//
// Define
//

#define PUBLIC			/* public */
#define PRIVATE			static
#define EXTERN			extern

// trigger runloop timer every INTERVAL seconds
#define INTERVAL		0.3
#define SHORTTIMEOUT		0.25

// debugging stuff and laziness on my part
#if defined( VERBOSE )
#  define InternalTrace		NSDebugLLog(@"Trace", @"%s", __PRETTY_FUNCTION__)
#  define LOG( f, args... )	NSDebugLLog(@"CTNetServices", f, ##args )
#else
#  define InternalTrace
#  define LOG( f, args... )
#endif /* DEBUG */

#define RespondsTo( sel )	[_delegate respondsToSelector: @selector(sel)]

//#define SetVersion( aClass )						\
//        do {								\
//          if( self == [aClass class] ) { [self setVersion: VERSION]; }	\
//          else { [self doesNotRecognizeSelector: _cmd]; }		\
//        } while( 0 );

#define INITIALIZE							\
        do {								\
          static BOOL isInitialized = NO;				\
          [super initialize];						\
          if( isInitialized ) { return; }				\
          isInitialized = YES;						\
        } while( 0 );

#if defined( _REENTRANT )
#  define THE_LOCK		pthread_spinlock_t lock
#  define CreateLock( x )	pthread_spin_init( &(x->lock), PTHREAD_PROCESS_PRIVATE)
#  define Lock( x )		pthread_spin_lock( &(x->lock) )
#  define Unlock( x )		pthread_spin_unlock( &(x->lock) )
#  define DestroyLock( x )	pthread_spin_destroy( &(x->lock) )
#else
#  define THE_LOCK		/* nothing */
#  define CreateLock( x )	/* nothing */
#  define Lock( x )		/* nothing */
#  define Unlock( x )		/* nothing */
#  define DestroyLock( x )	/* nothing */
#endif

//
// Typedef
//

typedef struct _Browser		// The actual CTNetServiceBrowser
{
  THE_LOCK;
  
  NSRunLoop		*runloop;
  NSString		*runloopmode;
  NSTimer		*timer;			// to control the runloop
  
  NSMutableDictionary	*services;
    // List of found services.
    // Key is <_name_type_domain> and value is an initialized CTNetService.
  
  int			 interfaceIndex;
} Browser;

typedef struct _Service		// The actual CTNetService
{
  THE_LOCK;
  
  NSRunLoop		*runloop;
  NSString		*runloopmode;
  NSTimer		*timer,			// to control the runloop
                        *timeout;		// to time-out the resolve
  
  NSMutableDictionary	*info;
    // The service's information, keys are
    // - Domain (string)
    // - Name (string)
    // - Type (string)
    // - Host (string)
    // - Addresses (mutable array)
    // - TXT (data)
  
  int			 interfaceIndex,	// should also be in 'info'
                         port;			// ditto
  
  id			 monitor;		// CTNetServiceMonitor
  
  BOOL			 isPublishing,		// true if publishing service
                         isMonitoring;		// true if monitoring
} Service;

typedef struct _Monitor		// The service monitor
{
  THE_LOCK;
  
  NSRunLoop		*runloop;
  NSString		*runloopmode;
  NSTimer		*timer;			// to control the runloop
} Monitor;

//
// Public
//

/**
 * This key identifies the most recent error.
 */
NSString * const CTNetServicesErrorCode = @"CTNetServicesErrorCode";

/**
 * This key identifies the originator of the error.
 */
NSString * const CTNetServicesErrorDomain = @"CTNetServicesErrorDomain";

//
// Private
//

//
// Private Interface
//

@interface CTNetServiceMonitor : NSObject
{
  @private
  void		* _netServiceMonitor;
  id		  _delegate;
  void		* _reserved;
}

- (id) initWithDelegate: (id) delegate;

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode;
- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode;

- (void) start;
- (void) stop;

@end

//
// Prototype
//

PRIVATE NSDictionary
  *CreateError(id sender,
               int errorCode);

PRIVATE int
  ConvertError(int errorCode);

PRIVATE void	// CTNetServiceBrowser
  EnumerationCallback(DNSServiceRef sdRef,
                      DNSServiceFlags flags,
                      uint32_t interfaceIndex,
                      DNSServiceErrorType  errorCode,
                      const char *replyDomain,
                      void *context),
  BrowserCallback(DNSServiceRef sdRef,
                  DNSServiceFlags flags,
                  uint32_t interfaceIndex,
                  DNSServiceErrorType errorCode,
                  const char *replyName,
                  const char *replyType,
                  const char *replyDomain,
                  void *context);

PRIVATE void	// CTNetService
  ResolverCallback(DNSServiceRef sdRef,
                   DNSServiceFlags flags,
                   uint32_t interfaceIndex,
                   DNSServiceErrorType errorCode,
                   const char *fullname,
                   const char *hosttarget,
                   uint16_t port,
                   uint16_t txtLen,
                   const char *txtRecord,
                   void *context),
  RegistrationCallback(DNSServiceRef sdRef,
                       DNSServiceFlags flags,
                       DNSServiceErrorType errorCode,
                       const char *name,
                       const char *regtype,
                       const char *domain,
                       void *context);


PRIVATE void	// CTNetService, CTNetServiceMonitor
  QueryCallback(DNSServiceRef sdRef,
                DNSServiceFlags flags,
                uint32_t interfaceIndex,
                DNSServiceErrorType errorCode,
                const char *fullname,
                uint16_t rrtype,
                uint16_t rrclass,
                uint16_t rdlen,
                const void *rdata,
                uint32_t ttl,
                void *context);

/***************************************************************************
**
** Implementation
**
*/

@implementation CTNetServiceBrowser

/**
 * <em>Description forthcoming</em>
 *
 *
 */

+ (void) initialize
{
  InternalTrace;
  
//  SetVersion( CTNetServiceBrowser );
//  {
//#ifndef _REENTRANT
//    LOG(@"%@ may NOT be thread-safe!", [self class]);
//#endif
//    
//    INITIALIZE
//  }
  
  return;
}

/***************************************************************************
**
** Private Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) cleanup
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    if( browser->runloop )
    {
      [self removeFromRunLoop: browser->runloop
                      forMode: browser->runloopmode];
    }
    
    if( browser->timer )
    {
      [browser->timer invalidate];
      [browser->timer release];
      browser->timer = nil;
    }
    
    if( _netServiceBrowser )
    {
      DNSServiceRefDeallocate(_netServiceBrowser);
      _netServiceBrowser = NULL;
    }
    
    [browser->services removeAllObjects];
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) executeWithError: (DNSServiceErrorType) err
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    if( kDNSServiceErr_NoError == err )
    {
      [self netServiceBrowserWillSearch: self];
      
      if( ! browser->runloop )
      {
        [self scheduleInRunLoop: [NSRunLoop currentRunLoop]
                        forMode: NSDefaultRunLoopMode];
      }
      
      [browser->runloop addTimer: browser->timer
                         forMode: browser->runloopmode];
      
      [browser->timer fire];
    }
    else // notify the delegate of the error
    {
      [self netServiceBrowser: self
                 didNotSearch: CreateError(self, err)];
    }
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) searchForDomain: (int) aFlag
{
  DNSServiceErrorType
    err = kDNSServiceErr_NoError;
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    do
    {
      if( ! _delegate )
      {
        err = CTNetServicesInvalidError;
        break;
      }
      
      if( browser->timer )
      {
        err = CTNetServicesActivityInProgress;
        break;
      }
      
      err = DNSServiceEnumerateDomains((DNSServiceRef *)&_netServiceBrowser,
                                       aFlag,
                                       browser->interfaceIndex,
                                       EnumerationCallback,
                                       self);
    } while( 0 );
  }
  Unlock(browser);
  
  [self executeWithError: err];
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) enumCallback: (DNSServiceRef) sdRef
                flags: (DNSServiceFlags) flags
            interface: (uint32_t) interfaceIndex
                error: (DNSServiceErrorType) errorCode
               domain: (const char *) replyDomain
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  
  if( _netServiceBrowser )
  {
    if( errorCode )
    {
      [self cleanup];
      
      [self netServiceBrowser: self
                 didNotSearch: CreateError(self, errorCode)];
    }
    else
    {  
      BOOL
        more = NO;
      
      if( replyDomain )
      {
        more = flags & kDNSServiceFlagsMoreComing;
        
        browser->interfaceIndex = interfaceIndex;
        
        if( flags & kDNSServiceFlagsAdd )
        {
          LOG(@"Found domain <%s>", replyDomain);
          
          [self netServiceBrowser: self
                    didFindDomain: [NSString stringWithUTF8String: replyDomain]
                       moreComing: more];
        }
        else // kDNSServiceFlagsRemove
        {
          LOG(@"Removed domain <%s>", replyDomain);
          
          [self netServiceBrowser: self
                  didRemoveDomain: [NSString stringWithUTF8String: replyDomain]
                       moreComing: more];
        }
      }
    }
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) browseCallback: (DNSServiceRef) sdRef
                  flags: (DNSServiceFlags) flags
              interface: (uint32_t) interfaceIndex
                  error: (DNSServiceErrorType) errorCode
                   name: (const char *) replyName
                   type: (const char *) replyType
                 domain: (const char *) replyDomain
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  
  if( _netServiceBrowser )
  {
    if( errorCode )
    {
      [self cleanup];
            
      [self netServiceBrowser: self
                 didNotSearch: CreateError(self, errorCode)];
    }
    else
    {
      CTNetService
        *service = nil;
      NSString
        *domain = nil,
        *type = nil,
        *name = nil,
        *key = nil;
      BOOL
        more = flags & kDNSServiceFlagsMoreComing;
      
      browser->interfaceIndex = interfaceIndex;
      
      if( nil == browser->services )
      {
        browser->services = [[NSMutableDictionary alloc] initWithCapacity: 1];
      }
    
      domain = [NSString stringWithUTF8String: replyDomain];
      type = [NSString stringWithUTF8String: replyType];
      name = [NSString stringWithUTF8String: replyName];
      
      key = [NSString stringWithFormat: @"%@%@%@", name, type, domain];
      
      if( flags & kDNSServiceFlagsAdd )
      {
        service = [[CTNetService alloc] initWithDomain: domain
                                                  type: type
                                                  name: name];
        
        if( service )
        {
          LOG(@"Found service <%s>", replyName);
          
          [self netServiceBrowser: self
                   didFindService: service
                       moreComing: more];
          
          [browser->services setObject: service
                                forKey: key];
          
          [service autorelease];
        }
        else
        {
          LOG(@"WARNING: Could not create an CTNetService for <%s>", replyName);
        }
      }
      else // kDNSServiceFlagsRemove
      {
        service = [browser->services objectForKey: key];
        
        if( service )
        {
          LOG(@"Removed service <%@>", [service name]);
          
          [self netServiceBrowser: self
                 didRemoveService: service
                       moreComing: more];
        }
        else
        {
          LOG(@"WARNING: Could not find <%@> in list", key);
        }
      }
    }
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) loop: (id) sender
{
	int
    sock = 0;
	struct timeval
		tout = { 0 };
	fd_set
		set;
	DNSServiceErrorType
		err = kDNSServiceErr_NoError;
	
	sock = DNSServiceRefSockFD(_netServiceBrowser);
	
	if( -1 != sock )
	{
		FD_ZERO(&set);
		FD_SET(sock, &set);
		
		if( 1 == select(sock + 1, &set, (fd_set *) NULL, (fd_set *) NULL, &tout) )
		{
			err = DNSServiceProcessResult(_netServiceBrowser);
		}
	}
	
	if( kDNSServiceErr_NoError != err )
	{
		[self netServiceBrowser: self
				   didNotSearch: CreateError(self, err)];
	}
	
	return;
}

/***************************************************************************
**
** Factory Methods
**
*/

/***************************************************************************
**
** Instance Methods
**
*/

/**
 * Removes the receiver from the specified runloop.
 *
 *
 */

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    if( browser->timer )
    {
      [browser->timer setFireDate: [NSDate date]];
      [browser->timer invalidate];
      browser->timer = nil;
    }
    
    // Do not release the runloop!
    browser->runloop = nil;
    
    [browser->runloopmode release];
    browser->runloopmode = nil;
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/**
 * Adds the receiver to the specified runloop.
 *
 *
 */

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode
{
  Browser* browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    if( browser->timer )
    {
      [browser->timer setFireDate: [NSDate date]];
      [browser->timer invalidate];
      browser->timer = nil;
    }
    
    browser->timer = [NSTimer timerWithTimeInterval: INTERVAL
                                             target: self
                                           selector: @selector(loop:)
                                           userInfo: nil
                                            repeats: YES];
    
    browser->runloop = aRunLoop;
    browser->runloopmode = mode;
    
    [browser->timer retain];
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/**
 * Search for all visible domains. This method is deprecated.
 *
 *
 */

- (void) searchForAllDomains
{
  DNSServiceFlags
    flags = 0;
  
  InternalTrace;
  
  flags = kDNSServiceFlagsBrowseDomains|kDNSServiceFlagsRegistrationDomains;
  [self searchForDomain: flags];
  
  //
  // That's it
  //
  
  return;
}

/**
 * Search for all browsable domains.
 *
 *
 */

- (void) searchForBrowsableDomains
{
  InternalTrace;
  
  [self searchForDomain: kDNSServiceFlagsBrowseDomains];
  
  //
  // That's it
  //
  
  return;
}

/**
 * Search for all registration domains. These domains can be used to register
 * a service.
 *
 */

- (void) searchForRegistrationDomains
{
  InternalTrace;
  
  [self searchForDomain: kDNSServiceFlagsRegistrationDomains];
  
  //
  // That's it
  //
  
  return;
}

/**
 * Search for a particular service within a given domain.
 *
 *
 */

- (void) searchForServicesOfType: (NSString *) serviceType
                        inDomain: (NSString *) domainName
{
  Browser
    *browser;
  DNSServiceErrorType
    err = kDNSServiceErr_NoError;
  DNSServiceFlags
    flags = 0;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    do
    {
      if( ! _delegate )
      {
        err = CTNetServicesInvalidError;
        break;
      }
      
      if( browser->timer )
      {
        err = CTNetServicesActivityInProgress;
        break;
      }
      
      err = DNSServiceBrowse((DNSServiceRef *) &_netServiceBrowser,
                             flags,
                             browser->interfaceIndex,
                             [serviceType UTF8String],
                             [domainName UTF8String],
                             BrowserCallback,
                             self);
    } while( 0 );
  }
  Unlock(browser);
  
  [self executeWithError: err];
  
  //
  // That's it
  //
  
  return;
}

/**
 * Halts all currently running searches.
 *
 *
 */

- (void) stop
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  
  Lock(browser);
  {
    [self cleanup];
    
    [self netServiceBrowserDidStopSearch: self];
  }
  Unlock(browser);
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Accessor Methods
**
*/

/**
 * Returns the receiver's delegate.
 *
 *
 */

- (id) delegate
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [[_delegate retain] autorelease];
}

/**
 * Sets the receiver's delegate.
 *
 *
 */

- (void) setDelegate: (id) delegate
{
  InternalTrace;
  
  if( _delegate != delegate )
  {
    [_delegate release];
    _delegate = [delegate retain];
  }
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Protocol Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowserWillSearch: (CTNetServiceBrowser *) aBrowser
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowserWillSearch:) )
  {
    [_delegate netServiceBrowserWillSearch: aBrowser];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aBrowser
              didNotSearch: (NSDictionary *) errorDict
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowser:didNotSearch:) )
  {
    [_delegate netServiceBrowser: aBrowser
                    didNotSearch: errorDict];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowserDidStopSearch: (CTNetServiceBrowser *) aBrowser
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowserDidStopSearch:) )
  {
    [_delegate netServiceBrowserDidStopSearch: aBrowser];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aBrowser
             didFindDomain: (NSString *) domainString
                moreComing: (BOOL) moreComing
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowser:didFindDomain:moreComing:) )
  {
    [_delegate netServiceBrowser: aBrowser
                   didFindDomain: domainString
                      moreComing: moreComing];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aBrowser
           didRemoveDomain: (NSString *) domainString
                moreComing: (BOOL) moreComing
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowser:didRemoveDomain:moreComing:) )
  {
    [_delegate netServiceBrowser: aBrowser
                 didRemoveDomain: domainString
                      moreComing: moreComing];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aBrowser
            didFindService: (CTNetService *) aService
                moreComing: (BOOL) moreComing
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowser:didFindService:moreComing:) )
  {
    [_delegate netServiceBrowser: aBrowser
                  didFindService: aService
                      moreComing: moreComing];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aBrowser
          didRemoveService: (CTNetService *) aService
                moreComing: (BOOL) moreComing
{
  InternalTrace;
  
  if( RespondsTo(netServiceBrowser:didRemoveService:moreComing:) )
  {
    [_delegate netServiceBrowser: aBrowser
                didRemoveService: aService
                      moreComing: moreComing];
  }
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Delegate Methods
**
*/

/***************************************************************************
**
** Override Methods
**
*/

/** <init />
 * Initializes the receiver.
 *
 *
 */

- (id) init
{
  InternalTrace;
  
  if( (self = [super init]) )
  {
    Browser
      *browser;
    
    browser = malloc(sizeof (struct _Browser));
    memset(browser, 0, sizeof browser);
    
    CreateLock(browser);
    
    browser->runloop = nil;
    browser->runloopmode = nil;
    browser->timer = nil;
    
    browser->services = [[NSMutableDictionary alloc] initWithCapacity: 1];
    
    browser->interfaceIndex = 0;
    
    _netServiceBrowser = NULL;
    _delegate = nil;
    _reserved = browser;
    
    return self;
  }
  
  //
  // That's it
  //
  
  return nil;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) dealloc
{
  Browser
    *browser;
  
  InternalTrace;
  
  browser = (Browser *) _reserved;
  {
    Lock(browser);
    {
      [self cleanup];
      
      [browser->services release];
      browser->services = nil;
      
      _delegate = nil;
    }
    Unlock(browser);
    
    DestroyLock(browser);
    
    free(browser);
  }
  [super dealloc];
  
  //
  // That's it
  //
  
  return;
}

@end

/***************************************************************************
**
** Implementation
**
*/

@implementation CTNetService

/**
 * <em>Description forthcoming</em>
 *
 *
 */

+ (void) initialize
{
  InternalTrace;
  
//  SetVersion( CTNetService );
//  {
//#ifndef _REENTRANT
//    LOG(@"%@ may NOT be thread-safe!", [self class]);
//#endif
//    
//    INITIALIZE
//  }
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Private Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) executeWithError: (DNSServiceErrorType) err
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    if( kDNSServiceErr_NoError == err )
    {
      if( YES == service->isPublishing )
      {
        [self netServiceWillPublish: self];
      }
      else
      {
        [self netServiceWillResolve: self];
      }
      
      if( ! service->runloop )
      {
        [self scheduleInRunLoop: [NSRunLoop currentRunLoop]
                        forMode: NSDefaultRunLoopMode];
      }
      
      [service->runloop addTimer: service->timer
                         forMode: service->runloopmode];
      
      [service->timer fire];
    }
    else // notify the delegate of the error
    {
      if( YES == service->isPublishing )
      {
        [self netService: self
           didNotPublish: CreateError(self, err)];
      }
      else
      {
        [self netService: self
           didNotResolve: CreateError(self, err)];
      }
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) cleanup
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    if( service->runloop )
    {
      [self removeFromRunLoop: service->runloop
                      forMode: service->runloopmode];
    }
    
    if( service->timer )
    {
      [service->timer invalidate];
      [service->timer release];
      service->timer = nil;
    }
    
    if( _netService )
    {
      DNSServiceRefDeallocate(_netService);
      _netService = NULL;
    }
    
    [service->info removeAllObjects];
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) stopResolving: (id) sender
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    [service->timeout invalidate];
    [service->timer invalidate];
    
    [self netService: self
       didNotResolve: CreateError(self, CTNetServicesTimeoutError)];
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) resolverCallback: (DNSServiceRef) sdRef
                    flags: (DNSServiceFlags) flags
                interface: (uint32_t) interfaceIndex
                    error: (DNSServiceErrorType) errorCode
                 fullname: (const char *) fullname
                   target: (const char *) hosttarget
                     port: (uint16_t) port
                   length: (uint16_t) txtLen
                   record: (const char *) txtRecord
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  
  if( _netService )
  {
    if( errorCode )
    {
      [self cleanup];
      
      [self netService: self
         didNotResolve: CreateError(self, errorCode)];
    }
    else
    {
      NSData
        *txt = nil;
      NSString
        *target = nil;
      
      // Add the TXT record
      txt = txtRecord ? [[NSData alloc] initWithBytes: txtRecord
                                               length: txtLen]
                      : nil;
      
      // Get the host
      target = hosttarget ? [[NSString alloc] initWithUTF8String: hosttarget]
                           : nil;
      
      // Add the port
      service->port = ntohs(port);
      
      // Remove the old TXT entry
      [service->info removeObjectForKey: @"TXT"];
      
      if( txt )
      {
        [service->info setObject: txt
                          forKey: @"TXT"];
        [txt release];
      }
      
      // Remove the old host entry
      [service->info removeObjectForKey: @"Host"];
      
      // Add the host if there is one
      if( target )
      {
        [service->info setObject: target
                          forKey: @"Host"];
        [target release];
      }
      
      // Add the interface so all subsequent queries are on the same interface
      service->interfaceIndex = interfaceIndex;
      
      service->timer = nil;
      
      // Prepare query for A and/or AAAA record
      errorCode = DNSServiceQueryRecord((DNSServiceRef *) &_netService,
                                        flags,
                                        interfaceIndex,
                                        hosttarget,
                                        kDNSServiceType_ANY,
                                        kDNSServiceClass_IN,
                                        QueryCallback,
                                        self);
      
      // No error? Then create a new timer
      if( kDNSServiceErr_NoError == errorCode )
      {
        service->timer = [NSTimer timerWithTimeInterval: INTERVAL
                                                 target: self
                                               selector: @selector(loop:)
                                               userInfo: nil
                                                repeats: YES];
        [service->timer fire];
      }
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) addAddress: (const void *) rdata
             length: (uint16_t) rdlen
               type: (uint16_t) rrtype
          interface: (uint32_t) interfaceIndex
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    NSData
      *data = nil;
    NSMutableArray
      *addresses = nil;
    struct sockaddr
      *address = { 0 };
    size_t
      length = 0;
    const unsigned char
      *rd = rdata;
    char
#if defined( INET6_ADDRSTRLEN )
      rdb[INET6_ADDRSTRLEN];
#else
      rdb[100]; // should be more than enough
#endif
    
    memset(rdb, 0, sizeof rdb);
    
    addresses = [service->info objectForKey: @"Addresses"];
    
    if( nil == addresses )
    {
      addresses = [[NSMutableArray alloc] initWithCapacity: 1];
    }
    
    switch( rrtype )
    {
      case kDNSServiceType_A:		// AF_INET
        {
          struct sockaddr_in
            ip4;
          
          // oogly
          sprintf(rdb, "%d.%d.%d.%d", rd[0], rd[1], rd[2], rd[3]);
          LOG(@"Found IPv4 <%s>", rdb);
          
          length = sizeof (struct sockaddr_in);
          memset(&ip4, 0, length);
          
          inet_pton(AF_INET, rdb, &ip4.sin_addr);
          ip4.sin_family = AF_INET;
          ip4.sin_port = htons(service->port);
          
          address = (struct sockaddr *) &ip4;
        }
        break;
      
#if defined( AF_INET6 )
      case kDNSServiceType_AAAA:	// AF_INET6
      case kDNSServiceType_A6:		// deprecates AAAA
        {
          struct sockaddr_in6
            ip6;
          
          // Even more oogly
          sprintf(rdb, "%x%x:%x%x:%x%x:%x%x:%x%x:%x%x:%x%x:%x%x",
                       rd[0], rd[1], rd[2], rd[3],
                       rd[4], rd[5], rd[6], rd[7],
                       rd[8], rd[9], rd[10], rd[11],
                       rd[12], rd[13], rd[14], rd[15]);
          LOG(@"Found IPv6 <%s>", rdb);
          
          length = sizeof (struct sockaddr_in6);
          memset(&ip6, 0, length);
          
          inet_pton(AF_INET6, rdb, &ip6.sin6_addr);
#if ! defined( NOT_HAVE_SA_LEN )
          ip6.sin6_len = sizeof ip6;
#endif
          ip6.sin6_family = AF_INET6;
          ip6.sin6_port = htons(service->port);
          ip6.sin6_flowinfo = 0;
          ip6.sin6_scope_id = interfaceIndex;
          
          address = (struct sockaddr *) &ip6;
        }
        break;
#endif /* AF_INET6 */      
      
      default:
        LOG(@"Unkown type of length <%d>", rdlen);
        break;
    }
    
    if( length )
    {
      // add it
      data = [NSData dataWithBytes: address
                            length: length];
      [addresses addObject: data];
      [service->info setObject: [addresses retain]
                        forKey: @"Addresses"];
      [addresses release];
      
      // notify the delegate
      [self netServiceDidResolveAddress: self];
      
      // got it, so invalidate the timeout
      [service->timeout invalidate];
      service->timeout = nil;
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) queryCallback: (DNSServiceRef) sdRef
                 flags: (DNSServiceFlags) flags
             interface: (uint32_t) interfaceIndex
                 error: (DNSServiceErrorType) errorCode
              fullname: (const char *) fullname
                  type: (uint16_t) rrtype
                 class: (uint16_t) rrclass
                length: (uint16_t) rdlen
                  data: (const void *) rdata
                   ttl: (uint32_t) ttl
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  
  if( _netService )
  {
    if( errorCode )
    {
      [self cleanup];
      
      [self netService: self
         didNotResolve: CreateError(self, errorCode)];
      
      Unlock(service);
      
      return;
    }
    
    switch( rrtype )
    {
      case kDNSServiceType_A:		// 1 -- AF_INET
        [self addAddress: rdata
                  length: rdlen
                    type: rrtype
               interface: interfaceIndex];
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
          NSData
            *data = nil;
          
          data = [NSData dataWithBytes: rdata
                                length: rdlen];
          
          [service->info removeObjectForKey: @"TXT"];
          [service->info setObject: data
                            forKey: @"TXT"];
          
          [self        netService: self
           didUpdateTXTRecordData: data];
        
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
        [self addAddress: rdata
                  length: rdlen
                    type: rrtype
               interface: interfaceIndex];
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
        [self addAddress: rdata
                  length: rdlen
                    type: rrtype
               interface: interfaceIndex];
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
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) registerCallback: (DNSServiceRef) sdRef
                    flags: (DNSServiceFlags) flags
                    error: (DNSServiceErrorType) errorCode
                     name: (const char *) name
                     type: (const char *) regtype
                   domain: (const char *) domain
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  
  if( _netService )
  {
    if( errorCode )
    {
      [self cleanup];
      
      [self netService: self
         didNotPublish: CreateError(self, errorCode)];
    }
    else
    {
      [self netServiceDidPublish: self];
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) loop: (id) sender
{
	int
    sock = 0;
	struct timeval
		tout = { 0 };
	fd_set
		set;
	DNSServiceErrorType
		err = kDNSServiceErr_NoError;
	
	sock = DNSServiceRefSockFD(_netService);
	
	if( -1 != sock )
	{
		FD_ZERO(&set);
		FD_SET(sock, &set);
		
		if( 1 == select(sock + 1, &set, (fd_set *) NULL, (fd_set *) NULL, &tout) )
		{
			err = DNSServiceProcessResult(_netService);
		}
	}
	
	if( kDNSServiceErr_NoError != err )
	{
		Service
		*service;
		
		service = (Service *) _reserved;
		
		if( YES == service->isPublishing )
		{
			[self netService: self
			   didNotPublish: CreateError(self, err)];
		}
		else
		{
			[self netService: self
			   didNotResolve: CreateError(self, err)];
		}
	}
	
	return;
}

/***************************************************************************
**
** Factory Methods
**
*/

/**
 * Converts txtDictionary into a TXT data.
 *
 *
 */

+ (NSData *) dataFromTXTRecordDictionary: (NSDictionary *) txtDictionary
{
  NSMutableData
    *result = nil;
  NSArray
    *keys = nil,
    *values = nil;
  int
    count = 0;
  
  InternalTrace;
  
  count = [txtDictionary count];
  
  if( count )
  {
    keys = [txtDictionary allKeys];
    values = [txtDictionary allValues];
    
    if( keys && values )
    {
      TXTRecordRef
        txt;
      int
        i = 0;
      char
        key[256];
      
      TXTRecordCreate(&txt, 0, NULL);
      
      for( ; i < count; i++ )
      {
        int
          length = 0,
          used = 0;
        DNSServiceErrorType
          err = kDNSServiceErr_Unknown;
        
        if( ! [[keys objectAtIndex: i] isKindOfClass: [NSString class]] )
        {
          LOG(@"%@ is not a string", [keys objectAtIndex: i]);
          break;
        }
        
        length = [[keys objectAtIndex: i] length];
        [[keys objectAtIndex: i] getCString: key
                                  maxLength: sizeof key];
        used = strlen(key);
        
        if( ! length || (used >= sizeof key) )
        {
          LOG(@"incorrect length %d - %d - %d", length, used, sizeof key);
          break;
        }
        
        strcat(key, "\0");
        
        if( [[values objectAtIndex: i] isKindOfClass: [NSString class]] )
        {
          char
            value[256];
          
          length = [[values objectAtIndex: i] length];
          [[values objectAtIndex: i] getCString: value
                                      maxLength: sizeof value];
          used = strlen(value);
          
          if( used >= sizeof value )
          {
            LOG(@"incorrect length %d - %d - %d", length, used, sizeof value);
            break;
          }
          
          err = TXTRecordSetValue(&txt,
                                  (const char *) key,
                                  used,
                                  value);
        }
        else if( [[values objectAtIndex: i] isKindOfClass: [NSData class]] && 
                 [[values objectAtIndex: i] length] < 256 &&
                 [[values objectAtIndex: i] length] >= 0 )
        {
          err = TXTRecordSetValue(&txt,
                                  (const char *) key,
                                  [[values objectAtIndex: i] length],
                                  [[values objectAtIndex: i] bytes]);
          
        }
        else if( [values objectAtIndex: i] == [NSNull null] )
        {
          err = TXTRecordSetValue(&txt,
                                  (const char *) key,
                                  0,
                                  NULL);
        }
        else
        {
          LOG(@"unknown value type");
          break;
        }
        
        if( err != kDNSServiceErr_NoError )
        {
          LOG(@"error creating data type");
          break;
        }
      }
      
      if( i == count )
      {
        result = [NSData dataWithBytes: TXTRecordGetBytesPtr(&txt)
                                length: TXTRecordGetLength(&txt)];
      }
      
      TXTRecordDeallocate(&txt);
    }
    else
    {
      LOG(@"No keys or values");
    }
    
    // both are autorelease'd
    keys = nil;
    values = nil;
  }
  else
  {
    LOG(@"Dictionary seems empty");
  }
  
  //
  // That's it
  //
  
  return result;
}

/**
 * Converts the TXT data txtData into a dictionary.
 *
 *
 */

+ (NSDictionary *) dictionaryFromTXTRecordData: (NSData *) txtData
{
  NSMutableDictionary
    *result = nil;
  int
    len = 0;
  const void
    *txt = 0;
  
  InternalTrace;
  
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
    count = TXTRecordGetCount(len, txt);
    result = [NSMutableDictionary dictionaryWithCapacity: 1];
    
    if( result )
    {
      // go through all keys
      for( ; i < count; i++ )
      {
        char
          key[256];
        uint8_t
          valLen = 0;
        const void
          *value = NULL;
        DNSServiceErrorType
          err = kDNSServiceErr_NoError;
        
        err = TXTRecordGetItemAtIndex(len, txt, i,
                                      sizeof key, key,
                                      &valLen, &value);
        
        // only if we can get the key and value...
        if( kDNSServiceErr_NoError == err )
        {
          NSData
            *data = nil;
          NSString
            *str = nil;
          
          str = [NSString stringWithUTF8String: key];
          
          if( value )
          {
            data = [NSData dataWithBytes: value
                                  length: valLen];
          }
          
          // only add if key and value were created and key doesn't exist yet
          if( data && str && [str length] && ! [result objectForKey: str] )
          {
            [result setObject: data
					   forKey: str];
          }
          // I'm not exactly sure what to do if there is a key WITHOUT a value
          // Theoretically '<6>foobar' should be identical to '<7>foobar='
          // i.e. the value would be [NSNull null]
          else
          {
            [result setObject: [NSNull null]
					   forKey: str];
          }
          
          // both are autorelease'd
          data = nil;
          str = nil;
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
  
  //
  // That's it
  //
  
  return result;
}

/***************************************************************************
**
** Instance Methods
**
*/

/**
 * Initializes the receiver for service resolution. Use this method to create
 * an object if you intend to -resolve a service.
 *
 */

- (id) initWithDomain: (NSString *) domain
                 type: (NSString *) type
                 name: (NSString *) name
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [self initWithDomain: domain
                         type: type
                         name: name
                         port: -1]; // -1 to indicate resolution, not publish
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
  InternalTrace;
  
  if( (self = [super init]) )
  {
    Service
      *service;
    
    service = malloc(sizeof (struct _Service));
    memset(service, 0, sizeof service);
    
    CreateLock(service);
    
    service->runloop = nil;
    service->runloopmode = nil;
    service->timer = nil;
    service->timeout = nil;
    
    service->info = [[NSMutableDictionary alloc] initWithCapacity: 1];
    [service->info setObject: [domain retain]
                      forKey: @"Domain"];
    [service->info setObject: [name retain]
                      forKey: @"Name"];
    [service->info setObject: [type retain]
                      forKey: @"Type"];
    
    service->interfaceIndex = 0;
    service->port = htons(port);
    
    service->isPublishing = ( -1 == port ) ? NO : YES;
    
    service->monitor = nil;
    
    _netService = NULL;
    _delegate = nil;
    _reserved = service;
    
    return self;
  }
  
  //
  // That's it
  //
  
  return nil;
}

/**
 * Removes the service from the specified run loop.
 *
 *
 */

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    if( service->timer )
    {
      [service->timer setFireDate: [NSDate date]];
      [service->timer invalidate];
      
      // Do not release the timer!
      service->timer = nil;
    }
    
    // Do not release the runloop!
    service->runloop = nil;
    
    [service->runloopmode release];
    service->runloopmode = nil;
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * Adds the service to the specified run loop.
 *
 *
 */

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    if( service->timer )
    {
      [service->timer setFireDate: [NSDate date]];
      [service->timer invalidate];
      service->timer = nil;
    }
    
    service->timer = [NSTimer timerWithTimeInterval: INTERVAL
                                             target: self
                                           selector: @selector(loop:)
                                           userInfo: nil
                                            repeats: YES];
    
    service->runloop = aRunLoop;
    service->runloopmode = mode;
    
    [service->timer retain];
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * Attempts to publish a service on the network.
 *
 *
 */

- (void) publish
{
  Service
    *service;
  DNSServiceErrorType
    err = kDNSServiceErr_NoError;
  DNSServiceFlags
    flags = 0;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    do
    {
      // cannot -publish on a service that's init'd for resolving
      if( NO == service->isPublishing )
      {
        err = CTNetServicesBadArgumentError;
        break;
      }
      
      if( ! _delegate )
      {
        err = CTNetServicesInvalidError;
        break;
      }
      
      if( service->timer )
      {
        err = CTNetServicesActivityInProgress;
        break;
      }
      
      if( service->timeout )
      {
        [service->timeout setFireDate: [NSDate date]];
        [service->timeout invalidate];
        service->timeout = nil;
      }
      
      err = DNSServiceRegister((DNSServiceRef *) &_netService,
                               flags, service->interfaceIndex,
                               [[service->info objectForKey: @"Name"] UTF8String],
                               [[service->info objectForKey: @"Type"] UTF8String],
                               [[service->info objectForKey: @"Domain"] UTF8String],
                               NULL, service->port, 0, NULL,
                               RegistrationCallback, self);
    } while( 0 );
  }
  Unlock(service);
  
  [self executeWithError: err];
  
  //
  // That's it
  //
  
  return;
}

/**
 * This method is deprecated. Use -resolveWithTimeout: instead.
 *
 *
 */

- (void) resolve
{
  InternalTrace;
  
  [self resolveWithTimeout: 5];
  
  //
  // That's it
  //
  
  return;
}

/**
 * Starts a service resolution for a limited duration.
 *
 *
 */

- (void) resolveWithTimeout: (NSTimeInterval) timeout
{
  Service
    *service;
  DNSServiceErrorType
    err = kDNSServiceErr_NoError;
  DNSServiceFlags
    flags = 0;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    do
    {
      // cannot -resolve on a service that's init'd for publishing
      if( YES == service->isPublishing )
      {
        err = CTNetServicesBadArgumentError;
        break;
      }
      
      if( ! _delegate )
      {
        err = CTNetServicesInvalidError;
        break;
      }
      
      if( service->timer )
      {
        err = CTNetServicesActivityInProgress;
        break;
      }
      
      if( service->timeout )
      {
        [service->timeout setFireDate: [NSDate date]];
        [service->timeout invalidate];
        service->timeout = nil;
      }
      
      service->timeout = [NSTimer alloc];
      {
        NSDate
          *date = nil;
        
        date = [NSDate dateWithTimeIntervalSinceNow: timeout + SHORTTIMEOUT];
        
        [service->timeout initWithFireDate: date
                                  interval: INTERVAL
                                    target: self
                                  selector: @selector(stopResolving:)
                                  userInfo: nil
                                   repeats: NO];
      }
      
      err = DNSServiceResolve((DNSServiceRef *) &_netService,
                              flags, service->interfaceIndex,
                              [[service->info objectForKey: @"Name"] UTF8String],
                              [[service->info objectForKey: @"Type"] UTF8String],
                              [[service->info objectForKey: @"Domain"] UTF8String],
                              ResolverCallback, self);
    } while( 0 );
  }
  Unlock(service);
  
  [self executeWithError: err];
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) stop
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    [self cleanup];
    
    [self netServiceDidStop: self];
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) startMonitoring
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    // Obviously this will only work on a resolver
    if( ! service->isPublishing )
    {
      if( ! service->isMonitoring )
      {
        service->monitor = [[CTNetServiceMonitor alloc] initWithDelegate: self];
        
        [service->monitor scheduleInRunLoop: service->runloop
                                    forMode: service->runloopmode];
        [service->monitor start];
        
        service->isMonitoring = YES;
      }
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) stopMonitoring
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    if( ! service->isPublishing )
    {
      if( service->isMonitoring )
      {
        [service->monitor stop];
        
        // Probably don't need it anymore, so release it
        [service->monitor release];
        service->monitor = nil;
        
        service->isMonitoring = NO;
      }
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Accessor Methods
**
*/

/**
 * Returns the receiver's delegate.
 *
 *
 */

- (id) delegate
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [[_delegate retain] autorelease];
}

/**
 * Sets the receiver's delegate.
 *
 *
 */

- (void) setDelegate: (id) delegate
{
  InternalTrace;
  
  if( _delegate != delegate )
  {
    [_delegate release];
    _delegate = [delegate retain];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * Returns an array of NSData objects that each contain the socket address of
 * the service.
 *
 */

- (NSArray *) addresses
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [((Service*)_reserved)->info objectForKey: @"Addresses"];
}

/**
 * Returns the domain name of the service.
 *
 *
 */

- (NSString *) domain
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [((Service*)_reserved)->info objectForKey: @"Domain"];
}

/**
 * Returns the host name of the computer publishing the service.
 *
 *
 */

- (NSString *) hostName
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [((Service*)_reserved)->info objectForKey: @"Host"];
}

/**
 * Returns the name of the service.
 *
 *
 */

- (NSString *) name
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [((Service*)_reserved)->info objectForKey: @"Name"];
}

/**
 * Returns the type of the service.
 *
 *
 */

- (NSString *) type
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [((Service*)_reserved)->info objectForKey: @"Type"];
}

/**
 * This method is deprecated. Use -TXTRecordData instead.
 *
 *
 */

- (NSString *) protocolSpecificInformation
{
  NSMutableArray
    *array = nil;
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  //
  // I must admit, the following may not be entirely correct...
  //
  Lock(service);
  {
    NSDictionary
      *dictionary = nil;
    
    dictionary = [CTNetService dictionaryFromTXTRecordData:
                   [self TXTRecordData]];
    
    if( dictionary )
    {
      NSEnumerator
        *keys = nil;
      id
        key = nil;
      
      array = [NSMutableArray arrayWithCapacity: [dictionary count]];
      keys = [dictionary keyEnumerator];
      
      while( key = [keys nextObject] )
      {
        id
          value = nil;
        
        value = [dictionary objectForKey: key];
        
        if( value != (NSData *) [NSNull null] )
        {
          [array addObject: [NSString stringWithFormat: @"%@=%@", key,
                              [NSString stringWithCString: [value bytes] 
                                                   length: [value length]]]];
        }
        else if( [key length] )
        {
          [array addObject: [NSString stringWithFormat: @"%@", key]];
        }
      }
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return ( [array count] ? [array componentsJoinedByString: @"\001"]
                         : (NSString *) nil );
}

/**
 * This method is deprecated. Use -setTXTRecordData: instead.
 *
 *
 */

- (void) setProtocolSpecificInformation: (NSString *) specificInformation
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  //
  // Again, the following may not be entirely correct...
  //
  Lock(service);
  {
    NSArray
      *array = nil;
    
    array = [specificInformation componentsSeparatedByString: @"\001"];
    
    if( array )
    {
      NSMutableDictionary
        *dictionary = nil;
      NSEnumerator
        *enumerator = nil;
      id
        item = nil;
      
      dictionary = [NSMutableDictionary dictionaryWithCapacity: [array count]];
      enumerator = [array objectEnumerator];
      
      while( item = [enumerator nextObject] )
      {
        NSArray
          *parts = nil;
        
        parts = [item componentsSeparatedByString:@"="];
        
        [dictionary setObject: [[parts objectAtIndex: 1] dataUsingEncoding: NSUTF8StringEncoding]
                       forKey: [parts objectAtIndex: 0]];
      }
      
      [self setTXTRecordData:
        [CTNetService dataFromTXTRecordDictionary: dictionary]];
    }
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return;
}

/**
 * Returns the TXT record.
 *
 *
 */

- (NSData *) TXTRecordData
{
  InternalTrace;
  
  //
  // That's it
  //
  
  return [((Service*)_reserved)->info objectForKey: @"TXT"];
}

/**
 * Sets the TXT record.
 *
 *
 */

- (BOOL) setTXTRecordData: (NSData *) recordData
{
  Service
    *service;
  BOOL
    result = NO;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    // Not allowed on a resolver...
    if( service->isPublishing )
    {
      DNSServiceErrorType
        err = kDNSServiceErr_NoError;
      
      // Set the value, or remove it if empty
      if( recordData )
      {
        [service->info setObject: recordData
                          forKey: @"TXT"];
      }
      else
      {
        [service->info removeObjectForKey: @"TXT"];
      }
      
      // Assume it worked
      result = YES;
      
      // Now update the record so others can pick it up
      err = DNSServiceUpdateRecord(_netService,
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
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return result;
}

/**
 * Retrieves the input and output stream for the receiver.
 *
 *
 */

- (BOOL) getInputStream: (NSInputStream **) inputStream
           outputStream: (NSOutputStream **) outputStream
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  
  Lock(service);
  {
    [NSStream getStreamsToHost: [service->info objectForKey: @"Host"]
                          port: ntohs(service->port)
                   inputStream: inputStream
                  outputStream: outputStream];
  }
  Unlock(service);
  
  //
  // That's it
  //
  
  return inputStream && outputStream;
}

/***************************************************************************
**
** Protocol Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceWillPublish: (CTNetService *) sender
{
  InternalTrace;
  
  if( RespondsTo(netServiceWillPublish:) )
  {
    [_delegate netServiceWillPublish: sender];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceDidPublish: (CTNetService *) sender
{
  InternalTrace;
  
  if( RespondsTo(netServiceDidPublish:) )
  {
    [_delegate netServiceDidPublish: sender];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netService: (CTNetService *) sender
      didNotPublish: (NSDictionary *) errorDict
{
  InternalTrace;
  
  if( RespondsTo(netService:didNotPublish:) )
  {
    [_delegate netService: sender
            didNotPublish: errorDict];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceWillResolve: (CTNetService *) sender
{
  InternalTrace;
  
  if( RespondsTo(netServiceWillResolve:) )
  {
    [_delegate netServiceWillResolve: sender];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceDidResolveAddress: (CTNetService *) sender
{
  InternalTrace;
  
  if( RespondsTo(netServiceDidResolveAddress:) )
  {
    [_delegate netServiceDidResolveAddress: sender];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netService: (CTNetService *) sender
      didNotResolve: (NSDictionary *) errorDict
{
  InternalTrace;
  
  if( RespondsTo(netService:didNotResolve:) )
  {
    [_delegate netService: sender
            didNotResolve: errorDict];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) netServiceDidStop: (CTNetService *) sender
{
  InternalTrace;
  
  if( RespondsTo(netServiceDidStop:) )
  {
    [_delegate netServiceDidStop: sender];
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void)      netService: (CTNetService *) sender
  didUpdateTXTRecordData: (NSData *) data
{
  InternalTrace;
  
  if( RespondsTo(netService:didUpdateTXTRecordData:) )
  {
    [_delegate   netService: sender
     didUpdateTXTRecordData: data];
  }
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Delegate Methods
**
*/

/***************************************************************************
**
** Override Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (id) init
{
  //
  // That's it
  //
  
  return nil;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) dealloc
{
  Service
    *service;
  
  InternalTrace;
  
  service = (Service *) _reserved;
  {
    Lock(service);
    {
      [self stopMonitoring];
      [self cleanup];
      
      [service->info release];
      service->info = nil;
      
      _delegate = nil;
    }
    Unlock(service);
    
    DestroyLock(service);
    
    free(service);
  }
  [super dealloc];
  
  //
  // That's it
  //
  
  return;
}

@end

/***************************************************************************
**
** Implementation
**
*/

@implementation CTNetServiceMonitor

/**
 * <em>Description forthcoming</em>
 *
 *
 */

+ (void) initialize
{
//  InternalTrace;
//  
//  SetVersion( CTNetServiceMonitor );
//  {
//    INITIALIZE
//  }
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Private Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) loop: (id) sender
{
  int
    sock = 0;
  struct timeval
    tout = { 0 };
  fd_set
    set;
  DNSServiceErrorType
    err = kDNSServiceErr_NoError;
  
  sock = DNSServiceRefSockFD(_netServiceMonitor);
  
  if( -1 != sock )
  {
    FD_ZERO(&set);
    FD_SET(sock, &set);
    
    if( 1 == select(sock + 1, &set, (fd_set *) NULL, (fd_set *) NULL, &tout) )
    {
      err = DNSServiceProcessResult(_netServiceMonitor);
    }
  }
  
  if( kDNSServiceErr_NoError != err )
  {
    // FIXME -- we do need to notify the delegate
    LOG(@"Error <%d> while monitoring", err);
  }
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) queryCallback: (DNSServiceRef) sdRef
                 flags: (DNSServiceFlags) flags
             interface: (uint32_t) interfaceIndex
                 error: (DNSServiceErrorType) errorCode
              fullname: (const char *) fullname
                  type: (uint16_t) rrtype
                 class: (uint16_t) rrclass
                length: (uint16_t) rdlen
                  data: (const void *) rdata
                   ttl: (uint32_t) ttl
{
  Monitor
    *monitor;
  
  InternalTrace;
  
  monitor = (Monitor *) _reserved;
  
  Lock(monitor);
  
  if( _delegate )
  {
    // we are 'monitoring' kDNSServiceType_TXT
    // this is already handled by the delegate's method of the same name
    // so we simply pass this through
    [_delegate queryCallback: sdRef
                       flags: flags
                   interface: interfaceIndex
                       error: errorCode
                    fullname: fullname
                        type: rrtype
                       class: rrclass
                      length: rdlen
                        data: rdata
                         ttl: ttl];
  }
  Unlock(monitor);
  
  //
  // That's it
  //
  
  return;
}

/***************************************************************************
**
** Factory Methods
**
*/

/***************************************************************************
**
** Instance Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (id) initWithDelegate: (id) delegate
{
  InternalTrace;
  
  if( (self = [super init]) )
  {
    Monitor
      *monitor;
    
    monitor = malloc(sizeof (struct _Monitor));
    memset(monitor, 0, sizeof monitor);
    
    CreateLock(monitor);
    
    monitor->runloop = nil;
    monitor->runloopmode = nil;
    monitor->timer = nil;
    
    _netServiceMonitor = NULL;
    _delegate = [delegate retain];
    _reserved = monitor;
    
    return self;
  }
  
  //
  // That's it
  //
  
  return nil;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode
{
  Monitor
    *monitor;
  
  InternalTrace;
  
  monitor = (Monitor *) _reserved;
  
  Lock(monitor);
  {
    if( monitor->timer )
    {
      [monitor->timer setFireDate: [NSDate date]];
      [monitor->timer invalidate];
      monitor->timer = nil;
    }
    
    // Do not release the runloop!
    monitor->runloop = nil;
    
    // [monitor->runloopmode release];
    monitor->runloopmode = nil;
  }
  Unlock(monitor);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode
{
  Monitor
    *monitor;
  
  InternalTrace;
  
  monitor = (Monitor *) _reserved;
  
  Lock(monitor);
  {
    if( monitor->timer )
    {
      [monitor->timer setFireDate: [NSDate date]];
      [monitor->timer invalidate];
      monitor->timer = nil;
    }
    
    monitor->runloop = aRunLoop;
    monitor->runloopmode = mode;
  }
  Unlock(monitor);
  
  //
  // That's it
  //
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) start
{
  Monitor
    *monitor;
  
  InternalTrace;
  
  monitor = (Monitor *) _reserved;
  
  Lock(monitor);
  {
    DNSServiceErrorType
      err = kDNSServiceErr_NoError;
    DNSServiceFlags
      flags = kDNSServiceFlagsLongLivedQuery;
    NSString
      *fullname = nil;
    
    do
    {
      if( ! _delegate )
      {
        err = CTNetServicesInvalidError;
        break;
      }
      
      if( monitor->timer )
      {
        err = CTNetServicesActivityInProgress;
        break;
      }
      
      fullname = [NSString stringWithFormat: @"%@.%@%@",
                   [_delegate name], [_delegate type], [_delegate domain]];
      
      err = DNSServiceQueryRecord((DNSServiceRef *) &_netServiceMonitor,
                                  flags,
                                  0,
                                  [fullname UTF8String],
                                  kDNSServiceType_TXT,
                                  kDNSServiceClass_IN,
                                  QueryCallback,
                                  self);
      
      if( kDNSServiceErr_NoError == err )
      {
        monitor->timer = [NSTimer timerWithTimeInterval: INTERVAL
                                                 target: self
                                               selector: @selector(loop:)
                                               userInfo: nil
                                                repeats: YES];

        [monitor->runloop addTimer: monitor->timer
                           forMode: monitor->runloopmode];
        
        [monitor->timer fire];
      }
    } while( 0 );
  }
  Unlock(monitor);
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) stop
{
  Monitor
    *monitor;
  
  InternalTrace;
  
  monitor = (Monitor *) _reserved;
  
  Lock(monitor);
  {
    if( monitor->runloop )
    {
      [self removeFromRunLoop: monitor->runloop
                      forMode: monitor->runloopmode];
    }
    
    if( monitor->timer )
    {
      [monitor->timer invalidate];
      [monitor->timer release];
      monitor->timer = nil;
    }
    
    if( _netServiceMonitor )
    {
      DNSServiceRefDeallocate(_netServiceMonitor);
      _netServiceMonitor = NULL;
    }
  }
  Unlock(monitor);

  return;
}

/***************************************************************************
**
** Accessor Methods
**
*/

/***************************************************************************
**
** Protocol Methods
**
*/

/***************************************************************************
**
** Delegate Methods
**
*/

/***************************************************************************
**
** Override Methods
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (id) init
{

  return nil;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

- (void) dealloc
{
  Monitor
    *monitor;
  
  InternalTrace;
  
  monitor = (Monitor *) _reserved;
  {
    Lock(monitor);
    {
      [self stop];
      
      _delegate = nil;
    }
    Unlock(monitor);
    
    DestroyLock(monitor);
    
    free(monitor);
  }
  [super dealloc];
  
  return;
}

@end

/***************************************************************************
**
** Functions
**
*/

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE NSDictionary
  * CreateError(id sender,
                int errorCode)
{
  NSMutableDictionary
    *dictionary = nil;
  int
    error = 0;
  
  InternalTrace;
  
  dictionary = [NSMutableDictionary dictionary];
  error = ConvertError(errorCode);
  
  LOG(@"%@ says error <%d> - <%d>", [sender description], errorCode, error);
  
  [dictionary setObject: [NSNumber numberWithInt: error]
                 forKey: CTNetServicesErrorCode];
  [dictionary setObject: sender
                 forKey: CTNetServicesErrorDomain];

  return dictionary; // autorelease'd
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE int
  ConvertError(int errorCode)
{
  InternalTrace;
  
  switch( errorCode )
  {
    case kDNSServiceErr_Unknown:
      return CTNetServicesUnknownError;
    
    case kDNSServiceErr_NoSuchName:
      return CTNetServicesNotFoundError;
    
    case kDNSServiceErr_NoMemory:
      return CTNetServicesUnknownError;
    
    case kDNSServiceErr_BadParam:
    case kDNSServiceErr_BadReference:
    case kDNSServiceErr_BadState:
    case kDNSServiceErr_BadFlags:
      return CTNetServicesBadArgumentError;
    
    case kDNSServiceErr_Unsupported:
      return CTNetServicesUnknownError;
    
    case kDNSServiceErr_NotInitialized:
      return CTNetServicesInvalidError;
    
    case kDNSServiceErr_AlreadyRegistered:
    case kDNSServiceErr_NameConflict:
      return CTNetServicesCollisionError;
    
    case kDNSServiceErr_Invalid:
      return CTNetServicesInvalidError;
    
    case kDNSServiceErr_Firewall:
      return CTNetServicesUnknownError;
    
    case kDNSServiceErr_Incompatible:
      // The client library is incompatible with the daemon
      return CTNetServicesInvalidError;
    
    case kDNSServiceErr_BadInterfaceIndex:
    case kDNSServiceErr_Refused:
      return CTNetServicesUnknownError;
    
    case kDNSServiceErr_NoSuchRecord:
    case kDNSServiceErr_NoAuth:
    case kDNSServiceErr_NoSuchKey:
      return CTNetServicesNotFoundError;
    
    case kDNSServiceErr_NATTraversal:
    case kDNSServiceErr_DoubleNAT:
    case kDNSServiceErr_BadTime:
      return CTNetServicesUnknownError;
  }

  return errorCode;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE void
  EnumerationCallback(DNSServiceRef sdRef,
                      DNSServiceFlags flags,
                      uint32_t interfaceIndex,
                      DNSServiceErrorType  errorCode,
                      const char *replyDomain,
                      void *context)
{
  // CTNetServiceBrowser
  [(id) context enumCallback: sdRef
                       flags: flags
                   interface: interfaceIndex
                       error: errorCode
                      domain: replyDomain];
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE void
  BrowserCallback(DNSServiceRef sdRef,
                  DNSServiceFlags flags,
                  uint32_t interfaceIndex,
                  DNSServiceErrorType errorCode,
                  const char *replyName,
                  const char *replyType,
                  const char *replyDomain,
                  void *context)
{
  // CTNetServiceBrowser
  [(id) context browseCallback: sdRef
                         flags: flags
                     interface: interfaceIndex
                         error: errorCode
                          name: replyName
                          type: replyType
                        domain: replyDomain];

  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE void
  ResolverCallback(DNSServiceRef sdRef,
                   DNSServiceFlags flags,
                   uint32_t interfaceIndex,
                   DNSServiceErrorType errorCode,
                   const char *fullname,
                   const char *hosttarget,
                   uint16_t port,
                   uint16_t txtLen,
                   const char *txtRecord,
                   void *context)
{
  // CTNetService
  [(id) context resolverCallback: sdRef
                           flags: flags
                       interface: interfaceIndex
                           error: errorCode
                        fullname: fullname
                          target: hosttarget
                            port: port
                          length: txtLen
                          record: txtRecord];
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE void
  RegistrationCallback(DNSServiceRef sdRef,
                       DNSServiceFlags flags,
                       DNSServiceErrorType errorCode,
                       const char *name,
                       const char *regtype,
                       const char *domain,
                       void *context)
{
  // CTNetService
  [(id) context registerCallback: sdRef
                           flags: flags
                           error: errorCode
                            name: name
                            type: regtype
                          domain: domain];
  
  return;
}

/**
 * <em>Description forthcoming</em>
 *
 *
 */

PRIVATE void
  QueryCallback(DNSServiceRef sdRef,
                DNSServiceFlags flags,
                uint32_t interfaceIndex,
                DNSServiceErrorType errorCode,
                const char *fullname,
                uint16_t rrtype,
                uint16_t rrclass,
                uint16_t rdlen,
                const void *rdata,
                uint32_t ttl,
                void *context)
{
  // CTNetService, CTNetServiceMonitor
  [(id) context queryCallback: sdRef
                        flags: flags
                    interface: interfaceIndex
                        error: errorCode
                     fullname: fullname
                         type: rrtype
                        class: rrclass
                       length: rdlen
                         data: rdata
                          ttl: ttl];
  
  return;
}

