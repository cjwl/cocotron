#import "PDFSelectedRange.h"

@implementation PDFSelectedRange

-initWithPage:(PDFPage *)page range:(NSRange)range {
   _page=[page retain];
   _range=range;
   return self;
}

-(void)dealloc {
   [_page release];
   [super dealloc];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(PDFPage *)page {
   return _page;
}

-(NSRange)range {
   return _range;
}

@end
