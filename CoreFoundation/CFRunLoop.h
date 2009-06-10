/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFDate.h>

typedef struct __NSRunLoop         *CFRunLoopRef;
typedef struct __NSTimer           *CFRunLoopTimerRef;
typedef struct __NSInputSource   *CFRunLoopSourceRef;
typedef struct CFRunLoopObserver *CFRunLoopObserverRef;

enum {
   kCFRunLoopRunFinished     =1,
   kCFRunLoopRunStopped      =2,
   kCFRunLoopRunTimedOut     =3,
   kCFRunLoopRunHandledSource=4,
};

typedef enum {
   kCFRunLoopEntry        = (1<<0),
   kCFRunLoopBeforeTimers = (1<<1),
   kCFRunLoopBeforeSources= (1<<2),
   // skip <<3,4
   kCFRunLoopBeforeWaiting= (1<<5),
   kCFRunLoopAfterWaiting = (1<<6),
   kCFRunLoopExit         = (1<<7),
   kCFRunLoopAllActivities= 0xFFFFFFF
} CFRunLoopActivity;

COREFOUNDATION_EXPORT const CFStringRef kCFRunLoopCommonModes;

typedef void        (*CFRunLoopCancelCallBack)(void *info,CFRunLoopRef self,CFStringRef mode);
typedef Boolean     (*CFRunLoopEqualCallBack)(const void *info,const void *other);
typedef mach_port_t (*CFRunLoopGetPortCallBack)(void *info);
typedef CFHashCode  (*CFRunLoopHashCallBack)(const void *info);
typedef void       *(*CFRunLoopMachPerformCallBack)(void *msg,CFIndex size,CFAllocatorRef allocator,void *info);
typedef void        (*CFRunLoopPerformCallBack)(void *info);
typedef void        (*CFRunLoopScheduleCallBack)(void *info,CFRunLoopRef self,CFStringRef mode);

typedef struct  {
   CFIndex                            version;
   void                              *info;
   CFAllocatorRetainCallBack          retain;
   CFAllocatorReleaseCallBack         release;
   CFAllocatorCopyDescriptionCallBack copyDescription;
   CFRunLoopEqualCallBack             equal;
   CFRunLoopHashCallBack              hash;
   CFRunLoopScheduleCallBack          schedule;
   CFRunLoopCancelCallBack            cancel;
   CFRunLoopPerformCallBack           perform;
} CFRunLoopSourceContext;

typedef struct  {
   CFIndex                            version;
   void                              *info;
   CFAllocatorRetainCallBack          retain;
   CFAllocatorReleaseCallBack         release;
   CFAllocatorCopyDescriptionCallBack copyDescription;
   CFRunLoopEqualCallBack             equal;
   CFRunLoopHashCallBack              hash;
   CFRunLoopGetPortCallBack           getPort;
   CFRunLoopMachPerformCallBack       perform;
} CFRunLoopSourceContext1;

typedef struct  {
   CFIndex                            version;
   void                              *info;
   CFAllocatorRetainCallBack          retain;
   CFAllocatorReleaseCallBack         release;
   CFAllocatorCopyDescriptionCallBack copyDescription;
} CFRunLoopObserverContext;

typedef void (*CFRunLoopObserverCallBack)(CFRunLoopObserverRef self,CFRunLoopActivity activity,void *info);

CFTypeID       CFRunLoopGetTypeID(void);

CFRunLoopRef   CFRunLoopGetCurrent(void);
CFRunLoopRef   CFRunLoopGetMain(void);
void           CFRunLoopRun(void);

void           CFRunLoopAddCommonMode(CFRunLoopRef self,CFStringRef mode);

void           CFRunLoopAddObserver(CFRunLoopRef self,CFRunLoopObserverRef observer,CFStringRef mode);
void           CFRunLoopRemoveObserver(CFRunLoopRef self,CFRunLoopObserverRef observer,CFStringRef mode);
Boolean        CFRunLoopContainsObserver(CFRunLoopRef self,CFRunLoopObserverRef observer,CFStringRef mode);

void           CFRunLoopAddSource(CFRunLoopRef self,CFRunLoopSourceRef source,CFStringRef mode);
void           CFRunLoopRemoveSource(CFRunLoopRef self,CFRunLoopSourceRef source,CFStringRef mode);
Boolean        CFRunLoopContainsSource(CFRunLoopRef self,CFRunLoopSourceRef source,CFStringRef mode);

void           CFRunLoopAddTimer(CFRunLoopRef self,CFRunLoopTimerRef timer,CFStringRef mode);
void           CFRunLoopRemoveTimer(CFRunLoopRef self,CFRunLoopTimerRef timer,CFStringRef mode);
Boolean        CFRunLoopContainsTimer(CFRunLoopRef self,CFRunLoopTimerRef timer,CFStringRef mode);

CFStringRef    CFRunLoopCopyCurrentMode(CFRunLoopRef self);
CFArrayRef     CFRunLoopCopyAllModes(CFRunLoopRef self);

Boolean        CFRunLoopIsWaiting(CFRunLoopRef self);
CFAbsoluteTime CFRunLoopGetNextTimerFireDate(CFRunLoopRef self,CFStringRef mode);
CFInteger      CFRunLoopRunInMode(CFStringRef mode,CFTimeInterval seconds,Boolean returnAfterSourceHandled);
void           CFRunLoopStop(CFRunLoopRef self);
void           CFRunLoopWakeUp(CFRunLoopRef self);

// sources

CFTypeID           CFRunLoopSourceGetTypeID(void);

CFRunLoopSourceRef CFRunLoopSourceCreate(CFAllocatorRef allocator,CFIndex order,CFRunLoopSourceContext *context);

CFIndex            CFRunLoopSourceGetOrder(CFRunLoopSourceRef self);
void               CFRunLoopSourceGetContext(CFRunLoopSourceRef self,CFRunLoopSourceContext *context);

void               CFRunLoopSourceInvalidate(CFRunLoopSourceRef self);
Boolean            CFRunLoopSourceIsValid(CFRunLoopSourceRef self);

void               CFRunLoopSourceSignal(CFRunLoopSourceRef self);

// observers

CFTypeID             CFRunLoopObserverGetTypeID(void);

CFRunLoopObserverRef CFRunLoopObserverCreate(CFAllocatorRef allocator,CFOptionFlags activities,Boolean repeats,CFIndex order,CFRunLoopObserverCallBack callback,CFRunLoopObserverContext *context);

CFOptionFlags        CFRunLoopObserverGetActivities(CFRunLoopObserverRef self);
Boolean              CFRunLoopObserverDoesRepeat(CFRunLoopObserverRef self);
CFIndex              CFRunLoopObserverGetOrder(CFRunLoopObserverRef self);
void                 CFRunLoopObserverGetContext(CFRunLoopObserverRef self,CFRunLoopObserverContext *context);

void                 CFRunLoopObserverInvalidate(CFRunLoopObserverRef self);
Boolean              CFRunLoopObserverIsValid(CFRunLoopObserverRef self);

