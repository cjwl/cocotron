#ifdef WINDOWS
#import "pthread.h"
#import <windows.h>
#import <errno.h>

int pthread_mutex_init(pthread_mutex_t *mutex,const pthread_mutexattr_t *attr) {
   *mutex=PTHREAD_MUTEX_INITIALIZER;
   return 0;
}

int pthread_mutex_lock(pthread_mutex_t volatile *mutex) {
   while(InterlockedCompareExchange(mutex,1,0)==1){
    ;
   }
   return 0;
}

int pthread_mutex_trylock(pthread_mutex_t volatile *mutex) {
   if(InterlockedCompareExchange(mutex,1,0)==1)
    return EBUSY;
    
   return 0;
}

int pthread_mutex_unlock(pthread_mutex_t volatile *mutex) {
   InterlockedExchange(mutex,0);
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
#endif

