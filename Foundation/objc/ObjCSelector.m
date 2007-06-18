/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>, Christopher Lloyd <cjwl@objc.net>
#import <Foundation/ObjCSelector.h>
#import <Foundation/ObjCHashTable.h>
#import <Foundation/ObjCException.h>
#import <Foundation/NSZone.h>
#import <Foundation/ObjCClass.h>
#import "objc_cache.h"

#define INITIAL_SELECTOR_TABLE_SIZE 4096 // Big System has about 3700 selectors

int selectorCount=0;

static SEL   nextSelector=(void *)sizeof(OBJCMethodCacheEntry);
static OBJCHashTable *nameToNumber=NULL;


SEL OBJCRegisterSelectorName(const char *name){
  SEL result;

   if(nameToNumber==NULL)
    nameToNumber=OBJCCreateHashTable(INITIAL_SELECTOR_TABLE_SIZE);

   result=(SEL)OBJCHashValueForKey(nameToNumber,name);

   if(result==OBJCNilSelector){
    selectorCount++;
    result=(SEL)OBJCHashInsertValueForKey(nameToNumber,name,(void *)nextSelector);
    nextSelector+=sizeof(OBJCMethodCacheEntry);
   }

   return result;
}

SEL OBJCRegisterMethodDescription(OBJCMethodDescription *method) {
   return OBJCRegisterSelectorName((const char *)method->name);
}

SEL OBJCRegisterMethod(OBJCMethod *method) {
   return OBJCRegisterSelectorName((const char *)method->method_name);
}

SEL sel_getUid(const char *selectorName) {
   if(nameToNumber==NULL)
    return NULL;

   return (SEL)OBJCHashValueForKey(nameToNumber,selectorName);
}

SEL sel_registerName(const char *cString){
   SEL result=sel_getUid(cString);

   if(result==NULL){
    char *copy=NSZoneMalloc(NULL,sizeof(char)*(strlen(cString)+1));

    strcpy(copy,cString);
    result=(SEL)OBJCRegisterSelectorName(copy);
   }

   return result;
}

const char *sel_getName(SEL selector) {
  OBJCHashEnumerator state=OBJCEnumerateHashTable(nameToNumber);
  const char        *check;

  if(selector==NULL)
    return NULL;
  
  while((check=OBJCNextHashEnumeratorKey(&state))!=NULL){
   SEL value=(SEL)OBJCHashValueForKey(nameToNumber,check);

   if(value==OBJCSelectorUniqueId(selector))
    return check;
  }

  return NULL;
}

BOOL sel_isMapped(SEL selector) {
   return (sel_getName(selector)!=NULL)?YES:NO;
}

