/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

/*  JPEG decode is based on the public domain implementation by Sean Barrett  http://www.nothings.org/stb_image.c  V 1.14 */

#import <Foundation/NSObject.h>
#import <ApplicationServices/ApplicationServices.h>
#import "KGImageSource.h"

@class NSData,NSDictionary;

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef   signed short  int16;
typedef unsigned int   uint32;
typedef   signed int    int32;
typedef unsigned int   uint;

typedef struct
{
   uint32 img_x, img_y;
   int img_n, img_out_n;

   #ifndef STBI_NO_STDIO
   FILE  *img_file;
   #endif
   uint8 *img_buffer, *img_buffer_end;
} stbi;

// huffman decoding acceleration
#define FAST_BITS   9  // larger handles more cases; smaller stomps less cache

typedef struct
{
   uint8  fast[1 << FAST_BITS];
   // weirdly, repacking this into AoS is a 10% speed loss, instead of a win
   uint16 code[256];
   uint8  values[256];
   uint8  size[257];
   unsigned int maxcode[18];
   int    delta[17];   // old 'firstsymbol' - old 'firstcode'
} huffman;

typedef struct
{
   #if STBI_SIMD
   unsigned short dequant2[4][64];
   #endif
   stbi s;
   huffman huff_dc[4];
   huffman huff_ac[4];
   uint8 dequant[4][64];

// sizes for components, interleaved MCUs
   int img_h_max, img_v_max;
   int img_mcu_x, img_mcu_y;
   int img_mcu_w, img_mcu_h;

// definition of jpeg image component
   struct
   {
      int id;
      int h,v;
      int tq;
      int hd,ha;
      int dc_pred;

      int x,y,w2,h2;
      uint8 *data;
      void *raw_data;
      uint8 *linebuf;
   } img_comp[4];

   uint32         code_buffer; // jpeg entropy-coded buffer
   int            code_bits;   // number of valid bits
   unsigned char  marker;      // marker seen while filling entropy buffer
   int            nomore;      // flag if we saw a marker so must stop

   int scan_n, order[4];
   int restart_interval, todo;
} jpeg;

// definition of jpeg image component

@interface KGImageSource_JPEG : KGImageSource {
   NSData *_jpg;
   uint8_t *_bitmap;
   jpeg jpeg_decoder;


   char *failure_reason;
}

@end
