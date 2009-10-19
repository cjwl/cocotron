/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread-Private.h>
#import <Foundation/NSRaiseException.h>

@implementation NSAutoreleasePool

#define PAGESIZE 1024

void objc_noAutoreleasePool(id object) {
   NSCLog("autorelease pool is nil, leaking %x %s",object,object_getClassName(object));
}

static inline void addObject(NSAutoreleasePool *self,id object){
   if(self==nil){
    objc_noAutoreleasePool(object);
    return;
   }
   
   if(self->_nextSlot>=self->_pageCount*PAGESIZE){
    self->_pageCount++;
    self->_pages=NSZoneRealloc(NULL,self->_pages,self->_pageCount*sizeof(id *));
    self->_pages[self->_pageCount-1]=NSZoneMalloc(NULL,PAGESIZE*sizeof(id));
   }

   self->_pages[self->_nextSlot/PAGESIZE][self->_nextSlot%PAGESIZE]=object;
   self->_nextSlot++;
}

+(void)addObject:object {
   if(NSThreadCurrentPool()==nil)
    [NSException raise:@"NSAutoreleasePoolException"
                format:@"NSAutoreleasePool no current pool"];

   addObject(NSThreadCurrentPool(),object);
}

-init {
   NSAutoreleasePool *current=NSThreadCurrentPool();

   _parent=current;

   _pageCount=1;
   _pages=NSZoneMalloc(NULL,_pageCount*sizeof(id *));
   _pages[0]=NSZoneMalloc(NULL,PAGESIZE*sizeof(id));
   _nextSlot=0;

   if(current!=nil)
    current->_childPool=self;
   _childPool=nil;

   NSThreadSetCurrentPool(self);

   return self;
}

-(void)dealloc {
   int i;

   [_childPool release];

   for(i=0;i<_nextSlot;i++){
    NS_DURING
     id object=_pages[i/PAGESIZE][i%PAGESIZE];

     [object release];
    NS_HANDLER
     NSLog(@"Exception while autoreleasing %@",localException);
    NS_ENDHANDLER
   }

   for(i=0;i<_pageCount;i++)
    NSZoneFree(NULL,_pages[i]);

   NSZoneFree(NULL,_pages);

   NSThreadSetCurrentPool(_parent);

   if(_parent!=nil)
    _parent->_childPool=nil;

   NSDeallocateObject(self);
   return;
   [super dealloc];
}

-(void)addObject:object {
   addObject(self,object);
}

id NSAutorelease(id object){
   addObject(NSThreadCurrentPool(),object);
   return object;
}

-(void)drain
{
	[self release];
}

-retain {
   [NSException raise:NSInvalidArgumentException format:@"-[NSAutoreleasePool retain] not allowed"];
   return nil;
}

@end
