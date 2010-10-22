#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(PDFKIT_INSIDE_BUILD)
#define PDFKIT_EXPORT extern "C" __declspec(dllexport)
#else
#define PDFKIT_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define PDFKIT_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(PDFKIT_INSIDE_BUILD)
#define PDFKIT_EXPORT __declspec(dllexport) extern
#else
#define PDFKIT_EXPORT __declspec(dllimport) extern
#endif
#else
#define PDFKIT_EXPORT extern
#endif

#endif
