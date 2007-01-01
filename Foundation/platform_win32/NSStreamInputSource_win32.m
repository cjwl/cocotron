/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#if defined(WIN32)
#import <Foundation/NSStreamInputSource_win32.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>

typedef struct {
   unsigned   _max;
   fd_set    *_set;
} YRSelectSet;

YRSelectSet *YRSelectSetNew() {
   YRSelectSet *sset=NSZoneMalloc(NSDefaultMallocZone(),sizeof(YRSelectSet));

   sset->_max=FD_SETSIZE;

   sset->_set=NSZoneMalloc(NSDefaultMallocZone(),
         sizeof(u_int)+sizeof(SOCKET)*sset->_max);

   return sset;
}

void YRSelectSetDealloc(YRSelectSet *sset) {
   NSZoneFree(NSDefaultMallocZone(),sset->_set);
   NSZoneFree(NSDefaultMallocZone(),sset);
}

void YRSelectSetZero(YRSelectSet *sset) {
   sset->_set->fd_count=0;

}

void YRSelectSetClear(YRSelectSet *sset,SOCKET socket) {
   int  i;

   for(i=0;i<sset->_set->fd_count;i++){
    if(sset->_set->fd_array[i]==socket){
     sset->_set->fd_count--; 
     while(i<sset->_set->fd_count){
      sset->_set->fd_array[i]=sset->_set->fd_array[i+1];
      i++;
     } 
     break;
    } 
   } 

}

void YRSelectSetSet(YRSelectSet *sset,SOCKET socket) {
   if(sset->_set->fd_count>=sset->_max){
    sset->_max*=2;
    sset->_set=NSZoneRealloc(NSDefaultMallocZone(),sset->_set,
      sizeof(unsigned)+sizeof(SOCKET)*sset->_max);
   }
   sset->_set->fd_array[sset->_set->fd_count++]=socket;
}

BOOL YRSelectSetIsSet(YRSelectSet *sset,SOCKET socket) {
   int i;

   for(i=0;i<sset->_set->fd_count;i++)
    if(sset->_set->fd_array[i]==socket)
     return YES;

   return NO;
}

fd_set *YRSelectSetFDSet(YRSelectSet *sset) {
   return sset->_set;
}

NSString *YRSocketErrorStringFromCode(int code) {
   return [NSString stringWithFormat:@"code=%d",code];
}

NSString *YRSocketErrorString(void) {
   return YRSocketErrorStringFromCode(WSAGetLastError());
}

BOOL _YRSocketAssert(int r,int line,const char *file){
   if(r<0){
    NSLog(@"socket error %@ at %d in %s",YRSocketErrorString(),line,file);
    return YES;
   }
   return NO;
}
#define YRSocketAssert(call)    _YRSocketAssert(call,__LINE__,__FILE__)

@implementation NSStreamInputSource_win32

static HANDLE              eventHandle=NULL;
static NSHandleMonitor_win32 *eventMonitor=nil;
static NSMutableArray     *eventMonitorModes=nil;


static CRITICAL_SECTION   *threadLock=NULL;
static SOCKET threadPingRead;
static SOCKET threadPingWrite;
static volatile numMonitors=0,maxMonitors=FD_SETSIZE;
static volatile struct monitorStruct {
   SOCKET socket;
   unsigned       activity;
   unsigned       suspended;
} *monitors;

static WINAPI DWORD selectThread(LPVOID arg){
   YRSelectSet *readset,*writeset,*exceptset;
   int      i,nfds;
   unsigned activity;

   readset=YRSelectSetNew();
   writeset=YRSelectSetNew();
   exceptset=YRSelectSetNew();

   while(YES){
    BOOL setEvent;

    YRSelectSetZero(readset);
    YRSelectSetZero(writeset);
    YRSelectSetZero(exceptset);

    EnterCriticalSection (threadLock);
    nfds=0;
    for(i=0;i<numMonitors;i++){
     if(monitors[i].activity!= XYXSocketNoActivity){
      if(nfds<monitors[i].socket)
       nfds=monitors[i].socket;

      if(monitors[i].activity&XYXSocketReadableActivity)
       YRSelectSetSet(readset,monitors[i].socket);

      if(monitors[i].activity&XYXSocketWritableActivity)
       YRSelectSetSet(writeset,monitors[i].socket);

      if(monitors[i].activity&XYXSocketExceptionalActivity)
       YRSelectSetSet(exceptset,monitors[i].socket);
     }
    }
    LeaveCriticalSection (threadLock);
    nfds++;

    YRSelectSetSet(readset,threadPingRead);
    if(nfds<=threadPingRead)
     nfds=threadPingRead+1;

    if(select(nfds,YRSelectSetFDSet(readset),YRSelectSetFDSet(writeset), YRSelectSetFDSet(exceptset),NULL)<0)
     continue;

    if(YRSelectSetIsSet(readset,threadPingRead)){
     char buf[4096];

     recv(threadPingRead,buf,4096,0);
    }

    setEvent=NO;
    EnterCriticalSection(threadLock);
    for(i=0;i<numMonitors;i++){
     activity=XYXSocketNoActivity;

     if(monitors[i].socket==INVALID_SOCKET)
      continue;

     if(YRSelectSetIsSet(readset,monitors[i].socket))
      activity|=XYXSocketReadableActivity;
     if(YRSelectSetIsSet(writeset,monitors[i].socket))
      activity|=XYXSocketWritableActivity;
     if(YRSelectSetIsSet(exceptset,monitors[i].socket))
      activity|=XYXSocketExceptionalActivity;

     if(activity!=XYXSocketNoActivity){
      monitors[i].activity&=~activity;
      monitors[i].suspended|=activity;
      setEvent=YES;
     }
    }
    LeaveCriticalSection(threadLock);
    if(setEvent)
     SetEvent(eventHandle);
   }
}

static inline void byteZero(void *vsrc,int size){
   unsigned char *src=vsrc;
   int i;

   for(i=0;i<size;i++)
    src[i]=0;
}

static void createPingPair(int pair[2]){
   SOCKET readSocket,writeSocket;
   struct              sockaddr_in address;
   int                 namelen;

   YRSocketAssert(readSocket=socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP));
   YRSocketAssert(writeSocket=socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP));

   byteZero(&address,sizeof(struct sockaddr_in));
   address.sin_family=AF_INET;
   address.sin_addr.s_addr=inet_addr("127.0.0.1");
   address.sin_port=0;
   YRSocketAssert(bind(readSocket,(struct sockaddr *)&address,
                                         sizeof(struct sockaddr_in)));
   namelen=sizeof(address);
   YRSocketAssert (getsockname(readSocket,(struct sockaddr *)&address,&namelen));

   YRSocketAssert(connect(writeSocket,(struct sockaddr *)&address,
        sizeof(struct sockaddr_in)));

   pair[0]=readSocket;
   pair[1]=writeSocket;
}

+(void)initialize {
   if(threadLock==NULL){
    int pair[2];
    DWORD threadID;

    monitors=NSZoneMalloc(NSDefaultMallocZone(),
         sizeof(struct monitorStruct)*maxMonitors);

   threadLock=NSZoneMalloc([self zone],sizeof(CRITICAL_SECTION));
   InitializeCriticalSection(threadLock);

    createPingPair(pair);
    threadPingRead=pair[0];
    threadPingWrite=pair[1];

    eventHandle=CreateEvent(NULL,FALSE,FALSE,NULL);
    eventMonitor=[[NSHandleMonitor_win32 handleMonitorWithHandle:eventHandle] retain];
    [eventMonitor setDelegate:self];
    [eventMonitor setCurrentActivity:Win32HandleSignaled];
    eventMonitorModes=[NSMutableArray new];

    CreateThread(NULL,0,selectThread,0,0,& threadID);
   }
}

-(void)pingThread {
   YRSocketAssert(send(threadPingWrite," ",1,0));
}

+(void)handleMonitorIndicatesSignaled:(NSHandleMonitor_win32 *)monitor {
   // do nothing
}

-(unsigned)fileActivity {
   return _activity;
}

-(void)monitorFileActivity:(unsigned)activity {
   _activity=activity;

   EnterCriticalSection(threadLock);
    monitors[_index].activity=(activity&~monitors[_index].suspended);
   LeaveCriticalSection(threadLock);

   if(!_inHandler)
    [self pingThread];
}

-(void)ceaseMonitoringFileActivity {
   [self monitorFileActivity:0];
}

-(void)addActivityMode:(NSString *)mode {
   if(![eventMonitorModes containsObject:mode])
    [[NSRunLoop currentRunLoop] addInputSource:eventMonitor forMode:mode];

   [[NSRunLoop currentRunLoop] addInputSource:self forMode:mode];
}

-(void)removeActivityMode:(NSString *)mode {
   [[NSRunLoop currentRunLoop] removeInputSource:self forMode:mode];
}

-(void)setDelegate:(id)delegate {
   _delegate=delegate;
}

-(id)delegate {
   return _delegate;
}

+socketMonitorWithDescriptor:(SOCKET)descriptor {
   return [[[self alloc] initWithDescriptor:descriptor] autorelease];
}

-initWithDescriptor:(SOCKET)descriptor {
   [super init];
   _socket=descriptor;
   _delegate=nil;
   _activity=0;

   _inHandler=NO;

   EnterCriticalSection (threadLock);
    for(_index=0;_index<numMonitors;_index++)
     if(monitors[_index].socket==INVALID_SOCKET)
      break;

    if(_index==numMonitors){
     numMonitors++;
     if(numMonitors>=maxMonitors){
      maxMonitors*=2;
      monitors=NSZoneRealloc(NSDefaultMallocZone(),(void *)monitors,
       sizeof(struct monitorStruct)*maxMonitors);
     }
    }

    monitors[_index].socket=_socket;
    monitors[_index].activity=XYXSocketNoActivity;
    monitors[_index].suspended=XYXSocketNoActivity;
   LeaveCriticalSection(threadLock);

   return self;
}

-(void)dealloc {
   EnterCriticalSection(threadLock);
    if(_index==numMonitors-1)
     numMonitors--;
    else{
     monitors[_index].socket=INVALID_SOCKET;
     monitors[_index].activity=XYXSocketNoActivity;
     monitors[_index].suspended=XYXSocketNoActivity;
    }
   LeaveCriticalSection(threadLock);

   [super dealloc];
}

-(BOOL)canProcessImmediateInput {
   return YES;
}

-(NSDate *)limitDateForMode:(NSString *)mode {
   return [NSDate distantFuture];
}

-(BOOL)processInputImmediately {
   BOOL result=NO;
   int activity,delegateActivity;

   if(_inHandler)
    return NO;

   EnterCriticalSection(threadLock);
    activity=monitors[_index].suspended;
   LeaveCriticalSection(threadLock);

   delegateActivity=_activity&activity;

   if(delegateActivity!=0){
    result=YES;

    _inHandler=YES;

    if(delegateActivity&XYXSocketReadableActivity)
     [[self delegate] activityMonitorIndicatesReadable:self];
    delegateActivity=_activity&activity;
    if(delegateActivity&XYXSocketWritableActivity)
     [[self delegate] activityMonitorIndicatesWriteable:self];
    delegateActivity=_activity&activity;
    if(delegateActivity&XYXSocketExceptionalActivity)
     [[self delegate] activityMonitorIndicatesException:self];

    _inHandler=NO;
   }

   EnterCriticalSection(threadLock);
    monitors[_index].activity|=(activity&_activity);
    monitors[_index].suspended&=~activity;
   LeaveCriticalSection(threadLock);

   [self pingThread];

   return result;
}

@end
#endif
