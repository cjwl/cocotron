
#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(COREDATA_INSIDE_BUILD)
#define COREDATA_EXPORT extern "C" __declspec(dllexport)
#else
#define COREDATA_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define COREDATA_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(COREDATA_INSIDE_BUILD)
#define COREDATA_EXPORT __declspec(dllexport) extern
#else
#define COREDATA_EXPORT __declspec(dllimport) extern
#endif
#else
#define COREDATA_EXPORT extern
#endif

#endif

