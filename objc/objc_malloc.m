#import "objc_malloc.h"

void *objc_malloc(size_t size) {
   return malloc(size);
}

void *objc_realloc(void *ptr,size_t size) {
   return realloc(ptr,size);
}

void *objc_calloc(size_t count,size_t size) {
   return calloc(count,size);
}

void  objc_free(void *ptr) {
   free(ptr);
}
