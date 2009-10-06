#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class O2Path,O2Image;

typedef enum {
 O2ClipPhaseNonZeroPath,
 O2ClipPhaseEOPath,
 O2ClipPhaseMask,
} O2ClipPhaseType;

@interface O2ClipPhase : NSObject {
   O2ClipPhaseType _type;
   id     _object;
   CGRect _rect;
   CGAffineTransform _transform;
}

-initWithNonZeroPath:(O2Path *)path;
-initWithEOPath:(O2Path *)path;
-initWithMask:(O2Image *)mask rect:(CGRect)rect transform:(CGAffineTransform)transform;

-(O2ClipPhaseType)phaseType;
-object;

@end
