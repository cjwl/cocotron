#import <objc/runtime.h>
#import "objc_tls.h"
#import "objc_lock.h"
#import <objc/message.h>
#import <pthread.h>

typedef unsigned long objc_uinteger;
typedef signed long objc_integer;

typedef struct RefCountBucket {
    struct RefCountBucket *next;
    void *object;
    objc_uinteger count;
} RefCountBucket;

typedef struct {
    objc_uinteger count;
    objc_uinteger nBuckets;
    RefCountBucket **buckets;
} RefCountTable;

static objc_lock RefCountLock = 0;

static inline RefCountTable *CreateRefCountTable() {
    RefCountTable *table;

    table = malloc(sizeof(RefCountTable));
    table->count = 0;
    table->nBuckets = 1024;
    table->buckets = calloc(table->nBuckets, sizeof(RefCountBucket *));

    return table;
}

static inline RefCountBucket *AllocBucketFromTable(RefCountTable *table) {
    return malloc(sizeof(RefCountBucket));
}

static inline void FreeBucketFromTable(RefCountTable *table, RefCountBucket *bucket) {
    free(bucket);
}

static inline objc_uinteger hashObject(id ptr) {
    return (objc_uinteger)ptr >> 4;
}

static inline RefCountBucket *XXHashGet(RefCountTable *table, id object) {
    objc_uinteger i = hashObject(object) % table->nBuckets;
    RefCountBucket *check;

    for(check = table->buckets[i]; check != NULL; check = check->next)
        if(check->object == object)
            return check;

    return NULL;
}

static inline void XXHashInsert(RefCountTable *table, RefCountBucket *insert) {
    objc_uinteger hash = hashObject(insert->object);
    objc_uinteger i = hash % table->nBuckets;

    if(table->count >= table->nBuckets) {
        objc_integer oldnBuckets = table->nBuckets;
        RefCountBucket **buckets = table->buckets;

        table->nBuckets = oldnBuckets * 2;
        table->buckets = calloc(table->nBuckets, sizeof(RefCountBucket *));
        for(i = 0; i < oldnBuckets; i++) {
            RefCountBucket *check, *next;

            for(check = buckets[i]; check != NULL; check = next) {
                objc_uinteger newi = hashObject(check->object) % table->nBuckets;
                next = check->next;
                check->next = table->buckets[newi];
                table->buckets[newi] = check;
            }
        }
        free(buckets);
        i = hash % table->nBuckets;
    }

    insert->next = table->buckets[i];
    table->buckets[i] = insert;
    table->count++;
}

static inline void XXHashRemove(RefCountTable *table, RefCountBucket *remove) {
    objc_uinteger i = hashObject(remove->object) % table->nBuckets;
    RefCountBucket *check = table->buckets[i], *prev = check;

    for(; check != NULL; check = check->next) {
        if(check == remove) {
            if(prev == check)
                table->buckets[i] = check->next;
            else
                prev->next = check->next;

            FreeBucketFromTable(table, check);
            table->count--;
            return;
        }
        prev = check;
    }
}

static inline RefCountTable *refTable(void) {
    static RefCountTable *refCountTable = NULL;

    if(refCountTable == NULL)
        refCountTable = CreateRefCountTable();

    return refCountTable;
}

void objc_IncrementExtraRefCount(id object) {
    RefCountBucket *refCount;
    RefCountTable *table = refTable();

    objc_lock_lock(&RefCountLock);
    if((refCount = XXHashGet(table, object)) == NULL) {
        refCount = AllocBucketFromTable(table);
        refCount->object = object;
        refCount->count = 1;
        XXHashInsert(refTable(), refCount);
    }
    refCount->count++;
    objc_lock_unlock(&RefCountLock);
}

bool objc_DecrementExtraRefCountWasZero(id object) {
    bool result = false;
    RefCountBucket *refCount;

    objc_lock_lock(&RefCountLock);
    if((refCount = XXHashGet(refTable(), object)) == NULL)
        result = true;
    else {
        refCount->count--;
        if(refCount->count == 1)
            XXHashRemove(refTable(), refCount);
    }
    objc_lock_unlock(&RefCountLock);

    return result;
}

objc_uinteger objc_ExtraRefCount(id object) {
    objc_uinteger result = 1;
    RefCountBucket *refCount;

    objc_lock_lock(&RefCountLock);
    if((refCount = XXHashGet(refTable(), object)) != NULL)
        result = refCount->count;
    objc_lock_unlock(&RefCountLock);

    return result;
}

void object_incrementExternalRefCount(id value) {
    objc_IncrementExtraRefCount(value);
}

bool object_decrementExternalRefCount(id value) {
    return objc_DecrementExtraRefCountWasZero(value);
}

unsigned long object_externalRefCount(id value) {
    return objc_ExtraRefCount(value);
}

id objc_retain(id value) {
    objc_IncrementExtraRefCount(value);
    return value;
}

void objc_release(id value) {
    if(objc_DecrementExtraRefCountWasZero(value)) {
        static SEL selector = NULL;

        if(selector == NULL)
            selector = sel_registerName("dealloc");

        IMP dealloc = objc_msg_lookup(value, selector);

        dealloc(value, selector);
    }
}

static objc_autoreleasepool *objc_autoreleaseCurrentPool() {
    return objc_tlsCurrent()->pool;
}

static void objc_autoreleaseSetCurrentPool(objc_autoreleasepool *pool) {
    objc_tlsCurrent()->pool = pool;
}

#define PAGESIZE 1024

void *objc_autoreleasePoolPush() {
    objc_autoreleasepool *current = objc_autoreleaseCurrentPool();
    objc_autoreleasepool *pool = malloc(sizeof(objc_autoreleasepool));

    pool->_parent = current;

    pool->_pageCount = 1;
    pool->_pages = malloc(pool->_pageCount * sizeof(id *));
    pool->_pages[0] = malloc(PAGESIZE * sizeof(id));
    pool->_nextSlot = 0;

    if(current != NULL)
        current->_childPool = pool;
    pool->_childPool = NULL;

    objc_autoreleaseSetCurrentPool(pool);

    return pool;
}

void objc_autoreleasePoolPop(void *poolX) {
    objc_autoreleasepool *pool = poolX;
    int i;

    if(pool == NULL)
        return;

    objc_autoreleasePoolPop(pool->_childPool);

    for(i = 0; i < pool->_nextSlot; i++) {
        //      NS_DURING
        id object = pool->_pages[i / PAGESIZE][i % PAGESIZE];

        objc_release(object);

        //    NS_HANDLER
        //   NSLog("Exception while autoreleasing %@",localException);
        //  NS_ENDHANDLER
    }

    for(i = 0; i < pool->_pageCount; i++)
        free(pool->_pages[i]);

    free(pool->_pages);

    objc_autoreleaseSetCurrentPool(pool->_parent);

    if(pool->_parent != NULL)
        pool->_parent->_childPool = NULL;

    free(pool);
}

void objc_autoreleaseNoPool(id object) {
    //  NSCLog("autorelease pool is nil, leaking %x %s",object,object_getClassName(object));
}

void objc_autoreleasePoolAdd(objc_autoreleasepool *pool, id object) {
    if(pool->_nextSlot >= pool->_pageCount * PAGESIZE) {
        pool->_pageCount++;
        pool->_pages = realloc(pool->_pages, pool->_pageCount * sizeof(id *));
        pool->_pages[pool->_pageCount - 1] = malloc(PAGESIZE * sizeof(id));
    }

    pool->_pages[pool->_nextSlot / PAGESIZE][pool->_nextSlot % PAGESIZE] = object;
    pool->_nextSlot++;
}

id objc_autorelease(id object) {
    objc_autoreleasepool *pool = objc_autoreleaseCurrentPool();

    if(pool == NULL) {
        objc_autoreleaseNoPool(object);
        return object;
    }

    objc_autoreleasePoolAdd(pool, object);

    return object;
}
