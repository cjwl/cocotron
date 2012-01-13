#import "NSLocale+windows.h"
#import <Foundation/NSString.h>

#include <windows.h>

@implementation NSLocale(windows)

BOOL NSCurrentLocaleIsMetric(){
   uint16_t buffer[2];
   int       size=GetLocaleInfoW(LOCALE_USER_DEFAULT,LOCALE_IMEASURE,buffer,2);

   if(buffer[0]=='0')
    return YES;
   
   return NO;
}

+(NSString *)_platformCurrentLocaleIdentifier {
      switch(GetSystemDefaultLCID() & 0x0000FFFF)
      {
         case 0x0407:
            return @"de_DE";

         case 0x0416:
            return @"pt_BR";
            
         default:
            return @"en_US";
      }
}

@end
