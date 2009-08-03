#import <Foundation/NSObject.h>
#import <CoreGraphics/CoreGraphics.h>

@class O2Path,KGImage;

typedef enum {
 KGClipPhaseNonZeroPath,
 KGClipPhaseEOPath,
 KGClipPhaseMask,
} KGClipPhaseType;

@interface KGClipPhase : NSObject {
   KGClipPhaseType _type;
   id     _object;
   CGRect _rect;
   CGAffineTransform _transform;
}

-initWithNonZeroPath:(O2Path *)path;
-initWithEOPath:(O2Path *)path;
-initWithMask:(KGImage *)mask rect:(CGRect)rect transform:(CGAffineTransform)transform;

-(KGClipPhaseType)phaseType;
-object;

@end
