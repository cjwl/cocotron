#ifdef WINDOWS
#import "pthread.h"
#import <windows.h>
#import <process.h>
#import <errno.h>

int sched_yield(void) {
   SwitchToThread();
   return 0;
}

int sched_get_priority_min(int policy) {
   return 0;
}

int sched_get_priority_max(int policy) {
   return 100;
}

int pthread_getschedparam(pthread_t thread,int *policy,struct sched_param *scheduling) {
   return 0;
}

int pthread_setschedparam(pthread_t thread,int policy,const struct sched_param *scheduling) {
   return 0;
}

pthread_t pthread_self(void) {
   return NULL;
}

static void pthread_mutex_init_win32(pthread_mutex_t volatile *mutex)
{
   LPCRITICAL_SECTION *pcs = (LPCRITICAL_SECTION *)mutex;
   *pcs = (LPCRITICAL_SECTION) malloc(sizeof(CRITICAL_SECTION));
   InitializeCriticalSection(*pcs);
}

int pthread_mutex_init(pthread_mutex_t *mutex,const pthread_mutexattr_t *attr)
{
   if ( !mutex) return EINVAL;
    pthread_mutex_init_win32(mutex);
   return 0;
}

int pthread_mutex_destroy(pthread_mutex_t *mutex)
{
   LPCRITICAL_SECTION *pcs = (LPCRITICAL_SECTION *)mutex;
   if (pcs && *pcs) {
    DeleteCriticalSection(*pcs);
    free(*pcs);
   }
   return 0;
}

int pthread_mutex_lock(pthread_mutex_t volatile *mutex)
{
   if ( !mutex) return EINVAL;
   if (*mutex == NULL) pthread_mutex_init_win32(mutex);
   
   LPCRITICAL_SECTION *pcs = (LPCRITICAL_SECTION *)mutex;   
   EnterCriticalSection(*pcs);
   return 0;
}

int pthread_mutex_trylock(pthread_mutex_t volatile *mutex)
{
   if ( !mutex) return EINVAL;
   if (*mutex == NULL) pthread_mutex_init_win32(mutex);
   
   LPCRITICAL_SECTION *pcs = (LPCRITICAL_SECTION *)mutex;
   if (TryEnterCriticalSection(*pcs) == 0)
    return EBUSY;
   return 0;
}

int pthread_mutex_unlock(pthread_mutex_t volatile *mutex)
{
   if ( !mutex) return EINVAL;
   LPCRITICAL_SECTION *pcs = (LPCRITICAL_SECTION *)mutex;
   LeaveCriticalSection(*pcs);
   return 0;
}


int pthread_once(pthread_once_t *once,void (*function)(void)) {
   pthread_mutex_lock(&(once->mutex));
   if(once->state==0){
    function();
    once->state=1;
   }
   pthread_mutex_unlock(&(once->mutex));
   return 0;
}

void *pthread_getspecific(pthread_key_t key) {
   if(key==TLS_OUT_OF_INDEXES)
    return NULL;
    
   void *result=TlsGetValue(key);
   if(result==NULL){
    if(GetLastError()==0)
        ; // no error
    else
        ; // error
   }
   return result;
}

int pthread_setspecific(pthread_key_t key, const void *value) {

   if(TlsSetValue(key,(void *)value)==0){
    return EINVAL;
   }
   
   return 0;
}

int pthread_key_create(pthread_key_t *key,void (*destructor)(void*)) {
// FIXME: implement destructor
   if((*key=TlsAlloc())==TLS_OUT_OF_INDEXES)
    return EAGAIN;
    
   return 0;
}


enum {
    condEvent_signal = 0,
    condEvent_broadcast = 1,
    condEventCount = 2
};

typedef struct pthread_cond_impl_win32 {
	volatile LONG waitersCount;
	HANDLE events[condEventCount];
} pthread_cond_impl;

int pthread_cond_init(pthread_cond_t *cond,const pthread_condattr_t *attr)
{
    if ( !cond) return EINVAL;
    pthread_cond_impl *impl = (pthread_cond_impl *) calloc(1, sizeof(pthread_cond_impl));
    
    impl->events[condEvent_signal] = CreateEvent(0, FALSE, FALSE, 0);
    impl->events[condEvent_broadcast] = CreateEvent(0, TRUE, FALSE, 0);
    
    *cond = impl;
    return 0;
}

int pthread_cond_destroy(pthread_cond_t *cond)
{
    if ( !cond) return EINVAL;
    pthread_cond_impl *impl = *((pthread_cond_impl **)cond);
    
    CloseHandle(impl->events[condEvent_signal]);
    CloseHandle(impl->events[condEvent_broadcast]);
    
    free(impl);
    *cond = NULL;
    return 0;
}

int pthread_cond_signal(pthread_cond_t *cond)
{
    if ( !cond) return EINVAL;
    pthread_cond_impl *impl = *((pthread_cond_impl **)cond);
    if ( !impl) return EINVAL;
    
    _Bool haveWaiters = impl->waitersCount > 0;
	
	if (haveWaiters) SetEvent(impl->events[condEvent_signal]);
    
    return 0;
}

int pthread_cond_broadcast(pthread_cond_t *cond)
{
    if ( !cond) return EINVAL;
    pthread_cond_impl *impl = *((pthread_cond_impl **)cond);
    if ( !impl) return EINVAL;
    
    _Bool haveWaiters = impl->waitersCount > 0;
	
	if (haveWaiters) SetEvent(impl->events[condEvent_broadcast]);

    return 0;
}


// struct timespec is expressed in Unix epoch (seconds from 1970-01-01);
// win32 FILETIME is expressed in units of 100 nanoseconds from 1601-01-01.
//
#define UNIX_EPOCH_START_AS_FILETIME  116444736000000000LL

static inline void timespec_to_filetime(struct timespec *ts, FILETIME *ft)
{
    LONGLONG ftime = ts->tv_sec*10000000 + (ts->tv_nsec + 50)/100 + UNIX_EPOCH_START_AS_FILETIME;
    *((LONGLONG *)ft) = ftime;
}

static inline void filetime_to_timespec(FILETIME *ft, struct timespec *ts)
{
    LONGLONG ftime = *((LONGLONG *)ft);
    ftime -= UNIX_EPOCH_START_AS_FILETIME;
    
    ts->tv_sec = (int)(ftime / 10000000);    
    ts->tv_nsec = (int)((ftime - (LONGLONG)ts->tv_sec*10000000LL) * 100);
}

static inline DWORD abstime_to_win32_millisec_timeout(const struct timespec *abstime)
{
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    
    struct timespec curtime;
    filetime_to_timespec(&ft, &curtime);
    
    double t0 = (double)curtime.tv_sec + ((double)curtime.tv_nsec / 1000000000.0);
    double t1 = (double)abstime->tv_sec + ((double)abstime->tv_nsec / 1000000000.0);

    if (t1 <= t0) return 0;
    
    return (DWORD)((t1 - t0) * 1000.0);
}


static int impl_win32_cond_wait(pthread_cond_t *cond,pthread_mutex_t *mutex,const struct timespec *abstime)
{
    if ( !cond) return EINVAL;
    pthread_cond_impl *impl = *((pthread_cond_impl **)cond);
    if ( !impl) return EINVAL;
    
    DWORD timeout = INFINITE;
    if (abstime) {
        timeout = abstime_to_win32_millisec_timeout(abstime);
    }
    
	InterlockedIncrement(&impl->waitersCount);
	
    pthread_mutex_unlock(mutex);
    
	int result = WaitForMultipleObjects(condEventCount, impl->events, FALSE, timeout);
    
	LONG newWaitersCount = InterlockedDecrement(&impl->waitersCount);
    _Bool lastWaiter = (result != WAIT_TIMEOUT) && (result == WAIT_OBJECT_0 + condEvent_broadcast) && (0 == newWaitersCount);
	
	if (lastWaiter) ResetEvent(impl->events[condEvent_broadcast]);
	
	pthread_mutex_lock(mutex);
    
    return (result == WAIT_TIMEOUT) ? ETIMEDOUT : 0;
}

int pthread_cond_wait(pthread_cond_t *cond,pthread_mutex_t *mutex)
{
    return impl_win32_cond_wait(cond, mutex, NULL);
}

int pthread_cond_timedwait(pthread_cond_t *cond,pthread_mutex_t *mutex,const struct timespec *abstime)
{
    if ( !abstime) return EINVAL;
    
    return impl_win32_cond_wait(cond, mutex, abstime);
}


typedef struct pthread_attr_impl_win32 {
    int detachstate;
} pthread_attr_impl;

int pthread_attr_init(pthread_attr_t *attr)
{
    if ( !attr) return EINVAL;
    pthread_attr_impl *impl = (pthread_attr_impl *) calloc(1, sizeof(pthread_attr_impl));
    *attr = impl;
    return 0;
}

int pthread_attr_destroy(pthread_attr_t *attr)
{
    pthread_attr_impl *impl = *((pthread_attr_impl **)attr);
    free(impl);
    *attr = NULL;
    return 0;
}

int pthread_attr_getdetachstate(const pthread_attr_t *attr, int *detachstate)
{
    if ( !attr || !detachstate) return EINVAL;
    pthread_attr_impl *impl = *((pthread_attr_impl **)attr);
    if ( !impl) return EINVAL;
    
    *detachstate = impl->detachstate;
    return 0;
}

int pthread_attr_setdetachstate(pthread_attr_t *attr, int detachstate)
{
    if ( !attr || !detachstate) return EINVAL;
    pthread_attr_impl *impl = *((pthread_attr_impl **)attr);
    if ( !impl) return EINVAL;
    
    impl->detachstate = detachstate;
    return 0;
}


typedef struct pthread_impl_win32 {
    uint32_t threadId;
    HANDLE win32Handle;
} pthread_impl;

typedef struct pthread_start_routine_args_win32 {
    void *(*pthreadStyleFunc)(void *);
    void *arg;
} pthread_start_routine_args;

unsigned __stdcall startroutine_thunk_for_win32_beginthreadex(void *arg)
{
    pthread_start_routine_args *threadArgs = (pthread_start_routine_args *)arg;
    
    threadArgs->pthreadStyleFunc(threadArgs->arg);
    
    free(threadArgs);
    return 0;
}

int pthread_create(pthread_t *thread,const pthread_attr_t *attr,void *(*start_routine)(void *),void *arg)
{
    if ( !thread) return EINVAL;
    
    // Win32 requires that a thread's start function uses the stdcall calling convention,
    // so we need a thunk to wrap the given start_routine. this object holds the function and its arguments.
    // the thread thunk function will release this object when the real start_routine finishes.
    pthread_start_routine_args *threadArgs = (pthread_start_routine_args *) malloc(sizeof(pthread_start_routine_args));
    threadArgs->pthreadStyleFunc = start_routine;
    threadArgs->arg = arg;

    uint32_t threadId = 0;
    HANDLE win32Handle = (HANDLE)_beginthreadex(NULL, 0, startroutine_thunk_for_win32_beginthreadex, threadArgs, 0, &threadId);
    if (!win32Handle) {
        free(threadArgs);
        return EAGAIN;
	}
    
    pthread_impl *impl = (pthread_impl *) calloc(1, sizeof(pthread_impl));
    impl->threadId = threadId;
    impl->win32Handle = win32Handle;
    
    *thread = impl;
    return 0;
}

void pthread_exit(void *value_ptr)
{
}

void *pthread_getw32threadhandle_np(pthread_t thread)
{
    if ( !thread) return NULL;
    pthread_impl *impl = (pthread_impl *)thread;
    return impl->win32Handle;
}

int pthread_join(pthread_t thread, void **value_ptr)
{
    if ( !thread) return EINVAL;
    pthread_impl *impl = (pthread_impl *)thread;
    
    if ( !impl->win32Handle) return 0;
    
    WaitForSingleObject(impl->win32Handle, INFINITE);
    
    CloseHandle(impl->win32Handle);
    impl->win32Handle = NULL;
    
    return 0;
}

int pthread_detach(pthread_t thread)
{
    if ( !thread) return EINVAL;
    pthread_impl *impl = (pthread_impl *)thread;
    
    if ( !impl->win32Handle) return 0;
    
    CloseHandle(impl->win32Handle);
    impl->win32Handle = NULL;
    
    return 0;
}

#endif

