/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <Foundation/NSSocketSet.h>

#ifndef WIN32
static inline unsigned roundToMaskWord(int fd){
   return (fd+NFDBITS-1)/NFDBITS;
}
#endif

NSSocketSet *NSSocketSetNew() {
   NSSocketSet *sset=NSZoneMalloc(NSDefaultMallocZone(),sizeof(NSSocketSet));

   sset->_max=FD_SETSIZE;
#ifdef WIN32
   sset->_set=NSZoneMalloc(NSDefaultMallocZone(),
         sizeof(u_int)+sizeof(SOCKET)*sset->_max);
#else
   sset->_set=NSZoneMalloc(NSDefaultMallocZone(),
         sizeof(fd_mask)*roundToMaskWord(sset->_max));
#endif
   return sset;
}

void NSSocketSetDealloc(NSSocketSet *sset) {
   NSZoneFree(NSDefaultMallocZone(),sset->_set);
   NSZoneFree(NSDefaultMallocZone(),sset);
}

void NSSocketSetZero(NSSocketSet *sset) {
#ifdef WIN32
   sset->_set->fd_count=0;
#elif defined(LINUX)
   int i,count=roundToMaskWord(sset->_max);

   for(i=0;i<count;i++)
    __FDS_BITS(sset->_set)[i]=0;
#else
   int i,count=roundToMaskWord(sset->_max);

   for(i=0;i<count;i++)
    sset->_set->fds_bits[i]=0;
#endif 
}

void NSSocketSetClear(NSSocketSet *sset,NSSocketDescriptor socket) {
#ifdef WIN32
   int  i;

   for(i=0;i<sset->_set->fd_count;i++){
    if(sset->_set->fd_array[i]==socket){
     sset->_set->fd_count--; 
     while(i<sset->_set->fd_count){
      sset->_set->fd_array[i]=sset->_set->fd_array[i+1];
      i++;
     } 
     break;
    } 
   } 
#elif defined(LINUX)
   __FDS_BITS(sset->_set)[socket/NFDBITS]&=~(1<<(socket%NFDBITS));
#else
   sset->_set->fds_bits[socket/NFDBITS]&=~(1<<(socket%NFDBITS));
#endif
}

void NSSocketSetSet(NSSocketSet *sset,NSSocketDescriptor socket) {
#ifdef WIN32
   if(sset->_set->fd_count>=sset->_max){
    sset->_max*=2;
    sset->_set=NSZoneRealloc(NSDefaultMallocZone(),sset->_set,
      sizeof(unsigned)+sizeof(SOCKET)*sset->_max);
   }
   sset->_set->fd_array[sset->_set->fd_count++]=socket;
#else
   while(socket>=sset->_max){
    int i=sset->_max;

    sset->_max*=2;
    sset->_set=NSZoneRealloc(NSDefaultMallocZone(),sset->_set,
      sizeof(fd_mask)*roundToMaskWord(sset->_max));

    for(;i<sset->_max;i++)
     NSSocketSetClear(sset,i);
   }
#ifdef LINUX
   __FDS_BITS(sset->_set)[socket/NFDBITS]|=(1<<(socket%NFDBITS));
#else
   sset->_set->fds_bits[socket/NFDBITS]|=(1<<(socket%NFDBITS));
#endif
#endif
}

BOOL NSSocketSetIsSet(NSSocketSet *sset,NSSocketDescriptor socket) {
#ifdef WIN32
   int i;

   for(i=0;i<sset->_set->fd_count;i++)
    if(sset->_set->fd_array[i]==socket)
     return YES;

   return NO;
#else
   if(socket>=sset->_max)
    return NO;

#ifdef LINUX
   return (__FDS_BITS(sset->_set)[socket/NFDBITS]&(1<<(socket%NFDBITS)))?YES:NO;
#else
   return (sset->_set->fds_bits[socket/NFDBITS]&(1<<(socket%NFDBITS)))?YES:NO;
#endif
#endif
}

fd_set *NSSocketSetFDSet(NSSocketSet *sset) {
   return sset->_set;
}
