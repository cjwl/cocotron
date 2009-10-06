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

#import "KGSurface.h"
#import "O2ColorSpace.h"
#import "KGDataProvider.h"

@implementation KGSurface

#define RI_MAX_GAUSSIAN_STD_DEVIATION	128.0f

/*-------------------------------------------------------------------*//*!
* \brief	Converts from the current internal format to another.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

// Can't use 'gamma' ?
static CGFloat dogamma(CGFloat c)
{    
	if( c <= 0.00304f )
		c *= 12.92f;
	else
		c = 1.0556f * (CGFloat)pow(c, 1.0f/2.4f) - 0.0556f;
	return c;
}

static CGFloat invgamma(CGFloat c)
{
	if( c <= 0.03928f )
		c /= 12.92f;
	else
		c = (CGFloat)pow((c + 0.0556f)/1.0556f, 2.4f);
	return c;
}

static CGFloat lRGBtoL(CGFloat r, CGFloat g, CGFloat b)
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
		CGFloat ooa = (result.a != 0.0f) ? 1.0f / result.a : (CGFloat)0.0f;
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

static void colorToBytesLittle(CGFloat color,uint8_t *scanline){
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

static void KGSurfaceWrite_RGBAffff_to_RGBAffffLittle(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*16;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

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

static void colorToBytesBig(CGFloat color,uint8_t *scanline){
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

static void KGSurfaceWrite_RGBAffff_to_RGBAffffBig(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*16;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

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

static unsigned char colorToNibble(CGFloat c){
	return RI_INT_MIN(RI_INT_MAX(RI_FLOOR_TO_INT(c * (CGFloat)0xF + 0.5f), 0), 0xF);
}

static void KGSurfaceWrite_RGBAffff_to_GA88(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=CGByteFromFloat(rgba.r);
    *scanline++=CGByteFromFloat(rgba.a);
   }
}

static void KGSurfaceWrite_RGBAffff_to_G8(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=CGByteFromFloat(lRGBtoL(rgba.r,rgba.g,rgba.b));
   }
}


static void KGSurfaceWrite_RGBAffff_to_RGBA8888(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=CGByteFromFloat(rgba.r);
    *scanline++=CGByteFromFloat(rgba.g);
    *scanline++=CGByteFromFloat(rgba.b);
    *scanline++=CGByteFromFloat(rgba.a);
   }
}

static void KGSurfaceWrite_RGBA8888_to_RGBA8888(KGSurface *self,int x,int y,KGRGBA8888 *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888 rgba=*span++;

    *scanline++=rgba.r;
    *scanline++=rgba.g;
    *scanline++=rgba.b;
    *scanline++=rgba.a;
   }
}

static void KGSurfaceWrite_RGBAffff_to_ABGR8888(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=CGByteFromFloat(rgba.a);
    *scanline++=CGByteFromFloat(rgba.b);
    *scanline++=CGByteFromFloat(rgba.g);
    *scanline++=CGByteFromFloat(rgba.r);
   }
}

static void KGSurfaceWrite_RGBA8888_to_ABGR8888(KGSurface *self,int x,int y,KGRGBA8888 *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888 rgba=*span++;

    *scanline++=rgba.a;
    *scanline++=rgba.b;
    *scanline++=rgba.g;
    *scanline++=rgba.r;
   }
}

static void KGSurfaceWrite_RGBA8888_to_BGRA8888(KGSurface *self,int x,int y,KGRGBA8888 *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBA8888 rgba=*span++;

    *scanline++=rgba.b;
    *scanline++=rgba.g;
    *scanline++=rgba.r;
    *scanline++=rgba.a;
   }
}

static void KGSurfaceWrite_RGBAffff_to_RGBA4444(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=colorToNibble(rgba.r)<<4|colorToNibble(rgba.g);
    *scanline++=colorToNibble(rgba.b)<<4|colorToNibble(rgba.a);
   }
}

static void KGSurfaceWrite_RGBAffff_to_BARG4444(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*2;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=colorToNibble(rgba.b)<<4|colorToNibble(rgba.a);
    *scanline++=colorToNibble(rgba.r)<<4|colorToNibble(rgba.g);
   }
}

static void KGSurfaceWrite_RGBAffff_to_RGBA2222(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=colorToNibble(rgba.a)<<6|colorToNibble(rgba.a)<<6|colorToNibble(rgba.a)<<2|colorToNibble(rgba.b);
   }
}

static void KGSurfaceWrite_RGBAffff_to_CMYK8888(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   uint8_t* scanline = self->_pixelBytes + y * self->_bytesPerRow;
   int i;
   
   scanline+=x*4;
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    *scanline++=CGByteFromFloat(1.0-rgba.r);
    *scanline++=CGByteFromFloat(1.0-rgba.g);
    *scanline++=CGByteFromFloat(1.0-rgba.b);
    *scanline++=CGByteFromFloat(0);
   }
}

static void KGSurfaceWrite_RGBAffff_to_RGBA8888_to_ANY(KGSurface *self,int x,int y,KGRGBAffff *span,int length){
   KGRGBA8888 span8888[length];
   int i;
   
   for(i=0;i<length;i++){
    KGRGBAffff rgba=*span++;

    span8888[i].r=CGByteFromFloat(rgba.r);
    span8888[i].g=CGByteFromFloat(rgba.g);
    span8888[i].b=CGByteFromFloat(rgba.b);
    span8888[i].a=CGByteFromFloat(rgba.a);
   }
   self->_writeRGBA8888(self,x,y,span8888,length);
}

static BOOL initFunctionsForParameters(KGSurface *self,size_t bitsPerComponent,size_t bitsPerPixel,O2ColorSpaceRef colorSpace,CGBitmapInfo bitmapInfo){
   self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_RGBA8888_to_ANY;// default
   
   switch(bitsPerComponent){
   
    case 32:
     switch(bitsPerPixel){
      case 32:
       break;
      case 128:
       switch(bitmapInfo&kCGBitmapByteOrderMask){
        case kCGBitmapByteOrderDefault:
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little:
         self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_RGBAffffLittle;
         return YES;
         
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big:
         self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_RGBAffffBig;
         return YES;
       }
     }
     break;
     
    case  8:
     switch(bitsPerPixel){
     
      case 8:
       self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_G8;
       return YES;

      case 16:
       self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_GA88;
       return YES;

      case 24:
       break;
       
      case 32:
       if([colorSpace type]==O2ColorSpaceDeviceRGB){

        switch(bitmapInfo&kCGBitmapAlphaInfoMask){
         case kCGImageAlphaNone:
          break;
          
         case kCGImageAlphaLast:
         case kCGImageAlphaPremultipliedLast:
          switch(bitmapInfo&kCGBitmapByteOrderMask){
           case kCGBitmapByteOrderDefault:
           case kCGBitmapByteOrder16Little:
           case kCGBitmapByteOrder32Little:
            self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_ABGR8888;
            self->_writeRGBA8888=KGSurfaceWrite_RGBA8888_to_ABGR8888;
            return YES;

           case kCGBitmapByteOrder16Big:
           case kCGBitmapByteOrder32Big:
            self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_RGBA8888;
            self->_writeRGBA8888=KGSurfaceWrite_RGBA8888_to_RGBA8888;
            return YES;
          }

          break;
          
         case kCGImageAlphaPremultipliedFirst:
          switch(bitmapInfo&kCGBitmapByteOrderMask){
           case kCGBitmapByteOrderDefault:
           case kCGBitmapByteOrder16Little:
           case kCGBitmapByteOrder32Little:
            self->_writeRGBA8888=KGSurfaceWrite_RGBA8888_to_BGRA8888;
            return YES;
          }
          break;
                    
         case kCGImageAlphaFirst:
          break;
          
         case kCGImageAlphaNoneSkipLast:
          break;
          
         case kCGImageAlphaNoneSkipFirst:
          break;
        }
       }
       else if([colorSpace type]==O2ColorSpaceDeviceCMYK){
        switch(bitmapInfo&kCGBitmapByteOrderMask){
         case kCGBitmapByteOrderDefault:
         case kCGBitmapByteOrder16Little:
         case kCGBitmapByteOrder32Little:
          break;
         
         case kCGBitmapByteOrder16Big:
         case kCGBitmapByteOrder32Big:
          self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_CMYK8888;
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
       switch(bitmapInfo&kCGBitmapByteOrderMask){
        case kCGBitmapByteOrderDefault:
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little:
         self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_BARG4444;
         return YES;
         
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big:
         self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_RGBA4444;
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
       self->_writeRGBAffff=KGSurfaceWrite_RGBAffff_to_RGBA2222;
       return YES;
     }
     break;

    case  1:
     switch(bitsPerPixel){
      case 1:
       //  self->_writeRGBAffff=KGSurfaceWriteSpan_lRGBAffff_PRE_01;
       return YES;
       
      case 3:
       break;
     }
     break;
   }
   return NO;   
}

-initWithBytes:(void *)bytes width:(size_t)width height:(size_t)height bitsPerComponent:(size_t)bitsPerComponent bytesPerRow:(size_t)bytesPerRow colorSpace:(O2ColorSpaceRef)colorSpace bitmapInfo:(CGBitmapInfo)bitmapInfo {
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
   
   if([super initWithWidth:width height:height bitsPerComponent:bitsPerComponent bitsPerPixel:bitsPerPixel bytesPerRow:bytesPerRow colorSpace:colorSpace bitmapInfo:bitmapInfo provider:provider decode:NULL interpolate:YES renderingIntent:kCGRenderingIntentDefault]==nil)
    return nil;
   
   if([provider isDirectAccess])
    _pixelBytes=(void *)[provider bytes];

   if(!initFunctionsForParameters(self,bitsPerComponent,_bitsPerPixel,colorSpace,bitmapInfo))
    NSLog(@"KGSurface -init error, return");

   size_t checkBPP;
   m_desc=KGImageParametersToPixelLayout(VG_lRGBA_8888_PRE,&checkBPP,&(_colorFormat));
   RI_ASSERT(checkBPP==bitsPerPixel);

   _clampExternalPixels=NO; // only set to yes if premultiplied
   m_mipmapsValid=NO;

   _mipmapsCount=0;
   _mipmapsCapacity=2;
   _mipmaps=(KGSurface **)NSZoneMalloc(NULL,_mipmapsCapacity*sizeof(KGSurface *));
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

-(NSData *)pixelData {
   return [_provider data];
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

void KGSurfaceClear(KGSurface *self,VGColor clearColor, int x, int y, int w, int h){
	RI_ASSERT(self->_pixelBytes);

	//intersect clear region with image bounds
	KGIntRect r=KGIntRectInit(0,0,self->_width,self->_height);
	r=KGIntRectIntersect(r,KGIntRectInit(x,y,w,h));
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
			KGSurfaceWritePixel(self,i, j, col);
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

VGColor KGSurfaceReadPixel(O2Image *self,int x, int y) {
	RI_ASSERT(self->_pixelBytes);
	RI_ASSERT(x >= 0 && x < self->_width);
	RI_ASSERT(y >= 0 && y < self->_height);
 
    KGRGBAffff span,*direct=KGImageReadSpan_lRGBAffff_PRE(self,x,y,&span,1);
   
    if(direct!=NULL)
     return VGColorFromRGBAffff(*direct,VGColor_lRGBA_PRE);
    else
     return VGColorFromRGBAffff(span,VGColor_lRGBA_PRE);
}


/*-------------------------------------------------------------------*//*!
* \brief	Blits a source region to destination. Source and destination
*			can overlap.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

static CGFloat ditherChannel(CGFloat c, int bits, CGFloat m)
{
	CGFloat fc = c * (CGFloat)((1<<bits)-1);
	CGFloat ic = (CGFloat)floor(fc);
	if(fc - ic > m) ic += 1.0f;
	return RI_MIN(ic / (CGFloat)((1<<bits)-1), 1.0f);
}

void KGSurfaceBlit(KGSurface *self,KGSurface * src, int sx, int sy, int dx, int dy, int w, int h, BOOL dither) {
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
			VGColor c = KGSurfaceReadPixel(src,srcsx + i, srcsy + j);
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
				CGFloat m = matrix[y*4+x] / 16.0f;

				if(rbits) col.r = ditherChannel(col.r, rbits, m);
				if(gbits) col.g = ditherChannel(col.g, gbits, m);
				if(bbits) col.b = ditherChannel(col.b, bbits, m);
				if(abits) col.a = ditherChannel(col.a, abits, m);
			}

			KGSurfaceWritePixel(self,dstsx + i, dstsy + j, col);
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

void KGSurfaceMask(KGSurface *self,KGSurface* src, VGMaskOperation operation, int x, int y, int w, int h) {
	RI_ASSERT(self->_pixelBytes);	//destination exists
	RI_ASSERT(w > 0 && h > 0);

	self->m_mipmapsValid = NO;
	if(operation == VG_CLEAR_MASK)
	{
		KGSurfaceClear(self,VGColorRGBA(0,0,0,0,VGColor_lRGBA), x, y, w, h);
		return;
	}
	if(operation == VG_FILL_MASK)
	{
		KGSurfaceClear(self,VGColorRGBA(1,1,1,1,VGColor_lRGBA), x, y, w, h);
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
			CGFloat aprev,amask ;
			CGFloat anew = 0.0f;
            
            KGImageReadSpan_Af_MASK(self,dstsx + i,dstsy + j,&aprev,1);
            KGImageReadSpan_Af_MASK(src,srcsx + i,srcsy + j,&amask,1);
            
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
			KGSurfaceWriteMaskPixel(self,dstsx + i, dstsy + j, anew);
		}
	}
}

void KGSurfaceWriteSpan_lRGBA8888_PRE(KGSurface *self,int x,int y,KGRGBA8888 *span,int length) {   
   if(length==0)
    return;

  // KGRGBA8888ConvertSpan(span,length,VGColor_lRGBA_PRE,self->_colorFormat);
   
   self->_writeRGBA8888(self,x,y,span,length);
   
   self->m_mipmapsValid = NO;
}

void KGSurfaceWriteSpan_lRGBAffff_PRE(KGSurface *self,int x,int y,KGRGBAffff *span,int length) {   
   if(length==0)
    return;
    
   KGRGBAffffConvertSpan(span,length,VGColor_lRGBA_PRE,self->_colorFormat);
   
   self->_writeRGBAffff(self,x,y,span,length);
   
   self->m_mipmapsValid = NO;
}

void KGSurfaceWritePixel(KGSurface *self,int x, int y, VGColor c) {
	RI_ASSERT(self->_pixelBytes);
	RI_ASSERT(x >= 0 && x < self->_width);
	RI_ASSERT(y >= 0 && y < self->_height);
	RI_ASSERT(c.m_format == self->_colorFormat);
    KGRGBAffff span=KGRGBAffffFromColor(VGColorConvert(c,VGColor_lRGBA_PRE));
    
    KGSurfaceWriteSpan_lRGBAffff_PRE(self,x,y,&span,1);
	self->m_mipmapsValid = NO;
}



/*-------------------------------------------------------------------*//*!
* \brief	Writes a filtered color to destination surface
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGSurfaceWriteFilteredPixel(KGSurface *self,int i, int j, VGColor color, VGbitfield channelMask) {
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
	VGColor d = KGSurfaceReadPixel(self,i,j);
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
	KGSurfaceWritePixel(self,i,j,d);
}

/*-------------------------------------------------------------------*//*!
* \brief	Writes the alpha mask to pixel (x,y) of a VG_A_8 image.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGSurfaceWriteMaskPixel(KGSurface *self,int x, int y, CGFloat m)	//can write only to VG_A_8
{
	RI_ASSERT(self->_pixelBytes);
	RI_ASSERT(x >= 0 && x < self->_width);
	RI_ASSERT(y >= 0 && y < self->_height);
	RI_ASSERT(self->m_desc.alphaBits == 8 && self->m_desc.redBits == 0 && self->m_desc.greenBits == 0 && self->m_desc.blueBits == 0 && self->m_desc.luminanceBits == 0 && self->_bitsPerPixel == 8);

	uint8_t* s = ((uint8_t*)(self->_pixelBytes + y * self->_bytesPerRow)) + x;
	*s = (uint8_t)CGByteFromFloat(m);
	self->m_mipmapsValid = NO;
}


/*-------------------------------------------------------------------*//*!
* \brief	Applies color matrix filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGSurfaceColorMatrix(KGSurface *self,KGSurface * src, const CGFloat* matrix, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask) {
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
			VGColor s = KGSurfaceReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);

			VGColor d=VGColorRGBA(0,0,0,0,procFormat);
			d.r = matrix[0+4*0] * s.r + matrix[0+4*1] * s.g + matrix[0+4*2] * s.b + matrix[0+4*3] * s.a + matrix[0+4*4];
			d.g = matrix[1+4*0] * s.r + matrix[1+4*1] * s.g + matrix[1+4*2] * s.b + matrix[1+4*3] * s.a + matrix[1+4*4];
			d.b = matrix[2+4*0] * s.r + matrix[2+4*1] * s.g + matrix[2+4*2] * s.b + matrix[2+4*3] * s.a + matrix[2+4*4];
			d.a = matrix[3+4*0] * s.r + matrix[3+4*1] * s.g + matrix[3+4*2] * s.b + matrix[3+4*3] * s.a + matrix[3+4*4];

			KGSurfaceWriteFilteredPixel(self,i, j, d, channelMask);
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

void KGSurfaceConvolve(KGSurface *self,KGSurface * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernel, CGFloat scale, CGFloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask) {
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
			VGColor s = KGSurfaceReadPixel(src,i, j);
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

					sum=VGColorAdd(sum, VGColorMultiplyByFloat(s,(CGFloat)kernel[kx*kernelHeight+ky]));
				}
			}

			sum=VGColorMultiplyByFloat(sum ,scale);
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			KGSurfaceWriteFilteredPixel(self,i, j, sum, channelMask);
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

void KGSurfaceSeparableConvolve(KGSurface *self,KGSurface * src, int kernelWidth, int kernelHeight, int shiftX, int shiftY, const RIint16* kernelX, const RIint16* kernelY, CGFloat scale, CGFloat bias, VGTilingMode tilingMode, VGColor edgeFillColor, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask) {
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
			VGColor s = KGSurfaceReadPixel(src,i, j);
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

				sum=VGColorAdd(sum , VGColorMultiplyByFloat(s,(CGFloat)kernelX[kx])) ;
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
			sum=VGColorAdd(sum, VGColorMultiplyByFloat(edge, (CGFloat)kernelX[ki]));
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

				sum=VGColorAdd(sum, VGColorMultiplyByFloat(s, (CGFloat)kernelY[ky]));
			}

			sum=VGColorMultiplyByFloat(sum,scale);
			sum.r += bias;
			sum.g += bias;
			sum.b += bias;
			sum.a += bias;

			KGSurfaceWriteFilteredPixel(self,i, j, sum, channelMask);
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

static KGRGBAffff gaussianReadPixel(int x, int y, int w, int h,KGRGBAffff *image)
{
	if(x < 0 || x >= w || y < 0 || y >= h) {	//apply tiling mode
	 return KGRGBAffffInit(0,0,0,0);
	}
	else
	{
		RI_ASSERT(x >= 0 && x < w && y >= 0 && y < h);
		return image[y*w+x];
	}
}

typedef struct KGGaussianKernel {
 int      refCount;
 int      xSize;
 int      xShift;
 CGFloat  xScale;
 CGFloat *xValues;

 int      ySize;
 int      yShift;
 CGFloat  yScale;
 CGFloat *yValues;
} KGGaussianKernel;

KGGaussianKernel *KGCreateGaussianKernelWithDeviation(CGFloat stdDeviation){
   KGGaussianKernel *kernel=NSZoneMalloc(NULL,sizeof(KGGaussianKernel));
   
   kernel->refCount=1;
   
   CGFloat stdDeviationX=stdDeviation;
   CGFloat stdDeviationY=stdDeviation;
   
	RI_ASSERT(stdDeviationX > 0.0f && stdDeviationY > 0.0f);
	RI_ASSERT(stdDeviationX <= RI_MAX_GAUSSIAN_STD_DEVIATION && stdDeviationY <= RI_MAX_GAUSSIAN_STD_DEVIATION);

	//find a size for the kernel
	CGFloat totalWeightX = stdDeviationX*(CGFloat)sqrt(2.0f*M_PI);
	CGFloat totalWeightY = stdDeviationY*(CGFloat)sqrt(2.0f*M_PI);
	const CGFloat tolerance = 0.99f;	//use a kernel that covers 99% of the total Gaussian support

	CGFloat expScaleX = -1.0f / (2.0f*stdDeviationX*stdDeviationX);
	CGFloat expScaleY = -1.0f / (2.0f*stdDeviationY*stdDeviationY);

	int kernelWidth = 0;
	CGFloat e = 0.0f;
	CGFloat sumX = 1.0f;	//the weight of the middle entry counted already
	do{
		kernelWidth++;
		e = (CGFloat)exp((CGFloat)(kernelWidth * kernelWidth) * expScaleX);
		sumX += e*2.0f;	//count left&right lobes
	}while(sumX < tolerance*totalWeightX);

	int kernelHeight = 0;
	e = 0.0f;
	CGFloat sumY = 1.0f;	//the weight of the middle entry counted already
	do{
		kernelHeight++;
		e = (CGFloat)exp((CGFloat)(kernelHeight * kernelHeight) * expScaleY);
		sumY += e*2.0f;	//count left&right lobes
	}while(sumY < tolerance*totalWeightY);

	//make a separable kernel
    kernel->xSize=kernelWidth*2+1;
    kernel->xValues=NSZoneMalloc(NULL,sizeof(CGFloat)*kernel->xSize);
    kernel->xShift = kernelWidth;
    kernel->xScale = 0.0f;
    int i;
	for(i=0;i<kernel->xSize;i++){
		int x = i-kernel->xShift;
		kernel->xValues[i] = (CGFloat)exp((CGFloat)x*(CGFloat)x * expScaleX);
		kernel->xScale += kernel->xValues[i];
	}
	kernel->xScale = 1.0f / kernel->xScale;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance

    kernel->ySize=kernelHeight*2+1;
    kernel->yValues=NSZoneMalloc(NULL,sizeof(CGFloat)*kernel->ySize);
    kernel->yShift = kernelHeight;
    kernel->yScale = 0.0f;
	for(i=0;i<kernel->ySize;i++)
	{
		int y = i-kernel->yShift;
		kernel->yValues[i] = (CGFloat)exp((CGFloat)y*(CGFloat)y * expScaleY);
		kernel->yScale += kernel->yValues[i];
	}
	kernel->yScale = 1.0f / kernel->yScale;	//NOTE: using the mathematical definition of the scaling term doesn't work since we cut the filter support early for performance
    
    return kernel;
}

KGGaussianKernelRef KGGaussianKernelRetain(KGGaussianKernelRef kernel) {
   if(kernel!=NULL)
    kernel->refCount++;
    
   return kernel;
}

void KGGaussianKernelRelease(KGGaussianKernelRef kernel) {
   if(kernel!=NULL){
    kernel->refCount--;
    if(kernel->refCount<=0){
     NSZoneFree(NULL,kernel->xValues);
     NSZoneFree(NULL,kernel->yValues);
     NSZoneFree(NULL,kernel);
    }
   }
}

void KGSurfaceGaussianBlur(KGSurface *self,O2Image * src, KGGaussianKernel *kernel){
	RI_ASSERT(src->_pixelBytes);	//source exists
	RI_ASSERT(self->_pixelBytes);	//destination exists

	//the area to be written is an intersection of source and destination image areas.
	//lower-left corners of the images are aligned.
	int w = RI_INT_MIN(self->_width, src->_width);
	int h = RI_INT_MIN(self->_height, src->_height);
	RI_ASSERT(w > 0 && h > 0);
    
	KGRGBAffff *tmp=NSZoneMalloc(NULL,src->_width*src->_height*sizeof(KGRGBAffff));

	//copy source region to tmp and do conversion
    int i,j;
	for(j=0;j<src->_height;j++){
     KGRGBAffff *tmpRow=tmp+j*src->_width;
     int         i,width=src->_width;
     KGRGBAffff *direct=KGImageReadSpan_lRGBAffff_PRE(src,0,j,tmpRow,width);
     
     if(direct!=NULL){
      for(i=0;i<width;i++)
       tmpRow[i]=direct[i];
     }
  	}

	KGRGBAffff *tmp2=NSZoneMalloc(NULL,w*src->_height*sizeof(KGRGBAffff));

	//horizontal pass
	for(j=0;j<src->_height;j++){
		for(i=0;i<w;i++){
			KGRGBAffff sum=KGRGBAffffInit(0,0,0,0);
            int ki;
			for(ki=0;ki<kernel->xSize;ki++){
				int x = i+ki-kernel->xShift;
				sum=KGRGBAffffAdd(sum, KGRGBAffffMultiplyByFloat(gaussianReadPixel(x, j, src->_width, src->_height, tmp),kernel->xValues[ki]));
			}
			tmp2[j*w+i] = KGRGBAffffMultiplyByFloat(sum, kernel->xScale);
		}
	}
	//vertical pass
	for(j=0;j<h;j++){
		for(i=0;i<w;i++){
			KGRGBAffff sum=KGRGBAffffInit(0,0,0,0);
            int kj;
			for(kj=0;kj<kernel->ySize;kj++){
				int y = j+kj-kernel->yShift;
				sum=KGRGBAffffAdd(sum,  KGRGBAffffMultiplyByFloat(gaussianReadPixel(i, y, w, src->_height, tmp2), kernel->yValues[kj]));
			}
            sum=KGRGBAffffMultiplyByFloat(sum, kernel->yScale);
			KGSurfaceWriteSpan_lRGBAffff_PRE(self,i, j, &sum,1);
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

void KGSurfaceLookup(KGSurface *self,KGSurface * src, const uint8_t * redLUT, const uint8_t * greenLUT, const uint8_t * blueLUT, const uint8_t * alphaLUT, BOOL outputLinear, BOOL outputPremultiplied, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask){
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
			VGColor s = KGSurfaceReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);

			VGColor d=VGColorRGBA(0,0,0,0,lutFormat);
			d.r = CGFloatFromByte(  redLUT[CGByteFromFloat(s.r)]);
			d.g = CGFloatFromByte(greenLUT[CGByteFromFloat(s.g)]);
			d.b = CGFloatFromByte( blueLUT[CGByteFromFloat(s.b)]);
			d.a = CGFloatFromByte(alphaLUT[CGByteFromFloat(s.a)]);

			KGSurfaceWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

/*-------------------------------------------------------------------*//*!
* \brief	Applies single channel lookup table filter.
* \param	
* \return	
* \note		
*//*-------------------------------------------------------------------*/

void KGSurfaceLookupSingle(KGSurface *self,KGSurface * src, const RIuint32 * lookupTable, KGSurfaceChannel sourceChannel, BOOL outputLinear, BOOL outputPremultiplied, BOOL filterFormatLinear, BOOL filterFormatPremultiplied, VGbitfield channelMask){
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
			VGColor s = KGSurfaceReadPixel(src,i,j);	//convert to RGBA [0,1]
			s=VGColorConvert(s,procFormat);
			int e;
			switch(sourceChannel)
			{
			case VG_RED:
				e = CGByteFromFloat(s.r);
				break;
			case VG_GREEN:
				e = CGByteFromFloat(s.g);
				break;
			case VG_BLUE:
				e = CGByteFromFloat(s.b);
				break;
			default:
				RI_ASSERT(sourceChannel == VG_ALPHA);
				e = CGByteFromFloat(s.a);
				break;
			}

			RIuint32 l = ((const RIuint32*)lookupTable)[e];
			VGColor d=VGColorRGBA(0,0,0,0,lutFormat);
			d.r = CGFloatFromByte((l>>24));
			d.g = CGFloatFromByte((l>>16));
			d.b = CGFloatFromByte((l>> 8));
			d.a = CGFloatFromByte((l    ));

			KGSurfaceWriteFilteredPixel(self,i, j, d, channelMask);
		}
	}
}

@end
