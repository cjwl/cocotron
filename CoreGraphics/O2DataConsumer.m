#import "O2DataConsumer.h"

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

O2DataConsumerRef O2DataConsumerCreateWithCFData(NSMutableData *data) {
   return [[O2DataConsumer alloc] initWithMutableData:data];
}

void O2DataConsumerRelease(O2DataConsumerRef self) {
   [self release];
}

@end

