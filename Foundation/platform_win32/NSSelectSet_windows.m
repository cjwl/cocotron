/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSSelectSet_windows.h"
#import "NSSocket_windows.h"
#import <Foundation/NSHandleMonitor_win32.h>
#import <Foundation/NSError.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNotificationCenter.h>

#import <malloc.h>

@implementation NSSelectSet(windows)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([NSSelectSet_windows class],0,NULL);
}

@end

@implementation NSSelectSet_windows

typedef struct {
   unsigned   max;
   fd_set    *fdset;
} native_set;

native_set *native_set_new() {
   native_set *native=NSZoneMalloc(NULL,sizeof(native_set));

   native->max=FD_SETSIZE;

   native->fdset=NSZoneMalloc(NULL,sizeof(fd_set));

   return native;
}

void native_set_free(native_set *native){
   NSZoneFree(NULL,native->fdset);
   NSZoneFree(NULL,native);
}

void native_set_reset(native_set *native) {
   native->fdset->fd_count=0;
}

void native_set_set(native_set *native,SOCKET socket) {
   if(native->fdset->fd_count>=native->max){
    native->max*=2;
    native->fdset=NSZoneRealloc(NULL,native->fdset,sizeof(fd_set)+sizeof(SOCKET)*(native->max-FD_SETSIZE));
   }
   native->fdset->fd_array[native->fdset->fd_count++]=socket;
}

void native_set_clear(native_set *native,SOCKET socket){
   int  i;

   for(i=0;i<native->fdset->fd_count;i++){
    if(native->fdset->fd_array[i]==socket){
     native->fdset->fd_count--; 
     while(i<native->fdset->fd_count){
      native->fdset->fd_array[i]=native->fdset->fd_array[i+1];
      i++;
     } 
     break;
    }
   }
}

void native_set_copy(native_set *native,native_set *copy){
   int i;
   
   while(copy->max<native->fdset->fd_count){
    copy->max*=2;
    copy->fdset=NSZoneRealloc(NULL,copy->fdset,sizeof(fd_set)+sizeof(SOCKET)*(copy->max-FD_SETSIZE));
   }
   
   for(i=0;i<native->fdset->fd_count;i++)
    copy->fdset->fd_array[i]=native->fdset->fd_array[i];
    
   copy->fdset->fd_count=i;
}

BOOL native_set_is_set(native_set *native,SOCKET socket) {
   int i;

   for(i=0;i<native->fdset->fd_count;i++)
    if(native->fdset->fd_array[i]==socket)
     return YES;

   return NO;
}


BOOL native_set_merge(native_set *native,native_set *merge){
   int i;
   
   for(i=0;i<native->fdset->fd_count;i++){
    SOCKET check=native->fdset->fd_array[i];
    
    if(!native_set_is_set(merge,check))
     native_set_set(merge,check);
   }
   return (i>0)?YES:NO;
}

void native_set_remove(native_set *native,native_set *remove){
   int i;
   
   for(i=0;i<native->fdset->fd_count;i++)
    native_set_clear(remove,native->fdset->fd_array[i]);
}

struct NSSelectSetBackgroundInfo {
   HANDLE                 eventHandle;
   NSHandleMonitor_win32 *eventMonitor;
   NSMutableArray        *eventMonitorModes;
   
   NSSocket_windows *pingRead;
   NSSocket_windows *pingWrite;
   
   SOCKET pingReadHandle;
   SOCKET pingWriteHandle;
   
   CRITICAL_SECTION *lock;
   
   native_set       *inputRead;
   native_set       *inputWrite;
   native_set       *inputExcept;

   native_set       *outputRead;
   native_set       *outputWrite;
   native_set       *outputExcept;
   native_set       *outputError;
};

static WINAPI DWORD selectThread(LPVOID arg){
   struct NSSelectSetBackgroundInfo *async=arg;
   native_set *activeRead;
   native_set *activeWrite;
   native_set *activeExcept;
   native_set *checkForErrors;
   native_set *gotErrors;
   
   activeRead=native_set_new();
   activeWrite=native_set_new();
   activeExcept=native_set_new();
   checkForErrors=native_set_new();
   gotErrors=native_set_new();
   
   while(YES){
    BOOL setEvent;
    
    EnterCriticalSection(async->lock);
    native_set_copy(async->inputRead,activeRead);
    native_set_copy(async->inputWrite,activeWrite);
    native_set_copy(async->inputExcept,activeExcept);

    native_set_copy(async->inputRead,checkForErrors);
    native_set_merge(async->inputWrite,checkForErrors);
    native_set_merge(async->inputExcept,checkForErrors);
    LeaveCriticalSection(async->lock);

    native_set_set(activeRead,async->pingReadHandle);
    
    setEvent=NO;
    if(select(42,activeRead->fdset,activeWrite->fdset,activeExcept->fdset,NULL)<0){
     int i;
     
     native_set_reset(gotErrors);
     
     for(i=0;i<checkForErrors->fdset->fd_count;i++){
      SOCKET check=checkForErrors->fdset->fd_array[i];
      int    ignore,ignoreLen=sizeof(ignore);
      
      if(getsockopt(check,IPPROTO_TCP,SO_TYPE,(void *)&ignore,&ignoreLen)<0)
       native_set_set(gotErrors,check);
     }
     
     EnterCriticalSection(async->lock);
     if(native_set_merge(gotErrors,async->outputError))
      setEvent=YES;
     native_set_remove(gotErrors,async->inputRead);
     native_set_remove(gotErrors,async->inputWrite);
     native_set_remove(gotErrors,async->inputExcept);
     LeaveCriticalSection(async->lock);
    }
    else {
     if(native_set_is_set(activeRead,async->pingReadHandle)){
      char buf[256];
     
      recv(async->pingReadHandle,buf,256,0);
     }
    
     EnterCriticalSection(async->lock);
     if(native_set_merge(activeRead,async->outputRead))
      setEvent=YES;
     if(native_set_merge(activeWrite,async->outputWrite))
      setEvent=YES;
     if(native_set_merge(activeExcept,async->outputExcept))
      setEvent=YES;

     native_set_remove(activeRead,async->inputRead);
     native_set_remove(activeWrite,async->inputWrite);
     native_set_remove(activeExcept,async->inputExcept);
     LeaveCriticalSection(async->lock);
    }
    
    if(setEvent)
     SetEvent(async->eventHandle);
   }
   return 0;
}

// one per thread at some point
static struct NSSelectSetBackgroundInfo *_async=NULL;

static void transferSetToNative(NSSet *set,native_set *native){
   NSEnumerator     *state=[set objectEnumerator];
   NSSocket_windows *socket;
   
   while((socket=[state nextObject])!=nil)
    native_set_set(native,[socket socketHandle]);
}

static void transferNativeToSet(native_set *native,NSMutableSet *set){
   int i;
   
   for(i=0;i<native->fdset->fd_count;i++)
    [set addObject:[[[NSSocket_windows alloc] initWithSocketHandle:native->fdset->fd_array[i]] autorelease]];
}

static void transferNativeToSetWithOriginals(native_set *native,NSMutableSet *set,NSSet *original,NSSocket_windows *cheater){
   int i;
   
   for(i=0;i<native->fdset->fd_count;i++){
    [cheater setSocketHandle:native->fdset->fd_array[i]];
    [set addObject:[original member:cheater]];
   }
}


+(void)handleMonitorIndicatesSignaled:(NSHandleMonitor_win32 *)monitor {
   NSSelectSet_windows *outputSet=[[[NSSelectSet alloc] init] autorelease];

   EnterCriticalSection(_async->lock);
   transferNativeToSet(_async->outputRead,outputSet->_readSet);
   transferNativeToSet(_async->outputWrite,outputSet->_writeSet);
   transferNativeToSet(_async->outputExcept,outputSet->_exceptionSet);
   LeaveCriticalSection(_async->lock);
   
   [[NSNotificationCenter defaultCenter] postNotificationName:NSSelectSetOutputNotification object:outputSet];
}

+(void)initBackgroundInfo {
   _async=NSZoneMalloc([self zone],sizeof(struct NSSelectSetBackgroundInfo));
   
   _async->eventHandle=CreateEvent(NULL,FALSE,FALSE,NULL);
   _async->eventMonitor=[[NSHandleMonitor_win32 handleMonitorWithHandle:_async->eventHandle] retain];
   [_async->eventMonitor setDelegate:self];
   [_async->eventMonitor setCurrentActivity:Win32HandleSignaled];
   _async->eventMonitorModes=[NSMutableArray new];

   _async->pingWrite=[[NSSocket alloc] initConnectedToSocket:&_async->pingRead];
   [_async->pingRead retain];
      
   _async->lock=NSZoneMalloc([self zone],sizeof(CRITICAL_SECTION));
   InitializeCriticalSection(_async->lock);
   
   _async->inputRead=native_set_new();
   _async->inputWrite=native_set_new();
   _async->inputExcept=native_set_new();

   _async->outputRead=native_set_new();
   _async->outputWrite=native_set_new();
   _async->outputExcept=native_set_new();
   _async->outputError=native_set_new();
}

-(void)waitInBackground {
   BOOL pingElseThread=YES;
   
   if([self isEmpty])
    return;
    
   if(_async==NULL){

    pingElseThread=NO;
    [isa initBackgroundInfo];
   }
   
   EnterCriticalSection(_async->lock);
   native_set_reset(_async->inputRead);
   native_set_reset(_async->inputWrite);
   native_set_reset(_async->inputExcept);
   
   transferSetToNative(_readSet,_async->inputRead);
   transferSetToNative(_writeSet,_async->inputWrite);
   transferSetToNative(_exceptionSet,_async->inputExcept);

   native_set_reset(_async->outputRead);
   native_set_reset(_async->outputWrite);
   native_set_reset(_async->outputExcept);
   native_set_reset(_async->outputError);
   LeaveCriticalSection(_async->lock);

   if(pingElseThread){
    unsigned char one[1]={ 42 };
   
    [_async->pingWrite write:one maxLength:1];
   }
   else {
    DWORD threadID;
    
    CreateThread(NULL,0,selectThread,_async,0,&threadID);
   }
}

-(NSError *)waitForSelectWithOutputSet:(NSSelectSet **)outputSetX beforeDate:(NSDate *)beforeDate {
   NSError          *result=nil;
   NSSocket_windows *cheater=[NSSocket_windows socketWithSocketHandle:0];
   NSTimeInterval    interval=[beforeDate timeIntervalSinceNow];
   native_set       *activeRead=native_set_new();
   native_set       *activeWrite=native_set_new();
   native_set       *activeExcept=native_set_new();
   struct timeval    timeval;

   transferSetToNative(_readSet,activeRead);
   transferSetToNative(_writeSet,activeWrite);
   transferSetToNative(_exceptionSet,activeExcept);
   
   if(interval>1000000)
    interval=1000000;
   if(interval<0)
    interval=0;

   timeval.tv_sec=interval;
   interval-=timeval.tv_sec;
   timeval.tv_usec=interval*1000;
 
   if(select(42,activeRead->fdset,activeWrite->fdset,activeExcept->fdset,&timeval)<0)
    result=[NSError errorWithDomain:NSWINSOCKErrorDomain code:WSAGetLastError() userInfo:nil];
    
   if(result==nil) {
    NSSelectSet_windows *outputSet=[[[NSSelectSet alloc] init] autorelease];

    transferNativeToSetWithOriginals(activeRead,outputSet->_readSet,_readSet,cheater);
    transferNativeToSetWithOriginals(activeWrite,outputSet->_writeSet,_writeSet,cheater);
    transferNativeToSetWithOriginals(activeExcept,outputSet->_exceptionSet,_exceptionSet,cheater);
   
    *outputSetX=outputSet;
   }
   
   native_set_free(activeRead);
   native_set_free(activeWrite);
   native_set_free(activeExcept);

   return result;
}

@end
