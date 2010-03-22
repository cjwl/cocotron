
#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(CGL_INSIDE_BUILD)
#define CGL_EXPORT extern "C" __declspec(dllexport)
#else
#define CGL_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define CGL_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(CGL_INSIDE_BUILD)
#define CGL_EXPORT __declspec(dllexport) extern
#else
#define CGL_EXPORT __declspec(dllimport) extern
#endif
#else
#define CGL_EXPORT extern
#endif


#endif // __cplusplus

typedef enum {
   kCGLNoError=0,
   kCGLBadAttribute=10000,
   kCGLBadProperty=10001,
   kCGLBadPixelFormat=10002,
   kCGLBadRendererInfo=10003,
   kCGLBadContext=10004,
   kCGLBadDrawable=10005,
   kCGLBadDisplay=10006,
   kCGLBadState=10007,
   kCGLBadValue=10008,
   kCGLBadMatch=10009,
   kCGLBadEnumeration=10010,
   kCGLBadOffScreen=10011,
   kCGLBadFullScreen=10012,
   kCGLBadWindow=10013,
   kCGLBadAddress=10014,
   kCGLBadCodeModule=10015,
   kCGLBadAlloc=10016,
   kCGLBadConnection=10017,
} CGLError;

typedef enum {
   kCGLCPSwapInterval  =222,
   kCGLCPSurfaceOpacity=236,
} CGLContextParameter;

typedef struct _CGLContextObj *CGLContextObj;
typedef struct _CGLPixelFormatObj *CGLPixelFormatObj;
typedef struct _CGLPBufferObj *CGLPBufferObj;
