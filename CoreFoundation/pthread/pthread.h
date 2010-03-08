
#ifdef WINDOWS
#ifndef PTHREAD_H
#define PTHREAD_H

#import <stdint.h>
#import <CoreFoundation/CFBase.h>

typedef void *pthread_t;
typedef uint32_t pthread_key_t;
typedef long pthread_mutex_t;

typedef struct {
 pthread_mutex_t mutex;
 int  state;
} pthread_once_t;

typedef void *pthread_cond_t;
typedef void *pthread_condattr_t;
typedef void *pthread_attr_t;
typedef void *pthread_mutexattr_t;

#define PTHREAD_ONCE_INIT {0,0}
#define PTHREAD_MUTEX_INITIALIZER 0

COREFOUNDATION_EXPORT int pthread_key_create(pthread_key_t *key, void (*destructor)(void*));
COREFOUNDATION_EXPORT int pthread_key_delete(pthread_key_t key);

COREFOUNDATION_EXPORT int pthread_create(pthread_t *thread,const pthread_attr_t *attr,void *(*start_routine)(void *),void *arg);
COREFOUNDATION_EXPORT pthread_t pthread_self(void);
COREFOUNDATION_EXPORT void *pthread_getw32threadhandle_np(pthread_t thread);


COREFOUNDATION_EXPORT void *pthread_getspecific(pthread_key_t key);
COREFOUNDATION_EXPORT int pthread_setspecific(pthread_key_t key, const void *value); 

COREFOUNDATION_EXPORT int pthread_equal(pthread_t t1, pthread_t t2); 

COREFOUNDATION_EXPORT int pthread_once(pthread_once_t *once,void (*function)(void));

COREFOUNDATION_EXPORT int pthread_mutex_init(pthread_mutex_t *mutex,const pthread_mutexattr_t *attr);

COREFOUNDATION_EXPORT int pthread_mutex_lock(volatile pthread_mutex_t *mutex);
COREFOUNDATION_EXPORT int pthread_mutex_trylock(volatile pthread_mutex_t *mutex);
COREFOUNDATION_EXPORT int pthread_mutex_unlock(volatile pthread_mutex_t *mutex);

COREFOUNDATION_EXPORT int pthread_cond_init(pthread_cond_t *cond,const pthread_condattr_t *attr);
COREFOUNDATION_EXPORT int pthread_cond_signal(pthread_cond_t *cond);
COREFOUNDATION_EXPORT int pthread_cond_wait(pthread_cond_t *cond,pthread_mutex_t *mutex);

#endif
#endif
