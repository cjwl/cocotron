#import <objc/objc-class.h>

// the cache entry size must be a power of 2
typedef struct {
   intptr_t            offsetToNextEntry;
   struct objc_method *method;
} OBJCMethodCacheEntry;

#define OBJCMethodCacheNumberOfEntries 64
#define OBJCMethodCacheMask            ((OBJCMethodCacheNumberOfEntries-1)*sizeof(OBJCMethodCacheEntry))

typedef struct objc_cache {
   OBJCMethodCacheEntry table[OBJCMethodCacheNumberOfEntries];
} OBJCMethodCache;
