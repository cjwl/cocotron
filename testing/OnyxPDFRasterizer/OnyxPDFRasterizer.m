#import <Foundation/Foundation.h>
#import <Onyx2D/O2DataProvider.h>
#import <Onyx2D/O2BitmapContext.h>
#import <Onyx2D/O2PDFDocument.h>
#import <Onyx2D/O2PDFPage.h>

void usage(){
   NSLog(@"Usage: -Path <path>");
   exit(1);
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSString          *path=[[NSUserDefaults standardUserDefaults] stringForKey:@"Path"];
        
    if(path==nil)
     usage();
   
    NSData           *pdf=[NSData dataWithContentsOfFile:path];
    O2DataProviderRef provider=O2DataProviderCreateWithCFData(pdf);
    O2PDFDocument    *document=[[O2PDFDocument alloc] initWithDataProvider:provider];
    int               i,pageCount=[document pageCount];
    O2ColorSpaceRef   rgbColor=O2ColorSpaceCreateDeviceRGB();
    
    NSLog(@"Processing %@",path);
    NSLog(@"Number of pages=%d",pageCount);
    
    for(i=0;i<pageCount;i++){
     NSAutoreleasePool *autoPool=[NSAutoreleasePool new];
     O2PDFPage       *page=[document pageAtNumber:i+1];
     O2Rect           mediaBox;
     O2ContextRef     context;
     
     NSLog(@"processing page %d",i);
     
     if(![page getRect:&mediaBox forBox:kO2PDFMediaBox]){
      NSLog(@"Unable to get media box");
      continue;
     }
     
     context=O2BitmapContextCreate(NULL,mediaBox.size.width,mediaBox.size.height,8,0,rgbColor,kO2ImageAlphaPremultipliedFirst|kO2BitmapByteOrder32Host);
     
     if(context==NULL){
      NSLog(@"Unable to create context for media box %f %f",mediaBox.size.width,mediaBox.size.height);
      continue;
     }
     
     O2ContextDrawPDFPage(context,page);
     
     O2ContextRelease(context);
     [autoPool release];
    }
    
    [pool drain];
    return 0;
}
