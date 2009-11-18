#import "O2ClipPhase.h"

@implementation O2ClipPhase

-initWithNonZeroPath:(O2Path *)path {
   _type=O2ClipPhaseNonZeroPath;
   _object=[path copy];
   return self;
}

-initWithEOPath:(O2Path *)path {
   _type=O2ClipPhaseEOPath;
   _object=[path copy];
   return self;
}

-initWithMask:(O2Image *)mask rect:(O2Rect)rect transform:(O2AffineTransform)transform {
   _type=O2ClipPhaseMask;
   _object=[mask retain];
   _rect=rect;
   _transform=transform;
   return self;
}

-(void)dealloc {
   [_object release];
   [super dealloc];
}

-(O2ClipPhaseType)phaseType {
   return _type;
}

-object {
   return _object;
}

@end
