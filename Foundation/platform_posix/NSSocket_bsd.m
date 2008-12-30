/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSSocket_bsd.h"
#import <Foundation/NSError.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#import <errno.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <sys/ioctl.h>

#ifdef __svr4__ // Solaris
#import <sys/filio.h>
#import <sys/signal.h>
#endif

@implementation NSSocket(bsd)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([NSSocket_bsd class],0,NULL);
}

@end

@implementation NSSocket_bsd

static inline void byteZero(void *vsrc,int size){
   unsigned char *src=vsrc;
   int i;

   for(i=0;i<size;i++)
    src[i]=0;
}

+(void)initialize {
#ifdef __svr4__ // Solaris
    sigignore(SIGPIPE);
#endif
}

-initWithDescriptor:(int)descriptor {
   _descriptor=descriptor;
   return self;
}

+socketWithDescriptor:(int)descriptor {
   return [[[self alloc] initWithDescriptor:descriptor] autorelease];
}

-(NSError *)errorForReturnValue:(int)returnValue {
   if(returnValue<0){
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
   }
   return nil;
}

-initTCPStream {
   NSError *error=[self errorForReturnValue:_descriptor=socket(PF_INET,SOCK_STREAM,IPPROTO_TCP)];
   if(error!=nil){
    [self dealloc];
    return nil;
   }
   return self;
}

-initUDPStream {
   NSError *error=[self errorForReturnValue:_descriptor=socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP)];
   if(error!=nil){
    [self dealloc];
    return nil;
   }
   return self;
}

-(void)closeAndDealloc {
   [self close];
   [self dealloc];
}

-initConnectedToSocket:(NSSocket **)otherX {
   // socketpair when we need it
   [self dealloc];
   *otherX=nil;
   return nil;
}


-(int)descriptor {
   return _descriptor;
}

-(void)setDescriptor:(int)descriptor {
   _descriptor=descriptor;
}

-(unsigned)hash {
   return (unsigned)_descriptor;
}

-(BOOL)isEqual:other {
   if(![other isKindOfClass:[NSSocket_bsd class]])
    return NO;
    
   return (_descriptor==((NSSocket_bsd *)other)->_descriptor)?YES:NO;
}

-(NSError *)close {
   return [self errorForReturnValue:close(_descriptor)];
}

-(NSError *)setOperationWouldBlock:(BOOL)blocks {
   u_long onoff=blocks?NO:YES;

   return [self errorForReturnValue:ioctl(_descriptor,FIONBIO,&onoff)];
}

-(BOOL)operationWouldBlock {
   return (errno==EINPROGRESS);
}

-(NSError *)connectToHost:(NSHost *)host port:(int)portNumber immediate:(BOOL *)immediate {
   BOOL     block=NO;
   NSArray *addresses=[host addresses];
   int      i,count=[addresses count];
   NSError *error=nil;
   
   *immediate=NO;

   if(!block){
    if((error=[self setOperationWouldBlock:NO])!=nil)
     return error;
   }
   
   for(i=0;i<count;i++){
    struct sockaddr_in try;
    NSString     *stringAddress=[addresses objectAtIndex:i];
    char          cString[[stringAddress cStringLength]+1];
    unsigned long address;
    
    [stringAddress getCString:cString];
    if((address=inet_addr(cString))==-1){
 // FIX
    }
    
    byteZero(&try,sizeof(struct sockaddr_in));
    try.sin_addr.s_addr=address;
    try.sin_family=AF_INET;
    try.sin_port=portNumber;

    if(connect(_descriptor,(struct sockaddr *)&try,sizeof(try))==0){
     if(!block){
      if((error=[self setOperationWouldBlock:YES])!=nil)
       return error;
     }
     *immediate=YES;
     return nil;
    }
    else if([self operationWouldBlock]){
     if(!block){
      if((error=[self setOperationWouldBlock:YES])!=nil)
       return error;
     }
     return nil;
    }
    else {
     error=[self errorForReturnValue:-1];
    }
   }

   if(error==nil)
    error=[NSError errorWithDomain:NSPOSIXErrorDomain code:EHOSTUNREACH userInfo:nil];
    
   return error;
}

-(BOOL)hasBytesAvailable {
   unsigned char buf[1];

   return (recv(_descriptor,buf,1,MSG_PEEK)==1)?YES:NO;
}

-(int)read:(unsigned char *)buffer maxLength:(unsigned)length {
   return recv(_descriptor,(void *)buffer,length,0);
}

-(int)write:(const unsigned char *)buffer maxLength:(unsigned)length {
   return send(_descriptor,(void *)buffer,length,0);
}

-(NSSocket *)acceptWithError:(NSError **)errorp {
   struct sockaddr addr;
   socklen_t       addrlen=sizeof(struct sockaddr);
   int             newSocket; 
   NSError        *error;
   
   error=[self errorForReturnValue:newSocket=accept(_descriptor,&addr,&addrlen)];
   if(errorp!=NULL)
    *errorp=error;
    
   return (error!=nil)?nil:[[[NSSocket_bsd alloc] initWithDescriptor:newSocket] autorelease];
}

@end


NSData *NSSocketAddressDataForNetworkOrderAddressBytesAndPort(const void *address,unsigned length,int port) {   
   return nil;
}
