#import <QuartzCore/CAMediaTimingFunction.h>
#import <Foundation/NSString.h>
#import <Foundation/NSRaise.h>

NSString * const kCAMediaTimingFunctionLinear=@"kCAMediaTimingFunctionLinear";
NSString * const kCAMediaTimingFunctionEaseIn=@"kCAMediaTimingFunctionEaseIn";
NSString * const kCAMediaTimingFunctionEaseOut=@"kCAMediaTimingFunctionEaseOut";
NSString * const kCAMediaTimingFunctionEaseInEaseOut=@"kCAMediaTimingFunctionEaseInEaseOut";
NSString * const kCAMediaTimingFunctionDefault=@"kCAMediaTimingFunctionDefault";

@implementation CAMediaTimingFunction

-initWithControlPoints:(float)c1x:(float)c1y:(float)c2x:(float)c2y {
   _c1x=c1x;
   _c1y=c1y;
   _c2x=c2x;
   _c2y=c2y;
   return self;
}

+functionWithControlPoints:(float)c1x:(float)c1y:(float)c2x:(float)c2y {
   return [[[self alloc] initWithControlPoints:c1x:c1y:c2x:c2y] autorelease];
}

+functionWithName:(NSString *)name {
   NSUnimplementedMethod();
   return nil;
}

-(void)getControlPointAtIndex:(size_t)index values:(float[2])ptr {
   NSUnimplementedMethod();
}

@end
