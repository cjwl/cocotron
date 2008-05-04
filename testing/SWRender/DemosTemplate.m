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
    
    CGImageRef _resamplingImage;
    CGPDFDocumentRef _pdfDocument;
}
@end

@implementation DEMONAME(Context)

static CGColorRef cgColorFromColor(NSColor *color){
   NSColor *rgbColor=[color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
   float rgba[4];
   
   [rgbColor getComponents:rgba];
   return CGColorCreate(CGColorSpaceCreateDeviceRGB(),rgba);
}

-init {
   _pixelsWide=400;
   _pixelsHigh=400;
   _bitsPerComponent=8;
   _bitsPerPixel=32;
   _bytesPerRow=(_pixelsWide*_bitsPerPixel)/8;
   _colorSpace=CGColorSpaceCreateDeviceRGB();
   _bitmapInfo=kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big;
   _data=NSZoneMalloc(NULL,_bytesPerRow*_pixelsHigh);
   _context=CGBitmapContextCreate(_data,_pixelsWide,_pixelsHigh,_bitsPerComponent,_bytesPerRow,_colorSpace,_bitmapInfo);

   _fillColor=cgColorFromColor([NSColor blueColor]);
   _strokeColor=cgColorFromColor([NSColor redColor]);
   _pathDrawingMode=kCGPathStroke;
   _shouldAntialias=YES;
   _interpolationQuality=kCGInterpolationDefault;
   _scalex=1;
   _scaley=1;
   _rotation=0;
   _blendMode=kCGBlendModeNormal;
   _shadowColor=cgColorFromColor([NSColor blackColor]);
   _shadowBlur=0;
   _shadowOffset=CGSizeMake(10,10);
   _lineWidth=1;
   _lineCap=kCGLineCapButt;
   _lineJoin=kCGLineJoinMiter;
   _miterLimit=1;
   _dashPhase=100;
   _dashLengthsCount=0;
   _dashLengths=NSZoneMalloc([self zone],sizeof(float)*4);
   
   NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"overlay" ofType:@"jpg"];
   NSData   *data=[NSData dataWithContentsOfFile:path];
   CGImageSourceRef source=CGImageSourceCreateWithData((CFDataRef)data,nil);
   _resamplingImage=CGImageSourceCreateImageAtIndex(source,0,nil);
   [(id)source release];
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

-(void)setStrokeColor:(NSColor *)color {
   CGColorRelease(_strokeColor);
   _strokeColor=cgColorFromColor(color);
}

-(void)setFillColor:(NSColor *)color {
   CGColorRelease(_fillColor);
   _fillColor=cgColorFromColor(color);
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

-(void)setShadowColor:(NSColor *)color {
   CGColorRelease(_shadowColor);
   _shadowColor=cgColorFromColor(color);
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

   CGContextBeginPath(_context);
   CGContextAddPath(_context,path);
   
   CGContextDrawPath(_context,_pathDrawingMode);
   CGContextRestoreGState(_context);
}

-(void)drawBitmapImageRep {   
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
  
   CGAffineTransform ctm=[self ctm];
   CGAffineTransform t=CGAffineTransformMakeTranslation(-(int)CGImageGetWidth(_resamplingImage),-(int)CGImageGetHeight(_resamplingImage));
   ctm=CGAffineTransformConcat(t,ctm);
   ctm=CGAffineTransformScale(ctm,2,2);
      
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   CGContextConcatCTM(_context,ctm);
   [self establishContextState];


   CGContextDrawImage(_context,CGRectMake(0,0,CGImageGetWidth(_resamplingImage),CGImageGetHeight(_resamplingImage)),_resamplingImage);
   
   CGContextRestoreGState(_context);
}

-(void)drawStraightLines {
   CGAffineTransform xform=[self ctm];
  int               i,width=400,height=400;

    CGMutablePathRef  path=CGPathCreateMutable();

   for(i=0;i<400;i+=10){
    
   CGPathMoveToPoint(path,NULL,i,0);
   CGPathAddLineToPoint(path,NULL,i,height);
   }
   
   for(i=0;i<400;i+=10){
   CGPathMoveToPoint(path,NULL,0,i);
   CGPathAddLineToPoint(path,NULL,width,i);
   }
   
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
   int i,limit=10;
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
    CGColorRef fillColor=CGColorCreate(CGColorSpaceCreateDeviceRGB(),components);

    CGPathAddRect(path,NULL,CGRectMake(i*width/limit,0,width/limit,height));
    
   CGContextAddPath(_context,path);
   
   CGContextSetFillColorWithColor(_context,fillColor);
   CGContextSetBlendMode(_context,kCGBlendModeCopy);
   CGContextDrawPath(_context,_pathDrawingMode);

    CGColorRelease(fillColor);
    CGPathRelease(path);
   }

   for(i=0;i<limit;i++){
    CGMutablePathRef path=CGPathCreateMutable();
    float      g=(i+1)/(float)limit;
    float      components[4]={g/2,(1.0-g),g,g};
    CGColorRef fillColor=CGColorCreate(CGColorSpaceCreateDeviceRGB(),components);

    CGPathAddRect(path,NULL,CGRectMake(0,0,width,height-i*height/limit));
   CGContextAddPath(_context,path);
    
   CGContextSetFillColorWithColor(_context,fillColor);
   CGContextSetBlendMode(_context,_blendMode);
   CGContextDrawPath(_context,_pathDrawingMode);

    CGColorRelease(fillColor);
    CGPathRelease(path);
   }
   
   CGContextRestoreGState(_context);
}

-(void)drawPDF {
   CGAffineTransform ctm=[self ctm];
   CGContextSaveGState(_context);
   CGContextClearRect(_context,CGRectMake(0,0,400,400));
   ctm=CGAffineTransformTranslate(ctm,-200,-200);
   CGContextConcatCTM(_context,ctm);

   if(_pdfDocument!=NULL){
    CGPDFPageRef page=CGPDFDocumentGetPage(_pdfDocument,1);
   
    CGContextDrawPDFPage(_context,page);
  // CGPDFPageRelease(page);
   }
   CGContextRestoreGState(_context);
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
   [render setShadowColor:cgColorFromColor(gState->_shadowColor)];
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
