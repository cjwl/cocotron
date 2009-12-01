#import "O2ImageDestination.h"
#import "O2Image.h"
#import "O2Exceptions.h"
#import "O2Encoder_TIFF.h"

@interface _O2ImageDestination : O2ImageDestination
@end

@implementation O2ImageDestination

CFTypeID O2ImageDestinationGetTypeID(void) {
   return 0;
}

CFArrayRef O2ImageDestinationCopyTypeIdentifiers(void) {
   O2UnimplementedFunction();
   return NULL;
}


O2ImageDestinationRef O2ImageDestinationCreateWithData(CFMutableDataRef data,CFStringRef type,size_t imageCount,CFDictionaryRef options) {
   O2DataConsumerRef consumer=O2DataConsumerCreateWithCFData(data);
   O2ImageDestinationRef self=O2ImageDestinationCreateWithDataConsumer(consumer,type,imageCount,options);
   O2DataConsumerRelease(consumer);
   return self;
}

O2ImageDestinationRef O2ImageDestinationCreateWithDataConsumer(O2DataConsumerRef dataConsumer,CFStringRef type,size_t imageCount,CFDictionaryRef options) {
   O2ImageDestinationRef self=NSAllocateObject([O2ImageDestination class],0,NULL);
   self->_consumer=O2DataConsumerRetain(dataConsumer);
   self->_type=(type==NULL)?NULL:CFRetain(type);
   self->_imageCount=imageCount;
   self->_options=(options==NULL)?NULL:CFRetain(options);
   self->_encoder=O2TIFFEncoderCreate(self->_consumer);
   O2TIFFEncoderBegin(self->_encoder);
   return self;
}

O2ImageDestinationRef O2ImageDestinationCreateWithURL(CFURLRef url,CFStringRef type,size_t imageCount,CFDictionaryRef options) {
   O2DataConsumerRef consumer=O2DataConsumerCreateWithURL(url);
   O2ImageDestinationRef self=O2ImageDestinationCreateWithDataConsumer(consumer,type,imageCount,options);
   O2DataConsumerRelease(consumer);
   return self;
}

void O2ImageDestinationSetProperties(O2ImageDestinationRef self,CFDictionaryRef properties) {
}

void O2ImageDestinationAddImage(O2ImageDestinationRef self,O2ImageRef image,CFDictionaryRef properties) {
   self->_imageCount--;
   O2TIFFEncoderWriteImage(self->_encoder,image,properties,(self->_imageCount==0)?YES:NO);
}

void O2ImageDestinationAddImageFromSource(O2ImageDestinationRef self,O2ImageSourceRef imageSource,size_t index,CFDictionaryRef properties) {
   O2ImageRef image=O2ImageSourceCreateImageAtIndex(imageSource,index,NULL);
   O2ImageDestinationAddImage(self,image,properties);
   O2ImageRelease(image);
}

bool O2ImageDestinationFinalize(O2ImageDestinationRef self) {
   O2TIFFEncoderEnd(self->_encoder);
   O2TIFFEncoderDealloc(self->_encoder);
   self->_encoder=NULL;
   return TRUE;
}

@end
