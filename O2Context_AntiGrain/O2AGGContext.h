#import <stdlib.h>

// There are some constructs in Onyx2D which cause compiler crashes with ObjC++
// So we're just wrapping the AGG calls with straight C until it is sorted out.

#ifdef __cplusplus
extern "C" {
#endif

typedef struct O2AGGContext *O2AGGContextRef;

O2AGGContextRef O2AGGContextCreateBGRA32(unsigned char *pixelBytes,size_t width,size_t height,size_t bytesPerRow);

void O2AGGContextBeginPath(O2AGGContextRef self);
void O2AGGContextMoveTo(O2AGGContextRef self,double x,double y);
void O2AGGContextAddLineTo(O2AGGContextRef self,double x,double y);
void O2AGGContextAddCurveToPoint(O2AGGContextRef self,double cp1x,double cp1y,double cp2x,double cp2y,double endx,double endy);
void O2AGGContextAddQuadCurveToPoint(O2AGGContextRef self,double cp1x,double cp1y,double endx,double endy);
void O2AGGContextCloseSubpath(O2AGGContextRef self);

void O2AGGContextClipReset(O2AGGContextRef self);
void O2AGGContextSetDeviceViewport(O2AGGContextRef self,int x,int y,int w,int h);
void O2AGGContextClipToPath(O2AGGContextRef self,int evenOdd);

void O2AGGContextFillPath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty);
void O2AGGContextEOFillPath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty);
void O2AGGContextStrokePath(O2AGGContextRef self,float r,float g,float b,float a,double xa,double xb,double xc,double xd,double xtx,double xty);

#ifdef __cplusplus
}
#endif
