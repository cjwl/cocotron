
#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(CFNETWORK_INSIDE_BUILD)
#define CFNETWORK_EXPORT extern "C" __declspec(dllexport)
#else
#define CFNETWORK_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define CFNETWORK_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(CFNETWORK_INSIDE_BUILD)
#define CFNETWORK_EXPORT __declspec(dllexport) extern
#else
#define CFNETWORK_EXPORT __declspec(dllimport) extern
#endif
#else
#define CFNETWORK_EXPORT extern
#endif

#endif // __cplusplus
