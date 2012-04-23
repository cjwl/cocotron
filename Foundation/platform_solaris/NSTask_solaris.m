/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - David Young <daver@geeks.org>
#import <Foundation/NSTask_solaris.h>
#import <Foundation/Foundation.h>

#define _USE_BSD
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>

#include <signal.h>

@interface NSTask(NSTask_posix)
-(void)setTerminationStatus:(int)terminationStatus;
-(void)taskFinished;
@end

// in POSIX implementation

extern NSMutableArray *_liveTasks; // = nil;

@implementation NSTask_solaris

/*
     SA_RESTART
           If set and the signal is caught,  functions  that  are
           interrupted  by the execution of this signal's handler
           are transparently  restarted  by  the  system,  namely
           fcntl(2), ioctl(2),  wait(2),
            waitid(2), and the following functions on  slow  dev-
           ices  like  terminals:  getmsg()  and  getpmsg()  (see
           getmsg(2));  putmsg() and putpmsg()  (see  putmsg(2));
           pread(),  read(), and readv() (see read(2)); pwrite(),
           write(),  and   writev()   (see   write(2));   recv(),
           recvfrom(),  and  recvmsg()  (see  recv(3SOCKET)); and
           send(), sendto(), and  sendmsg()  (see  send(3SOCKET).
           Otherwise, the function returns an  EINTR error.

     ... note that select() isn't one of those calls.
 */
+(void)initialize {
   if (self == [NSTask_solaris class]) {
       struct sigaction sa;

       sigaction (SIGCHLD, (struct sigaction *)0, &sa);
       sa.sa_flags |= SA_RESTART;
       sa.sa_handler = childSignalHandler;
       sigaction (SIGCHLD, &sa, (struct sigaction *)0);
   }
}

/*
     The wait4() function is an extended interface.  With  a  pid
     argument  of  0,  it  is equivalent to wait3(). If pid has a
     nonzero value, then wait4()  returns  status  only  for  the
     indicated process ID, but not for any other child processes.
     The status can be evaluated  using  the  macros  defined  by
     wstat(3XFN).
 */
+(void)signalPipeReadNotification:(NSNotification *)note {
   NSTask *task;
   pid_t pid;
   int status;

   [super signalPipeReadNotification:note];

   pid = wait4(0, &status, WNOHANG, NULL);
   if (pid < 0) {
       // [NSException raise:NSInvalidArgumentException format:@"wait4(): %s", strerror(errno)];
   }
   else if (pid == 0) {
    // This can happen when a child is suspended (^Z'ing at the shell)
       // something got out of synch here
      // [NSException raise:NSInternalInconsistencyException format:@"wait4() returned 0, but data was fed to the pipe!"];
   }
   else {
       @synchronized(_liveTasks) {
           NSEnumerator *taskEnumerator = [_liveTasks objectEnumerator];
           while (task = [taskEnumerator nextObject]) {
               if ([task processIdentifier] == pid) {
                   if (WIFEXITED(status))
                       [task setTerminationStatus:WEXITSTATUS(status)];
                   else
                       [task setTerminationStatus:-1];
                   
                   [task taskFinished];
                   
                   [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: NSTaskDidTerminateNotification object:task]];
                   
                   return;
               }
           }
       }
       
       // something got out of synch here
       [NSException raise:NSInternalInconsistencyException format:@"wait4() returned %d, but we have no matching task!", pid];
   }
}
   
@end
