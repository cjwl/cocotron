#import <CFNetwork/CFHost.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDebug.h>
#ifdef WINDOWS
#import <Foundation/NSHandleMonitor_win32.h>
#undef WINVER
#define WINVER 0x501
#import <windows.h>
#import <winsock2.h>
#import <ws2tcpip.h>
#endif
#import <pthread.h>
#import <process.h>

#if defined(WIN32) || defined(LINUX)
#define MAXHOSTNAMELEN 512
#endif

typedef enum {
   CFHostRequestInQueue,
   CFHostRequestInProgress,
   CFHostRequestDone,
   CFHostRequestDeallocate,
} CFHostRequestState;

typedef struct {
  CFHostRequestState _state;
   char             *_name;
   struct addrinfo  *_addressList;
#ifdef WINDOWS
   HANDLE            _event;
#endif
} CFHostRequest;

@interface __CFHost : NSObject {
   CFStringRef          _name;
   CFHostClientCallBack _callback;
   CFHostClientContext  _context;
   Boolean              _hasResolvedAddressing;
   CFArrayRef           _addressing;
   CFHostRequest       *_request;
#ifdef WINDOWS
   HANDLE                 _event;
   NSHandleMonitor_win32 *_monitor;
#endif
}

@end

@implementation __CFHost

#ifdef WINDOWS

typedef struct  {
   CRITICAL_SECTION queueLock;
   HANDLE           queueEvent;
   int              queueCapacity,queueCount;
   CFHostRequest  **queue;
} CFAddressResolverThreadInfo;

static int preXP_getaddrinfo(const char *host,const char *service,const struct addrinfo *hints,struct addrinfo **result){
   struct addrinfo *list=NULL;
   struct addrinfo *current=NULL;
   struct hostent  *hp;

   if((hp=gethostbyname(host))==NULL)
    return EAI_FAIL;
    
   switch(hp->h_addrtype){
       
    case AF_INET:;
     uint32_t **addr_list;
         
     addr_list=(uint32_t **)hp->h_addr_list;
     for(;*addr_list!=NULL;addr_list++){
      struct addrinfo    *node=NSZoneCalloc(NULL,1,sizeof(struct addrinfo));
      struct sockaddr_in *ipv4=NSZoneCalloc(NULL,1,sizeof(struct sockaddr_in));
      
      node->ai_family=AF_INET;
      node->ai_addrlen=sizeof(struct sockaddr_in);
      node->ai_addr=(struct sockaddr *)ipv4;
      ipv4->sin_family=AF_INET;
      ipv4->sin_addr.s_addr=**addr_list;
     
      if(list==NULL)
       list=current=node;
      else {
       current->ai_next=node;
       current=node;
      }
     }
     break;
   }
   
   *result=list;
   return 0;
}

static void preXP_freeaddrinfo(struct addrinfo *info){
   struct addrinfo *next;
   
   for(;info!=NULL;info=next){
    next=info->ai_next;
    NSZoneFree(NULL,info->ai_addr);
    NSZoneFree(NULL,info);
   }
}

static int any_getaddrinfo(const char *host,const char *service,const struct addrinfo *hints,struct addrinfo **result){
   HANDLE               library=LoadLibrary("WS2_32");
   typeof(getaddrinfo) *function=(typeof(getaddrinfo) *)GetProcAddress(library,"getaddrinfo");

   if(function==NULL){
    return preXP_getaddrinfo(host,service,hints,result);
   }
   else {
    return function(host,service,hints,result);
   }
}

static void any_freeaddrinfo(struct addrinfo *info){
   HANDLE              library=LoadLibrary("WS2_32");
   typeof(freeaddrinfo) *function=(typeof(freeaddrinfo) *)GetProcAddress(library,"freeaddrinfo");

   if(function==NULL){
    return preXP_freeaddrinfo(info);
   }
   else {
    return function(info);
   }
}

static struct addrinfo *blockingRequest(CFHostRequest *request){
   struct addrinfo *result;
   
   if(any_getaddrinfo(request->_name,NULL,NULL,&result)!=0)
    return NULL;
    
   return result;
}

static unsigned addressResolverThread(void *arg){
   CFAddressResolverThreadInfo *info=(CFAddressResolverThreadInfo *)arg;

   while(YES){
    Boolean queueEmpty;

    EnterCriticalSection(&(info->queueLock));
     queueEmpty=(info->queueCount==0)?TRUE:FALSE;
    LeaveCriticalSection(&(info->queueLock));
    
    if(queueEmpty){
     NSCooperativeThreadBlocking();
     WaitForSingleObject(info->queueEvent,INFINITE);
     NSCooperativeThreadWaiting();
    }
    
    CFHostRequest *request=NULL;
    
    EnterCriticalSection(&(info->queueLock));
 
    while(info->queueCount>0 && request==NULL){
     request=info->queue[0];
     
     info->queueCount--;

     int i;
     for(i=0;i<info->queueCount;i++)
      info->queue[i]=info->queue[i+1];
    }
    if(request!=NULL)
     request->_state=CFHostRequestInProgress;
     
    LeaveCriticalSection(&(info->queueLock));

    if(request!=NULL){     
     struct addrinfo *addressList=blockingRequest(request);

     HANDLE event=NULL;
     
     EnterCriticalSection(&(info->queueLock));
      request->_addressList=addressList;

      if(request->_state==CFHostRequestInProgress){
       request->_state=CFHostRequestDone;
       event=request->_event;
       request=NULL;
      }
     LeaveCriticalSection(&(info->queueLock));
    
     if(request!=NULL){
      if(request->_addressList!=NULL)
       any_freeaddrinfo(request->_addressList);
      NSZoneFree(NULL,request->_name);
      NSZoneFree(NULL,request);
     }

     if(event!=NULL){
      SetEvent(event);
     }
    }
   }
   return 0;
   
}

-(void)handleMonitorIndicatesSignaled:(NSHandleMonitor_win32 *)monitor {

   if(_request==NULL){
    // cancelled
    return;
   }
   
   CloseHandle(_request->_event);
   _request->_event=NULL;
   [_monitor invalidate];
   [_monitor setDelegate:nil];
   [_monitor autorelease];
   _monitor=nil;
   
   if(_addressing!=NULL){
    CFRelease(_addressing);
    _addressing=NULL;
   }
   if(_request->_addressList==NULL){
    if(NSDebugEnabled)
     NSLog(@"Host %@ did not resolve",_name);
   }
   else {
    int i;
    
    _addressing=CFArrayCreateMutable(NULL,0,&kCFTypeArrayCallBacks);
    
    struct addrinfo *check=_request->_addressList,*next;
    for(;check!=NULL;check=next){
     next=check->ai_next;
    
     CFDataRef data=CFDataCreate(NULL,(void *)check->ai_addr,check->ai_addrlen);

     CFArrayAppendValue(_addressing,data);
     CFRelease(data);
    }
   }
   if(_request->_addressList!=NULL)
    any_freeaddrinfo(_request->_addressList);
   NSZoneFree(NULL,_request->_name);
   NSZoneFree(NULL,_request);
   _request=NULL;
   
   if(_callback!=NULL)
    _callback(self,kCFHostAddresses,NULL,_context.info);
}

-(void)handleMonitorIndicatesAbandoned:(NSHandleMonitor_win32 *)monitor {
}

static pthread_mutex_t              asyncCreationLock=PTHREAD_MUTEX_INITIALIZER;
static CFAddressResolverThreadInfo *asyncInfo;

static CFAddressResolverThreadInfo *startResolverThreadIfNeeded(){
   pthread_mutex_lock(&asyncCreationLock);
  
  if(asyncInfo==NULL){
   asyncInfo=NSZoneMalloc(NULL,sizeof(CFAddressResolverThreadInfo));
   
   InitializeCriticalSection(&(asyncInfo->queueLock));
   asyncInfo->queueEvent=CreateEvent(NULL,FALSE,FALSE,NULL);
   
   asyncInfo->queueCapacity=1;
   asyncInfo->queueCount=0;
   asyncInfo->queue=NSZoneMalloc(NULL,sizeof(CFHostRequest *)*asyncInfo->queueCapacity);
         
   unsigned threadAddr;
    
   _beginthreadex(NULL,0,(void*)addressResolverThread,asyncInfo,0,&threadAddr);
  }
  pthread_mutex_unlock(&asyncCreationLock);
  
  return asyncInfo;
}

#if 1
#define SYNCHRONOUS 0
#else
#warning disable
#define SYNCHRONOUS 1
#endif

static void queueHostToAddressResolver(CFHostRef host){
    __CFHost *h = (__CFHost *)host;
    if(SYNCHRONOUS){
    int addressCount=0;
    struct addrinfo *addressList=blockingRequest(h->_request);

    h->_request->_state=CFHostRequestDone;
    h->_request->_addressList=addressList;

    SetEvent(h->_request->_event);
   }
   else {
   CFAddressResolverThreadInfo *info=startResolverThreadIfNeeded();

   EnterCriticalSection(&(info->queueLock));
   if(info->queueCount+1>=info->queueCapacity){
    info->queueCapacity*=2;
    info->queue=NSZoneRealloc(NULL,info->queue,sizeof(CFHostRequest *)*info->queueCapacity);
   }
   info->queue[info->queueCount++]=h->_request;
   LeaveCriticalSection(&(info->queueLock));
   
   SetEvent(info->queueEvent);
   }
}

static void cancelHostInAddressResolverIfNeeded(CFHostRef self){
    __CFHost *s = (__CFHost *)self;

   if(s->_request==NULL)
    return;
    
   if(SYNCHRONOUS){
   }
   else {
   CFAddressResolverThreadInfo *info;
   
   if((info=asyncInfo)==NULL)
    return;
    
   EnterCriticalSection(&(info->queueLock));
      
    if(s->_request->_state==CFHostRequestInProgress){
     s->_request->_state=CFHostRequestDeallocate;
     s->_request=NULL;
    }
    else {
     int i;
       
     for(i=0;i<info->queueCount;i++)
      if(info->queue[i]==s->_request){
       info->queueCount--;
       for(;i<info->queueCount;i++)
        info->queue[i]=info->queue[i+1];
       break;
      }
     }
      
   LeaveCriticalSection(&(info->queueLock));
   
   if(s->_request!=NULL){
    NSZoneFree(NULL,s->_request->_name);
    NSZoneFree(NULL,s->_request);
    s->_request=NULL;
   }
   }
}

#else
static void queueHostToAddressResolver(CFHostRef host){
}
static void cancelHostInAddressResolverIfNeeded(CFHostRef host){
}
#endif

CFTypeID CFHostGetTypeID() {
   NSUnimplementedFunction();
   return 0;
}

CFHostRef  CFHostCreateCopy(CFAllocatorRef alloc,CFHostRef self) {
   NSUnimplementedFunction();
   return 0;
}

CFHostRef  CFHostCreateWithAddress(CFAllocatorRef allocator,CFDataRef address) {
   NSUnimplementedFunction();
   return 0;
}

CFHostRef  CFHostCreateWithName(CFAllocatorRef allocator,CFStringRef name) {
    CFHostRef result=[__CFHost allocWithZone:NULL];

   ((__CFHost*)result)->_name=CFStringCreateCopy(allocator,name);
   
   return result;
}

-(void)dealloc {
   CFRelease(_name);
   if(self->_context.info!=NULL && self->_context.release!=NULL)
    self->_context.release(self->_context.info);
   CFRelease(_addressing);
#ifdef WINDOWS
   if(self->_event!=NULL)
    CloseHandle(self->_event);
   
   [self->_monitor setDelegate:nil];
   [self->_monitor invalidate];
   [self->_monitor release];
#endif
   [super dealloc];
}

CFArrayRef CFHostGetAddressing(CFHostRef self,Boolean *hasBeenResolved) {
   if(hasBeenResolved!=NULL)
    *hasBeenResolved=((__CFHost*)self)->_hasResolvedAddressing;

   return ((__CFHost*)self)->_addressing;
}

CFArrayRef CFHostGetNames(CFHostRef self,Boolean *hasBeenResolved) {
   NSUnimplementedFunction();
   return 0;
}

CFDataRef  CFHostGetReachability(CFHostRef self,Boolean *hasBeenResolved) {
   NSUnimplementedFunction();
   return 0;
}

Boolean    CFHostSetClient(CFHostRef self,CFHostClientCallBack callback,CFHostClientContext *context) {
    __CFHost *s = (__CFHost*)self;
    if(s->_context.info!=NULL && s->_context.release!=NULL)
    s->_context.release(s->_context.info);

   s->_callback=callback;
   if(context!=NULL)
    s->_context=*context;
   else {
    s->_context.version=0;
    s->_context.info=NULL;
    s->_context.retain=NULL;
    s->_context.release=NULL;
    s->_context.copyDescription=NULL;
   }

   if(s->_callback!=NULL){
    if(s->_context.info!=NULL && s->_context.retain!=NULL)
     s->_context.info=(void *)s->_context.retain(s->_context.info);
   }
   
   return TRUE;
}

static void CFHostCreateEventIfNeeded(CFHostRef self){
    __CFHost *s = (__CFHost*)self;
   if(s->_event==NULL){
    s->_event=CreateEvent(NULL,FALSE,FALSE,NULL);
    s->_monitor=[[NSHandleMonitor_win32 handleMonitorWithHandle:s->_event] retain];
    [s->_monitor setDelegate:s];
    [s->_monitor setCurrentActivity:Win32HandleSignaled];
   }
}

Boolean CFHostStartInfoResolution(CFHostRef self,CFHostInfoType infoType,CFStreamError *streamError) {
    __CFHost *s = (__CFHost*)self;

   switch(infoType){
   
    case kCFHostAddresses:
     if(s->_hasResolvedAddressing){
      NSLog(@"CFHostStartInfoResolution, addressing already resolved");
      return TRUE;
     }
     if(s->_callback!=NULL){
      if(s->_request!=NULL){
       NSLog(@"CFHostStartInfoResolution already started");
       return FALSE;
      }
      char *cStringName=NSZoneMalloc(NULL,MAXHOSTNAMELEN+1);

// this encoding is probably wrong but CFStringGetCString can do it
      if(!CFStringGetCString(s->_name,cStringName,MAXHOSTNAMELEN,kCFStringEncodingISOLatin1)){
        NSLog(@"CFStringGetCString failed for CFHostRef name %@",s->_name);
        NSZoneFree(NULL,cStringName);
        return FALSE;
      }
      
      s->_request=NSZoneMalloc(NULL,sizeof(CFHostRequest));
      s->_request->_state=CFHostRequestInQueue;
      s->_request->_name=cStringName;
      s->_request->_addressList=NULL;
      CFHostCreateEventIfNeeded(s);
      s->_request->_event=s->_event;

      queueHostToAddressResolver(s);
      return TRUE;
     }
     else {
      NSUnimplementedFunction();
      return FALSE;
     }
         
    case kCFHostNames:
     NSUnimplementedFunction();
     return FALSE;
     
    case kCFHostReachability:
     NSUnimplementedFunction();
     return FALSE;
     
    default:
     [NSException raise:NSInvalidArgumentException format:@"CFHostStartInfoResolution CFHostInfoType is not valid (%d)",infoType];
     return FALSE;
   }
}

void CFHostCancelInfoResolution(CFHostRef self,CFHostInfoType infoType) {
   switch(infoType){
   
    case kCFHostAddresses:
     cancelHostInAddressResolverIfNeeded(self);
     break;
     
    case kCFHostNames:
     NSUnimplementedFunction();
     break;
     
    case kCFHostReachability:
     NSUnimplementedFunction();
     break;
     
    default:
     [NSException raise:NSInvalidArgumentException format:@"CFHostCancelInfoResolution CFHostInfoType is not valid (%d)",infoType];
     break;
   }
}

void CFHostScheduleWithRunLoop(CFHostRef self,CFRunLoopRef runLoop,CFStringRef mode) {
   if(runLoop!=CFRunLoopGetCurrent())
    NSUnimplementedFunction();

   CFHostCreateEventIfNeeded(self);
   [(NSRunLoop *)runLoop addInputSource:((__CFHost *)self)->_monitor forMode:(NSString *)mode];
}

void CFHostUnscheduleFromRunLoop(CFHostRef self,CFRunLoopRef runLoop,CFStringRef mode) {
   if(runLoop!=CFRunLoopGetCurrent())
     NSUnimplementedFunction();

   [(NSRunLoop *)runLoop removeInputSource:((__CFHost *)self)->_monitor forMode:(NSString *)mode];
}

@end

