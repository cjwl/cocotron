#import <stdbool.h>
#include <unistd.h>

typedef unsigned int objc_lock;

static inline bool objc_lock_try(volatile objc_lock *__lock) {
    return __sync_bool_compare_and_swap(__lock, 0, 1);
}

static inline void objc_lock_lock(volatile objc_lock *__lock) {
    while(!__sync_bool_compare_and_swap(__lock, 0, 1)) {
#ifdef WIN32
        Sleep(0);
#else
        usleep(1);
#endif
    }
}

static inline void objc_lock_unlock(volatile objc_lock *__lock) {
    __sync_bool_compare_and_swap(__lock, 1, 0);
}
