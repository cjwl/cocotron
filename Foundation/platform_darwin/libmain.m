/* Copyright (c) 2010 Glenn Ganz
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSProcessInfo.h>

FOUNDATION_EXPORT void __attribute__ ((constructor)) libmain(void)
{
    char        ***env = _NSGetEnviron();
    static char **argValues=NULL;
    char        ***argvp;
    void        *p;
    int         i = -1;
    
    asm ("mov %%esp, %0" : "=r" (p));
    argvp = p;
    
    //loop until environment
    while (argvp != env) {
        argvp++;
    }
    argvp--;
    argValues = *argvp;
    
    while(1) {
        if(argValues[i + 1] != NULL) {
            i++;
        }
        else {
            i++;
            break;
        }
    }
    
    __NSInitializeProcess(i, (const char **)argValues);
}
