/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and /or associated documentation files
 * (the "Materials "), to deal in the Materials without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Materials,
 * and to permit persons to whom the Materials are furnished to do so,
 * subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Materials. 
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE MATERIALS OR
 * THE USE OR OTHER DEALINGS IN THE MATERIALS.
 *
 *-------------------------------------------------------------------*/

#import <Onyx2D/O2Surface.h>
#import <Onyx2D/O2ColorSpace.h>
#import <Onyx2D/O2DataProvider.h>

@implementation O2Surface

#define RI_MAX_GAUSSIAN_STD_DEVIATION	128.0f

/*-------------------------------------------------------------------*//*!
* \brief	Converts from the current internal format to another.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

// Can't use 'gamma' ?
static O2Float dogamma(O2Float c)
{    
	if( c <= 0.00304f )
		c *= 12.92f;
	else
		c = 1.0556f * (O2Float)pow(c, 1.0f/2.4f) - 0.0556f;
	return c;
}

static O2Float invgamma(O2Float c)
{
	if( c <= 0.03928f )
		c /= 12.92f;
	else
		c = (O2Float)pow((c + 0.0556f)/1.0556f, 2.4f);
	return c;
}

static O2Float lRGBtoL(O2Float r, O2Float g, O2Float b)
{
	return 0.2126f*r + 0.7152f*g + 0.0722f*b;
}

VGColor VGColorConvert(VGColor result,VGColorInternalFormat outputFormat){
	RI_ASSERT(result.r >= 0.0f && result.r <= 1.0f);
	RI_ASSERT(result.g >= 0.0f && result.g <= 1.0f);
	RI_ASSERT(result.b >= 0.0f && result.b <= 1.0f);
	RI_ASSERT(result.a >= 0.0f && result.a <= 1.0f);
	RI_ASSERT((result.m_format & VGColorLUMINANCE && result.r == result.g && result.r == result.b) || !(result.m_format & VGColorLUMINANCE));	//if luminance, r=g=b

	if( result.m_format == outputFormat )
		return result;

	if(result.m_format & VGColorPREMULTIPLIED)
	{	//unpremultiply
		RI_ASSERT(result.r <= result.a);
		RI_ASSERT(result.g <= result.a);
		RI_ASSERT(result.b <= result.a);
		O2Float ooa = (result.a != 0.0f) ? 1.0f / result.a : (O2Float)0.0f;
		result.r *= ooa;
		result.g *= ooa;
		result.b *= ooa;
	}

	//From Section 3.4.2 of OpenVG 1.0.1 spec
	//1: sRGB = gamma(lRGB)
	//2: lRGB = invgamma(sRGB)
	//3: lL = 0.2126 lR + 0.7152 lG + 0.0722 lB
	//4: lRGB = lL
	//5: sL = gamma(lL)
	//6: lL = invgamma(sL)
	//7: sRGB = sL

	//Source/Dest lRGB sRGB   lL   sL 
	//lRGB          —    1    3    3,5 
	//sRGB          2    —    2,3  2,3,5 
	//lL            4    4,1  —    5 
	//sL            7,2  7    6    — 

	#define shift 3
	unsigned int conversion = (result.m_format & (VGColorNONLINEAR | VGColorLUMINANCE)) | ((outputFormat & (VGColorNONLINEAR | VGColorLUMINANCE)) << shift);

	switch(conversion)
	{
	case VGColor_lRGBA | (VGColor_sRGBA << shift): result.r = dogamma(result.r); result.g = dogamma(result.g); result.b = dogamma(result.b); break;							//1
	case VGColor_lRGBA | (VGColor_lLA << shift)  : result.r = result.g = result.b = lRGBtoL(result.r, result.g, result.b); break;										//3
	case VGColor_lRGBA | (VGColor_sLA << shift)  : result.r = result.g = result.b = dogamma(lRGBtoL(result.r, result.g, result.b)); break;								//3,5
	case VGColor_sRGBA | (VGColor_lRGBA << shift): result.r = invgamma(result.r); result.g = invgamma(result.g); result.b = invgamma(result.b); break;				//2
	case VGColor_sRGBA | (VGColor_lLA << shift)  : result.r = result.g = result.b = lRGBtoL(invgamma(result.r), invgamma(result.g), invgamma(result.b)); break;		//2,3
	case VGColor_sRGBA | (VGColor_sLA << shift)  : result.r = result.g = result.b = dogamma(lRGBtoL(invgamma(result.r), invgamma(result.g), invgamma(result.b))); break;//2,3,5
	case VGColor_lLA   | (VGColor_lRGBA << shift): break;																	//4
	case VGColor_lLA   | (VGColor_sRGBA << shift): result.r = result.g = result.b = dogamma(result.r); break;												//4,1
	case VGColor_lLA   | (VGColor_sLA << shift)  : result.r = result.g = result.b = dogamma(result.r); break;												//5
	case VGColor_sLA   | (VGColor_lRGBA << shift): result.r = result.g = result.b = invgamma(result.r); break;											//7,2
	case VGColor_sLA   | (VGColor_sRGBA << shift): break;																	//7
	case VGColor_sLA   | (VGColor_lLA << shift)  : result.r = result.g = result.b = invgamma(result.r); break;											//6
	default: RI_ASSERT((result.m_format & (VGColorLUMINANCE | VGColorNONLINEAR)) == (outputFormat & (VGColorLUMINANCE | VGColorNONLINEAR))); break;	//nop
	}

	if(outputFormat & VGColorPREMULTIPLIED)
	{	//premultiply
		result.r *= result.a;
		result.g *= result.a;
		result.b *= result.a;
		RI_ASSERT(result.r <= result.a);
		RI_ASSERT(result.g <= result.a);
		RI_ASSERT(result.b <= result.a);
	}
	result.m_format = outputFormat;
    return result;
}

static void colorToBytesLittle(O2Float color,uint8_t *scanline){
   union {
    unsigned char bytes[4];
    float         f;
   } u;
   
   u.f=color;
   
#ifdef __LITTLE_ENDIAN__   
   scanline[0]=u.bytes[0];
   scanline[1]=u.bytes[1];
   scanline[2]=u.bytes[2];
   scanline[3]=u.bytes[3];
#else
   scanline[3]=u.bytes[0];
   scanline[2]=u.bytes[1];
   scanline[1]=u.bytes[2];
   scanline[0]=u.bytes[3];
#endif
}

static void O2SurfaceWrite_argb32f_to_argb32fLittle(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*16;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    colorToBytesLittle(rgba.r,scanline);
    scanline+=4;
    colorToBytesLittle(rgba.g,scanline);
    scanline+=4;
    colorToBytesLittle(rgba.b,scanline);
    scanline+=4;
    colorToBytesLittle(rgba.a,scanline);
    scanline+=4;
   }
}

static void colorToBytesBig(O2Float color,uint8_t *scanline){
   union {
    unsigned char bytes[4];
    float         f;
   } u;
   
   u.f=color;
   
#ifdef __BIG_ENDIAN__   
   scanline[0]=u.bytes[0];
   scanline[1]=u.bytes[1];
   scanline[2]=u.bytes[2];
   scanline[3]=u.bytes[3];
#else
   scanline[3]=u.bytes[0];
   scanline[2]=u.bytes[1];
   scanline[1]=u.bytes[2];
   scanline[0]=u.bytes[3];
#endif
}

static void O2SurfaceWrite_argb32f_to_argb32fBig(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*16;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    colorToBytesBig(rgba.r,scanline);
    scanline+=4;
    colorToBytesBig(rgba.g,scanline);
    scanline+=4;
    colorToBytesBig(rgba.b,scanline);
    scanline+=4;
    colorToBytesBig(rgba.a,scanline);
    scanline+=4;
   }
}

static unsigned char colorToNibble(O2Float c){
	return RI_INT_MIN(RI_INT_MAX(RI_FLOOR_TO_INT(c * (O2Float)0xF + 0.5f), 0), 0xF);
}

static void O2SurfaceWrite_argb32f_to_GA88(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*2;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=O2ByteFromFloat(rgba.r);
    *scanline++=O2ByteFromFloat(rgba.a);
   }
}

static void O2SurfaceWrite_argb32f_to_G8(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=O2ByteFromFloat(lRGBtoL(rgba.r,rgba.g,rgba.b));
   }
}


static void O2SurfaceWrite_argb32f_to_argb8u(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=O2ByteFromFloat(rgba.r);
    *scanline++=O2ByteFromFloat(rgba.g);
    *scanline++=O2ByteFromFloat(rgba.b);
    *scanline++=O2ByteFromFloat(rgba.a);
   }
}

static void O2SurfaceWrite_argb8u_to_argb8u(O2Surface *self,int x,int y,O2argb8u *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb8u rgba=*span++;

    *scanline++=rgba.r;
    *scanline++=rgba.g;
    *scanline++=rgba.b;
    *scanline++=rgba.a;
   }
}

static void O2SurfaceWrite_argb32f_to_ABGR8888(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=O2ByteFromFloat(rgba.a);
    *scanline++=O2ByteFromFloat(rgba.b);
    *scanline++=O2ByteFromFloat(rgba.g);
    *scanline++=O2ByteFromFloat(rgba.r);
   }
}

static void O2SurfaceWrite_argb8u_to_ABGR8888(O2Surface *self,int x,int y,O2argb8u *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb8u rgba=*span++;

    *scanline++=rgba.a;
    *scanline++=rgba.b;
    *scanline++=rgba.g;
    *scanline++=rgba.r;
   }
}

static void O2SurfaceWrite_argb8u_to_BGRA8888(O2Surface *self,int x,int y,O2argb8u *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb8u rgba=*span++;

    *scanline++=rgba.b;
    *scanline++=rgba.g;
    *scanline++=rgba.r;
    *scanline++=rgba.a;
   }
}

static void O2SurfaceWrite_argb32f_to_RGBA4444(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*2;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=colorToNibble(rgba.r)<<4|colorToNibble(rgba.g);
    *scanline++=colorToNibble(rgba.b)<<4|colorToNibble(rgba.a);
   }
}

static void O2SurfaceWrite_argb32f_to_BARG4444(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*2;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=colorToNibble(rgba.b)<<4|colorToNibble(rgba.a);
    *scanline++=colorToNibble(rgba.r)<<4|colorToNibble(rgba.g);
   }
}

static void O2SurfaceWrite_argb32f_to_RGBA2222(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=colorToNibble(rgba.a)<<6|colorToNibble(rgba.a)<<6|colorToNibble(rgba.a)<<2|colorToNibble(rgba.b);
   }
}

static void O2SurfaceWrite_argb32f_to_CMYK8888(O2Surface *self,int x,int y,O2argb32f *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    *scanline++=O2ByteFromFloat(1.0-rgba.r);
    *scanline++=O2ByteFromFloat(1.0-rgba.g);
    *scanline++=O2ByteFromFloat(1.0-rgba.b);
    *scanline++=O2ByteFromFloat(0);
   }
}

static void O2SurfaceWrite_argb32f_to_argb8u_to_ANY(O2Surface *self,int x,int y,O2argb32f *span,int length){
   O2argb8u span8888[length];
   int i;
   
   for(i=0;i<length;i++){
    O2argb32f rgba=*span++;

    span8888[i].r=O2ByteFromFloat(rgba.r);
    span8888[i].g=O2ByteFromFloat(rgba.g);
    span8888[i].b=O2ByteFromFloat(rgba.b);
    span8888[i].a=O2ByteFromFloat(rgba.a);
   }
   self->_writeargb8u(self,x,y,span8888,length);
}

static BOOL initFunctionsForParameters(O2Surface *self,size_t bitsPerComponent,size_t bitsPerPixel,O2ColorSpaceRef colorSpace,O2BitmapInfo bitmapInfo){
   self->_writeargb32f=O2SurfaceWrite_argb32f_to_argb8u_to_ANY;// default
   
   switch(bitsPerComponent){
   
    case 32:
     switch(bitsPerPixel){
      case 32:
       break;
      case 128:
       switch(bitmapInfo&kO2BitmapByteOrderMask){
        case kO2BitmapByteOrderDefault:
        case kO2BitmapByteOrder16Little:
        case kO2BitmapByteOrder32Little:
         self->_writeargb32f=O2SurfaceWrite_argb32f_to_argb32fLittle;
         return YES;
         
        case kO2BitmapByteOrder16Big:
        case kO2BitmapByteOrder32Big:
         self->_writeargb32f=O2SurfaceWrite_argb32f_to_argb32fBig;
         return YES;
       }
     }
     break;
     
    case  8:
     switch(bitsPerPixel){
     
      case 8:
       self->_writeargb32f=O2SurfaceWrite_argb32f_to_G8;
       return YES;

      case 16:
       self->_writeargb32f=O2SurfaceWrite_argb32f_to_GA88;
       return YES;

      case 24:
       break;
       
      case 32:
       if([colorSpace type]==kO2ColorSpaceModelRGB){

        switch(bitmapInfo&kO2BitmapAlphaInfoMask){
         case kO2ImageAlphaNone:
          break;
          
         case kO2ImageAlphaLast:
         case kO2ImageAlphaPremultipliedLast:
          switch(bitmapInfo&kO2BitmapByteOrderMask){
           case kO2BitmapByteOrderDefault:
           case kO2BitmapByteOrder16Little:
           case kO2BitmapByteOrder32Little:
            self->_writeargb32f=O2SurfaceWrite_argb32f_to_ABGR8888;
            self->_writeargb8u=O2SurfaceWrite_argb8u_to_ABGR8888;
            return YES;

           case kO2BitmapByteOrder16Big:
           case kO2BitmapByteOrder32Big:
            self->_writeargb32f=O2SurfaceWrite_argb32f_to_argb8u;
            self->_writeargb8u=O2SurfaceWrite_argb8u_to_argb8u;
            return YES;
          }

          break;
          
         case kO2ImageAlphaPremultipliedFirst:
          switch(bitmapInfo&kO2BitmapByteOrderMask){
           case kO2BitmapByteOrderDefault:
           case kO2BitmapByteOrder16Little:
           case kO2BitmapByteOrder32Little:
            self->_writeargb8u=O2SurfaceWrite_argb8u_to_BGRA8888;
            return YES;
          }
          break;
                    
         case kO2ImageAlphaFirst:
          break;
          
         case kO2ImageAlphaNoneSkipLast:
          break;
          
         case kO2ImageAlphaNoneSkipFirst:
          break;
        }
       }
       else if([colorSpace type]==kO2ColorSpaceModelCMYK){
        switch(bitmapInfo&kO2BitmapByteOrderMask){
         case kO2BitmapByteOrderDefault:
         case kO2BitmapByteOrder16Little:
         case kO2BitmapByteOrder32Little:
          break;
         
         case kO2BitmapByteOrder16Big:
         case kO2BitmapByteOrder32Big:
          self->_writeargb32f=O2SurfaceWrite_argb32f_to_CMYK8888;
         return YES;
        }
       }
       break;
     }
     break;
     
    case  4:
     switch(bitsPerPixel){
      case 4:
       break;
      case 12:
       break;
      case 16:
       switch(bitmapInfo&kO2BitmapByteOrderMask){
        case kO2BitmapByteOrderDefault:
        case kO2BitmapByteOrder16Little:
        case kO2BitmapByteOrder32Little:
         self->_writeargb32f=O2SurfaceWrite_argb32f_to_BARG4444;
         return YES;
         
        case kO2BitmapByteOrder16Big:
        case kO2BitmapByteOrder32Big:
         self->_writeargb32f=O2SurfaceWrite_argb32f_to_RGBA4444;
         return YES;
       }
     }
     break;
     
    case  2:
     switch(bitsPerPixel){
      case 2:
       break;
      case 6:
       break;
      case 8:
       self->_writeargb32f=O2SurfaceWrite_argb32f_to_RGBA2222;
       return YES;
     }
     break;

    case  1:
     switch(bitsPerPixel){
      case 1:
       //  self->_writeargb32f=O2SurfaceWriteSpan_largb32f_PRE_01;
       return YES;
       
      case 3:
       break;
     }
     break;
   }
   return NO;   
}

-initWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(O2BitmapInfo)bitmapInfo {
   O2DataProvider *provider;
   int bitsPerPixel=32;
   
   if(bytes!=NULL){
    provider=[[[O2DataProvider alloc] initWithBytes:bytes length:bytesPerRow*height] autorelease];
    m_ownsData=NO;
   }
   else {
    if(bytesPerRow==0)
     bytesPerRow=(width*bitsPerPixel)/8;
     
    NSMutableData *data=[NSMutableData dataWithLength:bytesPerRow*height*sizeof(uint8_t)]; // this will also zero the bytes
    provider=[[[O2DataProvider alloc] initWithData:data] autorelease];
  	m_ownsData=YES;
   }
   
   if([super initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo provider:provider decode:NULL interpolate:YES renderingIntent:kO2RenderingIntentDefault]==nil)
    return nil;
   
   if([provider isDirectAccess])
    _pixelBytes=(void *)[provider bytes];

   if(!initFunctionsForParameters(self,bitsPerComponent,_bitsPerPixel,colorSpace,bitmapInfo))
    NSLog(@"O2Surface -init error, return");

   size_t checkBPP;
   m_desc=O2ImageParametersToPixelLayout(VG_lRGBA_8888_PRE,&checkBPP,&(_colorFormat));
   RI_ASSERT(checkBPP==bitsPerPixel);

   _clampExternalPixels=NO; // only set to yes if premultiplied
   m_mipmapsValid=NO;

   _mipmapsCount=0;
   _mipmapsCapacity=2;
   _mipmaps=(O2Surface **)NSZoneMalloc(NULL,_mipmapsCapacity*sizeof(O2Surface *));
   return self;
}

-(void)dealloc {
    int i;
    
	for(i=0;i<_mipmapsCount;i++){
     [_mipmaps[i] release];
	}
	_mipmapsCount=0;

    _pixelBytes=NULL; // if we own it, it's in the provider, if not, no release

    [super dealloc];
}

-(void *)pixelBytes {
   return _pixelBytes;
}

-(void)setWidth:(size_t)width height:(size_t)height reallocateOnlyIfRequired:(BOOL)roir {

   if(!m_ownsData)
    return;

   _width=width;
   _height=height;
   _bytesPerRow=width*_bitsPerPixel/8;
   
   NSUInteger size=_bytesPerRow*height*sizeof(uint8_t);
   NSUInteger allocateSize=[[_provider data] length];
   
   if((size>allocateSize) || (!roir && size!=allocateSize)){
    [_provider release];
    
    NSMutableData *data=[NSMutableData dataWithLength:size];
    _provider=[[O2DataProvider alloc] initWithData:data];
    _pixelBytes=[data mutableBytes];
   }
}

/*-------------------------------------------------------------------*//*!
* \brief	Clears a rectangular portion of an image with the given clear color.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceClear(O2Surface *self,VGColor clearColor, int x, int y, int w, int h){
	RI_ASSERT(self->_pixelBytes);

	//intersect clear region with image bounds
	O2IntRect r=O2IntRectInit(0,0,self->_width,self->_height);
	r=O2IntRectIntersect(r,O2IntRectInit(x,y,w,h));
	if(!r.width || !r.height)
		return;		//intersection is empty or one of the rectangles is invalid

	VGColor col = clearColor;
	col=VGColorClamp(col);
	col=VGColorConvert(col,self->_colorFormat);

    int j;
	for(j=r.y;j<r.y + r.height;j++)
	{
        int i;
		for(i=r.x;i<r.x + r.width;i++)
		{
			O2SurfaceWritePixel(self,i, j, col);
		}
	}

	self->m_mipmapsValid = NO;
}


/*-------------------------------------------------------------------*//*!
* \brief	Returns the color at pixel (x,y).
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

VGColor O2SurfaceReadPixel(O2Image *self,int x, int y) {
	RI_ASSERT(self->_pixelBytes);
	RI_ASSERT(x >= 0 && x < self->_width);
	RI_ASSERT(y >= 0 && y < self->_height);
 
    O2argb32f span,*direct=O2ImageReadSpan_largb32f_PRE(self,x,y,&span,1);
   
    if(direct!=NULL)
     return VGColorFromargb32f(*direct,VGColor_lRGBA_PRE);
    else
     return VGColorFromargb32f(span,VGColor_lRGBA_PRE);
}


/*-------------------------------------------------------------------*//*!
* \brief	Blits a source region to destination. Source and destination
*			can overlap.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static O2Float ditherChannel(O2Float c, int bits, O2Float m)
{
	O2Float fc = c * (O2Float)((1<<bits)-1);
	O2Float ic = (O2Float)floor(fc);
	if(fc - ic > m) ic += 1.0f;
	return RI_MIN(ic / (O2Float)((1<<bits)-1), 1.0f);
}

void O2SurfaceBlit(O2Surface *self,O2Surface * src, int sx, int sy, int dx, int dy, int w, int h, BOOL dither) {
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(w > 0 && h > 0);

	sx = RI_INT_MIN(RI_INT_MAX(sx, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	sy = RI_INT_MIN(RI_INT_MAX(sy, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	dx = RI_INT_MIN(RI_INT_MAX(dx, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	dy = RI_INT_MIN(RI_INT_MAX(dy, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	w = RI_INT_MIN(w, (int)(RI_INT32_MAX>>2));
	h = RI_INT_MIN(h, (int)(RI_INT32_MAX>>2));
	int srcsx = sx, srcex = sx + w, dstsx = dx, dstex = dx + w;
	if(srcsx < 0)
	{
		dstsx -= srcsx;
		srcsx = 0;
	}
	if(srcex > src->_width)
	{
		dstex -= srcex - src->_width;
		srcex = src->_width;
	}
	if(dstsx < 0)
	{
		srcsx -= dstsx;
		dstsx = 0;
	}
	if(dstex > self->_width)
	{
		srcex -= dstex - self->_width;
		dstex = self->_width;
	}
	RI_ASSERT(srcsx >= 0 && dstsx >= 0 && srcex <= src->_width && dstex <= self->_width);
	w = srcex - srcsx;
	RI_ASSERT(w == dstex - dstsx);
	if(w <= 0)
		return;	//zero area

	int srcsy = sy, srcey = sy + h, dstsy = dy, dstey = dy + h;
	if(srcsy < 0)
	{
		dstsy -= srcsy;
		srcsy = 0;
	}
	if(srcey > src->_height)
	{
		dstey -= srcey - src->_height;
		srcey = src->_height;
	}
	if(dstsy < 0)
	{
		srcsy -= dstsy;
		dstsy = 0;
	}
	if(dstey > self->_height)
	{
		srcey -= dstey - self->_height;
		dstey = self->_height;
	}
	RI_ASSERT(srcsy >= 0 && dstsy >= 0 && srcey <= src->_height && dstey <= self->_height);
	h = srcey - srcsy;
	RI_ASSERT(h == dstey - dstsy);
	if(h <= 0)
		return;	//zero area

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,w*h*sizeof(VGColor));

	//copy source region to tmp
    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor c = O2SurfaceReadPixel(src,srcsx + i, srcsy + j);
			c=VGColorConvert(c,self->_colorFormat);
			tmp[j*w+i] = c;
		}
	}

	int rbits = self->m_desc.redBits, gbits = self->m_desc.greenBits, bbits = self->m_desc.blueBits, abits = self->m_desc.alphaBits;
	if(self->m_desc.luminanceBits)
	{
		rbits = gbits = bbits = self->m_desc.luminanceBits;
		abits = 0;
	}

	//write tmp to destination region
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor col = tmp[j*w+i];

			if(dither)
			{
				static const int matrix[16] = {
					0,  8,  2,  10,
					12, 4,  14, 6,
					3,  11, 1,  9,
					15, 7,  13, 5};
				int x = i & 3;
				int y = j & 3;
				O2Float m = matrix[y*4+x] / 16.0f;

				if(rbits) col.r = ditherChannel(col.r, rbits, m);
				if(gbits) col.g = ditherChannel(col.g, gbits, m);
				if(bbits) col.b = ditherChannel(col.b, bbits, m);
				if(abits) col.a = ditherChannel(col.a, abits, m);
			}

			O2SurfaceWritePixel(self,dstsx + i, dstsy + j, col);
		}
	}
    NSZoneFree(NULL,tmp);
	self->m_mipmapsValid = NO;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies a mask operation to a rectangular portion of a mask image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceMask(O2Surface *self,O2Surface* src, VGMaskOperation operation, int x, int y, int w, int h) {
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(w > 0 && h > 0);

	self->m_mipmapsValid = NO;
	if(operation == VG_CLEAR_MASK)
	{
		O2SurfaceClear(self,VGColorRGBA(0,0,0,0,VGColor_lRGBA), x, y, w, h);
		return;
	}
	if(operation == VG_FILL_MASK)
	{
		O2SurfaceClear(self,VGColorRGBA(1,1,1,1,VGColor_lRGBA), x, y, w, h);
		return;
	}

	RI_ASSERT(src->_pixelBytes);	//source exists

	//intersect destination region with source and destination image bounds
	x = RI_INT_MIN(RI_INT_MAX(x, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	y = RI_INT_MIN(RI_INT_MAX(y, (int)(RI_INT32_MIN>>2)), (int)(RI_INT32_MAX>>2));
	w = RI_INT_MIN(w, (int)(RI_INT32_MAX>>2));
	h = RI_INT_MIN(h, (int)(RI_INT32_MAX>>2));

	int srcsx = 0, srcex = w, dstsx = x, dstex = x + w;
	if(srcex > src->_width)
	{
		dstex -= srcex - src->_width;
		srcex = src->_width;
	}
	if(dstsx < 0)
	{
		srcsx -= dstsx;
		dstsx = 0;
	}
	if(dstex > self->_width)
	{
		srcex -= dstex - self->_width;
		dstex = self->_width;
	}
	RI_ASSERT(srcsx >= 0 && dstsx >= 0 && srcex <= src->_width && dstex <= self->_width);
	w = srcex - srcsx;
	RI_ASSERT(w == dstex - dstsx);
	if(w <= 0)
		return;	//zero area

	int srcsy = 0, srcey = h, dstsy = y, dstey = y + h;
	if(srcey > src->_height)
	{
		dstey -= srcey - src->_height;
		srcey = src->_height;
	}
	if(dstsy < 0)
	{
		srcsy -= dstsy;
		dstsy = 0;
	}
	if(dstey > self->_height)
	{
		srcey -= dstey - self->_height;
		dstey = self->_height;
	}
	RI_ASSERT(srcsy >= 0 && dstsy >= 0 && srcey <= src->_height && dstey <= self->_height);
	h = srcey - srcsy;
	RI_ASSERT(h == dstey - dstsy);
	if(h <= 0)
		return;	//zero area

    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			O2Float aprev,amask ;
			O2Float anew = 0.0f;
            
            O2ImageReadSpan_Af_MASK(self,dstsx + i,dstsy + j,&aprev,1);
            O2ImageReadSpan_Af_MASK(src,srcsx + i,srcsy + j,&amask,1);
            
			switch(operation)
			{
			case VG_SET_MASK:
				anew = amask;
				break;

			case VG_UNION_MASK:
				anew = 1.0f - (1.0f - amask)*(1.0f - aprev);
				break;

			case VG_INTERSECT_MASK:
				anew = amask * aprev;
				break;

			default:
				RI_ASSERT(operation == VG_SUBTRACT_MASK);
				anew = aprev * (1.0f - amask);
				break;
			}
			O2SurfaceWriteMaskPixel(self,dstsx + i, dstsy + j, anew);
		}
	}
}

void O2SurfaceWriteSpan_argb8u_PRE(O2Surface *self,int x,int y,O2argb8u *span,int length) {   
   if(length==0)
    return;

  // O2argb8uConvertSpan(span,length,VGColor_lRGBA_PRE,self->_colorFormat);
   
   self->_writeargb8u(self,x,y,span,length);
   
   self->m_mipmapsValid = NO;
}

void O2SurfaceWriteSpan_largb32f_PRE(O2Surface *self,int x,int y,O2argb32f *span,int length) {   
   if(length==0)
    return;
    
   O2argb32fConvertSpan(span,length,VGColor_lRGBA_PRE,self->_colorFormat);
   
   self->_writeargb32f(self,x,y,span,length);
   
   self->m_mipmapsValid = NO;
}

void O2SurfaceWritePixel(O2Surface *self,int x, int y, VGColor c) {
	RI_ASSERT(self->_pixelBytes);
	RI_ASSERT(x >= 0 && x < self->_width);
	RI_ASSERT(y >= 0 && y < self->_height);
	RI_ASSERT(c.m_format == self->_colorFormat);
    O2argb32f span=O2argb32fFromColor(VGColorConvert(c,VGColor_lRGBA_PRE));
    
    O2SurfaceWriteSpan_largb32f_PRE(self,x,y,&span,1);
	self->m_mipmapsValid = NO;
}



/*-------------------------------------------------------------------*//*!
* \brief	Writes a filtered color to destination surface
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceWriteFilteredPixel(O2Surface *self,int i, int j, VGColor color, VGbitfield channelMask) {
	//section 3.4.4: before color space conversion, premultiplied colors are
	//clamped to alpha, and the color is converted to nonpremultiplied format
	//section 11.2: how to deal with channel mask
	//step 1
	VGColor f = color;
	f=VGColorClamp(f);			//vgColorMatrix and vgLookups can produce colors that exceed alpha or [0,1] range
	f=VGColorUnpremultiply(f);

	//step 2: color space conversion
	f=VGColorConvert(f,(VGColorInternalFormat)(self->_colorFormat & (VGColorNONLINEAR | VGColorLUMINANCE)));

	//step 3: read the destination color and convert it to nonpremultiplied
	VGColor d = O2SurfaceReadPixel(self,i,j);
	d=VGColorUnpremultiply(d);
	RI_ASSERT(d.m_format == f.m_format);

	//step 4: replace the destination channels specified by the channelMask
	if(channelMask & VG_RED)
		d.r = f.r;
	if(channelMask & VG_GREEN)
		d.g = f.g;
	if(channelMask & VG_BLUE)
		d.b = f.b;
	if(channelMask & VG_ALPHA)
		d.a = f.a;

	//step 5: if destination is premultiplied, convert to premultiplied format
	if(self->_colorFormat & VGColorPREMULTIPLIED)
		d=VGColorPremultiply(d);
	//write the color to destination
	O2SurfaceWritePixel(self,i,j,d);
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes the alpha mask to pixel (x,y) of a VG_A_8 image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceWriteMaskPixel(O2Surface *self,int x, int y, O2Float m)	//can write only to VG_A_8
{
	RI_ASSERT(self->_pixelBytes);
	RI_ASSERT(x >= 0 && x < self->_width);
	RI_ASSERT(y >= 0 && y < self->_height);
	RI_ASSERT(self->m_desc.alphaBits == 8 && self->m_desc.redBits == 0 && self->m_desc.greenBits == 0 && self->m_desc.blueBits == 0 && self->m_desc.luminanceBits == 0 && self->_bitsPerPixel == 8);

	uint8_t* s = ((uint8_t*)(self->_pixelBytes + y * self->_bytesPerRow)) + x;
	*s = (uint8_t)O2ByteFromFloat(m);
	self->m_mipmapsValid = NO;
}


/*-------------------------------------------------------------------*//*!
* \brief	Applies color matrix filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceColorMatrix(O2Surface *self,O2Surface * src, const O2Float* matrix, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask) {
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(matrix);

	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat srcFormat = src->_colorFormat;
	VGColorInternalFormat procFormat = (VGColorInternalFormat)(srcFormat & ~VGColorLUMINANCE);	//process in RGB, not luminance
	if(filterFormatLinear)
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorNONLINEAR);
	else
		procFormat = (VGColorInternalFormat)(procFormat | VGColorNONLINEAR);

	if(filterFormatPremultiplied)
		procFormat = (VGColorInternalFormat)(procFormat | VGColorPREMULTIPLIED);
	else
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorPREMULTIPLIED);

    int j,i;
	for(j=0;j<h;j++)
	{
		for(i=0;i<w;i++)
		{
			VGColor s = O2SurfaceReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);

			VGColor d=VGColorRGBA(0,0,0,0,procFormat);
			d.r = matrix[0+4*0] * s.r + matrix[0+4*1] * s.g + matrix[0+4*2] * s.b + matrix[0+4*3] * s.a + matrix[0+4*4];
			d.g = matrix[1+4*0] * s.r + matrix[1+4*1] * s.g + matrix[1+4*2] * s.b + matrix[1+4*3] * s.a + matrix[1+4*4];
			d.b = matrix[2+4*0] * s.r + matrix[2+4*1] * s.g + matrix[2+4*2] * s.b + matrix[2+4*3] * s.a + matrix[2+4*4];
			d.a = matrix[3+4*0] * s.r + matrix[3+4*1] * s.g + matrix[3+4*2] * s.b + matrix[3+4*3] * s.a + matrix[3+4*4];

			O2SurfaceWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Reads a pixel from image with tiling mode applied.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static VGColor readTiledPixel(int x, int y, int w, int h, VGTilingMode tilingMode,VGColor *image, VGColor edge)
{
	VGColor s=VGColorZero();
	if(x < 0 || x >= w || y < 0 || y >= h)
	{	//apply tiling mode
		switch(tilingMode)
		{
		case VG_TILE_FILL:
			s = edge;
			break;
		case VG_TILE_PAD:
			x = RI_INT_MIN(RI_INT_MAX(x, 0), w-1);
			y = RI_INT_MIN(RI_INT_MAX(y, 0), h-1);
			RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
			s = image[y*w+x];
			break;
		case VG_TILE_REPEAT:
			x = RI_INT_MOD(x, w);
			y = RI_INT_MOD(y, h);
			RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
			s = image[y*w+x];
			break;
		}
	}
	else
	{
		RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
		s = image[y*w+x];
	}
	return s;
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns processing format for filtering.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static VGColorInternalFormat getProcessingFormat(VGColorInternalFormat srcFormat, BOOL filterFormatLinear, BOOL filterFormatPremultiplied)
{
	VGColorInternalFormat procFormat = (VGColorInternalFormat)(srcFormat & ~VGColorLUMINANCE);	//process in RGB, not luminance
	if(filterFormatLinear)
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorNONLINEAR);
	else
		procFormat = (VGColorInternalFormat)(procFormat | VGColorNONLINEAR);

	if(filterFormatPremultiplied)
		procFormat = (VGColorInternalFormat)(procFormat | VGColorPREMULTIPLIED);
	else
		procFormat = (VGColorInternalFormat)(procFormat & ~VGColorPREMULTIPLIED);
	return procFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies convolution filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceConvolve(O2Surface *self,O2Surface * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, O2Float scale, O2Float bias, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask) {
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(kernel && kernelWidth > 0 && kernelHeight > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->_colorFormat, filterFormatLinear, filterFormatPremultiplied);

	VGColor edge = edgeFillColor;
	edge=VGColorClamp(edge);
	edge=VGColorConvert(edge,procFormat);

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,src->_width*src->_height*sizeof(VGColor));

	//copy source region to tmp and do conversion
    int j;
	for(j=0;j<src->_height;j++)
	{
        int i;
		for(i=0;i<src->_width;i++)
		{
			VGColor s = O2SurfaceReadPixel(src,i, j);
			s=VGColorConvert(s,procFormat);
			tmp[j*src->_width+i] = s;
		}
	}

	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int kj;
			for(kj=0;kj<kernelHeight;kj++)
			{
                int ki;
				for(ki=0;ki<kernelWidth;ki++)
				{
					int x = i+ki-shiftX;
					int y = j+kj-shiftY;
					VGColor s = readTiledPixel(x, y, src->_width, src->_height, tilingMode, tmp, edge);

					int kx = kernelWidth-ki-1;
					int ky = kernelHeight-kj-1;
					RI_ASSERT(kx >= 0 && kx < kernelWidth && ky >= 0 && ky < kernelHeight);

					sum=VGColorAdd(sum, VGColorMultiplyByFloat(s,(O2Float)kernel[kx*kernelHeight+ky]));
				}
			}

			sum=VGColorMultiplyByFloat(sum ,scale);
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			O2SurfaceWriteFilteredPixel(self,i, j, sum, channelMask);
		}
	}
    NSZoneFree(NULL,tmp);
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies separable convolution filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceSeparableConvolve(O2Surface *self,O2Surface * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, O2Float scale, O2Float bias, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask) {
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(kernelX && kernelY && kernelWidth > 0 && kernelHeight > 0);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->_colorFormat, filterFormatLinear, filterFormatPremultiplied);

	VGColor edge = edgeFillColor;
	edge=VGColorClamp(edge);
	edge=VGColorConvert(edge,procFormat);

	VGColor *tmp=(VGColor *)NSZoneMalloc(NULL,src->_width*src->_height*sizeof(VGColor));

	//copy source region to tmp and do conversion
    int j;
	for(j=0;j<src->_height;j++)
	{
        int i;
		for(i=0;i<src->_width;i++)
		{
			VGColor s = O2SurfaceReadPixel(src,i, j);
			s=VGColorConvert(s,procFormat);
			tmp[j*src->_width+i] = s;
		}
	}

	VGColor *tmp2=(VGColor *)NSZoneMalloc(NULL,w*src->_height*sizeof(VGColor));

	for(j=0;j<src->_height;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int ki;
            
			for(ki=0;ki<kernelWidth;ki++)
			{
				int x = i+ki-shiftX;
				VGColor s = readTiledPixel(x, j, src->_width, src->_height, tilingMode, tmp, edge);

				int kx = kernelWidth-ki-1;
				RI_ASSERT(kx >= 0 && kx < kernelWidth);

				sum=VGColorAdd(sum , VGColorMultiplyByFloat(s,(O2Float)kernelX[kx])) ;
			}
			tmp2[j*w+i] = sum;
		}
	}

	if(tilingMode == VG_TILE_FILL)
	{	//convolve the edge color
		VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
        int ki;
		for(ki=0;ki<kernelWidth;ki++)
		{
			sum=VGColorAdd(sum, VGColorMultiplyByFloat(edge, (O2Float)kernelX[ki]));
		}
		edge = sum;
	}

	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor sum=VGColorRGBA(0,0,0,0,procFormat);
            int kj;
			for(kj=0;kj<kernelHeight;kj++)
			{
				int y = j+kj-shiftY;
				VGColor s = readTiledPixel(i, y, w, src->_height, tilingMode, tmp2, edge);

				int ky = kernelHeight-kj-1;
				RI_ASSERT(ky >= 0 && ky < kernelHeight);

				sum=VGColorAdd(sum, VGColorMultiplyByFloat(s, (O2Float)kernelY[ky]));
			}

			sum=VGColorMultiplyByFloat(sum,scale);
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			O2SurfaceWriteFilteredPixel(self,i, j, sum, channelMask);
		}
	}
    NSZoneFree(NULL,tmp);
    NSZoneFree(NULL,tmp2);
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies Gaussian blur filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static O2argb32f gaussianReadPixel(int x, int y, int w, int h,O2argb32f *image)
{
	if(x < 0 || x >= w || y < 0 || y >= h) {	//apply tiling mode
	 return O2argb32fInit(0,0,0,0);
	}
	else
	{
		RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
		return image[y*w+x];
	}
}

typedef struct O2GaussianKernel {
 int      refCount;
 int      xSize;
 int      xShift;
 O2Float  xScale;
 O2Float *xValues;

 int      ySize;
 int      yShift;
 O2Float  yScale;
 O2Float *yValues;
} O2GaussianKernel;

O2GaussianKernel *O2CreateGaussianKernelWithDeviation(O2Float stdDeviation){
   O2GaussianKernel *kernel=NSZoneMalloc(NULL,sizeof(O2GaussianKernel));
   
   kernel->refCount=1;
   
   O2Float stdDeviationX=stdDeviation;
   O2Float stdDeviationY=stdDeviation;
   
	RI_ASSERT(stdDeviationX > 0.0f && stdDeviationY > 0.0f);
	RI_ASSERT(stdDeviationX <= RI_MAX_GAUSSIAN_STD_DEVIATION && stdDeviationY <= RI_MAX_GAUSSIAN_STD_DEVIATION);
       
	//find a size for the kernel
	O2Float totalWeightX = stdDeviationX*(O2Float)sqrt(2.0f*M_PI);
	O2Float totalWeightY = stdDeviationY*(O2Float)sqrt(2.0f*M_PI);
	const O2Float tolerance = 0.99f;	//use a kernel that covers 99% of the total Gaussian support

	O2Float expScaleX = -1.0f / (2.0f*stdDeviationX*stdDeviationX);
	O2Float expScaleY = -1.0f / (2.0f*stdDeviationY*stdDeviationY);

	int kernelWidth = 0;
	O2Float e = 0.0f;
	O2Float sumX = 1.0f;	//the weight of the middle entry counted already
	do{
		kernelWidth++;
		e = (O2Float)exp((O2Float)(kernelWidth * kernelWidth) * expScaleX);
		sumX += e*2.0f;	//count left&right lobes
	}while(sumX < tolerance*totalWeightX);

	int kernelHeight = 0;
	e = 0.0f;
	O2Float sumY = 1.0f;	//the weight of the middle entry counted already
	do{
		kernelHeight++;
		e = (O2Float)exp((O2Float)(kernelHeight * kernelHeight) * expScaleY);
		sumY += e*2.0f;	//count left&right lobes
	}while(sumY < tolerance*totalWeightY);

	//make a separable kernel
    kernel->xSize=kernelWidth*2+1;
    kernel->xValues=NSZoneMalloc(NULL,sizeof(O2Float)*kernel->xSize);
    kernel->xShift = kernelWidth;
    kernel->xScale = 0.0f;
    int i;
	for(i=0;i<kernel->xSize;i++){
		int x = i-kernel->xShift;
		kernel->xValues[i] = (O2Float)exp((O2Float)x*(O2Float)x * expScaleX);
		kernel->xScale += kernel->xValues[i];
	}
	kernel->xScale = 1.0f / kernel->xScale;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance

    kernel->ySize=kernelHeight*2+1;
    kernel->yValues=NSZoneMalloc(NULL,sizeof(O2Float)*kernel->ySize);
    kernel->yShift = kernelHeight;
    kernel->yScale = 0.0f;
	for(i=0;i<kernel->ySize;i++)
	{
		int y = i-kernel->yShift;
		kernel->yValues[i] = (O2Float)exp((O2Float)y*(O2Float)y * expScaleY);
		kernel->yScale += kernel->yValues[i];
	}
	kernel->yScale = 1.0f / kernel->yScale;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance
    
    return kernel;
}

O2GaussianKernelRef O2GaussianKernelRetain(O2GaussianKernelRef kernel) {
   if(kernel!=NULL)
    kernel->refCount++;
    
   return kernel;
}

void O2GaussianKernelRelease(O2GaussianKernelRef kernel) {
   if(kernel!=NULL){
    kernel->refCount--;
    if(kernel->refCount<=0){
     NSZoneFree(NULL,kernel->xValues);
     NSZoneFree(NULL,kernel->yValues);
     NSZoneFree(NULL,kernel);
    }
   }
}

static O2argb32f argbFromColor(O2ColorRef color){   
   size_t    count=O2ColorGetNumberOfComponents(color);
   const float *components=O2ColorGetComponents(color);

   if(count==2)
    return O2argb32fInit(components[0],components[0],components[0],components[1]);
   if(count==4)
    return O2argb32fInit(components[0],components[1],components[2],components[3]);
    
   return O2argb32fInit(1,0,0,1);
}

void O2SurfaceGaussianBlur(O2Surface *self,O2Image * src, O2GaussianKernel *kernel,O2ColorRef color){
   O2argb32f argbColor=argbFromColor(color);
   
	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);
    
	O2argb32f *tmp=NSZoneMalloc(NULL,src->_width*src->_height*sizeof(O2argb32f));

	//copy source region to tmp and do conversion
    int i,j;
	for(j=0;j<src->_height;j++){
     O2argb32f *tmpRow=tmp+j*src->_width;
     int         i,width=src->_width;
     O2argb32f *direct=O2ImageReadSpan_largb32f_PRE(src,0,j,tmpRow,width);
     
     if(direct!=NULL){
      for(i=0;i<width;i++)
       tmpRow[i]=direct[i];
     }
     for(i=0;i<width;i++){
      tmpRow[i].a=argbColor.a*tmpRow[i].a;
      tmpRow[i].r=argbColor.r*tmpRow[i].a;
      tmpRow[i].g=argbColor.g*tmpRow[i].a;
      tmpRow[i].b=argbColor.b*tmpRow[i].a;
     }
     
  	}

	O2argb32f *tmp2=NSZoneMalloc(NULL,w*src->_height*sizeof(O2argb32f));

	//horizontal pass
	for(j=0;j<src->_height;j++){
		for(i=0;i<w;i++){
			O2argb32f sum=O2argb32fInit(0,0,0,0);
            int ki;
			for(ki=0;ki<kernel->xSize;ki++){
				int x = i+ki-kernel->xShift;
				sum=O2argb32fAdd(sum, O2argb32fMultiplyByFloat(gaussianReadPixel(x, j, src->_width, src->_height, tmp),kernel->xValues[ki]));
			}
			tmp2[j*w+i] = O2argb32fMultiplyByFloat(sum, kernel->xScale);
		}
	}
	//vertical pass
	for(j=0;j<h;j++){
		for(i=0;i<w;i++){
			O2argb32f sum=O2argb32fInit(0,0,0,0);
            int kj;
			for(kj=0;kj<kernel->ySize;kj++){
				int y = j+kj-kernel->yShift;
				sum=O2argb32fAdd(sum,  O2argb32fMultiplyByFloat(gaussianReadPixel(i, y, w, src->_height, tmp2), kernel->yValues[kj]));
			}
            sum=O2argb32fMultiplyByFloat(sum, kernel->yScale);
			O2SurfaceWriteSpan_largb32f_PRE(self,i, j, &sum,1);
		}
	}
    NSZoneFree(NULL,tmp);
    NSZoneFree(NULL,tmp2);
}

/*-------------------------------------------------------------------*//*!
* \brief	Returns lookup table format for lookup filters.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static VGColorInternalFormat getLUTFormat(BOOL outputLinear, BOOL outputPremultiplied)
{
	VGColorInternalFormat lutFormat = VGColor_lRGBA;
	if(outputLinear && outputPremultiplied)
		lutFormat = VGColor_lRGBA_PRE;
	else if(!outputLinear && !outputPremultiplied)
		lutFormat = VGColor_sRGBA;
	else if(!outputLinear && outputPremultiplied)
		lutFormat = VGColor_sRGBA_PRE;
	return lutFormat;
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies multi-channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceLookup(O2Surface *self,O2Surface * src, const uint8_t * redLUT, const uint8_t * greenLUT, const uint8_t * blueLUT, const uint8_t * alphaLUT, BOOL outputLinear, BOOL outputPremultiplied, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask){
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(redLUT && greenLUT && blueLUT && alphaLUT);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);

	VGColorInternalFormat procFormat = getProcessingFormat(src->_colorFormat, filterFormatLinear, filterFormatPremultiplied);
	VGColorInternalFormat lutFormat = getLUTFormat(outputLinear, outputPremultiplied);

    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor s = O2SurfaceReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);

			VGColor d=VGColorRGBA(0,0,0,0,lutFormat);
			d.r = O2Float32FromByte(  redLUT[O2ByteFromFloat(s.r)]);
			d.g = O2Float32FromByte(greenLUT[O2ByteFromFloat(s.g)]);
			d.b = O2Float32FromByte( blueLUT[O2ByteFromFloat(s.b)]);
			d.a = O2Float32FromByte(alphaLUT[O2ByteFromFloat(s.a)]);

			O2SurfaceWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies single channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void O2SurfaceLookupSingle(O2Surface *self,O2Surface * src, const RIuint32 * lookupTable, O2SurfaceChannel sourceChannel, BOOL outputLinear, BOOL outputPremultiplied, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask){
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(lookupTable);

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);

	if(src->m_desc.luminanceBits)
		sourceChannel = VG_RED;
	else if(src->m_desc.redBits + src->m_desc.greenBits + src->m_desc.blueBits == 0)
	{
		RI_ASSERT(src->m_desc.alphaBits);
		sourceChannel = VG_ALPHA;
	}

	VGColorInternalFormat procFormat = getProcessingFormat(src->_colorFormat, filterFormatLinear, filterFormatPremultiplied);
	VGColorInternalFormat lutFormat = getLUTFormat(outputLinear, outputPremultiplied);

    int j;
	for(j=0;j<h;j++)
	{
        int i;
		for(i=0;i<w;i++)
		{
			VGColor s = O2SurfaceReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);
			int e;
			switch(sourceChannel)
			{
			case VG_RED:
				e = O2ByteFromFloat(s.r);
				break;
			case VG_GREEN:
				e = O2ByteFromFloat(s.g);
				break;
			case VG_BLUE:
				e = O2ByteFromFloat(s.b);
				break;
			default:
				RI_ASSERT(sourceChannel == VG_ALPHA);
				e = O2ByteFromFloat(s.a);
				break;
			}

			RIuint32 l = ((const RIuint32*)lookupTable)[e];
			VGColor d=VGColorRGBA(0,0,0,0,lutFormat);
			d.r = O2Float32FromByte((l>>24));
			d.g = O2Float32FromByte((l>>16));
			d.b = O2Float32FromByte((l>> 8));
			d.a = O2Float32FromByte((l    ));

			O2SurfaceWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

@end
