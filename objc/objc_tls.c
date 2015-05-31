#import "objc_tls.h"
#import <objc/objc_arc.h>
#import <pthread.h>

static void objc_tls_free(void *tls) {
}

static pthread_key_t objc_tls_key;

static void createKey() {
    pthread_key_create(&objc_tls_key, objc_tls_free);

    objc_tls *tls = calloc(1, sizeof(objc_tls));

    pthread_setspecific(objc_tls_key, tls);
}

objc_tls *objc_tlsCurrent() {
    static pthread_once_t createKeyOnce = PTHREAD_ONCE_INIT;

    pthread_once(&createKeyOnce, createKey);

    return pthread_getspecific(objc_tls_key);
}
