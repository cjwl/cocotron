#import <CoreGraphics/CGLPixelSurface.h>
#import <CoreGraphics/CGWindow.h>
#import <Onyx2D/O2Image.h>
#import <AppKit/O2Surface_DIBSection.h>

@implementation CGLPixelSurface

-initWithFrame:(O2Rect)frame {
   _x=frame.origin.x;
   _y=frame.origin.y;
   _width=frame.size.width;
   _height=frame.size.height;
   _isOpaque=YES;
   _validBuffers=NO;
   _numberOfBuffers=0;
   _bufferObjects=NULL;
   _readPixels=NULL;
   _staticPixels=NULL;
   return self;
}

-(void)dealloc {
   [_surface release];
   [super dealloc];
}

-(CGWindow *)window {
   return _window;
}

-(BOOL)isOpaque {
   return _isOpaque;
}

-(O2Rect)frame {
   return O2RectMake(_x,_y,_width,_height);
}

-(void)setWindow:(CGWindow *)window {
   _window=window;
}

-(void)setFrame:(O2Rect)frame {
   _x=frame.origin.x;
   _y=frame.origin.y;
   _width=frame.size.width;
   _height=frame.size.height;
   _validBuffers=NO;
}

-(void)setFrameSize:(O2Size)value {
   NSRect rect=[self frame];
   
   rect.size=value;
   
   [self setFrame:rect];
}

-(void)setOpaque:(BOOL)value {
   _isOpaque=value;
}

-(void)validateBuffersIfNeeded {
   int i;

   if(_validBuffers)
    return;

// 0's are silently ignored per spec.
   CGLDeleteBuffers(_numberOfBuffers,_bufferObjects);
      
   if(_bufferObjects!=NULL)
    free(_bufferObjects);
    
   if(_readPixels!=NULL)
    free(_readPixels);
    
   if(_staticPixels!=NULL)
    free(_staticPixels);
   
   [_surface release];
   
   _validBuffers=YES;
   _numberOfBuffers=1;
   _rowsPerBuffer=(_height+(_numberOfBuffers-1))/_numberOfBuffers;
   _bufferObjects=malloc(_numberOfBuffers*sizeof(GLuint));
   _readPixels=malloc(_numberOfBuffers*sizeof(void *));
   _staticPixels=malloc(_numberOfBuffers*sizeof(void *));
   _surface=[[O2Surface_DIBSection alloc] initWithWidth:_width height:-_height compatibleWithDeviceContext:nil];
   
   for(i=0;i<_numberOfBuffers;i++){
    _bufferObjects[i]=0;
    _readPixels[i]=NULL;
    _staticPixels[i]=NULL;
}

  // CGLGenBuffers(_numberOfBuffers,_bufferObjects);

   int row=0,bytesPerRow=_width*4;
   
   for(i=0;i<_numberOfBuffers;i++){    
    _staticPixels[i]=((uint8_t *)[_surface pixelBytes])+row*bytesPerRow;

    if(_bufferObjects[i]==0){
     _readPixels[i]=_staticPixels[i];
    }
    else {
     _readPixels[i]=NULL;
     CGLBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, _bufferObjects[i]);
     CGLBufferData(GL_PIXEL_PACK_BUFFER_ARB, _width*_rowsPerBuffer*4, NULL,GL_STREAM_READ);
     CGLBindBuffer(GL_PIXEL_PACK_BUFFER_ARB, 0);
    }
    
    row+=_rowsPerBuffer;
   }
}


static inline uint32_t premultiplyPixel(uint32_t value){
   unsigned int a=(value>>24)&0xFF;
   unsigned int r=(value>>16)&0xFF;
   unsigned int g=(value>>8)&0xFF;
   unsigned int b=(value>>0)&0xFF;
   
   value&=0xFF000000;
   value|=O2Image_8u_mul_8u_div_255(r,a)<<16;
   value|=O2Image_8u_mul_8u_div_255(g,a)<<8;
   value|=O2Image_8u_mul_8u_div_255(b,a);
          
   return value;
}

-(O2Surface *)validSurface {   
   return _surface;
}

-(void)flushBuffer {
   [self validateBuffersIfNeeded];

   int bytesPerRow=_width*4;
   int i,row=0;
   
   glReadBuffer(GL_BACK);

   if(glGetError()!=GL_NO_ERROR)
    return;

   for(i=0;i<_numberOfBuffers;i++){
    int rowCount=MIN(_height-row,_rowsPerBuffer);

    if(_bufferObjects[i]==0)
     glReadPixels(0,row,_width,rowCount,GL_BGRA,GL_UNSIGNED_BYTE,_readPixels[i]);
    else {
     CGLBindBuffer(GL_PIXEL_PACK_BUFFER,_bufferObjects[i]);

     glReadPixels(0,row,_width,rowCount,GL_BGRA,GL_UNSIGNED_BYTE, 0);
    }
       
    row+=rowCount;
   }
   CGLBindBuffer(GL_PIXEL_PACK_BUFFER,0);          

   row=0;
   
   for(i=0;i<_numberOfBuffers;i++){
    int            r,rowCount=MIN(_height-row,_rowsPerBuffer);
    unsigned char *inputRow;
    unsigned char *outputRow=_staticPixels[i];
    
    if(_bufferObjects[i]==0)
     inputRow=_readPixels[i];
    else {
     CGLBindBuffer(GL_PIXEL_PACK_BUFFER,_bufferObjects[i]);          
     inputRow=(GLubyte*)CGLMapBuffer(GL_PIXEL_PACK_BUFFER,GL_READ_ONLY);
    }
    
    if(_isOpaque){
     // Opaque contexts ignore alpha so we set it to 0xFF to get proper results when blending
     // E.g. application clears context with color and zero alpha, this will display as the color on OS X
     // reading back will give us 0 alpha, premultiplying will give us black, which would be wrong.
     
     for(r=0;r<rowCount;r++,inputRow+=bytesPerRow,outputRow+=bytesPerRow){
      int c;
     
      for(c=0;c<bytesPerRow;c+=4){
       uint32_t pixel=*((uint32_t *)(inputRow+c));
       
       pixel|=0xFF000000;
       
       *((uint32_t *)(outputRow+c))=pixel;
       
      }
     }
    }
    else {
     for(r=0;r<rowCount;r++,inputRow+=bytesPerRow,outputRow+=bytesPerRow){
      int c;
     
      for(c=0;c<bytesPerRow;c+=4){
       uint32_t pixel=*((uint32_t *)(inputRow+c));
       
       pixel=premultiplyPixel(pixel);
       
       *((uint32_t *)(outputRow+c))=pixel;
       
      }
     }
    }
    
    if(_bufferObjects[i]!=0){
     CGLUnmapBuffer(GL_PIXEL_PACK_BUFFER);
    }
    
    row+=rowCount;
   }
   CGLBindBuffer(GL_PIXEL_PACK_BUFFER,0);          
   
   [_window flushOverlay:self];
   
#if 0    
   if(_usePixelBuffer){
    CGLBindBuffer(GL_PIXEL_PACK_BUFFER,0);
    if(inputBytes!=NULL){
     CGLUnmapBuffer(GL_PIXEL_PACK_BUFFER);
}
   }
#endif
}

-(NSString *)description {
   return [NSString stringWithFormat:@"<%@ %p:frame={ %d %d %d %d } surface=%@",isa,self,_x,_y,_width,_height,_surface];
}

@end
