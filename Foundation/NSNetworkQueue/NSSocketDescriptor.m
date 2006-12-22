/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSSocketDescriptor.h>
#import <Foundation/NSString.h>
#ifndef WIN32
#import <errno.h>
#import <string.h>
#endif

NSString *NSSocketErrorStringFromCode(int code) {
#ifdef WIN32
   return [NSString stringWithFormat:@"code=%d",code];
#else
   return [NSString stringWithCString:strerror(code)];
#endif
}

NSString *NSSocketErrorString(void) {
#ifdef WIN32
   return NSSocketErrorStringFromCode(WSAGetLastError());
#else
   return NSSocketErrorStringFromCode(errno);
#endif
}

BOOL _NSSocketAssert(int r,int line,const char *file){
   if(r<0){
    NSLog(@"socket error %@ at %d in %s",NSSocketErrorString(),line,file);
    return YES;
   }
   return NO;
}

NSException *_NSSocketException(int r,int line,const char *file){
   if(r<0){
    NSString *reason=[NSString stringWithFormat:@"socket error %@ at %d in %s",NSSocketErrorString(),line,file];

    return [NSException exceptionWithName:@"NSSocketException"
      reason:reason userInfo:nil];
   }
   return nil;
}

int NSSocketSetBlocking(NSSocketDescriptor socket,BOOL blocks){
   u_long onoff=blocks?NO:YES;
#ifdef WIN32
   return ioctlsocket(socket,FIONBIO,&onoff);
#else
   return ioctl(socket,FIONBIO,&onoff);
#endif
}

BOOL NSSocketOperationWouldBlock() {
#ifdef WIN32
   return (WSAGetLastError()==WSAEWOULDBLOCK);
#else
   return (errno==EINPROGRESS);
#endif
}
