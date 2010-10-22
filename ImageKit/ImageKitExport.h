#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(IMAGEKIT_INSIDE_BUILD)
#define IMAGEKIT_EXPORT extern "C" __declspec(dllexport)
#else
#define IMAGEKIT_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define IMAGEKIT_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(IMAGEKIT_INSIDE_BUILD)
#define IMAGEKIT_EXPORT __declspec(dllexport) extern
#else
#define IMAGEKIT_EXPORT __declspec(dllimport) extern
#endif
#else
#define IMAGEKIT_EXPORT extern
#endif

#endif

