#import <CoreGraphics/CGAffineTransform.h>
#import <CoreGraphics/CGFunction.h>
#import <CoreGraphics/CGPath.h>
#import <CoreGraphics/CGPattern.h>
#import "O2AffineTransform.h"
#import "O2Function.h"
#import "O2Pattern.h"
#import "O2Path.h"

static inline CGAffineTransform CGAffineTransformFromO2(O2AffineTransform xform){
   return *(CGAffineTransform *)&xform;
}

static inline O2AffineTransform O2AffineTransformFromCG(CGAffineTransform xform){
   return *(O2AffineTransform *)&xform;
}

static inline const O2AffineTransform *O2AffineTransformPtrFromCG(const CGAffineTransform *xform){
   return (const O2AffineTransform *)xform;
}

static inline const O2FunctionCallbacks *O2FunctionCallbacksFromCG(const CGFunctionCallbacks *callbacks){
   return (const O2FunctionCallbacks *)callbacks;
}

static inline const O2PatternCallbacks *O2PatternCallbacksFromCG(const CGPatternCallbacks *callbacks){
   return (const O2PatternCallbacks *)callbacks;
}

static inline const O2PathApplierFunction O2PathApplierFunctionFromCG(const CGPathApplierFunction function){
   return (const O2PathApplierFunction)function;
}
