/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
                 2009 Markus Hitter <mah@jump-ing.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/Win32EventInputSource.h>
#import <AppKit/Win32Display.h>
#import <AppKit/Win32Event.h>
#import <AppKit/NSEvent_periodic.h>
#import <AppKit/NSEvent_CoreGraphics.h>

@implementation Win32EventInputSource

/* We only post periodic events if there are no other normal events, otherwise
   a long event handling can constantly only generate periodics
 */
-(BOOL)processInputImmediately {
   BOOL hadPeriodic=[[Win32Display currentDisplay] containsAndRemovePeriodicEvents];
   MSG  msg;

   if(PeekMessage(&msg,NULL,0,0,PM_REMOVE)){        
        
        if(msg.message==COCOTRON_CHILD_PAINT) {
            // IMPORTANT: Since the OpenGL (child) window thread is pushing events through as fast
            // as it receives them we need to coalesce paints here to prevent pile up.
            while(YES){
                MSG check;

                if(!PeekMessage(&check,msg.hwnd,0,0,PM_NOREMOVE))
                    break;
                                            
                if(check.message==COCOTRON_CHILD_PAINT){
                    // I suppose it is posssible this fails after a PM_NOREMOVE
                    PeekMessage(&msg,msg.hwnd,0,0,PM_REMOVE);
                }
                else {
                    break;
                }
            }
        }

        if(msg.message==COCOTRON_CHILD_EVENT) {
            Win32ChildMSG *childMSG=(Win32ChildMSG *)msg.wParam;
            
            #warning investigate the flags on mouse moved to see if we are dropping enter/exit ones
            
            if(childMSG->msg.message==WM_MOUSEMOVE){
                // IMPORTANT: Since the OpenGL (child) window thread is pushing events through as fast
                // as it receives them we need to coalesce mouse moved here, should anyway to prevent lag.
                // flush all mouse moved
                while(YES){
                    MSG check;

                    if(!PeekMessage(&check,msg.hwnd,0,0,PM_NOREMOVE))
                        break;
                                                
                    if(check.message==COCOTRON_CHILD_EVENT){
                        Win32ChildMSG *checkChildMSG=(Win32ChildMSG *)check.wParam;
                        
                        if(checkChildMSG->msg.message==WM_MOUSEMOVE){
                            free(childMSG); // we're discarding this event, so free the data
                        
                            // I suppose it is posssible this fails after a PM_NOREMOVE
                            PeekMessage(&msg,msg.hwnd,0,0,PM_REMOVE);
                            
                            childMSG=(Win32ChildMSG *)msg.wParam;
                        }
                        else {
                            break;
                        }
                    }
                    else {
                        break;
                    }
                }
            }
        }
        
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    
    BYTE keyState[256];
    BYTE *keyboardState=NULL;
    
    if(msg.message==COCOTRON_CHILD_EVENT){
        Win32ChildMSG *childMSG=(Win32ChildMSG *)msg.wParam;
        
        keyboardState=childMSG->keyboardState;
        msg.message=childMSG->msg.message;
        msg.wParam=childMSG->msg.wParam;
        msg.lParam=childMSG->msg.lParam;
    }
    else {
        if(GetKeyboardState(keyState))
            keyboardState=keyState;
    }
    
    if(![(Win32Display *)[Win32Display currentDisplay] postMSG:msg keyboardState:keyboardState]){
     Win32Event *cgEvent=[Win32Event eventWithMSG:msg];
     NSEvent    *event=[[[NSEvent_CoreGraphics alloc] initWithDisplayEvent:cgEvent] autorelease];

     [[Win32Display currentDisplay] postEvent:event atStart:NO];
    }
    
    if(msg.message==COCOTRON_CHILD_EVENT){
        Win32ChildMSG *childMSG=(Win32ChildMSG *)msg.wParam;
        free(childMSG);
    }
    
    [pool release];
    return YES;
   }

   if(hadPeriodic){
    NSEvent *event=[[[NSEvent_periodic alloc] initWithType:NSPeriodic location:NSMakePoint(0,0) modifierFlags:0 window:nil] autorelease];

    [[Win32Display currentDisplay] postEvent:event atStart:NO];
   }

   return NO;
}

-(NSUInteger)waitForEventsAndMultipleObjects:(HANDLE *)objects count:(NSUInteger)count milliseconds:(DWORD)milliseconds {
   if(count==0){
    UINT timer=SetTimer(NULL,0,milliseconds,NULL);

    WaitMessage();

    KillTimer(NULL,timer);
    return WAIT_TIMEOUT;
   }

   return MsgWaitForMultipleObjects(count,objects,FALSE,milliseconds,QS_ALLINPUT);
}


@end
