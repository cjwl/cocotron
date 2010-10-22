#import <IOKit/IOKitLib.h>
#import <IOKit/network/IONetworkController.h>
#import <IOKit/network/IOEthernetInterface.h>
#import <IOKit/network/IONetworkInterface.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <windows.h>
#import <Iphlpapi.h>

static NSData *PrimaryEthernetMAC(){
   struct _IP_ADAPTER_INFO info[16],*check;
   DWORD           infoSize=sizeof(info);
   DWORD           status=GetAdaptersInfo(info,&infoSize);
   
   for(check=info;check!=NULL;check=check->Next){
    
    if(check->Type==MIB_IF_TYPE_ETHERNET){
     if(check->AddressLength==6){
      NSData *result=[[NSData alloc] initWithBytes:check->Address length:check->AddressLength];
      return result;
     }
    }
   }
   return nil;
}

@interface IOPlatformExpertDevice : NSObject 

-createCFProperty:name;

@end

@interface IOEthernetInterface : NSObject 

-initPrimary;

@end

@interface IONetworkController : NSObject 

@end

@implementation IOPlatformExpertDevice : NSObject

-createCFProperty:name {

   if([name isEqual:CFSTR(kIOPlatformSerialNumberKey)]){
    NSData *data=PrimaryEthernetMAC();
    
    if(data==nil)
     return NULL;
    else {
// **** WARNING: DO NOT CHANGE THIS. Application software may depend on the serial number for cryptography.
// The serial number is the primary MAC address with each nibble inverted in hex format
     NSInteger      i,length=[data length];
     const char    *hex="FEDCBA9876543210";
     unichar        buffer[length*2];
     const uint8_t *bytes=[data bytes];
     
     for(i=0;i<length;i++){
      uint8_t hi=bytes[i]>>4;
      uint8_t lo=bytes[i]&0x0F;
      
      buffer[i*2]=hex[hi];
      buffer[i*2+1]=hex[lo];
     }
     
     return [[NSString alloc] initWithCharacters:buffer length:length*2];
    }
   }
   
   return nil;
}

@end

@implementation IOEthernetInterface : NSObject

-initPrimary {
   return self;
}

-createParentEntry:name {
   if([name isEqual:CFSTR(kIOServicePlane)])
    return [[IONetworkController alloc] initPrimary];
   
   return nil;
}

@end

@implementation IONetworkController : NSObject

-initPrimary {
   return self;
}

-createCFProperty:name {

   if([name isEqual:CFSTR(kIOMACAddress)])
    return PrimaryEthernetMAC();
   
   return nil;
}

@end



const mach_port_t kIOMasterPortDefault=0;  

#define kIOProviderClassKey "kIOProviderClass"

CFMutableDictionaryRef IOServiceMatching(const char *name) {
   return [NSMutableDictionary dictionaryWithObject:[NSString stringWithCString:name] forKey:CFSTR(kIOProviderClassKey)];
}

io_service_t IOServiceGetMatchingService(mach_port_t masterPort,CFDictionaryRef matching) {
   NSString *type=[matching objectForKey:CFSTR(kIOProviderClassKey)];
   
   if([type isEqual:@"IOPlatformExpertDevice"])
    return [[IOPlatformExpertDevice alloc] init];

   return 0;
}

kern_return_t IOServiceGetMatchingServices(mach_port_t	masterPort,CFDictionaryRef matching,io_iterator_t *existing) {
   NSMutableArray *result=[NSMutableArray array];
   NSString *type=[matching objectForKey:CFSTR(kIOProviderClassKey)];

   if([type isEqual:@"IOEthernetInterface"]){
    NSDictionary *propertyMatch=[matching objectForKey:CFSTR(kIOPropertyMatchKey)];
    NSNumber *isPrimary=[propertyMatch objectForKey:CFSTR(kIOPrimaryInterface)];
    
    if([isPrimary boolValue]){
     [result addObject:[[[IOEthernetInterface alloc] initPrimary] autorelease]];
    }
   }

   *existing=[[result objectEnumerator] retain];

   return 0;
}

CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry,CFStringRef key,CFAllocatorRef allocator,IOOptionBits options) {
   return [entry createCFProperty:key];
}

io_object_t IOIteratorNext(io_iterator_t iterator) {
   return [[iterator nextObject] retain];
}

kern_return_t IORegistryEntryGetParentEntry(io_registry_entry_t entry,const io_name_t plane,io_registry_entry_t *parent) {
   *parent=[entry createParentEntry:CFSTR(plane)];
   return 0;
}

kern_return_t IOObjectRelease(io_object_t object) {
   [object release];
   return 0;
}

