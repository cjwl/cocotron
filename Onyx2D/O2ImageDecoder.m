#import <Onyx2D/O2ImageDecoder.h>

@implementation O2ImageDecoder

O2DataProviderRef O2ImageDecoderGetDataProvider(O2ImageDecoderRef self) {
    return self->_dataProvider;
}

size_t O2ImageDecoderGetWidth(O2ImageDecoderRef self) {
    return self->_width;
}

size_t O2ImageDecoderGetHeight(O2ImageDecoderRef self) {
    return self->_height;
}

size_t O2ImageDecoderGetBitsPerComponent(O2ImageDecoderRef self) {
    return self->_bitsPerComponent;
}

size_t O2ImageDecoderGetBitsPerPixel(O2ImageDecoderRef self) {
    return self->_bitsPerPixel;
}

size_t O2ImageDecoderGetBytesPerRow(O2ImageDecoderRef self) {
    return self->_bytesPerRow;
}

O2ColorSpaceRef O2ImageDecoderGetColorSpace(O2ImageDecoderRef self) {
    return self->_colorSpace;
}

O2BitmapInfo O2ImageDecoderGetBitmapInfo(O2ImageDecoderRef self) {
    return self->_bitmapInfo;
}

-(CFDataRef)createPixelData {
    return nil;
}

CFDataRef O2ImageDecoderCreatePixelData(O2ImageDecoderRef self) {
    return [self createPixelData];
}

@end