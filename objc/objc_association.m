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

#define BucketsInitialSize 509 // Some prime size (and as a bonus, next three n*2+1 are prime too)
#define AssociationObjectEntrySize    5

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

AssociationTable *CreateAssociationTable(unsigned int capacity) {
    AssociationTable *table=malloc(sizeof(AssociationTable));
    
    table->count=0;
    table->nBuckets=(capacity<5)?5:capacity;
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
    
    for(j=table->buckets[i];j!=NULL;j=j->next) {
        if(j->key==key){
            AssociationObjectEntry *oldValue=j->value;
            
            j->value=value;
            
            free(oldValue);
            return;
        }
    }
    int newSize = 0;
    if (table->count>=table->nBuckets) {
        // Expand the buckets size to limit collisions
        newSize=table->nBuckets*2+1; // Let"s use odd size
    } else if (table->count > BucketsInitialSize && table->count < table->nBuckets/2) {
        // Compact the table - plenty of free room
        newSize=table->nBuckets/2;
        if (newSize%2) {
            // Let"s use odd size
            newSize+=1;
        }
    }
    if(newSize != 0){
        unsigned int         nBuckets=table->nBuckets;
        AssociationHashBucket **buckets=table->buckets;
        
        table->nBuckets=newSize;
        table->buckets=calloc(table->nBuckets,sizeof(AssociationHashBucket *));
        
        // Get all of the existing buckets and place them into the new list
        for(i=0;i<nBuckets;i++) {
            j = buckets[i];
            while (j) {
                unsigned int newi=HASHPTR(j->key)%table->nBuckets;
                
                AssociationHashBucket *next = j->next;
                j->next=table->buckets[newi];
                table->buckets[newi]=j;
                
                j = next;
            }
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
                AssociationObjectEntry *e = entry + i;
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
                    AssociationObjectEntry *currentEntry = e;
                    e = e->nextEntry;
                    // Don't free the first entry of the list - it's part of the "entry" block that will be freed after the loop
                    if (currentEntry != entry + i) {
                        free(currentEntry);
                    }
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
        associationTable = CreateAssociationTable(BucketsInitialSize);
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
