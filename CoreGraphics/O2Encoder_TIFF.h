#import "O2DataConsumer.h"
#import "O2Image.h"
#import <stdbool.h>
#import <stdint.h>

typedef struct O2TIFFEncoder {
   bool              _bigEndian;
   size_t            _bufferOffset;
   size_t            _bufferPosition;
   size_t            _position;
   CFMutableDataRef  _buffer;
   uint8_t          *_mutablesBytes;
   CFIndex           _length;
   O2DataConsumerRef _consumer;
} *O2TIFFEncoderRef;

O2TIFFEncoderRef O2TIFFEncoderCreate(O2DataConsumerRef consumer);
void O2TIFFEncoderDealloc(O2TIFFEncoderRef self);

void O2TIFFEncoderBegin(O2TIFFEncoderRef self);
void O2TIFFEncoderWriteImage(O2TIFFEncoderRef self,O2ImageRef image,CFDictionaryRef properties,bool lastImage);
void O2TIFFEncoderEnd(O2TIFFEncoderRef self);

