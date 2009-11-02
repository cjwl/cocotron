//
//  O2Font_CG.m
//  SWRender
//
//  Created by Christopher Lloyd on 10/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "O2Font_CG.h"

@implementation O2Font(CG)

+allocWithZone:(NSZone *)zone {
   return NSAllocateObject([O2Font_CG class],0,zone);
}

@end

@implementation O2Font_CG

-initWithDataProvider:(O2DataProviderRef)provider {
   [super initWithDataProvider:provider];
   CFDataRef         cfData=O2DataProviderCopyData(provider);
   CGDataProviderRef cgProvider=CGDataProviderCreateWithCFData(cfData);
   CFRelease(cfData);
   
   _cgFont=CGFontCreateWithDataProvider(cgProvider);
   CGDataProviderRelease(cgProvider);
   
   return self;
}

@end
