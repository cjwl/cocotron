
#ifdef WINDOWS
#ifndef PTHREAD_H
#define PTHREAD_H

#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(PTHREAD_INSIDE_BUILD)
#define PTHREAD_EXPORT extern "C" __declspec(dllexport)
#else
#define PTHREAD_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define PTHREAD_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(PTHREAD_INSIDE_BUILD)
#define PTHREAD_EXPORT __declspec(dllexport) extern
#else
#define PTHREAD_EXPORT __declspec(dllimport) extern
#endif
#else
#define PTHREAD_EXPORT extern
#endif

#endif

#import <stdint.h>
#import <time.h>
#import <sched.h>

#ifndef ETIMEDOUT
#define	ETIMEDOUT 60
#endif

struct timespec {
  time_t tv_sec;
  long   tv_nsec;
};

typedef void *pthread_t;
typedef uint32_t pthread_key_t;
typedef void *pthread_mutex_t;

typedef struct {
 pthread_mutex_t mutex;
 int  state;
} pthread_once_t;

typedef void *pthread_cond_t;
typedef void *pthread_condattr_t;
typedef void *pthread_attr_t;
typedef void *pthread_mutexattr_t;

#define PTHREAD_ONCE_INIT {0,0}
#define PTHREAD_MUTEX_INITIALIZER NULL

enum {
 PTHREAD_CREATE_JOINABLE = 0,
 PTHREAD_CREATE_DETACHED = 1
};

PTHREAD_EXPORT int pthread_key_create(pthread_key_t *key, void (*destructor)(void*));
PTHREAD_EXPORT int pthread_key_delete(pthread_key_t key);

PTHREAD_EXPORT int pthread_create(pthread_t *thread,const pthread_attr_t *attr,void *(*start_routine)(void *),void *arg);

PTHREAD_EXPORT pthread_t pthread_self(void);
PTHREAD_EXPORT int pthread_join(pthread_t thread, void **value_ptr);
PTHREAD_EXPORT int pthread_detach(pthread_t thread);
PTHREAD_EXPORT void *pthread_getw32threadhandle_np(pthread_t thread);
PTHREAD_EXPORT void pthread_exit(void *value_ptr);

PTHREAD_EXPORT int pthread_attr_init(pthread_attr_t *attr);
PTHREAD_EXPORT int pthread_attr_destroy(pthread_attr_t *attr);
PTHREAD_EXPORT int pthread_attr_getdetachstate(const pthread_attr_t *attr, int *detachstate);
PTHREAD_EXPORT int pthread_attr_setdetachstate(pthread_attr_t *attr, int detachstate);
                      
PTHREAD_EXPORT int pthread_getschedparam(pthread_t thread,int *policy,struct sched_param *scheduling);
PTHREAD_EXPORT int pthread_setschedparam(pthread_t thread,int policy,const struct sched_param *scheduling);

PTHREAD_EXPORT void *pthread_getspecific(pthread_key_t key);
PTHREAD_EXPORT int pthread_setspecific(pthread_key_t key, const void *value); 

PTHREAD_EXPORT int pthread_equal(pthread_t t1, pthread_t t2); 

PTHREAD_EXPORT int pthread_once(pthread_once_t *once,void (*function)(void));

PTHREAD_EXPORT int pthread_mutex_init(pthread_mutex_t *mutex,const pthread_mutexattr_t *attr);
PTHREAD_EXPORT int pthread_mutex_destroy(pthread_mutex_t *mutex);

PTHREAD_EXPORT int pthread_mutex_lock(volatile pthread_mutex_t *mutex);
PTHREAD_EXPORT int pthread_mutex_trylock(volatile pthread_mutex_t *mutex);
PTHREAD_EXPORT int pthread_mutex_unlock(volatile pthread_mutex_t *mutex);

PTHREAD_EXPORT int pthread_cond_init(pthread_cond_t *cond,const pthread_condattr_t *attr);
PTHREAD_EXPORT int pthread_cond_destroy(pthread_cond_t *cond);
PTHREAD_EXPORT int pthread_cond_signal(pthread_cond_t *cond);
PTHREAD_EXPORT int pthread_cond_wait(pthread_cond_t *cond,pthread_mutex_t *mutex);
PTHREAD_EXPORT int pthread_cond_timedwait(pthread_cond_t *cond,pthread_mutex_t *mutex,const struct timespec *abstime);
PTHREAD_EXPORT int pthread_cond_broadcast(pthread_cond_t *cond);

#endif
#endif
