#import <CoreVideo/CVDisplayLink.h>
#import <Foundation/NSRaise.h>

// FIXME: use only one timer for all the display links, this will reduce run loop overhead

@interface CVDisplayLink : NSObject {
   NSTimer *_timer;
   CVDisplayLinkOutputCallback _callback;
   void  *_userInfo;
}

@end

@implementation CVDisplayLink

-init {
   return self;
}

-(void)dealloc {
   [_timer invalidate];
   [_timer release];
   [super dealloc];
}

-(void)timer:(NSTimer *)timer {
   if(_callback!=NULL)
    _callback(self,NULL,NULL,0,NULL,_userInfo);
}

-(void)start {
   _timer=[[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES] retain];
}

CVReturn CVDisplayLinkCreateWithActiveCGDisplays(CVDisplayLinkRef *result) {
   *result=[[CVDisplayLink alloc] init];
   return 0;
}

CVReturn CVDisplayLinkSetOutputCallback(CVDisplayLinkRef self,CVDisplayLinkOutputCallback callback,void *userInfo) {
   self->_callback=callback;
   self->_userInfo=userInfo;
   return 0;
}

CVReturn CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(CVDisplayLinkRef self,CGLContextObj cglContext,CGLPixelFormatObj cglPixelFormat) {
   return 0;
}

CVReturn CVDisplayLinkStart(CVDisplayLinkRef self) {
   [self start];
   return 0;
}

void CVDisplayLinkRelease(CVDisplayLinkRef self) {
   [self release];
}

@end
