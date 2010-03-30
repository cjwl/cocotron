/*
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 * Copyright (c) 2009 Vladimir Kirillov <proger@hackndev.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
// Original - David Young <daver@geeks.org>

#import <Foundation/NSTask_bsd.h>
#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>

#include <signal.h>
#include <errno.h>

@interface NSTask(NSTask_posix)
- (void)setTerminationStatus:(int)terminationStatus;
- (void)taskFinished;
@end

// in POSIX implementation

extern NSMutableArray *_liveTasks; // = nil;

@implementation NSTask_bsd
 
+(void)initialize
{
	if (self == [NSTask_bsd class]) {
		 struct sigaction sa;
/*
		 signal(SIGCHLD, childSignalHandler);
		 siginterrupt(SIGCHLD, 0);
 */
		 sigaction(SIGCHLD, NULL, &sa);
		 sa.sa_flags |= SA_RESTART;
		 sa.sa_handler = childSignalHandler;
		 sigaction(SIGCHLD, &sa, NULL);
	}
}

// Iterate through the monitors we know, calling wait4() on them to determine their state.
// There is enough API on Linux that we could extend OPENSTEP so that we'd know more about
// the child process; right now all cases are EventSignaled. We could have stuff about
// whether the child process exited normally/crashed/whatever, but none of that is in
// OPENSTEP yet so I'll leave that to a future programmer. --dwy 9/5/2002
+ (void)signalPipeReadNotification:(NSNotification *)note
{
	NSTask *task;
	pid_t pid;
	int status;

	[super signalPipeReadNotification:note];
	
	pid = wait4(-1, &status, WNOHANG, NULL);
	if (pid < 0) {
		 [NSException raise:NSInvalidArgumentException
					 format:@"wait4(): %s", strerror(errno)];
	}
	else if (pid == 0) {
		 // something got out of synch here
		 [NSException raise:NSInternalInconsistencyException
					 format:@"wait4() returned 0, but data was fed to the pipe!"];
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
                    
					[[NSNotificationCenter defaultCenter]
                     postNotification:[NSNotification
                                       notificationWithName:
                                       NSTaskDidTerminateNotification object:task]];
                    
					return;
                }
            }
         }

		 // something got out of synch here
		 [NSException raise:NSInternalInconsistencyException
					 format:@"wait4() returned %d, but we have no matching task!", pid];
	}
}
	
@end
