/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "ObjCException.h"

#import <stdarg.h>
#import <stdio.h>

void OBJCLog(const char *format,...) {
   va_list arguments;

   va_start(arguments,format);

   fprintf(stderr,"ObjC:");
   vfprintf(stderr,format,arguments);
   fprintf(stderr,"\n");
   fflush(stderr);
   va_end(arguments);
}

void OBJCPartialLog(const char *format,...) {
   va_list arguments;

   va_start(arguments,format);

   fprintf(stderr,"ObjC:");
   vfprintf(stderr,format,arguments);
   fflush(stderr);
   va_end(arguments);
}

void OBJCFinishLog(const char *format,...) {
   va_list arguments;

   va_start(arguments,format);

   vfprintf(stderr,format,arguments);
   fprintf(stderr,"\n");
   fflush(stderr);
   va_end(arguments);
}

void OBJCRaiseException(const char *name,const char *format,...) {
   va_list arguments;

   va_start(arguments,format);

   fprintf(stderr,"ObjC:%s:",name);
   vfprintf(stderr,format,arguments);
   fprintf(stderr,"\n");
   fflush(stderr);
   va_end(arguments);
}
