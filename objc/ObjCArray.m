/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "ObjCArray.h"
#import "objc_malloc.h"
#import "ObjCException.h"

OBJCArray *OBJCArrayNew() {
    OBJCArray *result=objc_calloc(1,sizeof(OBJCArray));

    result->data=NULL;
    result->count=0;
    result->size=0;

    return result;
}

void OBJCArrayDealloc(OBJCArray *array) {
   if(array->data!=NULL)
    objc_free(array->data);
   objc_free(array);
}

void OBJCArrayAdd(OBJCArray *array, void *item) {
   if (array->count >= array->size) {
    if (array->data == NULL)
     array->data = objc_calloc(1,sizeof(void *));
    else
     array->data = objc_realloc(array->data,(array->size*sizeof(void*))+sizeof(void *));
    array->size++;
   }
    
   array->data[array->count++] = item;
}

unsigned long OBJCArrayCount(OBJCArray *array) {
   return array->count;
}

void *OBJCArrayItemAtIndex(OBJCArray *array, unsigned long index) {
   if (index > array->count)
     OBJCRaiseException("OBJCArrayIndexBeyondBounds","OBJCArrayItemAtIndex index (%d) beyond bounds (%d)",index,array->count);

   return array->data[index];
}

void OBJCArrayRemoveItemAtIndex(OBJCArray *array, unsigned long index) {
   if (index > array->count)
     OBJCRaiseException("OBJCArrayIndexBeyondBounds","OBJCArrayItemAtIndex index (%d) beyond bounds (%d)",index,array->count);
    
   while (index < array->count-1) {
    array->data[index] = array->data[index+1];
    index++;
   }
   array->count--;
}

void *OBJCArrayEnumerate(OBJCArray *array, unsigned long *enumerator) {
   if (*enumerator < array->count)
    return array->data[(*enumerator)++];

   return NULL;
}
