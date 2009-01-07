/*
Original Author: Michael Ash on 11/7/08.
Copyright (c) 2008 Rogue Amoeba Software LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#import <Foundation/NSObject.h>

@class NSCondition;

// FIXME: the original class used mach ports, possible switch to NSCondition when it is implemented
/*
 
 A lockless mostly non-blocking latching trigger class.
 
 This class allows one thread to wait on actions from other threads. It is
 latching, meaning that a signal which arrives when nothing is waiting will
 cause the next waiter to immediately proceed. Multiple signals that are sent
 in succession when no thread is waiting will still only un-block a thread once.
 A signal sent when the latch is already triggered does nothing.
 
 A signaling thread is guaranteed never to block. A waiting thread only
 blocks if no signal has been sent. In other words, it is non-blocking
 except in cases where a thread really does have to wait.
 
 Examples:
 
 thread A waits, no signal has been sent so it blocks
 thread B signals, so thread A returns from waiting
 
 thread B signals
 thread A waits, sees the signal, and immediately returns
 
 thread B signals
 thread B signals again
 thread A waits, sees the signal, and immediately returns
 thread A waits again, and blocks waiting for a signal
 
 */
@interface NSLatchTrigger : NSObject
{
   NSCondition *_condition;
}

- (id)init;

- (void)signal;
- (void)wait;

@end
