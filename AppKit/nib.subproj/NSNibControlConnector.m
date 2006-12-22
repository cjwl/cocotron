/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <AppKit/NSNibControlConnector.h>

@implementation NSNibControlConnector

-(void)establishConnection {
   SEL selector=NSSelectorFromString(_label);

   if(selector==NULL)
    [NSException raise:NSInvalidArgumentException
         format:@"-[%@ %s] selector %@ does not exist:",isa,SELNAME(_cmd),_label];

   if([_source respondsToSelector:@selector(setAction:)])
    [_source performSelector:@selector(setAction:) withObject:(id)selector];
   else {
    [NSException raise:NSInvalidArgumentException
         format:@"-[%@ %s] _source does not respond to setAction:",isa,SELNAME(_cmd)];
   }

   if([_source respondsToSelector:@selector(setTarget:)])
    [_source performSelector:@selector(setTarget:) withObject:_destination];
   else {
    [NSException raise:NSInvalidArgumentException
         format:@"-[%@ %s] _source does not respond to setTarget:",isa,SELNAME(_cmd)];
   }
}

@end
