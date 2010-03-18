/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "ObjCHashTable.h"
#import "objc_malloc.h"

OBJCHashTable * OBJCCreateHashTable (unsigned capacity) {
    OBJCHashTable *result=objc_calloc(1,sizeof(OBJCHashTable));

    result->count=0;
    result->nBuckets=10;
    result->buckets=objc_calloc(result->nBuckets,sizeof(OBJCHashBucket *));

    return result;
}

void *OBJCHashInsertValueForKey(OBJCHashTable *table, const char *key,void *value) {
   unsigned        hash=OBJCHashString(key);
   int             i=hash%table->nBuckets;
   OBJCHashBucket *j;

   for(j=table->buckets[i];j!=NULL;j=j->next)
    if(OBJCIsStringEqual(j->key,key)){
     j->key=key;
     j->value=value;
     return value;
    }

   if(table->count>=table->nBuckets){
    int         nBuckets=table->nBuckets;
    OBJCHashBucket **buckets=table->buckets,*next;

    table->nBuckets=nBuckets*2;
    table->buckets= objc_calloc(table->nBuckets,sizeof(OBJCHashBucket *));

    for(i=0;i<nBuckets;i++)
     for(j=buckets[i];j!=NULL;j=next){
      int newi= OBJCHashString (j->key)%table->nBuckets;

      next=j->next;
      j->next=table->buckets[newi];
      table->buckets[newi]=j;
     }
    objc_free(buckets);
    i=hash%table->nBuckets;
   }

   j=objc_malloc(sizeof(OBJCHashBucket));
   j->key=key;
   j->value=value;
   j->next=table->buckets[i];
   table->buckets[i]=j;
   table->count++;

   return value;
}

OBJCHashEnumerator OBJCEnumerateHashTable(OBJCHashTable *table) {
   OBJCHashEnumerator state;

   state.table=table;
   for(state.i=0;state.i<table->nBuckets;state.i++)
    if(table->buckets[state.i]!=NULL)
     break;
   state.j=(state.i<table->nBuckets)?table->buckets[state.i]:NULL;

   return state;
}

const char *OBJCNextHashEnumeratorKey(OBJCHashEnumerator *state) {
   const char *key;

   if(state->j==NULL)
    return NULL;

   key=state->j->key;

   if((state->j=state->j->next)!=NULL)
    return key;

   for(state->i++;state->i<state->table->nBuckets;state->i++)
    if((state->j=state->table->buckets[state->i])!=NULL)
     return key;

   state->j=NULL;

   return key;
}

void *OBJCNextHashEnumeratorValue(OBJCHashEnumerator *state) {
   void *value;

   if(state->j==NULL)
    return NULL;

   value=state->j->value;

   if((state->j=state->j->next)!=NULL)
    return value;

   for(state->i++;state->i<state->table->nBuckets;state->i++)
    if((state->j=state->table->buckets[state->i])!=NULL)
     return value;

   state->j=NULL;

   return value;
}

