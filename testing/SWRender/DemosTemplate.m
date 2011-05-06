#import "DemoContext.h"

@interface DEMONAME(Context) : DemoContext {
   int             _pixelsWide;
   int             _pixelsHigh;
   int             _bitsPerComponent;
   int             _bitsPerPixel;
   int             _bytesPerRow;
   CGColorSpaceRef _colorSpace;
   CGBitmapInfo    _bitmapInfo;
   void           *_data;
   CGContextRef    _context;

    CGColorRef _fillColor;
    CGColorRef _strokeColor;
    CGPathDrawingMode _pathDrawingMode;
    BOOL        _shouldAntialias;
    CGInterpolationQuality _interpolationQuality;
    float       _scalex;
    float       _scaley;
    float       _rotation;
    CGBlendMode _blendMode;
    CGColorRef  _shadowColor;
    float       _shadowBlur;
    CGSize      _shadowOffset;
    float       _lineWidth;
    CGLineCap   _lineCap;
    CGLineJoin  _lineJoin;
    float        _miterLimit;
    float        _dashPhase;
    unsigned     _dashLengthsCount;
    float       *_dashLengths;
    float        _flatness;
    
    CGFontRef       _font;
    CGImageRef _resamplingImage;
    CGPDFDocumentRef _pdfDocument;
}
@end

@implementation DEMONAME(Context)

static CGColorRef createCGColor(float r,float g,float b,float a){
   float rgba[4]={r,g,b,a};
   
   CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
   CGColorRef result=CGColorCreate(colorSpace,rgba);
   
   CGColorSpaceRelease(colorSpace);
   
   return result;
}

-init {
   _pixelsWide=400;
   _pixelsHigh=400;
   _bitsPerComponent=8;
   _bitsPerPixel=32;
   _bytesPerRow=(_pixelsWide*_bitsPerPixel)/8;
   _colorSpace=CGColorSpaceCreateDeviceRGB();
   _bitmapInfo=kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little;
   _data=NSZoneMalloc(NULL,_bytesPerRow*_pixelsHigh);
   _context=CGBitmapContextCreate(_data,_pixelsWide,_pixelsHigh,_bitsPerComponent,_bytesPerRow,_colorSpace,_bitmapInfo);
   
   NSLog(@"%s %d",__FILE__,__LINE__);
   _fillColor=createCGColor(0,0,1,1);
   _strokeColor=createCGColor(1,0,0,1);
   _pathDrawingMode=kCGPathStroke;
   _shouldAntialias=YES;
   _interpolationQuality=kCGInterpolationLow;
   _scalex=1;
   _scaley=1;
   _rotation=0;
   _blendMode=kCGBlendModeNormal;
   _shadowColor=createCGColor(0,0,0,1);
   _shadowBlur=1;
   _shadowOffset=CGSizeMake(10,10);
   _lineWidth=1;
   _lineCap=kCGLineCapButt;
   _lineJoin=kCGLineJoinMiter;
   _miterLimit=1;
   _dashPhase=100;
   _dashLengthsCount=0;
   _dashLengths=NSZoneMalloc([self zone],sizeof(float)*4);
   NSLog(@"%s %d",__FILE__,__LINE__);
   
   CGDataProviderRef provider=CGDataProviderCreateWithFilename("/Library/Fonts/Times New Roman.ttf");
   
   if(provider==NULL)
    NSLog(@"PROVIDER FAILED");
    
   if((_font=CGFontCreateWithDataProvider(provider))==NULL)
    NSLog(@"FONT FAILED");
   
   CGDataProviderRelease(provider);
   
   
   NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"pattern" ofType:@"jpg"];
 //  NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"redLZWSquare" ofType:@"tif"];
   NSData   *data=[NSData dataWithContentsOfFile:path];
   CGImageSourceRef source=CGImageSourceCreateWithData((CFDataRef)data,nil);
   _resamplingImage=CGImageSourceCreateImageAtIndex(source,0,nil);
   NSLog(@"%s %d",__FILE__,__LINE__);
   [(id)source release];
   NSMutableData *tiff=[NSMutableData data];
   CGImageDestinationRef destination=CGImageDestinationCreateWithData((CFMutableDataRef)tiff,(CFStringRef)@"public.tiff",1,NULL);
   CGImageDestinationAddImage(destination,_resamplingImage,NULL);
 #if 0
   CGImageDestinationFinalize(destination);
   NSLog(@"%s %d",__FILE__,__LINE__);
   
#ifdef ONYX2D
   [tiff writeToFile:@"/tmp/o2.tiff" atomically:YES];
#else
   [tiff writeToFile:@"/tmp/cg.tiff" atomically:YES];
#endif
   #endif

   NSLog(@"%s %d",__FILE__,__LINE__);

#if 0
   if(![_resamplingImage isKindOfClass:NSClassFromString(@"O2Image")])
    NSLog(@"IMAGE data=%@",CGDataProviderCopyData(CGImageGetDataProvider(_resamplingImage)));
#endif
   if(_resamplingImage==nil)
    NSLog(@"no image! path=%@ %d",path,[data length]);
   NSLog(@"%s %d",__FILE__,__LINE__);
   return self;
}

-(void)dealloc {
   NSZoneFree(NULL,_data);
   CGContextRelease(_context);
   NSZoneFree(NULL,self);
   [super dealloc];
}

-(size_t)pixelsWide {
   return _pixelsWide;
}

-(size_t)pixelsHigh {
   return _pixelsHigh;
}

-(size_t)bitsPerComponent {
   return _bitsPerComponent;
}

-(size_t)bitsPerPixel {
   return _bitsPerPixel;
}

-(size_t)bytesPerRow {
   return _bytesPerRow;
}

-(CGBitmapInfo)bitmapInfo {
   return _bitmapInfo;
}

-(void *)bytes {
   return _data;
}

-(void)setStrokeColor:(float)r:(float)g:(float)b:(float)a {
   CGColorRelease(_strokeColor);
   _strokeColor=createCGColor(r,g,b,a);
}

-(void)setFillColor:(float)r:(float)g:(float)b:(float)a {
   CGColorRelease(_fillColor);
   _fillColor=createCGColor(r,g,b,a);
}

-(void)setBlendMode:(CGBlendMode)mode {
   _blendMode=mode;
}

-(void)setShadowBlur:(float)value {
   _shadowBlur=value;
}

-(void)setShadowOffsetX:(float)value {
   _shadowOffset.width=value;
}
-(void)setShadowOffsetY:(float)value {
   _shadowOffset.height=value;
}

-(void)setShadowColor:(float)r:(float)g:(float)b:(float)a {
   CGColorRelease(_shadowColor);
   _shadowColor=createCGColor(r,g,b,a);
}

-(void)setPathDrawingMode:(CGPathDrawingMode)mode {
   _pathDrawingMode=mode;
}

-(void)setLineWidth:(float)width {
   _lineWidth=width;
}

-(void)setDashPhase:(float)phase {
   _dashPhase=phase;
}

-(void)setDashLength:(float)value {
   if(value<1)
    _dashLengthsCount=0;
   else {
    int i;
    
    _dashLengthsCount=4;
    for(i=0;i<4;i++)
     _dashLengths[i]=value*(i+1);
   }
}

-(void)setFlatness:(float)value {
   _flatness=value;
}

-(void)setScaleX:(float)value {
   _scalex=value;
}

-(void)setScaleY:(float)value {
   _scaley=value;
}

-(void)setRotation:(float)value {
   _rotation=value;
}

-(void)setShouldAntialias:(BOOL)value {
   _shouldAntialias=value;
}

-(void)setInterpolationQuality:(CGInterpolationQuality)value {
   _interpolationQuality=value;
}

-(void)setImageData:(NSData *)data {
   CGImageSourceRef source=CGImageSourceCreateWithData((CFDataRef)data,nil);
   _resamplingImage=CGImageSourceCreateImageAtIndex(source,0,nil);
}

-(void)setPDFData:(NSData *)data {
   if(_pdfDocument!=NULL)
    CGPDFDocumentRelease(_pdfDocument);
   
   CGDataProviderRef provider=CGDataProviderCreateWithCFData(data);
   
   _pdfDocument=CGPDFDocumentCreateWithProvider(provider);
   CGDataProviderRelease(provider);
}

-(CGAffineTransform)ctm {
   CGAffineTransform ctm=CGAffineTransformMakeTranslation(400/2,400/2);
   
   ctm=CGAffineTransformScale(ctm, _scalex,_scaley);
   
   return CGAffineTransformRotate(ctm,M_PI*_rotation/180.0);
}

-(void)establishContextState {
   CGContextSetShouldAntialias(_context,_shouldAntialias);
   CGContextSetBlendMode(_context,_blendMode);
   CGContextSetFillColorWithColor(_context,_fillColor);
   CGContextSetStrokeColorWithColor(_context,_strokeColor);
   CGContextSetLineWidth(_context,_lineWidth);
   CGContextSetLineCap(_context,_lineCap);
   CGContextSetLineJoin(_context,_lineJoin);
   CGContextSetMiterLimit(_context,_miterLimit);
   CGContextSetLineDash(_context,_dashPhase,_dashLengths,_dashLengthsCount);
   CGContextSetFlatness(_context,_flatness);
   CGContextSetInterpolationQuality(_context,_interpolationQuality);
}

static void addSliceToPath(CGMutablePathRef path,float innerRadius,float outerRadius,float startAngle,float endAngle){
   CGPoint point;

   point=CGPointApplyAffineTransform(CGPointMake(outerRadius,0),CGAffineTransformMakeRotation(startAngle));
   CGPathMoveToPoint(path,NULL,point.x,point.y);
   CGPathAddArc(path,NULL,0,0,outerRadius,startAngle,endAngle,NO);
   point=CGPointApplyAffineTransform(CGPointMake(innerRadius,0),CGAffineTransformMakeRotation(endAngle));
   CGPathAddLineToPoint(path,NULL,point.x,point.y);
   CGPathAddArc(path,NULL,0,0,innerRadius,endAngle,startAngle,YES);
   CGPathCloseSubpath(path);
}

-(void)drawClassic {
   CGAffineTransform xform=[self ctm];
   CGMutablePathRef  path=CGPathCreateMutable();

   addSliceToPath(path,50,100,M_PI*30/180.0,M_PI*330/180.0);

   addSliceToPath(path,150,300,M_PI*0/180.0,M_PI*60/180.0);
   addSliceToPath(path,150,300,M_PI*120/180.0,M_PI*180/180.0);
   addSliceToPath(path,150,300,M_PI*240/180.0,M_PI*300/180.0);


   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,xform);

   [self establishContextState];

#if 1
   CGRect frame=CGRectMake(0,0,300,50);
   CGFloat radius=50;
   
   CGContextBeginPath(_context);
 //     CGContextMoveToPoint(_context,CGRectGetMinX(frame)+radius,CGRectGetMaxY(frame));
      CGContextAddArc(_context,CGRectGetMaxX(frame)-radius,CGRectGetMaxY(frame),radius,M_PI_2,M_PI_2*3,YES);
      CGContextAddArc(_context,CGRectGetMinX(frame)+radius,CGRectGetMinY(frame)+radius,radius,M_PI_2*3,M_PI_2,YES);
      CGContextClosePath(_context);
      CGContextFillPath(_context);
#else
   CGContextBeginPath(_context);
   CGContextAddPath(_context,path);
   
   CGContextDrawPath(_context,_pathDrawingMode);
#endif

   CGContextRestoreGState(_context);
}

-(void)drawBitmapImageRep {   
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
  
   CGAffineTransform ctm=[self ctm];
   CGAffineTransform t=CGAffineTransformMakeTranslation(-(int)CGImageGetWidth(_resamplingImage)/2,-(int)CGImageGetHeight(_resamplingImage)/2);

   ctm=CGAffineTransformConcat(t,ctm);
 //  ctm=CGAffineTransformScale(ctm,2,2);
      
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,ctm);
   [self establishContextState];


#if 0
   CGColorRef color=CGColorCreateGenericRGB(1,0,0,1);
   CGContextSetShadowWithColor(_context,CGSizeMake(-5,-5),5,color);
   CGColorRelease(color);
#endif
#if 0
   CGContextAddEllipseInRect(_context,CGRectMake(0,0,CGImageGetWidth(_resamplingImage),CGImageGetHeight(_resamplingImage)));
   CGContextClip(_context);
#endif

   if(_resamplingImage!=NULL)
   CGContextDrawImage(_context,CGRectMake(0,0,CGImageGetWidth(_resamplingImage),CGImageGetHeight(_resamplingImage)),_resamplingImage);
   
   CGContextRestoreGState(_context);
}

-(void)drawStraightLines {
   CGAffineTransform xform=[self ctm];
  int               i,width=200,height=200;

    CGMutablePathRef  path=CGPathCreateMutable();

#if 0
   CGPathMoveToPoint(path,NULL,-width,0);
   CGPathAddLineToPoint(path,NULL,width,0);
   CGPathMoveToPoint(path,NULL,0,-height);
   CGPathAddLineToPoint(path,NULL,0,height);
#else
   CGPathMoveToPoint(path,NULL,0,0);
   for(i=0;i<width;i+=2){
    
   CGPathAddLineToPoint(path,NULL,i,0);
   CGPathAddLineToPoint(path,NULL,i,height);
   }
   
   for(i=0;i<height;i+=2){
   CGPathAddLineToPoint(path,NULL,0,i);
   CGPathAddLineToPoint(path,NULL,width,i);
   }
   
#endif

   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,xform);
   [self establishContextState];

   CGContextBeginPath(_context);
   CGContextAddPath(_context,path);
   
   CGContextDrawPath(_context,_pathDrawingMode);
   CGContextRestoreGState(_context);
      
   CGPathRelease(path);
}

-(void)drawBlending {
   int width=400;
   int height=400;
   int i,limit=40;
   CGAffineTransform ctm=[self ctm];

   ctm=CGAffineTransformTranslate(ctm,-200,-200);

   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,ctm);
   [self establishContextState];

   for(i=0;i<limit;i++){
    CGMutablePathRef path=CGPathCreateMutable();
    float      g=(i+1)/(float)limit;
    float      components[4]={g,g,g,g};
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGColorRef fillColor=CGColorCreate(colorSpace,components);

    CGPathAddRect(path,NULL,CGRectMake(i*width/limit,0,width/limit,height));
    
   CGContextAddPath(_context,path);
   
   CGContextSetFillColorWithColor(_context,fillColor);
   CGContextSetBlendMode(_context,kCGBlendModeCopy);
   CGContextDrawPath(_context,_pathDrawingMode);

    CGColorRelease(fillColor);
    CGColorSpaceRelease(colorSpace);
    CGPathRelease(path);
   }

   for(i=0;i<limit;i++){
    CGMutablePathRef path=CGPathCreateMutable();
    float      g=(i+1)/(float)limit;
    float      components[4]={g/2,(1.0-g),g,g};
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGColorRef fillColor=CGColorCreate(colorSpace,components);

    CGPathAddRect(path,NULL,CGRectMake(0,0,width,height-i*height/limit));
   CGContextAddPath(_context,path);
    
   CGContextSetFillColorWithColor(_context,fillColor);
   CGContextSetBlendMode(_context,_blendMode);
   CGContextDrawPath(_context,_pathDrawingMode);

    CGColorRelease(fillColor);
    CGColorSpaceRelease(colorSpace);
    CGPathRelease(path);
   }
   
   CGContextRestoreGState(_context);
}

static void evaluate(void *info,const float *in, float *output) {
   static CGFloat _C0[4]={0,1,0,1};
   static CGFloat _C1[4]={1,0,0,1};
   float         x=in[0];
   int           i;

    for(i=0;i<4;i++)
     output[i]=_C0[i]+x*(_C1[i]-_C0[i]);
}

-(void)drawAxialGradient {
   CGAffineTransform ctm=[self ctm];
   CGFunctionRef function;
   CGShadingRef  shading;
   float         domain[2]={0,1};
   float         range[8]={0,1,0,1,0,1,0,1};
   CGFunctionCallbacks callbacks={0,evaluate,NULL};
   CGPoint _startPoint={0,100};
   CGPoint _endPoint={30,100};
   BOOL _extendStart=YES,_extendEnd=YES;
 
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextSetRGBFillColor(_context,0.5,0.5,0.5,0.5);
  // CGContextFillRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,ctm);
   [self establishContextState];

   function=CGFunctionCreate(self,1,domain,4,range,&callbacks);

   shading=CGShadingCreateAxial(CGColorSpaceCreateDeviceRGB(),CGPointMake(_startPoint.x,_startPoint.y),
      CGPointMake(_endPoint.x,_endPoint.y),function,_extendStart,_extendEnd);
      
   CGContextBeginPath(_context);
   CGContextAddArc(_context,0,0,200,0,M_PI*2,YES);
   CGContextClip(_context);

   CGContextDrawShading(_context,shading);
   CGShadingRelease(shading);
   
   CGFunctionRelease(function);
   CGContextRestoreGState(_context);
}

-(void)drawRadialGradient {
   CGAffineTransform ctm=[self ctm];
   CGFunctionRef function;
   CGShadingRef  shading;
   float         domain[2]={0,1};
   float         range[8]={0,1,0,1,0,1,0,1};
   CGFunctionCallbacks callbacks={0,evaluate,NULL};
   CGPoint _startPoint={0,0};
   CGPoint _endPoint={0,0};
   CGFloat _startRadius=30,_endRadius=100;
   BOOL _extendStart=YES,_extendEnd=YES;
 
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextSetRGBFillColor(_context,0.5,0.5,0.5,0.5);
   CGContextFillRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,ctm);
   [self establishContextState];

   function=CGFunctionCreate(self,1,domain,4,range,&callbacks);

   shading=CGShadingCreateRadial(CGColorSpaceCreateDeviceRGB(),CGPointMake(_startPoint.x,_startPoint.y),_startRadius,
       CGPointMake(_endPoint.x,_endPoint.y),_endRadius,function,_extendStart,_extendEnd);
    
   CGContextDrawShading(_context,shading);
   CGShadingRelease(shading);
   
   CGFunctionRelease(function);
   CGContextRestoreGState(_context);
}

-(void)drawGlyphs {
   CGAffineTransform ctm=[self ctm];
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextSetRGBFillColor(_context,1,1,1,1);
   CGContextFillRect(_context,CGRectMake(0,0,400,400));
   ctm=CGAffineTransformTranslate(ctm,-200,-200);
   CGContextConcatCTM(_context,ctm);

   CGContextSetRGBFillColor(_context,1,0,0,1);

   NSString *string=@"Cocotron";
   int       i,length=[string length];
   CGGlyph   glyphs[length];
   
   for(i=0;i<length;i++){
    NSString *name=[string substringWithRange:NSMakeRange(i,1)];
    glyphs[i]=CGFontGetGlyphWithGlyphName(_font,name);
   }
   
   CGContextSetFont(_context,_font);
   CGContextSetFontSize(_context,200.0);
   CGContextShowGlyphsAtPoint(_context,50,50,glyphs,length);
   
   CGContextRestoreGState(_context);
}

-(void)drawPDF {
   CGAffineTransform ctm=[self ctm];
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextSetRGBFillColor(_context,1,1,1,1);
   CGContextFillRect(_context,CGRectMake(0,0,400,400));
   ctm=CGAffineTransformTranslate(ctm,-200,-200);
   CGContextConcatCTM(_context,ctm);

   if(_pdfDocument!=NULL){
    CGPDFPageRef page=CGPDFDocumentGetPage(_pdfDocument,1);
   
    CGContextDrawPDFPage(_context,page);
  // CGPDFPageRelease(page);
   }
   CGContextRestoreGState(_context);
}

-(void)drawLayers {
   CGAffineTransform ctm=[self ctm];
   
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextSetRGBFillColor(_context,1,1,1,1);
   CGContextFillRect(_context,CGRectMake(0,0,400,400));
   CGContextSetShadowWithColor(_context,CGSizeMake(30,30),_shadowBlur,_shadowColor);
   CGContextBeginTransparencyLayer(_context,NULL);
//   CGContextConcatCTM(_context,ctm);
//   CGContextSetShadow(_context,CGSizeMake(10,10),5.0);
   CGContextAddEllipseInRect(_context,CGRectMake(50,50,100,100));
   CGContextSetFillColorWithColor(_context,_fillColor);
   CGContextFillPath(_context);
   CGContextEndTransparencyLayer(_context);
   CGContextRestoreGState(_context);
}

static void drawPattern(void *info, CGContextRef ctxt){
   CGContextSetRGBFillColor(ctxt,1,1,0,1);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0,0,8,8));
   CGContextSetRGBFillColor(ctxt,1,0,1,1);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0,3,6,6));
   CGContextSetRGBFillColor(ctxt,0,0,1,1);
   CGContextFillEllipseInRect(ctxt,CGRectMake(0,6,4,6));
}

-(void)drawPattern {
   CGPatternCallbacks callbacks={0,drawPattern,NULL};
   CGPatternRef pattern=CGPatternCreate(NULL,CGRectMake(0,0,10,10),CGAffineTransformIdentity,10,10,kCGPatternTilingNoDistortion,YES,&callbacks);
   CGColorSpaceRef colorSpace=CGColorSpaceCreatePattern(NULL);
   CGFloat components[4]={1};
   CGColorRef color=CGColorCreateWithPattern(colorSpace,pattern,components);

#ifdef USING_QUARTZ2DX
   CGContextRef save=_context;
   CGRect media=CGRectMake(0,0,400,400);
   _context=CGPDFContextCreateWithURL([NSURL fileURLWithPath:@"/tmp/foo.pdf"],&media,NULL);
   CGPDFContextBeginPage(_context,NULL);
#endif
   CGContextSaveGState(_context);

   CGContextClearRect(_context,CGRectMake(0,0,400,400));

   CGAffineTransform ctm=[self ctm];
   ctm=CGAffineTransformTranslate(ctm,-200,-200);
   CGContextConcatCTM(_context,ctm);

   CGContextSetFillColorWithColor(_context,color);
   CGContextFillRect(_context,CGRectMake(0,0,300,300));
   CGContextRestoreGState(_context);
#ifdef USING_QUARTZ2DX
   CGPDFContextEndPage(_context);
   CGPDFContextClose(_context);
   CGContextRelease(_context);
   
   _context=save;
#endif

   CGColorRelease(color);
   CGColorSpaceRelease(colorSpace);
   CGPatternRelease(pattern);
}

#if 0

-(void)drawSampleInRender:(KGRender *)render {
   float      blackComponents[4]={0,0,0,1};
   CGColorRef blackColor=CGColorCreate(CGColorSpaceCreateDeviceRGB(),blackComponents);
   
   CGMutablePathRef  path1=CGPathCreateMutable();
   CGMutablePathRef  path2=CGPathCreateMutable();
   CGAffineTransform xform=CGAffineTransformMakeScale(.5,.5);
#if 1   
   addSliceToPath(path1,50,100,M_PI*30/180.0,M_PI*330/180.0);

   addSliceToPath(path1,150,300,M_PI*0/180.0,M_PI*60/180.0);
   addSliceToPath(path1,150,300,M_PI*120/180.0,M_PI*180/180.0);
   addSliceToPath(path1,150,300,M_PI*240/180.0,M_PI*300/180.0);
#else      
   CGPathMoveToPoint(path1,NULL,0,0);
   CGPathAddLineToPoint(path1,NULL,100,100);
   CGPathAddCurveToPoint(path1,NULL,0,100,100,200,200,200);
   CGPathAddLineToPoint(path1,NULL,100,100);
   CGPathAddLineToPoint(path1,NULL,200,10);
   CGPathCloseSubpath(path1);
#endif

   CGPathAddPath(path2,&xform,path1);
   
   [render clear];
  
   CGAffineTransform ctm=[self ctm];
   
#if 0   
   [render setShadowColor:createCGColor(gState->_shadowColor)];
   [render setShadowOffset:CGSizeMake(gState->_shadowOffset.width,gState->_shadowOffset.height)];
   [render setShadowBlur:gState->_shadowBlur];
#endif
#if 0
   [render drawPath:path1 drawingMode:_pathDrawingMode blendMode:kCGBlendModeNormal
      interpolationQuality:kCGInterpolationDefault fillColor:_destinationColor strokeColor:[NSColor blackColor] lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths flatness:gState->_flatness transform:ctm antialias:gState->_shouldAntialias];
 #endif
#if 1
   [render drawPath:path2 drawingMode:_pathDrawingMode blendMode:gState->_blendMode
      interpolationQuality:kCGInterpolationDefault fillColor:_sourceColor strokeColor:_destinationColor lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths flatness:gState->_flatness transform:ctm antialias:gState->_shouldAntialias];
 #endif
    
}



-(void)drawBlendingInRender:(KGRender *)render {
   int width=400;
   int height=400;
   int i,limit=10;
   CGAffineTransform ctm=[self ctm];

   ctm=CGAffineTransformTranslate(ctm,-200,-200);
   [render clear];

   for(i=0;i<limit;i++){
    CGMutablePathRef path=CGPathCreateMutable();
    float      g=(i+1)/(float)limit;
    NSColor *fillColor=[NSColor colorWithDeviceRed:g green:g blue:g alpha:g];

    CGPathAddRect(path,NULL,CGRectMake(i*width/limit,0,width/limit,height));
    
    [render drawPath:path drawingMode:_pathDrawingMode blendMode:kCGBlendModeCopy
      interpolationQuality:kCGInterpolationDefault fillColor:fillColor strokeColor:NULL lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths flatness:gState->_flatness transform:ctm antialias:gState->_shouldAntialias];
    CGColorRelease(fillColor);
    CGPathRelease(path);
   }

   for(i=0;i<limit;i++){
    CGMutablePathRef path=CGPathCreateMutable();
    float      g=(i+1)/(float)limit;
    float      components[4]={g/2,(1.0-g),g,g};
    NSColor *fillColor=[NSColor colorWithDeviceRed:g green:g blue:g alpha:g];

    CGPathAddRect(path,NULL,CGRectMake(0,0,width,height-i*height/limit));
    
    [render drawPath:path drawingMode:_pathDrawingMode blendMode:gState->_blendMode
      interpolationQuality:kCGInterpolationDefault fillColor:fillColor strokeColor:NULL lineWidth:gState->_lineWidth lineCap:gState->_lineCap lineJoin:gState->_lineJoin miterLimit:gState->_miterLimit dashPhase:gState->_dashPhase dashLengthsCount:gState->_dashLengthsCount dashLengths:gState->_dashLengths  flatness:gState->_flatness transform:ctm antialias:gState->_shouldAntialias];
    CGColorRelease(fillColor);
    CGPathRelease(path);
   }
}

#endif
@end
