#import "NSLocale+windows.h"
#import <Foundation/NSString.h>

#import <windows.h>

@implementation NSLocale(windows)

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
