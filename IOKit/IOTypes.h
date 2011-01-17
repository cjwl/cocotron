#import <CoreFoundation/CoreFoundation.h>

#ifdef __cplusplus

#if defined(__WIN32__)
#if defined(IOKIT_INSIDE_BUILD)
#define IOKIT_EXPORT extern "C" __declspec(dllexport)
#else
#define IOKIT_EXPORT extern "C" __declspec(dllimport) 
#endif
#else
#define IOKIT_EXPORT extern "C"
#endif

#else

#if defined(__WIN32__)
#if defined(IOKIT_INSIDE_BUILD)
#define IOKIT_EXPORT __declspec(dllexport) extern
#else
#define IOKIT_EXPORT __declspec(dllimport) extern
#endif
#else
#define IOKIT_EXPORT extern
#endif


#endif // __cplusplus

typedef mach_port_t	io_object_t;
typedef io_object_t io_service_t;
typedef io_object_t io_registry_entry_t;
typedef io_object_t io_iterator_t;
typedef io_object_t io_name_t;

typedef UInt32		IOOptionBits;
