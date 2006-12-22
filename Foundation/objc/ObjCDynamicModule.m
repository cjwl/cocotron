/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>, Christopher Lloyd <cjwl@objc.net>
#import <Foundation/ObjCDynamicModule.h>
#import <Foundation/ObjCModule.h>

#ifdef WIN32
#import <windows.h>
#else
#import <dlfcn.h>
#import <sys/param.h>
#import <string.h>
#import <stdlib.h>
#import <unistd.h>
#endif

#ifdef WIN32
// only frameworks need to call this from DllMain, NSLoadModule will do it for loaded object files (i.e. bundles)
int OBJCRegisterDLL(HINSTANCE handle){
   char path[MAX_PATH+1];

   if(!GetModuleFileName(handle,path,MAX_PATH))
    OBJCRaiseWin32Failure("OBJCModuleFailed","OBJCInitializeModule, GetModuleFileName failed");
   else
    OBJCLinkQueuedModulesToObjectFileWithPath(path);

   return 1;
}

NSModuleHandle NSLoadModule(const char *path) {
   NSModuleHandle handle;
   
   OBJCResetModuleQueue();
   
   handle=LoadLibrary(path);

   if(handle!=NULL)
    OBJCRegisterDLL(handle);
   
   return handle;
}
#else

NSModuleHandle NSLoadModule(const char *path) {
   NSModuleHandle handle;

   // dlopen doesn't accept partial paths.
   if (path[0] != '/' && path[0] != '.') {
      char buf[MAXPATHLEN];

      if (getcwd(buf, MAXPATHLEN) != NULL) {
          strncat(buf, "/", MAXPATHLEN);
          strncat(buf, path, MAXPATHLEN);
          path = buf;
      }
      else {
          OBJCLog("NSLoadModule: cannot find cwd and relative path specified");
          return NULL;
      }
   }

   handle = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
   if (NSLastModuleError() != NULL){
       OBJCLog(NSLastModuleError());
       handle = NULL;
   }

   return handle;
}
#endif

BOOL NSUnloadModule(NSModuleHandle handle) {
#ifdef WIN32
   return NO;
#else
   if (dlclose(handle))
       return NO;

   return YES;
#endif
}

const char *NSLastModuleError(void) {
#ifdef WIN32
   return NULL;
#else
   return dlerror();
#endif
}

void *NSSymbolInModule(NSModuleHandle handle, const char *symbol) {
#ifdef WIN32
   return NULL;
#else
   return dlsym(handle, symbol);
#endif
}
