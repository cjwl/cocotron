#import <PDFKit/PDFPage.h>
#import <AppKit/NSRaise.h>
#import <AppKit/NSGraphicsContext.h>
#import <Onyx2D/O2Context_distill.h>

@implementation PDFPage

/* init is the designated initializer for this class */
-init {
   _capacityOfCharacters=128;
   _characters=NSZoneMalloc(NULL,sizeof(unichar)*_capacityOfCharacters);
   _characterRects=NSZoneMalloc(NULL,sizeof(NSRect)*_capacityOfCharacters);
   
   return self;
}

-(void)dealloc {
   CGPDFPageRelease(_pageRef);
   [_label release];
   NSZoneFree(NULL,_characters);
   NSZoneFree(NULL,_characterRects);
   [super dealloc];
}

-(void)setPageRef:(CGPDFPageRef)pageRef {
   pageRef=CGPDFPageRetain(pageRef);
   CGPDFPageRelease(_pageRef);
   _pageRef=pageRef;
   _hasBeenDistilled=NO;
}

-(void)setDocument:(PDFDocument *)document {
   _document=document;
}

-(void)setLabel:(NSString *)value {
   value=[value copy];
   [_label release];
   _label=value;
}

-(PDFDocument *)document {
   return _document;
}

-(CGPDFPageRef)pageRef {
   return _pageRef;
}

-(NSString *)label {
  return _label;
}

-(void)distiller:(O2Context_distill *)distiller unicode:(unichar *)unicode rects:(O2Rect *)rects count:(NSUInteger)count {   
   if(_capacityOfCharacters<_numberOfCharacters+count){
    while(_capacityOfCharacters<_numberOfCharacters+count)
     _capacityOfCharacters*=2;

    _characters=NSZoneRealloc(NULL,_characters,_capacityOfCharacters*sizeof(unichar));
    _characterRects=NSZoneRealloc(NULL,_characterRects,_capacityOfCharacters*sizeof(NSRect));
   }
    
   NSUInteger i;
   
   for(i=0;i<count;i++){
    _characters[_numberOfCharacters]=unicode[i];
    _characterRects[_numberOfCharacters]=NSMakeRect(rects[i].origin.x,rects[i].origin.y,rects[i].size.width,rects[i].size.height);
    _numberOfCharacters++;
   }
}

-(void)distillIfNeeded {
   if(!_hasBeenDistilled){
    _hasBeenDistilled=YES;

    _numberOfCharacters=0;

    O2Context_distill *distiller=[[O2Context_distill alloc] init];
   
    [(O2Context_distill *)distiller setDelegate:self];
    
    CGContextDrawPDFPage(distiller,_pageRef);
    
    CGContextRelease(distiller);
   }
}

-(NSUInteger)numberOfCharacters {
   [self distillIfNeeded];
   
   return _numberOfCharacters;
}

-(NSString *)string {
   [self distillIfNeeded];
   
   return [[[NSString alloc] initWithCharactersNoCopy:_characters length:_numberOfCharacters freeWhenDone:NO] autorelease];
}

-(void)_getRects:(NSRect *)rects range:(NSRange)range {
   NSInteger i;
   
   for(i=0;i<range.length;i++)
    rects[i]=_characterRects[range.location+i];
}

-(NSRect)boundsForBox:(PDFDisplayBox)box {
   return CGPDFPageGetBoxRect(_pageRef,box);
}

-(void)transformContextForBox:(PDFDisplayBox)box {
#if 0
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];

   CGAffineTransform xform=CGPDFPageGetDrawingTransform(_pageRef,box,0,TRUE);

   CGContextConcatCTM(context,xform);
#endif
}

-(void)drawWithBox:(PDFDisplayBox)box {
   CGContextRef context=[[NSGraphicsContext currentContext] graphicsPort];

   [self transformContextForBox:box];
   CGContextDrawPDFPage(context,_pageRef);
}

@end
