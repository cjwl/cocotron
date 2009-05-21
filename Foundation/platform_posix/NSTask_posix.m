/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSTask_posix.h>
#import <Foundation/NSRunLoop-InputSource.h>
#import <Foundation/NSPlatform_posix.h>
#import <Foundation/NSFileHandle_posix.h>
#import <Foundation/Foundation.h>

#include <unistd.h>
#include <sys/ioctl.h>
#include <signal.h>
#include <errno.h>

// these cannot be static, subclasses need them :/
NSMutableArray *_liveTasks = nil;
NSPipe *_taskPipe = nil;

@implementation NSTask_posix

void childSignalHandler(int sig);

// it is possible that this code could execute before _taskPipe is set up, in
// which case we wind up send some messages to nil.
void childSignalHandler(int sig) {
    if (sig == SIGCHLD) {
// FIX, this probably isnt safe to do from a signal handler
       int quad = 32;
       NSData *data = [NSData dataWithBytes:&quad length:sizeof(int)];
       NSFileHandle *handle = [_taskPipe fileHandleForWriting];

       [handle writeData:data];
    }
}

+(void)signalPipeReadNotification:(NSNotification *)note {
   [[_taskPipe fileHandleForReading] readInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

+(void)initialize {
   if(self==[NSTask_posix class]){
    NSFileHandle *forReading;
    
    _liveTasks=[[NSMutableArray alloc] init];
    _taskPipe=[[NSPipe alloc] init];
    forReading=[_taskPipe fileHandleForReading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(signalPipeReadNotification:)
      name:NSFileHandleReadCompletionNotification object:forReading];
    
    [forReading readInBackgroundAndNotifyForModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
   }
}

-init {
   _launchPath=nil;
   _arguments=nil;
   _currentDirectoryPath=[[[NSFileManager defaultManager] currentDirectoryPath] copy];
   _isRunning=NO;
   return self;
}

-(void)dealloc {
   [_launchPath release];
   [_arguments release];
   [_currentDirectoryPath release];
   [_stdin release];
   [_stdout release];
   [_stderr release];

   [super dealloc];
}

-(void)setLaunchPath:(NSString *)path {
   [_launchPath autorelease];
   _launchPath=[path copy];
}

-(void)setArguments:(NSArray *)arguments {
   [_arguments autorelease];
   _arguments=[arguments copy];
}

-(void)setCurrentDirectoryPath:(NSString *)path {
   [_currentDirectoryPath autorelease];
   _currentDirectoryPath=[path copy];
}

-(NSString *)launchPath {
   return _launchPath;
}

-(int)processIdentifier {
   return _processID;
}

-(NSArray *)arguments {
   return _arguments;
}

-(NSString *)currentDirectoryPath {
   return _currentDirectoryPath;
}

-(BOOL)isRunning {
   return _isRunning;
}

-(void)setStandardInput:input {
    _stdin = [input retain];
}

-(void)setStandardOutput:output {
    _stdout = [output retain];
}

-(void)setStandardError:error {
    _stderr = [error retain];
}

-(void)launch {
   if(_launchPath==nil)
    [NSException raise:NSInvalidArgumentException
                format:@"NSTask launchPath is nil"];

   _processID = fork(); 
   if (_processID == 0) {  // child process
       NSMutableArray *array = [[_arguments mutableCopy] autorelease];
       const char     *path = [_launchPath cString];
       NSInteger            i,count=[array count];
       char          *args[count+1];
       
       if (array == nil)
           array = [NSMutableArray array];

       [array insertObject:_launchPath atIndex:0];
       for(i=0;i<count;i++)
        args[i]=(char *)[[[array objectAtIndex:i] description] cString];
       args[i]=NULL;
       
       if ([_stdin isKindOfClass:[NSFileHandle class]] || [_stdin isKindOfClass:[NSPipe class]]) {
           int fd = -1;
           
           close(STDIN_FILENO);
           if ([_stdin isKindOfClass:[NSFileHandle class]])
               fd = [(NSFileHandle_posix *)_stdin fileDescriptor];
           else
               fd = [(NSFileHandle_posix *)[_stdin fileHandleForReading] fileDescriptor];

           dup2(fd, STDIN_FILENO);
       }
       if ([_stdout isKindOfClass:[NSFileHandle class]] || [_stdout isKindOfClass:[NSPipe class]]) {
           int fd = -1;

           close(STDOUT_FILENO);
           if ([_stdout isKindOfClass:[NSFileHandle class]])
               fd = [(NSFileHandle_posix *)_stdout fileDescriptor];
           else
               fd = [(NSFileHandle_posix *)[_stdout fileHandleForWriting] fileDescriptor];

           dup2(fd, STDOUT_FILENO);
       }
       if ([_stderr isKindOfClass:[NSFileHandle class]] || [_stderr isKindOfClass:[NSPipe class]]) {
           int fd = -1;

           close(STDERR_FILENO);
           if ([_stderr isKindOfClass:[NSFileHandle class]])
               fd = [(NSFileHandle_posix *)_stderr fileDescriptor];
           else
               fd = [(NSFileHandle_posix *)[_stderr fileHandleForWriting] fileDescriptor];

           dup2(fd, STDERR_FILENO);
       }

       chdir([_currentDirectoryPath fileSystemRepresentation]);

       execve(path, args, NSPlatform_environ());
       [NSException raise:NSInvalidArgumentException
                   format:@"NSTask: execve(%s) returned: %s", path, strerror(errno)];
   }
   else if (_processID != -1) {
       _isRunning = YES;
       [_liveTasks addObject:self];
   }
   else
       [NSException raise:NSInvalidArgumentException
                   format:@"fork() failed: %s", strerror(errno)];
}

-(void)terminate {
   kill(_processID, SIGTERM);
   [_liveTasks removeObject:self];
}

-(int)terminationStatus { return _terminationStatus; }			// OSX specs this
-(void)setTerminationStatus:(int)terminationStatus { _terminationStatus = terminationStatus; }

-(void)taskFinished {
   _isRunning = NO;
   [_liveTasks removeObject:self];
}

@end
