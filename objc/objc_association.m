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
#define AssociationObjectEntryMask    ((AssociationObjectEntrySize-1)*sizeof(AssociationObjectEntry))

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
    unsigned int i=((unsigned int)key>>5)%table->nBuckets;
    AssociationHashBucket *j;
    
    for(j=table->buckets[i];j!=NULL;j=j->next)
        if(j->key==key)
            return j->value;
    
    return NULL;
}


void AssociationTableInsert(AssociationTable *table,id key, AssociationObjectEntry *value){
    unsigned int        hash=(unsigned int)key>>5;
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
                unsigned int newi=((unsigned int)j->key>>5)%table->nBuckets;
                
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
    unsigned int i=((unsigned int)key>>5%table)->nBuckets;
    AssociationHashBucket *j=table->buckets[i],*prev=j;
    
    for(;j!=NULL;j=j->next){
        if(j->key==key){
            if(prev==j)
                table->buckets[i]=j->next;
            else
                prev->next=j->next;
            
            AssociationObjectEntry *entry = j->value;
            do {
                for (int i = 0; i < AssociationObjectEntrySize; i++) {
                    AssociationObjectEntry *e = (void *)entry + i;
                    
                    switch (e->policy) {
                        case OBJC_ASSOCIATION_ASSIGN:
                            break;
                        case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
                        case OBJC_ASSOCIATION_RETAIN:
                        case OBJC_ASSOCIATION_COPY_NONATOMIC:
                        case OBJC_ASSOCIATION_COPY:
                            [e->object release];
                            break;
                    }
                }
            } while (entry->nextEntry != nil);

            free(j->value);
            free(j);
            table->count--;
            return;
        }
        prev=j;
    }
}

void objc_removeAssociatedObjects(id object)
{
    if (associationTable == NULL) {
        return;
    }
    
    AssociationSpinLockLock(&AssociationLock);
        
    AssociationTableRemove(associationTable, object);
    
    AssociationSpinLockUnlock(&AssociationLock);
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
    
    uintptr_t               index = (uintptr_t)(key) & AssociationObjectEntryMask;
    AssociationObjectEntry *entry = ((void *)objectTable) + index;
    
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
                switch (entry->policy) {
                    case OBJC_ASSOCIATION_ASSIGN:
                        break;
                    case OBJC_ASSOCIATION_RETAIN_NONATOMIC:
                    case OBJC_ASSOCIATION_RETAIN:
                    case OBJC_ASSOCIATION_COPY_NONATOMIC:
                    case OBJC_ASSOCIATION_COPY:
                        [entry->object release];
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
    
    uintptr_t               index = (uintptr_t)(key) & AssociationObjectEntryMask;
    AssociationObjectEntry *entry = ((void *)objectTable) + index;

    AssociationSpinLockUnlock(&AssociationLock);
    return entry->object;
}
