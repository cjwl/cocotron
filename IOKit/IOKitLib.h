#import <IOKit/IOTypes.h>

IOKIT_EXPORT const mach_port_t kIOMasterPortDefault;  

// these go in IOKitKeys.h
#define kIOPlatformSerialNumberKey "IOPlatformSerialNumber"
#define kIOPropertyMatchKey		"IOPropertyMatch"
#define kIOServicePlane			"IOService"

IOKIT_EXPORT CFMutableDictionaryRef IOServiceMatching(const char *name);  

IOKIT_EXPORT io_service_t  IOServiceGetMatchingService(mach_port_t masterPort,CFDictionaryRef matching);  
IOKIT_EXPORT kern_return_t IOServiceGetMatchingServices(mach_port_t	masterPort,CFDictionaryRef matching,io_iterator_t *existing);

IOKIT_EXPORT CFTypeRef     IORegistryEntryCreateCFProperty(io_registry_entry_t entry,CFStringRef key,CFAllocatorRef allocator,IOOptionBits options);  

IOKIT_EXPORT io_object_t   IOIteratorNext(io_iterator_t iterator);

IOKIT_EXPORT kern_return_t IORegistryEntryGetParentEntry(io_registry_entry_t entry,const io_name_t plane,io_registry_entry_t *parent);

IOKIT_EXPORT kern_return_t IOObjectRelease(io_object_t object);  

