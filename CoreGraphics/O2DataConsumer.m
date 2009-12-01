#import "O2DataConsumer.h"
#import "O2Exceptions.h"

@implementation O2DataConsumer

-initWithMutableData:(NSMutableData *)data {
   _data=[data retain];
   return self;
}

-(void)dealloc {
   [_data release];
   [super dealloc];
}

-(NSMutableData *)mutableData {
   return _data;
}

O2DataConsumerRef O2DataConsumerCreateWithCFData(CFMutableDataRef data) {
   return [[O2DataConsumer alloc] initWithMutableData:(NSMutableData *)data];
}

O2DataConsumerRef O2DataConsumerCreateWithURL(CFURLRef url) {
   O2UnimplementedFunction();
   return NULL;
}

O2DataConsumerRef O2DataConsumerRetain(O2DataConsumerRef self) {
   return (self!=NULL)?(O2DataConsumerRef)CFRetain(self):NULL;
}

void O2DataConsumerRelease(O2DataConsumerRef self) {
   if(self!=NULL)
    CFRelease(self);
}

size_t O2DataConsumerPutBytes(O2DataConsumerRef self,const void *buffer,size_t count) {
   [self->_data appendBytes:buffer length:count];
   return count;
}

@end

