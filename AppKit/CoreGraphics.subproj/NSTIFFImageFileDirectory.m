/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSTIFFImageFileDirectory.h"
#import "NSTIFFReader.h"
#import "KGPDFFilter.h"
#import <ApplicationServices/ApplicationServices.h>

@implementation NSTIFFImageFileDirectory

-initWithTIFFReader:(NSTIFFReader *)reader {
   unsigned i,numberOfEntries=[reader nextUnsigned16];

   _xPosition=0;
   _xResolution=72.0;
   _yPosition=0;
   _yResolution=72.0;
   
   for(i=0;i<numberOfEntries;i++){
    unsigned offset=[reader currentOffset];
    unsigned tag=[reader nextUnsigned16];

    switch(tag){

     case NSTIFFTagArtist:
      _artist=[[reader expectASCII] copy];
      break;

     case NSTIFFTagBitsPerSample:
      [reader expectArrayOfUnsigned16:&_bitsPerSample count:&_sizeOfBitsPerSample];
      break;

     case NSTIFFTagCellLength:
      _cellLength=[reader expectUnsigned16];
      break;

     case NSTIFFTagCellWidth:
      _cellWidth=[reader expectUnsigned16];
      break;

     case NSTIFFTagColorMap:
      [reader expectArrayOfUnsigned16:&_colorMap count:&_sizeOfColorMap];
      break;

     case NSTIFFTagCompression:
      _compression=[reader expectUnsigned16];
      break;

     case NSTIFFTagCopyright:
      _copyright=[[reader expectASCII] copy];
      break;

     case NSTIFFTagDateTime:
      _dateTime=[[reader expectASCII] copy];
      break;

     case NSTIFFTagDocumentName:
      _documentName=[[reader expectASCII] copy];
      break;

     case NSTIFFTagExtraSamples:
      [reader expectArrayOfUnsigned16:&_extraSamples count:&_sizeOfExtraSamples];
      break;

     case NSTIFFTagFillOrder:
      _fillOrder=[reader expectUnsigned16];
      break;

     case NSTIFFTagFreeByteCounts:
      _freeByteCounts=[reader expectUnsigned32];
      break;

     case NSTIFFTagFreeOffsets:
      _freeByteCounts=[reader expectUnsigned32];
      break;

     case NSTIFFTagGrayResponseCurve:
      [reader expectArrayOfUnsigned16:&_grayResponseCurve count:&_sizeOfGrayResponseCurve];
      break;

     case NSTIFFTagGrayResponseUnit:
      _grayResponseUnit=[reader expectUnsigned16];
      break;

     case NSTIFFTagHostComputer:
      _hostComputer=[[reader expectASCII] copy]; 
      break;

     case NSTIFFTagImageDescription:
      _imageDescription=[[reader expectASCII] copy]; 
      break;

     case NSTIFFTagImageLength:
      _imageLength=[reader expectUnsigned16OrUnsigned32];
      break;

     case NSTIFFTagImageWidth:
      _imageWidth=[reader expectUnsigned16OrUnsigned32];
      break;

     case NSTIFFTagMake:
      _make=[[reader expectASCII] copy]; 
      break;

     case NSTIFFTagMaxSampleValue:
      [reader expectArrayOfUnsigned16:&_maxSampleValue count:&_sizeOfMaxSampleValue];
      break;

     case NSTIFFTagMinSampleValue:
      [reader expectArrayOfUnsigned16:&_minSampleValue count:&_sizeOfMinSampleValue];
      break;

     case NSTIFFTagModel:
      _model=[[reader expectASCII] copy]; 
      break;

     case NSTIFFTagNewSubfileType:
      _newSubfileType=[reader expectUnsigned32];
      break;

     case NSTIFFTagOrientation:
      _orientation=[reader expectUnsigned16];
      break;

     case NSTIFFTagPageName:
      _pageName=[[reader expectASCII] copy]; 
      break;

     case NSTIFFTagPageNumber:
      [reader expectArrayOfUnsigned16:&_pageNumbers count:&_sizeOfPageNumbers];
      break;

     case NSTIFFTagPhotometricInterpretation:
      _photometricInterpretation=[reader expectUnsigned16];
      break;

     case NSTIFFTagPlanarConfiguration:
      _planarConfiguration=[reader expectUnsigned16];
      break;

     case NSTIFFTagResolutionUnit:
      _resolutionUnit=[reader expectUnsigned16];
      break;

     case NSTIFFTagRowsPerStrip:
      _rowsPerStrip=[reader expectUnsigned16OrUnsigned32];
      break;

     case NSTIFFTagSampleFormat:
      [reader expectArrayOfUnsigned16:&_sampleFormats count:&_sizeOfSampleFormats];
      break;
     
     case NSTIFFTagSamplesPerPixel:
      _samplesPerPixel=[reader expectUnsigned16];
      break;

     case NSTIFFTagSoftware:
      _software=[[reader expectASCII] copy]; 
      break;

     case NSTIFFTagStripByteCounts:
      [reader expectArrayOfUnsigned16OrUnsigned32:&_stripByteCounts count:&_sizeOfStripByteCounts];
      break;

     case NSTIFFTagStripOffsets:
      [reader expectArrayOfUnsigned16OrUnsigned32:&_stripOffsets count:&_sizeOfStripOffsets];
      break;

     case NSTIFFTagSubfileType:
      _subfileType=[reader expectUnsigned16];
      break;

     case NSTIFFTagThreshholding:
      _threshholding=[reader expectUnsigned16];
      break;

     case NSTIFFTagXMP:
      [reader expectArrayOfUnsigned8:&_xmp count:&_sizeOfXMP];
      break;

     case NSTIFFTagXPosition:
      _xPosition=[reader expectRational];
      break;

     case NSTIFFTagXResolution:
      _xResolution=[reader expectRational];
      break;

     case NSTIFFTagYPosition:
      _yPosition=[reader expectRational];
      break;

     case NSTIFFTagYResolution:
      _yResolution=[reader expectRational];
      break;

     case NSTIFFTagPhotoshopPrivate1:
     case NSTIFFTagPhotoshopPrivate2:
      // ignore
      break;

     default:
      if([reader tracingEnabled])
       NSLog(@"TIFF trace: unknown tag=%d",tag);
      break;

    }
    [reader seekToOffset:offset+12];
   }
   return self;
}

-(void)dealloc {
   [_artist release];
   if(_bitsPerSample!=NULL)
    NSZoneFree([self zone],_bitsPerSample);
   if(_colorMap!=NULL)
    NSZoneFree([self zone],_colorMap);
   [_copyright release];
   [_dateTime release];
   [_documentName release];
   if(_extraSamples!=NULL)
    NSZoneFree([self zone],_extraSamples);
   if(_grayResponseCurve!=NULL)
    NSZoneFree([self zone],_grayResponseCurve);
   [_hostComputer release];
   [_imageDescription release];
   [_make release];
   if(_maxSampleValue!=NULL)
    NSZoneFree([self zone],_maxSampleValue);
   if(_minSampleValue!=NULL)
    NSZoneFree([self zone],_minSampleValue);
   [_model release];
   [_pageName release];
   if(_pageNumbers!=NULL)
    NSZoneFree([self zone],_pageNumbers);
   if(_sampleFormats!=NULL)
    NSZoneFree([self zone],_sampleFormats);
   [_software release];
   if(_stripByteCounts!=NULL)
    NSZoneFree([self zone],_stripByteCounts);
   if(_stripOffsets!=NULL)
    NSZoneFree([self zone],_stripOffsets);
   if(_xmp!=NULL)
    NSZoneFree([self zone],_xmp);

   [super dealloc];
}

-(int)imageLength {
   return _imageLength;
}

-(int)imageWidth {
   return _imageWidth;
}

static void decode_R8_G8_B8_A8(const unsigned char *stripBytes,unsigned byteCount,unsigned char *pixelBytes,int bytesPerRow,int *pixelBytesRowp,int height){
   int pixelBytesRow=*pixelBytesRowp;
   int pixelBytesCol=0;
   int i;

   for(i=0;i<byteCount;i++){
    pixelBytes[pixelBytesRow*bytesPerRow+pixelBytesCol]=stripBytes[i];
    pixelBytesCol++;

    if(pixelBytesCol>=bytesPerRow){
     pixelBytesCol=0;
     pixelBytesRow++;
     if(pixelBytesRow>=height)
      break;
    }
   }

   *pixelBytesRowp=pixelBytesRow;
}

static void decode_R8_G8_B8_Afill(const unsigned char *stripBytes,unsigned byteCount,unsigned char *pixelBytes,int bytesPerRow,int *pixelBytesRowp,int height){
   int pixelBytesRow=*pixelBytesRowp;
   int pixelBytesCol=0;
   int i;

   for(i=0;i<byteCount;i++){
    pixelBytes[pixelBytesRow*bytesPerRow+pixelBytesCol]=stripBytes[i];
    pixelBytesCol++;

    if(((pixelBytesCol+1)%4)==0){
     pixelBytes[pixelBytesRow*bytesPerRow+pixelBytesCol]=0xFF;
     pixelBytesCol++;
    }

    if(pixelBytesCol>=bytesPerRow){
     pixelBytesCol=0;
     pixelBytesRow++;
     if(pixelBytesRow>=height)
      break;
    }
   }

   *pixelBytesRowp=pixelBytesRow;
}

-(BOOL)getRGBAImageBytes:(unsigned char *)pixelBytes data:(NSData *)data {
   const unsigned char *bytes=[data bytes];
   unsigned             length=[data length];
   unsigned             strip,i;
   int                  bitsPerPixel,bytesPerRow,pixelBytesRow,pixelBytesCol;

// general checks
   if(_imageLength==0){
    NSLog(@"TIFF general failure, imageLength=0",_imageLength);
    return NO;
   }

   if(_imageWidth==0){
    NSLog(@"TIFF rastering error, imageWidth=0",_imageWidth);
    return NO;
   }

   if(_sizeOfStripByteCounts!=_sizeOfStripOffsets){
    NSLog(@"TIFF strip error, # of StripOffsets (%d) ! = # of StripByteCounts (%d)", _sizeOfStripOffsets, _sizeOfStripByteCounts);
    return NO;
   }

   if(_sizeOfBitsPerSample!=_samplesPerPixel){
    NSLog(@"TIFF data error, size of bitsPerSample array (%d) != samplesPerPixel (%d)",_sizeOfBitsPerSample,_samplesPerPixel);
    return NO;
   }

// specific checks for unimplemented features

   if(_compression!=NSTIFFCompression_none/* && _compression!=NSTIFFCompression_LZW*/){
    NSLog(@"TIFF unsupported, compression %d",_compression);
    return NO;
   }

   if(_samplesPerPixel!=4 && _samplesPerPixel!=3){
    NSLog(@"TIFF unsupported, samplesPerPixel!=4 or 3, got %d",_samplesPerPixel);
    return NO;
   }

   if(_sampleFormats!=NULL){
    for(i=0;i<_sizeOfSampleFormats;i++)
     if(_sampleFormats[i]!=NSTIFFSampleFormat_UINT){
      NSLog(@"TIFF unsupported, sampleFormats[%d]!=1, got %d",i,_sampleFormats[i]);
      return NO;
     }
   }
   
   bitsPerPixel=0;
   for(i=0;i<_sizeOfBitsPerSample;i++){
    bitsPerPixel+=_bitsPerSample[i];
    if(_bitsPerSample[i]!=8){
     NSLog(@"TIFF unsupported, bitsPerSample[%d]!=8, got %d",i, _bitsPerSample[i]);
     return NO;
    }
   }
   
   bytesPerRow=_imageWidth*4;
   pixelBytesRow=0;
   pixelBytesCol=0;

   if(_compression==NSTIFFCompression_LZW){
    
    for(strip=0;strip<_sizeOfStripOffsets;strip++){
     unsigned offset=_stripOffsets[strip];
     unsigned byteCount=_stripByteCounts[strip];

     if(offset+byteCount>length){
      NSLog(@"TIFF strip error, offset (%d) + byteCount (%d) > length (%d)",offset,byteCount,length);
      return NO;
     }
     NSData *data=[NSData dataWithBytes:bytes+offset length:byteCount];
     
     data=[KGPDFFilter LZWDecode_data:data parameters:nil];
     if(_samplesPerPixel==4)
      decode_R8_G8_B8_A8([data bytes],[data length],pixelBytes,bytesPerRow,&pixelBytesRow,_imageLength);
     else
      decode_R8_G8_B8_Afill([data bytes],[data length],pixelBytes,bytesPerRow,&pixelBytesRow,_imageLength);
    }
      
   }
   else {
    for(strip=0;strip<_sizeOfStripOffsets;strip++){
     unsigned offset=_stripOffsets[strip];
     unsigned byteCount=_stripByteCounts[strip];

     if(offset+byteCount>length){
      NSLog(@"TIFF strip error, offset (%d) + byteCount (%d) > length (%d)",offset,byteCount,length);
      return NO;
     }
     if(_samplesPerPixel==4)
      decode_R8_G8_B8_A8(bytes+offset,byteCount,pixelBytes,bytesPerRow,&pixelBytesRow,_imageLength);
     else
      decode_R8_G8_B8_Afill(bytes+offset,byteCount,pixelBytes,bytesPerRow,&pixelBytesRow,_imageLength);
    }
   }
   
   return YES;
}

-(NSDictionary *)properties {
   NSMutableDictionary *result=[NSMutableDictionary new];
   
   [result setObject:[NSNumber numberWithDouble:_xResolution] forKey:kCGImagePropertyDPIWidth];
   [result setObject:[NSNumber numberWithDouble:_yResolution] forKey:kCGImagePropertyDPIHeight];
   
   return result;
}

@end
