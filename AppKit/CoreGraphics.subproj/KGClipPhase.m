#import "KGClipPhase.h"

@implementation KGClipPhase

-initWithNonZeroPath:(KGPath *)path {
   _type=KGClipPhaseNonZeroPath;
   _object=[path copy];
   return self;
}

-initWithEOPath:(KGPath *)path {
   _type=KGClipPhaseEOPath;
   _object=[path copy];
   return self;
}

-initWithMask:(KGImage *)mask rect:(CGRect)rect transform:(CGAffineTransform)transform {
   _type=KGClipPhaseMask;
   _object=[mask retain];
   _rect=rect;
   _transform=transform;
   return self;
}

-(void)dealloc {
   [_object release];
   [super dealloc];
}

-(KGClipPhaseType)phaseType {
   return _type;
}

-object {
   return _object;
}

@end
