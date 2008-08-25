/* FILE: CTNetServices.h
 *
 * Project              Tryst
 * Class                CTNetServices
 * Creator		Chris B. Vetter
 * Maintainer           Chris B. Vetter
 * Creation Date	Mon Sep 11 14:46:24 CEST 2006
 *
 * Copyright (c) 2006 Chris B. Vetter
 * Bugfixing by D. Theisen
 *
  
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

/***************************************************************************/

//
// Include
//

#import <Foundation/NSObject.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSArray.h>

//
// Define
//

//
// Typedef
//

typedef enum
{
  /**
   * <list>
   *   <item>
   *     <strong>CTNetServicesUnknownError</strong><br />
   *     An unknown error occurred.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesCollisionError</strong><br />
   *     The given registration has had a name collision. Registration should
   *     be cancelled and tried again with a different name.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesNotFoundError</strong><br />
   *     The service could not be found.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesActivityInProgress</strong><br />
   *     A request is already in progress.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesBadArgumentError</strong><br />
   *     An invalid argument was used to create the object.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesCancelledError</strong><br />
   *     The request has been cancelled.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesInvalidError</strong><br />
   *     The service was improperly configured.
   *     <br /><br />
   *   </item>
   *   <item>
   *     <strong>CTNetServicesTimeoutError</strong><br />
   *     The request has timed out before a successful resolution.
   *     <br /><br />
   *   </item>
   * </list>
   */
  CTNetServicesUnknownError		= -72000L,
  CTNetServicesCollisionError		= -72001L,
  CTNetServicesNotFoundError		= -72002L,
  CTNetServicesActivityInProgress	= -72003L,
  CTNetServicesBadArgumentError		= -72004L,
  CTNetServicesCancelledError		= -72005L,
  CTNetServicesInvalidError		= -72006L,
  CTNetServicesTimeoutError		= -72007L
} CTNetServicesError;

//
// Public
//

extern NSString * const CTNetServicesErrorCode;
extern NSString * const CTNetServicesErrorDomain;

//
// Referenced Classes
//

@class	NSInputStream,
        NSOutputStream,
        NSRunLoop;

//
// Interface
//

/**
 * <unit>
 *   <heading>
 *     CTNetService class description
 *   </heading>
 *   <p>
 *     <!-- Foreword -->
 *   </p>
 *   <unit />
 *   <p>
 *     <!-- Afterword -->
 *   </p>
 * </unit>
 * <p>
 *   [CTNetService] lets you publish a network service in a domain using
 *   multicast DNS. Additionally, it lets you resolve a network service that
 *   was discovered by [CTNetServiceBrowser].
 * </p>
 */

@interface CTNetService : NSObject
{
  @private
  void		* _netService;
  id		  _delegate;
  void		* _reserved;
}

//
// Factory Methods
//

+ (NSData *) dataFromTXTRecordDictionary: (NSDictionary *) txtDictionary;
+ (NSDictionary *) dictionaryFromTXTRecordData: (NSData *) txtData;

//
// Instance Methods
//

- (id) initWithDomain: (NSString *) domain
                 type: (NSString *) type
                 name: (NSString *) name;
- (id) initWithDomain: (NSString *) domain
                 type: (NSString *) type
                 name: (NSString *) name
                 port: (int) port;

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode;
- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode;

- (void) publish;
- (void) resolve;
- (void) resolveWithTimeout: (NSTimeInterval) timeout;
- (void) stop;

- (void) startMonitoring;
- (void) stopMonitoring;

//
// Accessor Methods
//

- (id) delegate;
- (void) setDelegate: (id) delegate;

- (NSArray *) addresses;
- (NSString *) domain;
- (NSString *) hostName;
- (NSString *) name;
- (NSString *) type;

- (NSString *) protocolSpecificInformation;
- (void) setProtocolSpecificInformation: (NSString *) specificInformation;

- (NSData *) TXTRecordData;
- (BOOL) setTXTRecordData: (NSData *) recordData;

- (BOOL) getInputStream: (NSInputStream **) inputStream
           outputStream: (NSOutputStream **) outputStream;

@end

/***************************************************************************/

//
// Interface
//

/**
 * <unit>
 *   <heading>
 *     CTNetServiceBrowser class description
 *   </heading>
 *   <p>
 *     <!-- Foreword -->
 *   </p>
 *   <unit />
 *   <p>
 *     <!-- Afterword -->
 *   </p>
 * </unit>
 * <p>
 *   [CTNetServiceBrowser] asynchronously lets you discover network domains
 *   and, additionally, search for a type of network service. It sends its
 *   delegate a message whenever it discovers a new network service, and
 *   whenever a network service goes away.
 * </p>
 * <p>
 *   Each [CTNetServiceBrowser] performs one search at a time. So in order
 *   to perform multiple searches simultaneously, create multiple instances.
 * </p>
 */

@interface CTNetServiceBrowser : NSObject
{
  @private
  void		* _netServiceBrowser;
  id		  _delegate;
  void		* _reserved;
}

//
// Factory Methods
//

//
// Instance Methods
//

- (id) init;

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode;
- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop
                   forMode: (NSString *) mode;

- (void) searchForAllDomains;
- (void) searchForBrowsableDomains;
- (void) searchForRegistrationDomains;

- (void) searchForServicesOfType: (NSString *) serviceType
                        inDomain: (NSString *) domainName;

- (void) stop;

//
// Accessor Methods
//

- (id) delegate;
- (void) setDelegate: (id) delegate;

@end

/***************************************************************************/

//
// Interface
//

/**
 * <unit>
 *   <heading>
 *     NSObject (CTNetServiceDelegateMethods) class description
 *   </heading>
 *   <p>
 *     <!-- Foreword -->
 *   </p>
 *   <unit />
 *   <p>
 *     <!-- Afterword -->
 *   </p>
 * </unit>
 * <p>
 *  This informal protocol must be adopted by any class wishing to implement
 *  an [CTNetService] delegate.
 * </p>
 */

@interface NSObject (CTNetServiceDelegateMethods)

/**
 * Notifies the delegate that the network is ready to publish the service.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-publish]<br />
 * </p>
 */

- (void) netServiceWillPublish: (CTNetService *) sender;

/**
 * Notifies the delegate that the service was successfully published.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-publish]<br />
 * </p>
 */

- (void) netServiceDidPublish: (CTNetService *) sender;

/**
 * Notifies the delegate that the service could not get published.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-publish]<br />
 * </p>
 */

- (void) netService: (CTNetService *) sender
      didNotPublish: (NSDictionary *) errorDict;

/**
 * Notifies the delegate that the network is ready to resolve the service.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-resolveWithTimeout:]<br />
 * </p>
 */

- (void) netServiceWillResolve: (CTNetService *) sender;

/**
 * Notifies the delegate that the service was resolved.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-resolveWithTimeout:]<br />
 * </p>
 */

- (void) netServiceDidResolveAddress: (CTNetService *) sender;

/**
 * Notifies the delegate that the service could not get resolved.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-resolveWithTimeout:]<br />
 * </p>
 */

- (void) netService: (CTNetService *) sender
      didNotResolve: (NSDictionary *) errorDict;

/**
 * Notifies the delegate that the request was stopped.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-stop]<br />
 * </p>
 */

- (void) netServiceDidStop: (CTNetService *) sender;

/**
 * Notifies the delegate that the TXT record has been updated.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetService-startMonitoring]<br />
 *   [CTNetService-stopMonitoring]
 * </p>
 */

- (void)      netService: (CTNetService *) sender
  didUpdateTXTRecordData: (NSData *) data;

@end

/***************************************************************************/

//
// Interface
//

/**
 * <unit>
 *   <heading>
 *     NSObject (CTNetServiceBrowserDelegateMethods) class description
 *   </heading>
 *   <p>
 *     <!-- Foreword -->
 *   </p>
 *   <unit />
 *   <p>
 *     <!-- Afterword -->
 *   </p>
 * </unit>
 * <p>
 *  This informal protocol must be adopted by any class wishing to implement
 *  an [CTNetServiceBrowser] delegate.
 * </p>
 */

@interface NSObject (CTNetServiceBrowserDelegateMethods)

/**
 * Notifies the delegate that the search is about to begin.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetServiceBrowser-netServiceBrowser:didNotSearch:]<br />
 * </p>
 */

- (void) netServiceBrowserWillSearch: (CTNetServiceBrowser *) aNetServiceBrowser;

/**
 * Notifies the delegate that the search was unsuccessful.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetServiceBrowser-netServiceBrowserWillSearch:]<br />
 * </p>
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aNetServiceBrowser
              didNotSearch: (NSDictionary *) errorDict;

/**
 * Notifies the delegate that the search was stopped.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetServiceBrowser-stop]<br />
 * </p>
 */

- (void) netServiceBrowserDidStopSearch: (CTNetServiceBrowser *) aNetServiceBrowser;

/**
 * Notifies the delegate that a domain was found.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetServiceBrowser-searchForBrowsableDomains]<br />
 *   [CTNetServiceBrowser-searchForRegistrationDomains]<br />
 * </p>
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aNetServiceBrowser
             didFindDomain: (NSString *) domainString
                moreComing: (BOOL) moreComing;

/**
 * Notifies the delegate that a domain has become unavailable.
 *
 * <p><strong>See also:</strong><br />
 *   <br />
 * </p>
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aNetServiceBrowser
           didRemoveDomain: (NSString *) domainString
                moreComing: (BOOL) moreComing;

/**
 * Notifies the delegate that a service was found.
 *
 * <p><strong>See also:</strong><br />
 *   [CTNetServiceBrowser-searchForServicesOfType:inDomain:]<br />
 * </p>
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aNetServiceBrowser
            didFindService: (CTNetService *) aNetService
                moreComing: (BOOL) moreComing;

/**
 * Notifies the delegate that a service has become unavailable.
 *
 * <p><strong>See also:</strong><br />
 *   <br />
 * </p>
 */

- (void) netServiceBrowser: (CTNetServiceBrowser *) aNetServiceBrowser
          didRemoveService: (CTNetService *) aNetService
                moreComing: (BOOL) moreComing;

@end
