/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

/*  JPEG decode is based on the public domain implementation by Sean Barrett  http://www.nothings.org/stb_image.c  V 1.00 */

#import "KGImageSource_JPEG.h"
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import "KGDataProvider.h"
#import "KGColorSpace.h"
#import "KGImage.h"

#import <assert.h>
#import <string.h>

@implementation KGImageSource_JPEG

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef   signed short  int16;
typedef unsigned int   uint32;
typedef   signed int    int32;
typedef unsigned int   uint;

enum
{
   SCAN_load=0,
   SCAN_type,
   SCAN_header,
};

enum
{
   STBI_default = 0, // only used for req_comp

   STBI_grey       = 1,
   STBI_grey_alpha = 2,
   STBI_rgb        = 3,
   STBI_rgb_alpha  = 4,
};

typedef unsigned char stbi_uc;

static int e(KGImageSource_JPEG *self,char *str)
{
   self->failure_reason = str;
   return 0;
}

#define e(self,x,y)  e(self,x)
#define ep(x,y)   (e(self,x,y),NULL)   

static void start_mem(KGImageSource_JPEG *self,const uint8 *buffer, int len)
{
   self->img_buffer = buffer;
   self->img_buffer_end = buffer+len;
}

static int at_eof(KGImageSource_JPEG *self)
{
   return self->img_buffer >= self->img_buffer_end;   
}

static int get8(KGImageSource_JPEG *self)
{
   if (self->img_buffer < self->img_buffer_end)
      return *self->img_buffer++;
   return 0;
}

static uint8 get8u(KGImageSource_JPEG *self)
{
   return (uint8) get8(self);
}

static int get16(KGImageSource_JPEG *self)
{
   int z = get8(self);
   return (z << 8) + get8(self);
}

static void skip(KGImageSource_JPEG *self,int n)
{
      self->img_buffer += n;
}

//////////////////////////////////////////////////////////////////////////////
//
//  "baseline" JPEG/JFIF decoder (not actually fully baseline implementation)
//
//    simple implementation
//      - channel subsampling of at most 2 in each dimension
//      - doesn't support delayed output of y-dimension
//      - simple interface (only one output format: 8-bit interleaved RGB)
//      - doesn't try to recover corrupt jpegs
//      - doesn't allow partial loading, loading multiple at once
//      - still fast on x86 (copying globals into locals doesn't help x86)
//      - allocates lots of intermediate memory (full size of all components)
//        - non-interleaved case requires this anyway
//        - allows good upsampling (see next)
//    high-quality
//      - upsampled channels are bilinearly interpolated, even across blocks
//      - quality integer IDCT derived from IJG's 'slow'
//    performance
//      - fast huffman; reasonable integer IDCT
//      - uses a lot of intermediate memory, could cache poorly
//      - load http://nothings.org/remote/anemones.jpg 3 times on 2.8Ghz P4
//          stb_jpeg:   1.34 seconds (MSVC6, default release build)
//          stb_jpeg:   1.06 seconds (MSVC6, processor = Pentium Pro)
//          IJL11.dll:  1.08 seconds (compiled by intel)
//          IJG 1998:   0.98 seconds (MSVC6, makefile provided by IJG)
//          IJG 1998:   0.95 seconds (MSVC6, makefile + proc=PPro)





static int build_huffman(KGImageSource_JPEG *self,huffman *h, int *count)
{
   int i,j,k=0,code;
   // build size list for each symbol (from JPEG spec)
   for (i=0; i < 16; ++i)
      for (j=0; j < count[i]; ++j)
         h->size[k++] = (uint8) (i+1);
   h->size[k] = 0;

   // compute actual symbols (from jpeg spec)
   code = 0;
   k = 0;
   for(j=1; j <= 16; ++j) {
      // compute delta to add to code to compute symbol id
      h->delta[j] = k - code;
      if (h->size[k] == j) {
         while (h->size[k] == j)
            h->code[k++] = (uint16) (code++);
         if (code-1 >= (1 << j)) return e(self,"bad code lengths","Corrupt JPEG");
      }
      // compute largest code + 1 for this size, preshifted as needed later
      h->maxcode[j] = code << (16-j);
      code <<= 1;
   }
   h->maxcode[j] = 0xffffffff;

   // build non-spec acceleration table; 255 is flag for not-accelerated
   memset(h->fast, 255, 1 << FAST_BITS);
   for (i=0; i < k; ++i) {
      int s = h->size[i];
      if (s <= FAST_BITS) {
         int c = h->code[i] << (FAST_BITS-s);
         int m = 1 << (FAST_BITS-s);
         for (j=0; j < m; ++j) {
            h->fast[c+j] = (uint8) i;
         }
      }
   }
   return 1;
}



 
static void grow_buffer_unsafe(KGImageSource_JPEG *self)
{
   do {
      int b = self->nomore ? 0 : get8(self);
      if (b == 0xff) {
         int c = get8(self);
         if (c != 0) {
            self->marker = (unsigned char) c;
            self->nomore = 1;
            return;
         }
      }
      self->code_buffer = (self->code_buffer << 8) | b;
      self->code_bits += 8;
   } while (self->code_bits <= 24);
}

// (1 << n) - 1
static unsigned long bmask[17]={0,1,3,7,15,31,63,127,255,511,1023,2047,4095,8191,16383,32767,65535};

// decode a jpeg huffman value from the bitstream
static int decode(KGImageSource_JPEG *self,huffman *h)
{
   unsigned int temp;
   int c,k;

   if (self->code_bits < 16) grow_buffer_unsafe(self);

   // look at the top FAST_BITS and determine what symbol ID it is,
   // if the code is <= FAST_BITS
   c = (self->code_buffer >> (self->code_bits - FAST_BITS)) & ((1 << FAST_BITS)-1);
   k = h->fast[c];
   if (k < 255) {
      if (h->size[k] > self->code_bits)
         return -1;
      self->code_bits -= h->size[k];
      return h->values[k];
   }

   // naive test is to shift the self->code_buffer down so k bits are
   // valid, then test against maxcode. To speed this up, we've
   // preshifted maxcode left so that it has (16-k) 0s at the
   // end; in other words, regardless of the number of bits, it
   // wants to be compared against something shifted to have 16;
   // that way we don't need to shift inside the loop.
   if (self->code_bits < 16)
      temp = (self->code_buffer << (16 - self->code_bits)) & 0xffff;
   else
      temp = (self->code_buffer >> (self->code_bits - 16)) & 0xffff;
   for (k=FAST_BITS+1 ; ; ++k)
      if (temp < h->maxcode[k])
         break;
   if (k == 17) {
      // error! code not found
      self->code_bits -= 16;
      return -1;
   }

   if (k > self->code_bits)
      return -1;

   // convert the huffman code to the symbol id
   c = ((self->code_buffer >> (self->code_bits - k)) & bmask[k]) + h->delta[k];
   assert((((self->code_buffer) >> (self->code_bits - h->size[c])) & bmask[h->size[c]]) == h->code[c]);

   // convert the id to a symbol
   self->code_bits -= k;
   return h->values[c];
}

// combined JPEG 'receive' and JPEG 'extend', since baseline
// always extends everything it receives.
static int extend_receive(KGImageSource_JPEG *self,int n)
{
   unsigned int m = 1 << (n-1);
   unsigned int k;
   if (self->code_bits < n) grow_buffer_unsafe(self);
   k = (self->code_buffer >> (self->code_bits - n)) & bmask[n];
   self->code_bits -= n;
   // the following test is probably a random branch that won't
   // predict well. I tried to table accelerate it but failed.
   // maybe it's compiling as a conditional move?
   if (k < m)
      return (-1 << n) + k + 1;
   else
      return k;
}

// given a value that's at position X in the zigzag stream,
// where does it appear in the 8x8 matrix coded as row-major?
static uint8 dezigzag[64+15] =
{
    0,  1,  8, 16,  9,  2,  3, 10,
   17, 24, 32, 25, 18, 11,  4,  5,
   12, 19, 26, 33, 40, 48, 41, 34,
   27, 20, 13,  6,  7, 14, 21, 28,
   35, 42, 49, 56, 57, 50, 43, 36,
   29, 22, 15, 23, 30, 37, 44, 51,
   58, 59, 52, 45, 38, 31, 39, 46,
   53, 60, 61, 54, 47, 55, 62, 63,
   // let corrupt input sample past end
   63, 63, 63, 63, 63, 63, 63, 63,
   63, 63, 63, 63, 63, 63, 63
};

// decode one 64-entry block--
static int decode_block(KGImageSource_JPEG *self,short data[64], huffman *hdc, huffman *hac, int b)
{
   int diff,dc,k;
   int t = decode(self,hdc);
   if (t < 0) return e(self,"bad huffman code","Corrupt JPEG");

   // 0 all the ac values now so we can do it 32-bits at a time
   memset(data,0,64*sizeof(data[0]));

   diff = t ? extend_receive(self,t) : 0;
   dc = img_comp[b].dc_pred + diff;
   img_comp[b].dc_pred = dc;
   data[0] = (short) dc;

   // decode AC components, see JPEG spec
   k = 1;
   do {
      int r,s;
      int rs = decode(self,hac);
      if (rs < 0) return e(self,"bad huffman code","Corrupt JPEG");
      s = rs & 15;
      r = rs >> 4;
      if (s == 0) {
         if (rs != 0xf0) break; // end block
         k += 16;
      } else {
         k += r;
         // decode into unzigzag'd location
         data[dezigzag[k++]] = (short) extend_receive(self,s);
      }
   } while (k < 64);
   return 1;
}

// take a -128..127 value and clamp it and convert to 0..255
static uint8 clamp(int x)
{
   x += 128;
   // trick to use a single test to catch both cases
   if ((unsigned int) x > 255) {
      if (x < 0) return 0;
      if (x > 255) return 255;
   }
   return (uint8) x;
}

#define f2f(x)  (int) (((x) * 4096 + 0.5))
#define fsh(x)  ((x) << 12)

// derived from jidctint -- DCT_ISLOW
#define IDCT_1D(s0,s1,s2,s3,s4,s5,s6,s7)       \
   int t0,t1,t2,t3,p1,p2,p3,p4,p5,x0,x1,x2,x3; \
   p2 = s2;                                    \
   p3 = s6;                                    \
   p1 = (p2+p3) * f2f(0.5411961f);             \
   t2 = p1 + p3*f2f(-1.847759065f);            \
   t3 = p1 + p2*f2f( 0.765366865f);            \
   p2 = s0;                                    \
   p3 = s4;                                    \
   t0 = fsh(p2+p3);                            \
   t1 = fsh(p2-p3);                            \
   x0 = t0+t3;                                 \
   x3 = t0-t3;                                 \
   x1 = t1+t2;                                 \
   x2 = t1-t2;                                 \
   t0 = s7;                                    \
   t1 = s5;                                    \
   t2 = s3;                                    \
   t3 = s1;                                    \
   p3 = t0+t2;                                 \
   p4 = t1+t3;                                 \
   p1 = t0+t3;                                 \
   p2 = t1+t2;                                 \
   p5 = (p3+p4)*f2f( 1.175875602f);            \
   t0 = t0*f2f( 0.298631336f);                 \
   t1 = t1*f2f( 2.053119869f);                 \
   t2 = t2*f2f( 3.072711026f);                 \
   t3 = t3*f2f( 1.501321110f);                 \
   p1 = p5 + p1*f2f(-0.899976223f);            \
   p2 = p5 + p2*f2f(-2.562915447f);            \
   p3 = p3*f2f(-1.961570560f);                 \
   p4 = p4*f2f(-0.390180644f);                 \
   t3 += p1+p4;                                \
   t2 += p2+p3;                                \
   t1 += p2+p4;                                \
   t0 += p1+p3;

// .344 seconds on 3*anemones.jpg
static void idct_block(KGImageSource_JPEG *self,uint8 *out, int out_stride, short data[64], uint8 *dequantize)
{
   int i,val[64],*v=val;
   uint8 *o,*dq = dequantize;
   short *d = data;

   if (self->stbi_jpeg_dc_only) {
      // ok, I don't really know why this is right, but it seems to be:
      int z = 128 + ((d[0] * dq[0]) >> 3);
      for (i=0; i < 8; ++i) {
         out[0] = out[1] = out[2] = out[3] = out[4] = out[5] = out[6] = out[7] = z;
         out += out_stride;
      }
      return;
   }

   // columns
   for (i=0; i < 8; ++i,++d,++dq, ++v) {
      // if all zeroes, shortcut -- this avoids dequantizing 0s and IDCTing
      if (d[ 8]==0 && d[16]==0 && d[24]==0 && d[32]==0 && d[40]==0 && d[48]==0 && d[56]==0) {
         //    no shortcut                 0     seconds
         //    (1|2|3|4|5|6|7)==0          0     seconds
         //    all separate               -0.047 seconds
         //    1 && 2|3 && 4|5 && 6|7:    -0.047 seconds
         int dcterm = d[0] * dq[0] << 2;
         v[0] = v[8] = v[16] = v[24] = v[32] = v[40] = v[48] = v[56] = dcterm;
      } else {
         IDCT_1D(d[ 0]*dq[ 0],d[ 8]*dq[ 8],d[16]*dq[16],d[24]*dq[24],d[32]*dq[32],d[40]*dq[40],d[48]*dq[48],d[56]*dq[56])
         // constants scaled things up by 1<<12; let's bring them back
         // down, but keep 2 extra bits of precision
         x0 += 512; x1 += 512; x2 += 512; x3 += 512;
         v[ 0] = (x0+t3) >> 10;
         v[56] = (x0-t3) >> 10;
         v[ 8] = (x1+t2) >> 10;
         v[48] = (x1-t2) >> 10;
         v[16] = (x2+t1) >> 10;
         v[40] = (x2-t1) >> 10;
         v[24] = (x3+t0) >> 10;
         v[32] = (x3-t0) >> 10;
      }
   }

   for (i=0, v=val, o=out; i < 8; ++i,v+=8,o+=out_stride) {
      // no fast case since the first 1D IDCT spread components out
      IDCT_1D(v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7])
      // constants scaled things up by 1<<12, plus we had 1<<2 from first
      // loop, plus horizontal and vertical each scale by sqrt(8) so together
      // we've got an extra 1<<3, so 1<<17 total we need to remove.
      x0 += 65536; x1 += 65536; x2 += 65536; x3 += 65536;
      o[0] = clamp((x0+t3) >> 17);
      o[7] = clamp((x0-t3) >> 17);
      o[1] = clamp((x1+t2) >> 17);
      o[6] = clamp((x1-t2) >> 17);
      o[2] = clamp((x2+t1) >> 17);
      o[5] = clamp((x2-t1) >> 17);
      o[3] = clamp((x3+t0) >> 17);
      o[4] = clamp((x3-t0) >> 17);
   }
}

#define MARKER_none  0xff
// if there's a pending marker from the entropy stream, return that
// otherwise, fetch from the stream and get a marker. if there's no
// marker, return 0xff, which is never a valid marker value
static uint8 get_marker(KGImageSource_JPEG *self)
{
   uint8 x;
   if (self->marker != MARKER_none) { x = self->marker; self->marker = MARKER_none; return x; }
   x = get8u(self);
   if (x != 0xff) return MARKER_none;
   while (x == 0xff)
      x = get8u(self);
   return x;
}

#define RESTART(x)     ((x) >= 0xd0 && (x) <= 0xd7)

// after a restart interval, reset the entropy decoder and
// the dc prediction
static void reset(KGImageSource_JPEG *self)
{
   self->code_bits = 0;
   self->code_buffer = 0;
   self->nomore = 0;
   img_comp[0].dc_pred = img_comp[1].dc_pred = img_comp[2].dc_pred = 0;
   self->marker = MARKER_none;
   self->todo = self->restart_interval ? self->restart_interval : 0x7fffffff;
   // no more than 1<<31 MCUs if no restart_interal? that's plenty safe,
   // since we don't even allow 1<<30 pixels
}

static int parse_entropy_coded_data(KGImageSource_JPEG *self)
{
   reset(self);
   if (self->scan_n == 1) {
      int i,j;
      short data[64];
      int n = self->order[0];
      // non-interleaved data, we just need to process one block at a time,
      // in trivial scanline order
      // number of blocks to do just depends on how many actual "pixels" this
      // component has, independent of interleaved MCU blocking and such
      int w = (img_comp[n].x+7) >> 3;
      int h = (img_comp[n].y+7) >> 3;
      for (j=0; j < h; ++j) {
         for (i=0; i < w; ++i) {
            if (!decode_block(self,data, self->huff_dc+img_comp[n].hd, self->huff_ac+img_comp[n].ha, n)) return 0;
            idct_block(self,img_comp[n].data+img_comp[n].w2*j*8+i*8, img_comp[n].w2, data, self->dequant[img_comp[n].tq]);
            // every data block is an MCU, so countdown the restart interval
            if (--self->todo <= 0) {
               if (self->code_bits < 24) grow_buffer_unsafe(self);
               // if it's NOT a restart, then just bail, so we get corrupt data
               // rather than no data
               if (!RESTART(self->marker)) return 1;
               reset(self);
            }
         }
      }
   } else { // interleaved!
      int i,j,k,x,y;
      short data[64];
      for (j=0; j < self->img_mcu_y; ++j) {
         for (i=0; i < self->img_mcu_x; ++i) {
            // scan an interleaved mcu... process scan_n components in order
            for (k=0; k < self->scan_n; ++k) {
               int n = self->order[k];
               // scan out an mcu's worth of this component; that's just determined
               // by the basic H and V specified for the component
               for (y=0; y < img_comp[n].v; ++y) {
                  for (x=0; x < img_comp[n].h; ++x) {
                     int x2 = (i*img_comp[n].h + x)*8;
                     int y2 = (j*img_comp[n].v + y)*8;
                     if (!decode_block(self,data, self->huff_dc+img_comp[n].hd, self->huff_ac+img_comp[n].ha, n)) return 0;
                     idct_block(self,img_comp[n].data+img_comp[n].w2*y2+x2, img_comp[n].w2, data, self->dequant[img_comp[n].tq]);
                  }
               }
            }
            // after all interleaved components, that's an interleaved MCU,
            // so now count down the restart interval
            if (--self->todo <= 0) {
               if (self->code_bits < 24) grow_buffer_unsafe(self);
               // if it's NOT a restart, then just bail, so we get corrupt data
               // rather than no data
               if (!RESTART(self->marker)) return 1;
               reset(self);
            }
         }
      }
   }
   return 1;
}

static int process_marker(KGImageSource_JPEG *self,int m)
{
   int L;
   switch (m) {
      case MARKER_none: // no marker found
         return e(self,"expected marker","Corrupt JPEG");

      case 0xC2: // SOF - progressive
         return e(self,"progressive jpeg","JPEG format not supported (progressive)");

      case 0xDD: // DRI - specify restart interval
         if (get16(self) != 4) return e(self,"bad DRI len","Corrupt JPEG");
         self->restart_interval = get16(self);
         return 1;

      case 0xDB: // DQT - define quantization table
         L = get16(self)-2;
         while (L > 0) {
            int z = get8(self);
            int p = z >> 4;
            int t = z & 15,i;
            if (p != 0) return e(self,"bad DQT type","Corrupt JPEG");
            if (t > 3) return e(self,"bad DQT table","Corrupt JPEG");
            for (i=0; i < 64; ++i)
               self->dequant[t][dezigzag[i]] = get8u(self);
            L -= 65;
         }
         return L==0;

      case 0xC4: // DHT - define huffman table
         L = get16(self)-2;
         while (L > 0) {
            uint8 *v;
            int sizes[16],i,m=0;
            int z = get8(self);
            int tc = z >> 4;
            int th = z & 15;
            if (tc > 1 || th > 3) return e(self,"bad DHT header","Corrupt JPEG");
            for (i=0; i < 16; ++i) {
               sizes[i] = get8(self);
               m += sizes[i];
            }
            L -= 17;
            if (tc == 0) {
               if (!build_huffman(self,self->huff_dc+th, sizes)) return 0;
               v = self->huff_dc[th].values;
            } else {
               if (!build_huffman(self,self->huff_ac+th, sizes)) return 0;
               v = self->huff_ac[th].values;
            }
            for (i=0; i < m; ++i)
               v[i] = get8u(self);
            L -= m;
         }
         return L==0;
   }
   // check for comment block or APP blocks
   if ((m >= 0xE0 && m <= 0xEF) || m == 0xFE) {
      skip(self,get16(self)-2);
      return 1;
   }
   return 0;
}

// after we see SOS
static int process_scan_header(KGImageSource_JPEG *self)
{
   int i;
   int Ls = get16(self);
   self->scan_n = get8(self);
   if (self->scan_n < 1 || self->scan_n > 4 || self->scan_n > (int) self->img_n) return e(self,"bad SOS component count","Corrupt JPEG");
   if (Ls != 6+2*self->scan_n) return e(self,"bad SOS len","Corrupt JPEG");
   for (i=0; i < self->scan_n; ++i) {
      int id = get8(self), which;
      int z = get8(self);
      for (which = 0; which < self->img_n; ++which)
         if (img_comp[which].id == id)
            break;
      if (which == self->img_n) return 0;
      img_comp[which].hd = z >> 4;   if (img_comp[which].hd > 3) return e(self,"bad DC huff","Corrupt JPEG");
      img_comp[which].ha = z & 15;   if (img_comp[which].ha > 3) return e(self,"bad AC huff","Corrupt JPEG");
      self->order[i] = which;
   }
   if (get8(self) != 0) return e(self,"bad SOS","Corrupt JPEG");
   get8(self); // should be 63, but might be 0
   if (get8(self) != 0) return e(self,"bad SOS","Corrupt JPEG");

   return 1;
}

static int process_frame_header(KGImageSource_JPEG *self,int scan)
{
   int Lf,p,i,z, h_max=1,v_max=1;
   Lf = get16(self);         if (Lf < 11) return e(self,"bad SOF len","Corrupt JPEG"); // JPEG
   p  = get8(self);          if (p != 8) return e(self,"only 8-bit","JPEG format not supported: 8-bit only"); // JPEG baseline
   self->img_y = get16(self);      if (self->img_y == 0) return e(self,"no header height", "JPEG format not supported: delayed height"); // Legal, but we don't handle it--but neither does IJG
   self->img_x = get16(self);      if (self->img_x == 0) return e(self,"0 width","Corrupt JPEG"); // JPEG requires
   self->img_n = get8(self);
   if (self->img_n != 3 && self->img_n != 1) return e(self,"bad component count","Corrupt JPEG");    // JFIF requires

   if (Lf != 8+3*self->img_n) return e(self,"bad SOF len","Corrupt JPEG");

   for (i=0; i < self->img_n; ++i) {
      img_comp[i].id = get8(self);
      if (img_comp[i].id != i+1)   // JFIF requires
         if (img_comp[i].id != i)  // jpegtran outputs non-JFIF-compliant files!
            return e(self,"bad component ID","Corrupt JPEG");
      z = get8(self);
      img_comp[i].h = (z >> 4);  if (!img_comp[i].h || img_comp[i].h > 4) return e(self,"bad H","Corrupt JPEG");
      img_comp[i].v = z & 15;    if (!img_comp[i].v || img_comp[i].v > 4) return e(self,"bad V","Corrupt JPEG");
      img_comp[i].tq = get8(self);   if (img_comp[i].tq > 3) return e(self,"bad TQ","Corrupt JPEG");
   }

   if (scan != SCAN_load) return 1;

   if ((1 << 30) / self->img_x / self->img_n < self->img_y) return e(self,"too large", "Image too large to decode");

   for (i=0; i < self->img_n; ++i) {
      if (img_comp[i].h > h_max) h_max = img_comp[i].h;
      if (img_comp[i].v > v_max) v_max = img_comp[i].v;
   }

   // compute interleaved mcu info
   self->img_h_max = h_max;
   self->img_v_max = v_max;
   self->img_mcu_w = h_max * 8;
   self->img_mcu_h = v_max * 8;
   self->img_mcu_x = (self->img_x + self->img_mcu_w-1) / self->img_mcu_w;
   self->img_mcu_y = (self->img_y + self->img_mcu_h-1) / self->img_mcu_h;

   for (i=0; i < self->img_n; ++i) {
      // number of effective pixels (e.g. for non-interleaved MCU)
      img_comp[i].x = (self->img_x * img_comp[i].h + h_max-1) / h_max;
      img_comp[i].y = (self->img_y * img_comp[i].v + v_max-1) / v_max;
      // to simplify generation, we'll allocate enough memory to decode
      // the bogus oversized data from using interleaved MCUs and their
      // big blocks (e.g. a 16x16 iMCU on an image of width 33); we won't
      // discard the extra data until colorspace conversion
      img_comp[i].w2 = self->img_mcu_x * img_comp[i].h * 8;
      img_comp[i].h2 = self->img_mcu_y * img_comp[i].v * 8;
      img_comp[i].data = (uint8 *) NSZoneMalloc(NULL,img_comp[i].w2 * img_comp[i].h2);
      if (img_comp[i].data == NULL) {
         for(--i; i >= 0; --i)
            NSZoneFree(NULL,img_comp[i].data);
         return e(self,"outofmem", "Out of memory");
      }
   }

   return 1;
}

// use comparisons since in some cases we handle more than one case (e.g. SOF)
#define DNL(x)         ((x) == 0xdc)
#define SOI(x)         ((x) == 0xd8)
#define EOI(x)         ((x) == 0xd9)
#define SOF(x)         ((x) == 0xc0 || (x) == 0xc1)
#define SOS(x)         ((x) == 0xda)

static int decode_jpeg_header(KGImageSource_JPEG *self,int scan)
{
   int m;
   self->marker = MARKER_none; // initialize cached marker to empty
   m = get_marker(self);
   if (!SOI(m)) return e(self,"no SOI","Corrupt JPEG");
   if (scan == SCAN_type) return 1;
   m = get_marker(self);
   while (!SOF(m)) {
      if (!process_marker(self,m)) return 0;
      m = get_marker(self);
      while (m == MARKER_none) {
         // some files have extra padding after their blocks, so ok, we'll scan
         if (at_eof(self)) return e(self,"no SOF", "Corrupt JPEG");
         m = get_marker(self);
      }
   }
   if (!process_frame_header(self,scan)) return 0;
   return 1;
}

static int decode_jpeg_image(KGImageSource_JPEG *self)
{
   int m;
   self->restart_interval = 0;
   if (!decode_jpeg_header(self,SCAN_load)) return 0;
   m = get_marker(self);
   while (!EOI(m)) {
      if (SOS(m)) {
         if (!process_scan_header(self)) return 0;
         if (!parse_entropy_coded_data(self)) return 0;
      } else {
         if (!process_marker(self,m)) return 0;
      }
      m = get_marker(self);
   }
   return 1;
}

// static jfif-centered resampling with cross-block smoothing
// here by cross-block smoothing what I mean is that the resampling
// is bilerp and crosses blocks; I dunno what IJG means

#define div4(x) ((uint8) ((x) >> 2))

static void resample_v_2(uint8 *out1, uint8 *input, int w, int h, int s)
{
   // need to generate two samples vertically for every one in input
   uint8 *above;
   uint8 *below;
   uint8 *source;
   uint8 *out2;
   int i,j;
   source = input;
   out2 = out1+w;
   for (j=0; j < h; ++j) {
      above = source;
      source = input + j*s;
      below = source + s; if (j == h-1) below = source;
      for (i=0; i < w; ++i) {
         int n = source[i]*3;
         out1[i] = div4(above[i] + n);
         out2[i] = div4(below[i] + n);
      }
      out1 += w*2;
      out2 += w*2;
   }
}

static void resample_h_2(uint8 *out, uint8 *input, int w, int h, int s)
{
   // need to generate two samples horizontally for every one in input
   int i,j;
   if (w == 1) {
      for (j=0; j < h; ++j)
         out[j*2+0] = out[j*2+1] = input[j*s];
      return;
   }
   for (j=0; j < h; ++j) {
      out[0] = input[0];
      out[1] = div4(input[0]*3 + input[1]);
      for (i=1; i < w-1; ++i) {
         int n = input[i]*3;
         out[i*2-2] = div4(input[i-1] + n);
         out[i*2-1] = div4(input[i+1] + n);
      }
      out[w*2-2] = div4(input[w-2]*3 + input[w-1]);
      out[w*2-1] = input[w-1];
      out += w*2;
      input += s;
   }
}

// .172 seconds on 3*anemones.jpg
static void resample_hv_2(uint8 *out, uint8 *input, int w, int h, int s)
{
   // need to generate 2x2 samples for every one in input
   int i,j;
   int os = w*2;
   // generate edge samples... @TODO lerp them!
   for (i=0; i < w; ++i) {
      out[i*2+0] = out[i*2+1] = input[i];
      out[i*2+(2*h-1)*os+0] = out[i*2+(2*h-1)*os+1] = input[i+(h-1)*w];
   }
   for (j=0; j < h; ++j) {
      out[j*os*2+0] = out[j*os*2+os+0] = input[j*w];
      out[j*os*2+os-1] = out[j*os*2+os+os-1] = input[j*w+i-1];
   }
   // now generate interior samples; i & j point to top left of input
   for (j=0; j < h-1; ++j) {
      uint8 *in1 = input+j*s;
      uint8 *in2 = in1 + s;
      uint8 *out1 = out + (j*2+1)*os + 1;
      uint8 *out2 = out1 + os;
      for (i=0; i < w-1; ++i) {
         int p00 = in1[0], p01=in1[1], p10=in2[0], p11=in2[1];
         int p00_3 = p00*3, p01_3 = p01*3, p10_3 = p10*3, p11_3 = p11*3;

         #define div16(x)  ((uint8) ((x) >> 4))

         out1[0] = div16(p00*9 + p01_3 + p10_3 + p11);
         out1[1] = div16(p01*9 + p00_3 + p01_3 + p10);
         out2[0] = div16(p10*9 + p11_3 + p00_3 + p01);
         out2[1] = div16(p11*9 + p10_3 + p01_3 + p00);
         out1 += 2;
         out2 += 2;                                                         
         ++in1;
         ++in2;
      }
   }
}

#define float2fixed(x)  ((int) ((x) * 65536 + 0.5))

// 0.38 seconds on 3*anemones.jpg   (0.25 with processor = Pro)
// VC6 without processor=Pro is generating multiple LEAs per multiply!
static void YCbCr_to_RGB_row(uint8 *out, uint8 *y, uint8 *pcb, uint8 *pcr, int count, int step)
{
   int i;
#if 1
   for (i=0; i < count; ++i) {
      int y_fixed = (y[i] << 16) + 32768; // rounding
      int r,g,b;
      int cr = pcr[i] - 128;
      int cb = pcb[i] - 128;
      r=g=b=y_fixed;
      
      r >>= 16;
      g >>= 16;
      b >>= 16;
      if ((unsigned) r > 255) { if (r < 0) r = 0; else r = 255; }
      if ((unsigned) g > 255) { if (g < 0) g = 0; else g = 255; }
      if ((unsigned) b > 255) { if (b < 0) b = 0; else b = 255; }
      out[0] = (uint8)r;
      out[1] = (uint8)g;
      out[2] = (uint8)b;
      if (step == 4) out[3] = 255;
      out += step;
   }
#else
   for (i=0; i < count; ++i) {
      int y_fixed = (y[i] << 16) + 32768; // rounding
      int r,g,b;
      int cr = pcr[i] - 128;
      int cb = pcb[i] - 128;
      r = y_fixed + cr*float2fixed(1.40200f);
      g = y_fixed - cr*float2fixed(0.71414f) - cb*float2fixed(0.34414f);
      b = y_fixed                            + cb*float2fixed(1.77200f);
      r >>= 16;
      g >>= 16;
      b >>= 16;
      if ((unsigned) r > 255) { if (r < 0) r = 0; else r = 255; }
      if ((unsigned) g > 255) { if (g < 0) g = 0; else g = 255; }
      if ((unsigned) b > 255) { if (b < 0) b = 0; else b = 255; }
      out[0] = (uint8)r;
      out[1] = (uint8)g;
      out[2] = (uint8)b;
      if (step == 4) out[3] = 255;
      out += step;
   }
#endif
}

// clean up the temporary component buffers
static void cleanup_jpeg(KGImageSource_JPEG *self)
{
   int i;
   for (i=0; i < self->img_n; ++i) {
      if (img_comp[i].data) {
         NSZoneFree(NULL,img_comp[i].data);
         img_comp[i].data = NULL;
      }
   }
}

static void load_jpeg_image(KGImageSource_JPEG *self,int *out_x, int *out_y, int *comp, int req_comp)
{
   int i, n;
   // validate req_comp
   if (req_comp < 0 || req_comp > 4){
    ep("bad req_comp", "Internal error");
    return;
   }
   
   // load a jpeg image from whichever source
   if (!decode_jpeg_image(self)) { cleanup_jpeg(self); return ; }

   // determine actual number of components to generate
   n = req_comp ? req_comp : self->img_n;

   // resample components to full size... memory wasteful, but this
   // lets us bilerp across blocks while upsampling
   for (i=0; i < self->img_n; ++i) {
      // if we're outputting fewer than 3 components, we're grey not RGB;
      // in that case, don't bother upsampling Cb or Cr
        if (n < 3 && i) continue;

      // check if the component scale is less than max; if so it needs upsampling
      if (img_comp[i].h != self->img_h_max || img_comp[i].v != self->img_v_max) {
         int stride = self->img_x;
         // allocate final size; make sure it's big enough for upsampling off
         // the edges with upsample up to 4x4 (although we only support 2x2
         // currently)
         uint8 *new_data = (uint8 *) NSZoneMalloc(NULL,(self->img_x+3)*(self->img_y+3));
         if (new_data == NULL) {
            cleanup_jpeg(self);
            ep("outofmem", "Out of memory (image too large?)");
            return;
         }
         if (img_comp[i].h*2 == self->img_h_max && img_comp[i].v*2 == self->img_v_max) {
            int tx = (self->img_x+1)>>1;
            resample_hv_2(new_data, img_comp[i].data, tx,(self->img_y+1)>>1, img_comp[i].w2);
            stride = tx*2;
         } else if (img_comp[i].h == self->img_h_max && img_comp[i].v*2 == self->img_v_max) {
            resample_v_2(new_data, img_comp[i].data, self->img_x,(self->img_y+1)>>1, img_comp[i].w2);
         } else if (img_comp[i].h*2 == self->img_h_max && img_comp[i].v == self->img_v_max) {
            int tx = (self->img_x+1)>>1;
            resample_h_2(new_data, img_comp[i].data, tx,self->img_y, img_comp[i].w2);
            stride = tx*2;
         } else {
            // @TODO resample uncommon sampling pattern with nearest neighbor
            NSZoneFree(NULL,new_data);
            cleanup_jpeg(self);
            ep("uncommon H or V", "JPEG not supported: atypical downsampling mode");
            return;
         }
         img_comp[i].w2 = stride;
         NSZoneFree(NULL,img_comp[i].data);
         img_comp[i].data = new_data;
      }
   }

   // now convert components to output image
   {
      uint32 i,j;
      self->_bitmap=NSZoneMalloc(NULL,n * self->img_x * self->img_y + 1);

      if (n >= 3) { // output STBI_rgb_*
         for (j=0; j < self->img_y; ++j) {
            uint8 *y  = img_comp[0].data + j*img_comp[0].w2;
            uint8 *out = self->_bitmap + n * self->img_x * j;
            if (self->img_n == 3) {
               uint8 *cb = img_comp[1].data + j*img_comp[1].w2;
               uint8 *cr = img_comp[2].data + j*img_comp[2].w2;
               YCbCr_to_RGB_row(out, y, cb, cr, self->img_x, n);
            } else {
               for (i=0; i < self->img_x; ++i) {
                  out[0] = out[1] = out[2] = y[i];
                  out[3] = 255; // not used if n == 3
                  out += n;
               }
            }
         }
      } else {      // output STBI_grey_*
         for (j=0; j < self->img_y; ++j) {
            uint8 *y  = img_comp[0].data + j*img_comp[0].w2;
            uint8 *out = self->_bitmap + n * self->img_x * j;
            if (n == 1)
               for (i=0; i < self->img_x; ++i) *out++ = *y++;
            else
               for (i=0; i < self->img_x; ++i) *out++ = *y++, *out++ = 255;
         }
      }
      cleanup_jpeg(self);
      *out_x = self->img_x;
      *out_y = self->img_y;
      if (comp) *comp  = self->img_n; // report original components, not output

   }
}


static void stbi_jpeg_load_from_memory(KGImageSource_JPEG *self,const stbi_uc *buffer, int len, int *x, int *y, int *comp, int req_comp)
{
   start_mem(self,buffer,len);
    load_jpeg_image(self,x,y,comp,req_comp);
}

+(BOOL)isTypeOfData:(NSData *)data {
   const unsigned char *bytes=[data bytes];
   unsigned             i,length=[data length];
   unsigned char        jpg[2]={0xFF,0xD8};

   if(length<2)
    return NO;
   
   for(i=0;i<2;i++)
    if(jpg[i]!=bytes[i])
     return NO;
   
   return YES;
}

-initWithData:(NSData *)data options:(NSDictionary *)options {
   _jpg=[data copy];
   return self;
}

-initWithContentsOfFile:(NSString *)path {
   NSData *data=[NSData dataWithContentsOfFile:path];
   if(data==nil){
    [self dealloc];
    return nil;
   }
   
   return [self initWithData:data options:nil];
}

-(void)dealloc {
   [_jpg release];
   [super dealloc];
}

-(unsigned)count {
   return 1;
}

-(KGImage *)imageAtIndex:(unsigned)index options:(NSDictionary *)options {
   int            width,height;
   int            comp;

   stbi_jpeg_load_from_memory(self,[_jpg bytes],[_jpg length],&width,&height,&comp,STBI_rgb_alpha);
   int            bitsPerPixel=32;
   int            bytesPerRow=(bitsPerPixel/(sizeof(char)*8))*width;
   NSData        *bitmap;

   bitmap=[[NSData alloc] initWithBytesNoCopy:_bitmap length:bytesPerRow*height];

   KGDataProvider *provider=[[KGDataProvider alloc] initWithData:bitmap];
   KGColorSpace   *colorSpace=[[KGColorSpace alloc] initWithGenericRGB];
   KGImage        *image=[[KGImage alloc] initWithWidth:width height:height bitsPerComponent:8 bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow
      colorSpace:colorSpace bitmapInfo:0/*kCGImageAlphaLast|kCGBitmapByteOrder32Little*/ provider:provider decode:NULL interpolate:NO renderingIntent:kCGRenderingIntentDefault];
      
   [colorSpace release];
   [provider release];
   [bitmap release];
   
   return image;
}

@end
