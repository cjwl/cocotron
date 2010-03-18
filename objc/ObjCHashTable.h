/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <objc/objc.h>

#import <string.h>

typedef struct {
    unsigned long count;
    unsigned long nBuckets;
    struct OBJCHashBucket **buckets;
} OBJCHashTable;

typedef struct OBJCHashBucket {
   struct OBJCHashBucket *next;
   const char            *key;
   void                  *value;
} OBJCHashBucket;

typedef struct {
   OBJCHashTable         *table;
   long                   i;
   struct OBJCHashBucket *j;
} OBJCHashEnumerator;

OBJCHashTable *OBJCCreateHashTable(unsigned capacity);
void *OBJCHashInsertValueForKey(OBJCHashTable *table,const char *key,void *value);
OBJCHashEnumerator OBJCEnumerateHashTable(OBJCHashTable *table);
const char *OBJCNextHashEnumeratorKey(OBJCHashEnumerator *enumerator);
void *OBJCNextHashEnumeratorValue(OBJCHashEnumerator *enumerator);

static inline unsigned OBJCHashString (const void *data) {
   const unsigned char *s=data;
   unsigned             result=0,i;

   if(s!=NULL){
    result=5381;

    for(i=0;s[i]!='\0';i++)
     result=((result<<5)+result)+s[i]; // hash*33+c
   }

   return result;
};

static inline int OBJCIsStringEqual (const void *data1, const void *data2) {

    return (strcmp ((char *) data1, (char *) data2)) ? NO : YES;
};

static inline void *OBJCHashValueForKey(OBJCHashTable *table,const char *key){
   int             i=OBJCHashString(key)%table->nBuckets;
   OBJCHashBucket *j;

   for(j=table->buckets[i];j!=NULL;j=j->next)
    if(OBJCIsStringEqual(j->key,key))
     return j->value;

   return NULL;
}

