/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

/*  zlib decode is based on the public domain zlib decode v0.2 by Sean Barrett 2006-11-18  http://www.nothings.org/stb_image.c */

// First revision - Christopher Lloyd <cjwl@objc.net>
#import "KGPDFFilter.h"
#import "KGPDFObject.h"
#import "KGPDFDictionary.h"
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

#import <assert.h>
#import <stdlib.h>
#import <memory.h>

@interface KGPDFFilter : NSObject {
   KGPDFDictionary *_parameters;
}

+(NSData *)decodeWithName:(const char *)name data:(NSData *)data parameters:(KGPDFDictionary *)parameters;

@end

NSData *KGPDFFilterWithName(const char *name,NSData *data,KGPDFDictionary *parameters) {
   return [KGPDFFilter decodeWithName:name data:data parameters:parameters];
}

@implementation KGPDFFilter

typedef unsigned short uint16;
static int e(const char *str){
   NSLog(@"STB ERROR %s",str);
   return 0;
}

// fast-way is faster to check than jpeg huffman, but slow way is slower
#define ZFAST_BITS  9 // accelerate all cases in default tables
#define ZFAST_MASK  ((1 << ZFAST_BITS) - 1)

typedef struct {
   uint16 fast[1 << ZFAST_BITS];
   uint16 firstcode[16];
   int    maxcode[17];
   uint16 firstsymbol[16];
   unsigned char  size[288];
   uint16 value[288]; 
} zhuffman;

static int bitreverse16(int n) {
  n = ((n & 0xAAAA) >>  1) | ((n & 0x5555) << 1);
  n = ((n & 0xCCCC) >>  2) | ((n & 0x3333) << 2);
  n = ((n & 0xF0F0) >>  4) | ((n & 0x0F0F) << 4);
  n = ((n & 0xFF00) >>  8) | ((n & 0x00FF) << 8);
  return n;
}

static int bit_reverse(int v, int bits) {
   assert(bits <= 16);
   // to bit reverse n bits, reverse 16 and shift
   // e.g. 11 bits, bit reverse and shift away 5
   return bitreverse16(v) >> (16-bits);
}

static int zbuild_huffman(zhuffman *z, const unsigned char *sizelist, int num) {
   int i,k=0;
   int code, next_code[16], sizes[17];

   // DEFLATE spec for generating codes
   memset(sizes, 0, sizeof(sizes));
   memset(z->fast, 255, sizeof(z->fast));
   for (i=0; i < num; ++i) 
      ++sizes[sizelist[i]];
   sizes[0] = 0;
   for (i=1; i < 16; ++i)
      assert(sizes[i] <= (1 << i));
   code = 0;
   for (i=1; i < 16; ++i) {
      next_code[i] = code;
      z->firstcode[i] = code;
      z->firstsymbol[i] = k;
      code = (code + sizes[i]);
      if (sizes[i])
         if (code-1 >= (1 << i)) return e("bad codelengths");
      z->maxcode[i] = code << (16-i); // preshift for inner loop
      code <<= 1;
      k += sizes[i];
   }
   z->maxcode[16] = 0x10000; // sentinel
   for (i=0; i < num; ++i) {
      int s = sizelist[i];
      if (s) {
         int c = next_code[s] - z->firstcode[s] + z->firstsymbol[s];
         z->size[c] = s;
         z->value[c] = i;
         if (s <= ZFAST_BITS) {
            int k = bit_reverse(next_code[s],s);
            while (k < (1 << ZFAST_BITS)) {
               z->fast[k] = c;
               k += (1 << s);
            }
         }
         ++next_code[s];
      }
   }
   return 1;
}

// zlib-from-memory implementation for PNG reading
//    because PNG allows splitting the zlib stream arbitrarily,
//    and it's annoying structurally to have PNG call ZLIB call PNG,
//    we require PNG read all the IDATs and combine them into a single
//    memory buffer

typedef struct {
   const unsigned char *inBytes;
   unsigned             inLength;
   unsigned             inPosition;
   
   unsigned char *outBytes;
   unsigned       outLength;
   unsigned       outPosition;
      
   unsigned int  code_buffer;
   int           num_bits;
   zhuffman      z_length;
   zhuffman      z_distance;
} KGFlateDecode;


static unsigned char KGFlateDecodeNextByte(KGFlateDecode *inflate){
   if(inflate->inPosition<inflate->inLength)
    return inflate->inBytes[inflate->inPosition++];
   
   return 0;
}

static int length_base[31] = {
   3,4,5,6,7,8,9,10,11,13,
   15,17,19,23,27,31,35,43,51,59,
   67,83,99,115,131,163,195,227,258,0,0
};

static int length_extra[31]= {
 0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0
};

static int dist_base[32] = {
 1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577,0,0
};

static int dist_extra[32] = {
 0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13
};

static void fill_bits(KGFlateDecode *inflate) {
   do {
    assert(inflate->code_buffer < (1U << inflate->num_bits));
    
    inflate->code_buffer |= KGFlateDecodeNextByte(inflate) << inflate->num_bits;
    inflate->num_bits += 8;
   } while (inflate->num_bits <= 24);
}

static unsigned int zreceive(KGFlateDecode *inflate,int n) {
   unsigned int k;
   
   if (inflate->num_bits < n)
    fill_bits(inflate);
    
   k = inflate->code_buffer & ((1 << n) - 1);
   inflate->code_buffer >>= n;
   inflate->num_bits -= n;
   
   return k;   
}

static int zhuffman_decode(KGFlateDecode *inflate,zhuffman *z) {
   int b,s,k;
   
   if (inflate->num_bits < 16)
    fill_bits(inflate);
    
   b = z->fast[inflate->code_buffer & ZFAST_MASK];
   if (b < 0xffff) {
      s = z->size[b];
      inflate->code_buffer >>= s;
      inflate->num_bits -= s;
      
      return z->value[b];
   }

   // not resolved by fast table, so compute it the slow way
   // use jpeg approach, which requires MSbits at top
   k = bit_reverse(inflate->code_buffer, 16);
   for (s=ZFAST_BITS+1; ; ++s)
      if (k < z->maxcode[s])
         break;
   if (s == 16)
    return -1; // invalid code!
    
   // code size is s, so:
   b = (k >> (16-s)) - z->firstcode[s] + z->firstsymbol[s];
   
   assert(z->size[b] == s);
   
   inflate->code_buffer >>= s;
   inflate->num_bits -= s;
   
   return z->value[b];
}

 // need to make room for n bytes
static void expand(KGFlateDecode *inflate,int n)  {   
   if(inflate->outPosition+n>inflate->outLength){
    do{
     inflate->outLength*=2;
    }while (inflate->outPosition + n > inflate->outLength);
   
    inflate->outBytes = NSZoneRealloc(NULL,inflate->outBytes, inflate->outLength);
   }
}

static void appendBytes(KGFlateDecode *inflate,const unsigned char *bytes,unsigned length){
   unsigned i;
      
   for(i=0;i<length;i++)
    inflate->outBytes[inflate->outPosition++]=bytes[i];
}

static int parse_huffman_block(KGFlateDecode *inflate) {
   for(;;) {
      int z = zhuffman_decode(inflate,&(inflate->z_length));
      
      if (z < 256) {
         if (z < 0)
          return e("bad huffman code"); // error in huffman codes
         
         expand(inflate,1);
         inflate->outBytes[inflate->outPosition++] = z;
      } else {
      unsigned char *p;
         int len,dist;
         
         if (z == 256)
          return 1;
          
         z -= 257;
         len = length_base[z];
         if (length_extra[z])
          len += zreceive(inflate,length_extra[z]);
          
         z = zhuffman_decode(inflate,&(inflate->z_distance));
         
         if (z < 0)
          return e("bad huffman code");
          
         dist = dist_base[z];
         if (dist_extra[z])
          dist += zreceive(inflate,dist_extra[z]);
          
         if (inflate->outPosition < dist)
          return e("bad dist");
          
         expand(inflate,len); // we need to pre-expand to make sure outBytes doesn't change
         appendBytes(inflate,inflate->outBytes+inflate->outPosition-dist,len);
        }
   }
}

static int compute_huffman_codes(KGFlateDecode *inflate) {
   static unsigned char length_dezigzag[19] = { 16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15 };
    zhuffman z_codelength;
   unsigned char lencodes[286+32+137];//padding for maximum single op
   unsigned char codelength_sizes[19];
   int i,n;

   int hlit  = zreceive(inflate,5) + 257;
   int hdist = zreceive(inflate,5) + 1;
   int hclen = zreceive(inflate,4) + 4;

   memset(codelength_sizes, 0, sizeof(codelength_sizes));
   for (i=0; i < hclen; ++i) {
      int s = zreceive(inflate,3);
      
      codelength_sizes[length_dezigzag[i]] = s;
   }
   if (!zbuild_huffman(&z_codelength, codelength_sizes, 19))
    return 0;

   n = 0;
   while (n < hlit + hdist) {
      int c = zhuffman_decode(inflate,&z_codelength);
      
      assert(c >= 0 && c < 19);
      
      if (c < 16)
         lencodes[n++] = c;
      else if (c == 16) {
         c = zreceive(inflate,2)+3;
         memset(lencodes+n, lencodes[n-1], c);
         n += c;
      } else if (c == 17) {
         c = zreceive(inflate,3)+3;
         memset(lencodes+n, 0, c);
         n += c;
      } else {
         assert(c == 18);
         c = zreceive(inflate,7)+11;
         memset(lencodes+n, 0, c);
         n += c;
      }
   }
   if (n != hlit+hdist)
    return e("bad codelengths");
   if (!zbuild_huffman(&(inflate->z_length), lencodes, hlit))
    return 0;
   if (!zbuild_huffman(&(inflate->z_distance), lencodes+hlit, hdist))
    return 0;
    
   return 1;
}

static int parse_uncompressed_block(KGFlateDecode *inflate) {
   unsigned char header[4];
   int len,nlen,k;
   
   if (inflate->num_bits & 7)
      zreceive(inflate,inflate->num_bits & 7); // discard
      
   // drain the bit-packed data into header
   k = 0;
   while (inflate->num_bits > 0) {
      header[k++] = (unsigned char) (inflate->code_buffer & 255); // wtf this warns?
      inflate->code_buffer >>= 8;
      inflate->num_bits -= 8;
   }
   
   assert(inflate->num_bits == 0);
   
   // now fill header the normal way
   while (k < 4)
      header[k++] = KGFlateDecodeNextByte(inflate);
      
   len  = header[0] * 256 + header[1];
   nlen = header[2] * 256 + header[3];
   
   if (nlen != ~len)
    return e("zlib corrupt");
   if (inflate->inPosition + len > inflate->inLength)
    return e("read past buffer");
   
   expand(inflate,len);
   appendBytes(inflate,inflate->inBytes+inflate->inPosition,len);
   inflate->inPosition += len;

   return 1;
}

static int parse_zlib_header(KGFlateDecode *inflate) {
   int cmf   = KGFlateDecodeNextByte(inflate);
      int cm       = cmf & 15;
     // int cinfo    = cmf >> 4;
   int flg   = KGFlateDecodeNextByte(inflate);
   
   if ((cmf*256+flg) % 31 != 0)
    return e("bad zlib header"); // zlib spec
   if (flg & 32)
    return e("no preset dict"); // preset dictionary not allowed in png
   if (cm != 8)
    return e("bad compression"); // DEFLATE required for png
   // window = 1 << (8 + cinfo)... but who cares, we fully buffer output
   
   return 1;
}

static const unsigned char default_length[288] = {
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
8,8,8,8,8,8,8,8,8,8,8,8,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,9,9,9,9,9,9,9,9,
9,9,9,9,
7,7,7,7,7,7,7,7,7,7,7,7,
7,7,7,7,7,7,7,7,7,7,7,7,
8,8,8,8,8,8,8,8,

};

static const unsigned char default_distance[32] = {
 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
};

static int parse_zlib(KGFlateDecode *inflate) {
   int final, type;
   
   if (!parse_zlib_header(inflate))
    return 0;
   inflate->num_bits = 0;
   inflate->code_buffer = 0;
   do {
      final = zreceive(inflate,1);
      type = zreceive(inflate,2);
      if (type == 0) {
         if (!parse_uncompressed_block(inflate))
          return 0;
      } else if (type == 3) {
         return 0;
      } else {
         if (type == 1) {
            if (!zbuild_huffman(&(inflate->z_length)  , default_length  , 288))
             return 0;
            if (!zbuild_huffman(&(inflate->z_distance), default_distance,  32))
             return 0;
         } else {
            if (!compute_huffman_codes(inflate))
             return 0;
         }
         if (!parse_huffman_block(inflate))
          return 0;
      }
   } while (!final);
   
   return 1;
}

unsigned char *stbi_zlib_decode_malloc(KGFlateDecode *inflate,const unsigned char *buffer, int len, int *outlen) {
   int initial_size=8192;
   unsigned char *p = NSZoneMalloc(NULL,initial_size);

   inflate->inBytes = buffer;
   inflate->inLength=len;
   inflate->inPosition=0;
   
   if (p == NULL) return NULL;
   
   inflate->outBytes = p;
   inflate->outPosition=0;
   inflate->outLength   =  initial_size;

   if (parse_zlib(inflate)) {
      *outlen = inflate->outPosition;
      return inflate->outBytes;
   } else {
      free(inflate->outBytes);
      return NULL;
   }
}

+(NSData *)FlateDecode_data:(NSData *)data parameters:(KGPDFDictionary *)parameters {
   KGFlateDecode flateDecode;

   int len;
   unsigned char *result=stbi_zlib_decode_malloc(&flateDecode,[data bytes],[data length],&len);
   
   if(result==NULL)
    return nil;

   return [NSData dataWithBytesNoCopy:result length:len];
}


+(NSData *)decodeWithName:(const char *)name data:(NSData *)data parameters:(KGPDFDictionary *)parameters {
   if(strcmp(name,"FlateDecode")==0){
    KGPDFInteger predictor;
    
    data=[self FlateDecode_data:data parameters:parameters];

    if([parameters getIntegerForKey:"Predictor" value:&predictor]){
     if(predictor>1){
      NSMutableData *mutable=[NSMutableData data];
      const  char *bytes=[data bytes];
      unsigned             length=[data length];
      KGPDFInteger colors;
      KGPDFInteger bitsPerComponent;
      KGPDFInteger columns;
      int          bytesPerRow;
      int          row,rowLength,numberOfRows;
      
      if(![parameters getIntegerForKey:"Colors" value:&colors])
       colors=1;
      if(![parameters getIntegerForKey:"BitsPerComponent" value:&bitsPerComponent])
       bitsPerComponent=8;
      if(![parameters getIntegerForKey:"Columns" value:&columns])
       columns=1;
       
//NSLog(@"predictor=%d,colors=%d,bpc=%d,columns=%d,length=%d",predictor,colors,bitsPerComponent,columns,length);

      bytesPerRow=(((colors*bitsPerComponent)*columns)+7)/8;
      rowLength=bytesPerRow+1;
      numberOfRows=length/rowLength;
      
      if((length%rowLength)!=0)
       ;//NSLog(@"length mod rowLength=%d",length%rowLength);
        
      for(row=0;row<numberOfRows;row++){
       int i,filter=bytes[0];
        char change[rowLength];
       
       for(i=0;i<rowLength-1;i++)
        change[i]=bytes[1+i];
        
       if(filter==0){
        // do nothing
       }
       else if(filter==1){
        int last=change[0];
        
        for(i=1;i<rowLength-1;i++){
         last=last+change[i];              
         change[i]=last;
        }
       }
       else if(filter==2){
        int last=change[0];
        
        for(i=1;i<rowLength-1;i++){
         last=last-change[i];              
         change[i]=last;
        }
       }
       else {
        NSLog(@"unsupported filter %d for predictor %d",filter,predictor);
       }
       
       [mutable appendBytes:change length:rowLength-1];
       bytes+=rowLength;
       length-=rowLength;
      }
      if(length>1)
       [mutable appendBytes:bytes length:length-1];
      data=mutable;
     }
    }
   
   
    return data;
   }
   NSLog(@"Unknown KGPDFFilter name = %s",name);
   return nil;
}

@end
