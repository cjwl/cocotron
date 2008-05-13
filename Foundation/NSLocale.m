/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSDictionary.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSRaise.h>

NSString *NSLocaleCountryCode=@"NSLocaleCountryCode";
NSString *NSLocaleLanguageCode=@"NSLocaleLanguageCode";
NSString *NSLocaleVariantCode=@"NSLocaleVariantCode";
NSString *NSLocaleIdentifier=@"NSLocaleIdentifier";

NSString *NSLocaleGroupingSeparator=@"NSLocaleGroupingSeparator";
NSString *NSLocaleDecimalSeparator=@"NSLocaleDecimalSeparator";
NSString *NSLocaleCalendar=@"NSLocaleCalendar";
NSString *NSLocaleCurrencyCode=@"NSLocaleCurrencyCode";
NSString *NSLocaleCurrencySymbol=@"NSLocaleCurrencySymbol";
NSString *NSLocaleUsesMetricSystem=@"NSLocaleUsesMetricSystem";
NSString *NSLocaleMeasurementSystem=@"NSLocaleMeasurementSystem";

NSString *NSLocaleScriptCode=@"NSLocaleScriptCode";
NSString *NSLocaleExemplarCharacterSet=@"NSLocaleExemplarCharacterSet";
NSString *NSLocaleCollationIdentifier=@"NSLocaleCollationIdentifier";

@implementation NSLocale

static NSLocale *_sharedSystemLocale  = nil;
static NSLocale *_sharedCurrentLocale = nil;

-(NSDictionary *)_locale {
   return _locale;
}

+systemLocale {
   if (_sharedSystemLocale == nil)
      _sharedSystemLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
   return _sharedSystemLocale;
}

+currentLocale {
   if (_sharedCurrentLocale == nil)
   {
      NSString *localeIdentifier;
      
      if([self respondsToSelector:@selector(_platformCurrentLocaleIdentifier)])
       localeIdentifier=[self performSelector:@selector(_platformCurrentLocaleIdentifier)];
      else
       localeIdentifier=@"en_US";
       
      _sharedCurrentLocale = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
   }
   return _sharedCurrentLocale;
}

-(void)dealloc {
   [_locale release];
   [super dealloc];
}

+autoupdatingCurrentLocale {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)availableLocaleIdentifiers {
   NSUnimplementedMethod();
   return 0;
}

+(NSString *)canonicalLocaleIdentifierFromString:(NSString *)string {
   NSUnimplementedMethod();
   return 0;
}

+(NSDictionary *)componentsFromLocaleIdentifier:(NSString *)identifier {
   if ([identifier isEqualToString:[[NSLocale currentLocale] localeIdentifier]])
      return [_sharedCurrentLocale _locale];
   else if ([identifier isEqualToString:[[NSLocale systemLocale] localeIdentifier]])
      return [_sharedSystemLocale _locale];
   else
      return [[[[NSLocale alloc] initWithLocaleIdentifier:identifier] autorelease] _locale];
   return 0;
}

+(NSString *)localeIdentifierFromComponents:(NSDictionary *)components {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)ISOCountryCodes {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)ISOLanguageCodes {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)ISOCurrencyCodes {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)commonISOCurrencyCodes {
   NSUnimplementedMethod();
   return 0;
}

+(NSArray *)preferredLanguages {
   NSUnimplementedMethod();
   return 0;
}

-initWithLocaleIdentifier:(NSString *)identifier {
   [super init];

   NSString *separator, *language;

   if ([identifier isEqualToString:@"de_DE"])
   {
      separator = @",";
      language  = @"German";
   }

   else if ([identifier isEqualToString:@"pt_BR"])
   {
      separator = @",";
      language  = @"pt_BR";
   }

   else
   {
      separator = @".";
      language  = @"English";
   }
   _locale = [[NSDictionary dictionaryWithObjectsAndKeys:identifier, NSLocaleIdentifier,
                                                          separator, NSLocaleDecimalSeparator,
                                                           language, NSLocaleLanguageCode, nil] retain];
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-initWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
   return self;

}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-(NSString *)localeIdentifier {
   return [_locale objectForKey:NSLocaleIdentifier];
}

-objectForKey:key {
   return [_locale objectForKey:key];
}

-(NSString *)displayNameForKey:key value:value {
   NSUnimplementedMethod();
   return 0;
}

@end
