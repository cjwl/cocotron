#import "NSRunLoopState_posix.h"
#import <Foundation/NSSelectInputSourceSet.h>
#import <Foundation/NSArray.h>
#import"NSCancelInputSource_posix.h"

@implementation NSRunLoopState(posix)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([NSRunLoopState_posix class],0,NULL);
}

@end

@implementation NSRunLoopState_posix

-init {
   _inputSourceSet=[[NSSelectInputSourceSet alloc] init];
   _asyncInputSourceSets=[[NSArray alloc] init];
   _timers=[NSMutableArray new];
   _cancelSource=[[NSCancelInputSource_posix alloc] init];
   [self addInputSource:_cancelSource];
   return self;
}

@end
