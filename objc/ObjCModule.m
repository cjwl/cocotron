/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "ObjCModule.h"
#import "objc_class.h"
#import "objc_sel.h"
#import <objc/Protocol.h>
#import "ObjCException.h"
#import "objc_malloc.h"
#import "objc_protocol.h"
 
#import <string.h>

#define INITIAL_CLASS_ARRAY_SIZE 512

#ifdef SOLARIS
    #import <stdio.h>
    #define PATH_MAX 1024
#endif

#ifdef WIN32
	#import <windows.h>
#else
#define __USE_GNU // for dladdr()
#import <dlfcn.h>
#import <unistd.h>
#import <sys/param.h>
#import <limits.h>
#endif
#ifdef BSD
#import <sys/sysctl.h>
#endif

static Class *unresolvedClasses = NULL;
static int unresolvedClassesSize = 0;
static Class *sentLoadMessageClasses = NULL;
static int sentLoadMessageClassesSize = 0;



static OBJCArray *OBJCObjectFileImageArray(void) {
   static OBJCArray *objectFileImageArray=NULL;

   if(objectFileImageArray==NULL)
    objectFileImageArray=OBJCArrayNew();

   return objectFileImageArray;
}


static OBJCObjectFile *OBJCObjectFileWithPath(const char *path) {
   OBJCObjectFile *result=objc_calloc(1,sizeof(OBJCObjectFile));
   
   result->path=objc_calloc(strlen(path)+1,sizeof(char));
   strcpy(result->path,path);
   result->moduleArray = OBJCArrayNew();
   
   return result;
}

OBJCObjectFile *OBJCUniqueObjectFileWithPath(const char *path) {
   OBJCObjectFile *result;
   OBJCArray      *array=OBJCObjectFileImageArray();
   unsigned long   arrayIndex=0;

   while((result=OBJCArrayEnumerate(array,&arrayIndex))!=NULL){
     if (strcmp(result->path, path) == 0)
       return result;
   }

   result=OBJCObjectFileWithPath(path);
   
   OBJCArrayAdd(array,result);
   
   return result;
}

OBJCObjectFile *OBJCObjectFileForPointer(void *ptr){
#ifdef WIN32
// GetModuleHandleEx would work here, but it is only available on XP and above
   return NULL;
#else
   Dl_info info;

   if(!dladdr(ptr,&info)){
    OBJCRaiseException("OBJCInternalInconsistencyException","Can't resolve object file image for module");
	return NULL;
   }
   
   return OBJCUniqueObjectFileWithPath(info.dli_fname);
#endif
}

#if defined(WIN32)

#define MAXPATHLEN 8192

int _NSGetExecutablePath(char *path,uint32_t *capacity) {
   int        bufferCapacity=MAXPATHLEN;
   uint16_t   buffer[bufferCapacity+1];
   DWORD      i,bufferSize=GetModuleFileNameW(GetModuleHandle(NULL),buffer,bufferCapacity);
      
   for(i=0;i<bufferSize;i++)
    if(buffer[i]=='\\')
     buffer[i]='/';

   int size=WideCharToMultiByte(CP_UTF8,0,buffer,bufferSize,NULL,0,NULL,NULL);

   if(size+1>*capacity){
    *capacity=size+1;
    return -1;
   }
    
   size=WideCharToMultiByte(CP_UTF8,0,buffer,bufferSize,path,*capacity,NULL,NULL);
   path[size]='\0';
   size++;
    
   *capacity=size;
       
   return 0;
}

// FIXME: these implementations do not return the size needed

#elif defined(LINUX)

int _NSGetExecutablePath(char *path,uint32_t *capacity) {
   if((*capacity=readlink("/proc/self/exe",path,*capacity))<0){
    *capacity=0;
    return -1;
   }
    
   return 0;
}

#elif defined(__APPLE__)

extern int _NSGetExecutablePath(char *path,uint32_t *capacity);

#elif defined(BSD)

int _NSGetExecutablePath(char *path,uint32_t *capacity) {
#if defined(FREEBSD)
   int mib[4];
   
   mib[0] = CTL_KERN;
   mib[1] = KERN_PROC;
   mib[2] = KERN_PROC_PATHNAME;
   mib[3] = -1;

   size_t cb = *capacity;

   if(sysctl(mib, 4, path, &cb, NULL, 0)<0){
    *capacity=0;
    return -1;
   }
   *capacity=strlen(path);

   return 0;
#else
   int length;
   
   if((length=readlink("/proc/curproc/file", path, 1024))<0){
    *capacity=0;
    return -1;
   }
   *capacity=length;

#endif   
   return 0;
}

#elif defined(SOLARIS)

int _NSGetExecutablePath(char *path,uint32_t *capacity) {
   char probe[PATH_MAX+1]; 
   
   sprintf(probe,"/proc/%ld/path/a.out",(long)getpid()); 
   
   if((*capacity=readlink(probe,path,*capacity))<0){
    *capacity=0;
    return -1;
   }
   
   return 0;
}
#endif

void OBJCInitializeProcess() {
#ifdef __APPLE__
extern void OBJCInitializeProcess_Darwin(void);

   OBJCInitializeProcess_Darwin();
#endif
}

OBJCObjectFile *OBJCMainObjectFile(){
   static OBJCObjectFile *mainObjectFile=NULL;
   
   if(mainObjectFile==NULL){
    uint32_t length=MAXPATHLEN;
    char     path[length+1];
   
    if(_NSGetExecutablePath(path,&length)<0)
     path[0]='\0';
    else
     path[length]='\0';

    mainObjectFile=OBJCUniqueObjectFileWithPath(path);
   }
   
   return mainObjectFile;
}

void OBJCLinkModuleToActiveObjectFile(OBJCModule *module){
   OBJCObjectFile *objectFile=OBJCObjectFileForPointer(module);
   
   if(objectFile==NULL)
    objectFile=OBJCMainObjectFile();
	
   if(objectFile!=NULL)
    OBJCArrayAdd(objectFile->moduleArray,module);
}

static OBJCArray *OBJCModuleQueueWithReset(BOOL reset){
   static OBJCArray *ownershipQueue=NULL;
   OBJCArray        *result;

   if(ownershipQueue==NULL)
    ownershipQueue=OBJCArrayNew();

   result=ownershipQueue;

   if(reset)
    ownershipQueue=NULL;

   return result;
}

static OBJCArray *OBJCModuleQueue(){
   return OBJCModuleQueueWithReset(NO);
}


static void OBJCSymbolTableRegisterSelectors(OBJCSymbolTable *symbolTable){
   SEL *selectorReferences=symbolTable->selectorReferences;

   if(selectorReferences!=NULL){
    while(*selectorReferences!=NULL){
     *selectorReferences=(SEL)sel_registerNameNoCopy((const char *)*selectorReferences);
     selectorReferences++;
    }
   }
}

void OBJCAddToUnResolvedClasses(Class class) {
    Class superClass = class->super_class;
    
    //check for root object
    if(superClass) {
        for(int i= 0; i < unresolvedClassesSize; i++) {
            Class currentClass = unresolvedClasses[i];
            if(currentClass == NULL || currentClass == (Class)-1) {
                unresolvedClasses[i] = class;
                return;
            }
        }
        int newCSize = 0;
        if(unresolvedClassesSize == 0) {
            newCSize = INITIAL_CLASS_ARRAY_SIZE;
        }
        else {
            newCSize = 2 * unresolvedClassesSize;

        }
        unresolvedClasses = (Class *)realloc(unresolvedClasses, newCSize * sizeof(Class));

        for(int i = unresolvedClassesSize;i  < newCSize;i ++) {
            unresolvedClasses [i] = NULL;
        }
        unresolvedClasses[unresolvedClassesSize] = class;
        
        unresolvedClassesSize = newCSize;
        
    }    
}

BOOL OBJCCheckClassIsResolved(Class class)
{
    if(class->super_class == 0) {
        //root object
        return YES;
    }
    
    Class superClass;
    if(!(class->info&CLASS_INFO_LINKED)){
        return NO;
    }
    else {
        superClass = class_getSuperclass(class);
    }
    
    if(superClass != Nil) {
        return OBJCCheckClassIsResolved(superClass);
    }
    else {
        return NO;
    }
    
    
}
void OBJCSendLoadMessage(Class class) {
    
    int i = 0;

    for(;i < sentLoadMessageClassesSize;i++) {
        if(sentLoadMessageClasses[i] == NULL) {
            break;
        }
        else if(sentLoadMessageClasses[i] == class) {
            //message already sent
            return;
        }
    }
	
	if(class->super_class != 0) {
		//send load first to the superclass
        OBJCSendLoadMessage(class->super_class);
    }

    //check for space and increase size if neeeded
    if(i == sentLoadMessageClassesSize) {
        int newCSize = 0;
        if(sentLoadMessageClassesSize == 0) {
            newCSize = INITIAL_CLASS_ARRAY_SIZE;
        }
        else {
            newCSize = 2 * sentLoadMessageClassesSize;
        }
        sentLoadMessageClasses = (Class *)realloc(sentLoadMessageClasses, newCSize * sizeof(Class));        
        for(int j=sentLoadMessageClassesSize;j < newCSize;j++) {
            sentLoadMessageClasses [j] = NULL;
        }
        sentLoadMessageClasses[sentLoadMessageClassesSize] = class;
        sentLoadMessageClassesSize = newCSize;
    }
	else {
		sentLoadMessageClasses[i] = class;
	}
    
       
    Method m = class_getClassMethod(class, @selector(load));
    if(m) {
        IMP imp = method_getImplementation(m);
        if(imp) {
            (*imp)(class, @selector(load));
        }
    }
}
void OBJCSendLoadMessages() {
    
    //until NSObject is not in runtime we don't need to check
    if(objc_lookUpClass("NSObject") == Nil) {
        return;
    }
    
    for(int i= 0; i < unresolvedClassesSize; i++) {
        Class class = unresolvedClasses[i];
        if(class == NULL) {
            continue;
        }
        
        if(OBJCCheckClassIsResolved(class) == YES) {
            //remove it from unresolved
            unresolvedClasses[i] = NULL;
        }
        else {
            //still unresolved classes, wait for more classes
            return;
        }
    }
    
    int   i,capacity=objc_getClassList(NULL,0);
    Class list[capacity];
    
    objc_getClassList(list,capacity);
    
    for(i=0;i<capacity;i++){

        OBJCSendLoadMessage(list[i]);
    }
}

static void OBJCSymbolTableRegisterClasses(OBJCSymbolTable *symbolTable){
   unsigned i,count=symbolTable->classCount;
    
   for(i=0;i<count;i++){
      struct objc_class *class=(struct objc_class *)symbolTable->definitions[i];
             
      // mark class and metaclass as having a direct method list pointer
      class->info|=CLASS_NO_METHOD_ARRAY;
      class->isa->info|=CLASS_NO_METHOD_ARRAY;
      
      OBJCRegisterClass(class);
      OBJCAddToUnResolvedClasses(class);
              
       if(strcmp(class_getName(class), "Protocol") == 0) {
           // Fix protocol classes where isa is not yet set. This is the case for all
           // classes loaded before Protocol class is loaded.
           int   i,capacity=objc_getClassList(NULL,0);
           Class list[capacity];
           
           objc_getClassList(list,capacity);
           
           for(i=0;i<capacity;i++){
               Class class = list[i];
               struct objc_protocol_list *protocols;
               
               for(protocols=class->protocols;protocols!=NULL;protocols=protocols->next){
                   unsigned i;
                   
                   for(i=0;i<protocols->count;i++){
                       OBJCProtocolTemplate *template=(OBJCProtocolTemplate *)protocols->list[i];
                       
                       OBJCRegisterProtocol(template);
                   }
               }
           }           
       }
   }
}

static void OBJCSymbolTableRegisterCategories(OBJCSymbolTable *symbolTable){
   static OBJCArray *unlinkedCategories=NULL;
   
   unsigned offset=symbolTable->classCount;
   unsigned i,count=symbolTable->categoryCount;

   if(unlinkedCategories!=NULL && objc_lookUpClass("Protocol") != Nil){
    int unlinkedIndex=unlinkedCategories->count;
   
    while(--unlinkedIndex>=0){
     Category category=OBJCArrayItemAtIndex(unlinkedCategories,unlinkedIndex);
     Class         class=objc_lookUpClass(category->className);

     if(class!=Nil){
      OBJCRegisterCategoryInClass(category,class);
	  OBJCArrayRemoveItemAtIndex(unlinkedCategories,unlinkedIndex);
	 }
	}
   }

   for(i=0;i<count;i++){
    Category category=(Category)symbolTable->definitions[offset+i];
    Class         class=objc_lookUpClass(category->className);

    if(class!=Nil && objc_lookUpClass("Protocol") != Nil)
     OBJCRegisterCategoryInClass(category,class);
	else {
	 if(unlinkedCategories==NULL)
	  unlinkedCategories=OBJCArrayNew();
	  
	 OBJCArrayAdd(unlinkedCategories,category);
	}
   }
}

// GNU style for now
static void OBJCSymbolTableRegisterStringsIfNeeded(OBJCSymbolTable *symbolTable){
   static OBJCArray        *unlinkedObjects=NULL;

   unsigned long            offset=symbolTable->classCount+symbolTable->categoryCount;
   OBJCStaticInstanceList **listOfLists=symbolTable->definitions[offset];

   if(unlinkedObjects!=NULL){
    int count=unlinkedObjects->count;
   
    while(--count>=0){
     OBJCStaticInstanceList *staticInstances=OBJCArrayItemAtIndex(unlinkedObjects,count);
     Class                   class=objc_lookUpClass(staticInstances->name);

     if(class!=Nil){
	  unsigned i;
	  
      for(i=0;staticInstances->instances[i]!= nil;i++)
       staticInstances->instances[i]->isa = class;
	   
	  OBJCArrayRemoveItemAtIndex(unlinkedObjects,count);
	 }
	}
   }

   if(listOfLists!=NULL){
    for (;*listOfLists != NULL;listOfLists++) {
     OBJCStaticInstanceList *staticInstances=*listOfLists;
     Class                   class=objc_lookUpClass(staticInstances->name);
	 unsigned                i;

     if(class!=Nil){
      for(i=0;staticInstances->instances[i]!= nil;i++)
       staticInstances->instances[i]->isa = class;
	 }
	 else {
	  if(unlinkedObjects==NULL)
	   unlinkedObjects=OBJCArrayNew();
	  
	  OBJCArrayAdd(unlinkedObjects,staticInstances);
	 }
    }
   }
}

static void OBJCSymbolTableRegisterProtocolsIfNeeded(OBJCSymbolTable *symbolTable){
// FIX or address issue
#if 0
// this needs to handle unknown protocol class
   unsigned offset=symbolTable->classCount+symbolTable->categoryCount+symbolTable->objectDefCount;
   unsigned i,count=symbolTable->protocolDefCount;

   for(i=0;i<count;i++){
    OBJCProtocolTemplate *template=(OBJCProtocolTemplate *)symbolTable->definitions[offset+i];
    OBJCRegisterProtocol(template);
   }
#endif
}

void OBJCQueueModule(OBJCModule *module) {
   OBJCArrayAdd(OBJCModuleQueue(),module);
   OBJCLinkModuleToActiveObjectFile(module);
   OBJCSymbolTableRegisterSelectors(module->symbolTable);
   OBJCSymbolTableRegisterClasses(module->symbolTable);
   OBJCSymbolTableRegisterCategories(module->symbolTable);
#ifndef __APPLE__
   OBJCSymbolTableRegisterStringsIfNeeded(module->symbolTable);
   OBJCSymbolTableRegisterProtocolsIfNeeded(module->symbolTable);
#endif

   OBJCLinkClassTable();
}

void OBJCResetModuleQueue(void) {
   OBJCArray *queue=OBJCModuleQueueWithReset(YES);
   
   OBJCArrayDealloc(queue);
}

void OBJCLinkQueuedModulesToObjectFileWithPath(const char *path){
   OBJCObjectFile *objectFile=OBJCUniqueObjectFileWithPath(path);
   OBJCArray      *queue=OBJCModuleQueueWithReset(YES);
   OBJCModule     *module;
   unsigned long   state=0;

   while((module=OBJCArrayEnumerate(queue,&state))!=NULL)
    OBJCArrayAdd(objectFile->moduleArray,module);

   OBJCArrayDealloc(queue);
}

OBJCObjectFile *OBJCObjectFileFromClass(Class class) {
   OBJCArray      *array=OBJCObjectFileImageArray();
   int             count=array->count;

   while(--count>=0){
    OBJCObjectFile *objectFile=OBJCArrayItemAtIndex(array,count);
    OBJCModule     *module;
    unsigned long   moduleIndex = 0;
	
    while((module=OBJCArrayEnumerate(objectFile->moduleArray,&moduleIndex))!=NULL) {
     unsigned classIndex;

     for(classIndex=0;classIndex<module->symbolTable->classCount;classIndex++){
      if(module->symbolTable->definitions[classIndex]==class){
       return objectFile;
	  }
     }
    }
   }

   return NULL;
}

const char *class_getImageName(Class cls) {
   OBJCObjectFile *file = OBJCObjectFileFromClass(cls);

   if (file)
      return file->path;

    return NULL;
}

const char *objc_mainImageName(){
   OBJCObjectFile *file=OBJCMainObjectFile();
   
   if(file!=NULL)
    return file->path;

   return NULL;
}

const char **objc_copyImageNames(unsigned *countp) {
   OBJCArray      *array=OBJCObjectFileImageArray();
   unsigned long   arrayIndex=0,count=OBJCArrayCount(array);
   const char    **result=malloc(count*sizeof(char *));
   OBJCObjectFile *objectFile;

   while((objectFile=OBJCArrayEnumerate(array,&arrayIndex))!=NULL)
    result[arrayIndex-1]=objectFile->path;

   *countp=count;
   
   return result;
}
