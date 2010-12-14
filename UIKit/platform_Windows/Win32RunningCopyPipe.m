/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/Win32RunningCopyPipe.h>
#import <Foundation/NSHandleMonitor_win32.h>
#import <AppKit/NSApplication.h>

@interface NSApplication(private)
-(void)_reopen;
@end

@implementation Win32RunningCopyPipe

static Win32RunningCopyPipe *_runningCopyPipe=nil;

-(void)startReading {
   _readOverlap.Offset=0;
   _readOverlap.OffsetHigh=0;
   _readOverlap.hEvent=_event;

   if(_state==STATE_CONNECTING){
    if(!ConnectNamedPipe(_pipe,&_readOverlap)){
     if(GetLastError()!=ERROR_IO_PENDING)
      NSLog(@"ConnectNamedPipe failed");
     }
   }
   else {
    if(!ReadFile(_pipe,_readBuffer,65536,&_readCount,&_readOverlap)){
     if(GetLastError()!=ERROR_IO_PENDING)
      NSLog(@"ReadFile failed");
    }
   }
}

-(void)handleMonitorIndicatesSignaled:(NSHandleMonitor_win32 *)monitor {
   if(!GetOverlappedResult(_pipe,&_readOverlap,&_readCount,TRUE))
    NSLog(@"GetOverlappedResult failed %d", GetLastError());

   if(_state==STATE_CONNECTING)
    _state=STATE_READING;
   else {
    NSString *path=[NSString stringWithCharacters:_readBuffer length:_readCount/2];

    if(!DisconnectNamedPipe(_pipe))
     NSLog(@"DisconnectNamedPipe failed");
    _state=STATE_CONNECTING;
	   
	   if([path isEqual:@"@reopen"]) [NSApp _reopen];
		else
    if([[NSApp delegate] respondsToSelector:@selector(application:openFile:)]){
     [[NSApp delegate] application:NSApp openFile:path];
    }
   }

   [self startReading];
}

-initWithPipeHandle:(HANDLE)pipeHandle {
   _pipe=pipeHandle;

   _event=CreateEvent(NULL,FALSE,FALSE,NULL);
   _eventMonitor=[[NSHandleMonitor_win32 handleMonitorWithHandle:_event] retain];
   [_eventMonitor setDelegate:self];
   [_eventMonitor setCurrentActivity:Win32HandleSignaled];
   [[NSRunLoop currentRunLoop] addInputSource:_eventMonitor forMode:NSDefaultRunLoopMode];
   _state=STATE_CONNECTING;

   [self startReading];

   return self;
}

-(void)invalidate {
   [[NSRunLoop currentRunLoop] removeInputSource:_eventMonitor forMode:NSDefaultRunLoopMode];
   CloseHandle(_event);
   CloseHandle(_pipe);
}

+(void)invalidateRunningCopyPipe {
   [_runningCopyPipe invalidate];
}

+(NSString *)pipeName {
   return [NSString stringWithFormat:@"\\\\.\\pipe\\%@~V1~",[[NSProcessInfo processInfo] processName]];
}

+(BOOL)createRunningCopyPipe {
   if(_runningCopyPipe==nil){
    HANDLE pipe=CreateNamedPipe([[self pipeName] cString],
      PIPE_ACCESS_INBOUND|FILE_FLAG_OVERLAPPED,
      PIPE_TYPE_MESSAGE|PIPE_READMODE_MESSAGE|PIPE_WAIT,
      1,8192,8192,0,NULL);

    if(pipe==INVALID_HANDLE_VALUE)
     return NO;

    _runningCopyPipe=[[Win32RunningCopyPipe alloc] initWithPipeHandle:pipe];
    return YES;
   }

   return YES;
}

+(void)_startRunningCopyPipe {
   if(![self createRunningCopyPipe]){
    NSString *path;

    if([[NSUserDefaults standardUserDefaults] stringForKey:@"NSUseRunningCopy"]!=nil){
     if(![[NSUserDefaults standardUserDefaults] boolForKey:@"NSUseRunningCopy"])
      return;
    }

    path=[[NSUserDefaults standardUserDefaults] stringForKey:@"NSOpen"];
	   
	if([path length]==0) path=@"@reopen";
	   
	  

    //if([path length]>0)
	{
     HANDLE pipe=CreateFile([[self pipeName] cString],GENERIC_WRITE,FILE_SHARE_WRITE,NULL,OPEN_EXISTING,0,NULL);

     if(pipe==INVALID_HANDLE_VALUE)
      return;
     else {
      unsigned  length=[path length];
      unichar   buffer[length];
      DWORD     wrote;

      [path getCharacters:buffer];

      if(!WriteFile(pipe,buffer,length*2,&wrote,NULL)){
       NSLog(@"WriteFile failed");
       return;
      }
     }
    }
    exit(0);
   }
}

+(void)startRunningCopyPipe {
   NSAutoreleasePool *pool=[NSAutoreleasePool new];
   
   [self _startRunningCopyPipe];

   [pool release];
}

@end
