#import <objc/runtime.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSObject.h>
#ifdef WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

// the cache entry size must be a power of 2
typedef struct {
    void                    *nextEntry;
    const void              *key;
    id                      object;
    objc_AssociationPolicy policy;
} AssociationObjectEntry;

#define AssociationObjectEntrySize    4

#define HASHPTR(p) (((unsigned int)p)>>5)

typedef struct AssociationHashBucket {
    struct AssociationHashBucket    *next;
    id                              key;
    AssociationObjectEntry          *value;
} AssociationHashBucket;

typedef struct AssociationTable {
    unsigned int              count;
    unsigned int              nBuckets;
    AssociationHashBucket **buckets;
} AssociationTable;

typedef struct {
    AssociationTable                *table;
    unsigned int                    i;
    struct AssociationHashBucket    *j;
} NSHashEnumerator;


AssociationTable *CreateAssociationTable(unsigned int capacity) {
    AssociationTable *table=malloc(sizeof(AssociationTable));

    table->count=0;
    table->nBuckets=(capacity<4)?4:capacity;
    table->buckets=calloc(table->nBuckets,sizeof(AssociationHashBucket *));
    
    return table;
}

AssociationObjectEntry *AssociationTableGet(AssociationTable *table,id key){
    unsigned int i=HASHPTR(key)%table->nBuckets;
    AssociationHashBucket *j;
    
    for(j=table->buckets[i];j!=NULL;j=j->next)
        if(j->key==key)
            return j->value;
    
    return NULL;
}


void AssociationTableInsert(AssociationTable *table,id key, AssociationObjectEntry *value){
    unsigned int        hash=HASHPTR(key);
    unsigned int        i=hash%table->nBuckets;
    AssociationHashBucket *j;
    
    for(j=table->buckets[i];j!=NULL;j=j->next)
        if(j->key==key){
            id oldKey=j->key;
            AssociationObjectEntry *oldValue=j->value;
            
            j->key=key;
            j->value=value;            
            return;
        }
        
    if(table->count>=table->nBuckets){
        unsigned int         nBuckets=table->nBuckets;
        AssociationHashBucket **buckets=table->buckets,*next;
        
        table->nBuckets=nBuckets*2;
        table->buckets=calloc(table->nBuckets,sizeof(AssociationHashBucket *));
        
        for(i=0;i<nBuckets;i++)
            for(j=buckets[i];j!=NULL;j=next){
                unsigned int newi=HASHPTR(key)%table->nBuckets;
                
                next=j->next;
                j->next=table->buckets[newi];
                table->buckets[newi]=j;
            }
        free(buckets);
        i=hash%table->nBuckets;
    }
    
    j=malloc(sizeof(AssociationHashBucket));
    j->key=key;
    j->value=value;
    j->next=table->buckets[i];
    table->buckets[i]=j;
    table->count++;
}

void *AssociationTableInsertIfAbsent(AssociationTable *table, id key, AssociationObjectEntry *value){
    void *old=AssociationTableGet(table,key);
    
    if(old!=NULL)
        return old;
    AssociationTableInsert(table,key,value);
    return NULL;
}

typedef unsigned int AssociationSpinLock;

void AssociationSpinLockLock( volatile AssociationSpinLock *__lock )
{
    while(!__sync_bool_compare_and_swap(__lock, 0, 1))
    {
#ifdef WIN32
        Sleep(0);
#else
        usleep(1);
#endif
    }
}

void AssociationSpinLockUnlock( volatile AssociationSpinLock *__lock )
{
    __sync_bool_compare_and_swap(__lock, 1, 0);
}

static AssociationSpinLock AssociationLock=0;
static AssociationTable *associationTable = NULL;


void AssociationTableRemove(AssociationTable *table,id key){
    AssociationSpinLockLock(&AssociationLock);
    
    unsigned int i=HASHPTR(key)%table->nBuckets;
    AssociationHashBucket *j=table->buckets[i],*prev=j;

   for(;j!=NULL;j=j->next){
        if(j->key==key){
            // array to keep track of the objects to release - that must be done outside of the lock
            // since the release can trigger more association changes
            int releaseCount = 0;
            int releaseTableSize = 0;
            id *objectsToRelease = NULL;
            
           if(prev==j)
                table->buckets[i]=j->next;
            else
                prev->next=j->next;
            
            AssociationObjectEntry *entry = j->value;

            for (int i = 0; i < AssociationObjectEntrySize; i++) {
                AssociationObjectEntry *e = (AssociationObjectEntry *)entry + i;
                while (e) {
                    switch (e->policy) {
                        case OBJC_ASSOCIATION_ASSIGN:
                            break;
                        case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
                        case OBJC_ASSOCIATION_RETAIN:
                        case OBJC_ASSOCIATION_COPY_NONATOMIC:
                        case OBJC_ASSOCIATION_COPY:
                            if (releaseCount >= releaseTableSize) {
                                if (releaseTableSize == 0) {
                                    releaseTableSize = 8;
                                } else {
                                    releaseTableSize *= 2;
                                }
                                objectsToRelease = realloc(objectsToRelease, sizeof(id)*releaseTableSize);
                            }
                            objectsToRelease[releaseCount++] = e->object;
                            break;
                    }
                    void *prevEntry = e;
                    e = e->nextEntry;
                    free(prevEntry);
                }
            }
            
            free(entry);
            free(j);
            table->count--;
            
            AssociationSpinLockUnlock(&AssociationLock);

            // Do the cleaning outside of the lock since it might trigger more association playing
            for (int i = 0; i < releaseCount; ++i) {
                [objectsToRelease[i] release];
            }
            free(objectsToRelease);
            
            return;
        }
        prev=j;
    }
    AssociationSpinLockUnlock(&AssociationLock);
}

void objc_removeAssociatedObjects(id object)
{
    if (associationTable == NULL) {
        return;
    }
    AssociationTableRemove(associationTable, object);
    
}

void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
{
    AssociationSpinLockLock(&AssociationLock);

    if (associationTable == NULL) {
        associationTable = CreateAssociationTable(512);
    }
    
    AssociationObjectEntry   *objectTable = AssociationTableGet(associationTable, object);
    if (objectTable == NULL) {
        objectTable = calloc(sizeof(AssociationObjectEntry), AssociationObjectEntrySize);
        AssociationTableInsert(associationTable, object, objectTable);
    }
    
    uintptr_t               index = HASHPTR(key) % AssociationObjectEntrySize;
    AssociationObjectEntry *entry = ((AssociationObjectEntry *)objectTable) + index;
    if (entry->object == nil) {
        entry->policy = policy;
        entry->key = key;
        switch (policy) {
            case OBJC_ASSOCIATION_ASSIGN:
                entry->object = value;
                break;
            case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
            case OBJC_ASSOCIATION_RETAIN:
                entry->object = [value retain];
                break;
            case OBJC_ASSOCIATION_COPY_NONATOMIC:
            case OBJC_ASSOCIATION_COPY:
                entry->object = [value copy];
                break;
        }
    }
    else {
        AssociationObjectEntry *newEntry;
        do {
            if (entry->key == key) {
                id objectToRelease = nil;
                
                switch (entry->policy) {
                    case OBJC_ASSOCIATION_ASSIGN:
                        break;
                    case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
                    case OBJC_ASSOCIATION_RETAIN:
                    case OBJC_ASSOCIATION_COPY_NONATOMIC:
                    case OBJC_ASSOCIATION_COPY:
                        objectToRelease = entry->object;
                        break;
                }
                entry->policy = policy;
                switch (policy) {
                    case OBJC_ASSOCIATION_ASSIGN:
                        entry->object = value;
                        break;
                    case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
                    case OBJC_ASSOCIATION_RETAIN:
                        entry->object = [value retain];
                        break;
                    case OBJC_ASSOCIATION_COPY_NONATOMIC:
                    case OBJC_ASSOCIATION_COPY:
                        entry->object = [value copy];
                        break;
                }
                AssociationSpinLockUnlock(&AssociationLock);
                
                // Do the cleaning outside of the lock since it might trigger more association playing
                [objectToRelease release];

                return;
            }
            if (entry->nextEntry != nil) {
                entry = entry->nextEntry;
            }
        } while (entry->nextEntry != nil);
        
        newEntry = malloc(sizeof(AssociationObjectEntry));
        newEntry->policy = policy;
        newEntry->key = key;
        switch (policy) {
            case OBJC_ASSOCIATION_ASSIGN:
                newEntry->object = value;
                break;
            case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
            case OBJC_ASSOCIATION_RETAIN:
                newEntry->object = [value retain];
                break;
            case OBJC_ASSOCIATION_COPY_NONATOMIC:
            case OBJC_ASSOCIATION_COPY:
                newEntry->object = [value copy];
                break;
        }
        newEntry->nextEntry = NULL;
        entry->nextEntry = newEntry;
    }

    AssociationSpinLockUnlock(&AssociationLock);
}

id objc_getAssociatedObject(id object, const void *key)
{

    if (associationTable == NULL) {
        return nil;
    }

    AssociationSpinLockLock(&AssociationLock);

    AssociationObjectEntry   *objectTable = AssociationTableGet(associationTable, object);
    if (objectTable == NULL) {
        AssociationSpinLockUnlock(&AssociationLock);
        return nil;
    }

    uintptr_t               index = HASHPTR(key) % AssociationObjectEntrySize;
    AssociationObjectEntry *entry = ((AssociationObjectEntry *)objectTable) + index;
    while (entry) {
        if (entry->key == key) {
            break;
        }
        entry = entry->nextEntry;
    }
    AssociationSpinLockUnlock(&AssociationLock);
    if (entry) {
        return entry->object;        
    } else {
        return nil;
    }
}
