#import <PDFKit/PDFDocument.h>
#import <PDFKit/PDFPage.h>
#import <PDFKit/PDFSelection.h>
#import <Foundation/NSData.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSMutableArray.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotificationCenter.h>
#import <AppKit/NSRaise.h>
#import "PDFSelectedRange.h"

NSString *const PDFDocumentDidEndFindNotification=@"PDFDocumentDidEndFindNotification";
NSString *const PDFDocumentDidFindMatchNotification=@"PDFDocumentDidFindMatchNotification";

@implementation PDFDocument

-initWithData:(NSData *)data {
   CGDataProviderRef provider=CGDataProviderCreateWithCFData(data);
   _documentRef=CGPDFDocumentCreateWithProvider(provider);
   CGDataProviderRelease(provider);
   _pages=[[NSMutableArray alloc] init];
   
   NSInteger i,count=CGPDFDocumentGetNumberOfPages(_documentRef);

   for(i=0;i<count;i++){
    CGPDFPageRef pageRef=CGPDFDocumentGetPage(_documentRef,i+1);
    PDFPage     *page=[[[self pageClass] alloc] init];
    
    [page setPageRef:pageRef];
    [page setDocument:self];
    [page setLabel:[NSString stringWithFormat:@"%d",i+1]];
    [_pages addObject:page];
   }
   
   return self;
}

-initWithURL:(NSURL *)url {
   NSData *data=[NSData dataWithContentsOfURL:url];
   
   if(data==nil){
    [self dealloc];
    return nil;
   }
   
   if([self initWithData:data]==nil)
    return nil;
   
   _documentURL=[url copy];
   return self;
}

-(void)dealloc {
   [_documentURL release];
   CGPDFDocumentRelease(_documentRef);
   [super dealloc];
}

-(NSURL *)documentURL {
   return _documentURL;
}

-(void)setDelegate:object {
   _delegate=object;
}

-(NSUInteger)pageCount {
   return [_pages count];
}

-(Class)pageClass {
   return [PDFPage class];
}

-(PDFPage *)pageAtIndex:(NSUInteger)index {
   return [_pages objectAtIndex:index];
}

-(NSUInteger)indexForPage:(PDFPage *)page {
   return [_pages indexOfObjectIdenticalTo:page];
}

-(BOOL)isFinding {
   return (_findTimer!=nil)?YES:NO;
}

-(void)cancelFindString {
   [_findTimer invalidate];
   [_findTimer release];
   _findTimer=nil;
}

-(NSArray *)findOnCurrentPage {
   NSMutableArray *result=[NSMutableArray array];
   NSString  *text=[[_pages objectAtIndex:_findPageIndex] string];
   NSInteger i,textLength=[text length];
   unichar   textBuffer[textLength];
      
   if(_findOptions&NSCaseInsensitiveSearch)
    text=[text uppercaseString];
   
   [text getCharacters:textBuffer];
   
   for(i=0;i<textLength;){
    for(;i<textLength && _findPosition<_findPatternLength;i++,_findPosition++){
     while((_findPosition>-1) && (textBuffer[i]!=_findPattern[_findPosition]))
      _findPosition=_findNext[_findPosition];
     
     if(_findPosition<=0){
      // start
     }
    }
    
    if(_findPosition>=_findPatternLength){
     NSInteger maxRange=i;
     NSInteger rangeLocation=maxRange-_findPatternLength;
     NSInteger pageForRange=_findPageIndex;
     NSMutableArray *selectionRanges=[NSMutableArray array];
     
     do{
      PDFPage  *page=[_pages objectAtIndex:pageForRange];
      NSInteger pageRangeLocation=MAX(0,rangeLocation);
      NSInteger pageRangeLength=maxRange-pageRangeLocation;
      PDFSelectedRange *selectedRange=[[[PDFSelectedRange alloc] initWithPage:page range:NSMakeRange(pageRangeLocation,pageRangeLength)] autorelease];
      
      [selectionRanges addObject:selectedRange];
      
      maxRange=pageRangeLocation;
      
      if(maxRange<=0){
       pageForRange--;
       if(pageForRange<0)
        break;
        
       maxRange=[[[_pages objectAtIndex:pageForRange] string] length];
       rangeLocation=maxRange-pageRangeLength;
      }
      
     }while(maxRange>rangeLocation);
     
     PDFSelection *selection=[[[PDFSelection alloc] initWithDocument:self] autorelease];
     
     [selection _setSelectedRanges:selectionRanges];
     
     [result addObject:selection];
     
     _findPosition=0;
    }
    
   }
   
   return result;
}

-(void)_findOnCurrentPage:(NSTimer *)timer {

   if(_findPageIndex<[_pages count]){
    NSArray  *selections=[self findOnCurrentPage];
    NSInteger i,count=[selections count];
    
    for(i=0;i<count && [self isFinding];i++){
     PDFSelection *selection=[selections objectAtIndex:i];
     
     if([_delegate respondsToSelector:@selector(didMatchString:)])
      [_delegate didMatchString:selection];
     
     [[NSNotificationCenter defaultCenter] postNotificationName:PDFDocumentDidFindMatchNotification
     object:self userInfo:[NSDictionary dictionaryWithObject:selection forKey:@"PDFDocumentFoundSelection"]];
    }

    _findPageIndex++;
   }
   else {
    [_findTimer invalidate];
    [_findTimer release];
    _findTimer=nil;

     [[NSNotificationCenter defaultCenter] postNotificationName:PDFDocumentDidEndFindNotification object:self userInfo:nil];
   }
   
}

-(void)_setupFindString:(NSString *)string withOptions:(NSUInteger)options {
   NSInteger i,pos;
   
   _findOptions=options;

   if(_findOptions&NSCaseInsensitiveSearch)
    string=[string uppercaseString];

   _findPatternLength=[string length];
   
   if(_findPatternLength==0){
    _findPattern=NULL;
    _findNext=NULL;
    _findPosition=0;
    _findPageIndex=[_pages count];
    return;
   }

   _findPattern=NSZoneMalloc(NULL,_findPatternLength*sizeof(unichar));
  
   [string getCharacters:_findPattern];

#if 0
// backwards isnt completely implemented, but first thing you do is reverse the pattern
// (then process the text stream in reverse)
   if(options&NSBackwardsSearch){
    for(pos=0;pos<_findPatternLength/2;pos++){
     unichar tmp=_findPattern[pos];
     _findPattern[pos]=_findPattern[_findPatternLength-pos-1];
     _findPattern[_findPatternLength-pos-1]=tmp;
    }
   }
#endif

   _findNext=NSZoneMalloc(NULL,_findPatternLength*sizeof(NSInteger));

// Modified Knuth-Morris-Pratt sequential search.
   
   pos=0;
   _findNext[0]=-1;
   i=-1; 
   while(pos<_findPatternLength-1){
    while(i>-1 && _findPattern[pos]!=_findPattern[i])
     i=_findNext[i];
    pos++;
    i++;
    if(_findPattern[pos]==_findPattern[i])
     _findNext[pos]=_findNext[i];
    else
     _findNext[pos]=i;
   }
    
   _findPosition=0;
   
   _findPageIndex=0;
}

-(void)beginFindString:(NSString *)string withOptions:(NSUInteger)options { 
   [self _setupFindString:string withOptions:options];

   _findTimer=[[NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(_findOnCurrentPage:) userInfo:nil repeats:YES] retain];
}

-(NSArray *)findString:(NSString *)string withOptions:(NSUInteger) options {
   NSMutableArray *result=[NSMutableArray array];
   
   [self _setupFindString:string withOptions:options];
   while(_findPageIndex<[_pages count]){
    NSArray *batch=[self findOnCurrentPage];
    
    [result addObjectsFromArray:batch];
    
    _findPageIndex++;
   }
   
   return result;
}

@end
