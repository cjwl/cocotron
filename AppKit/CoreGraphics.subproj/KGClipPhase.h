#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>

@class KGPath,KGImage;

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

-initWithNonZeroPath:(KGPath *)path;
-initWithEOPath:(KGPath *)path;
-initWithMask:(KGImage *)mask rect:(CGRect)rect transform:(CGAffineTransform)transform;

-(KGClipPhaseType)phaseType;
-object;

@end
