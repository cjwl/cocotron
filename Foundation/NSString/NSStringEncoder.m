/* Copyright (c) 2013 Aiy André - plasq

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import "NSStringEncoder.h"

#import <CoreFoundation/CFString.h>
#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRaiseException.h>

#import "Encoding/CP874.h"
#import "Encoding/CP932.h"
#import "Encoding/CP936.h"
#import "Encoding/CP949.h"
#import "Encoding/CP950.h"
#import "Encoding/CP1250.h"
#import "Encoding/CP1251.h"
#import "Encoding/CP1252.h"
#import "Encoding/CP1253.h"
#import "Encoding/CP1254.h"
#import "Encoding/CP1255.h"
#import "Encoding/CP1256.h"
#import "Encoding/CP1257.h"
#import "Encoding/CP1258.h"

// Returns the
static const uint16_t *tableForCFEncoding(CFStringEncoding encoding)
{
    switch (encoding) {
        case kCFStringEncodingDOSThai:
            return cp874;
        case kCFStringEncodingDOSJapanese:
            return cp932;
        case kCFStringEncodingDOSChineseSimplif:
            return cp936;
        case kCFStringEncodingDOSKorean:
            return cp949;
        case kCFStringEncodingDOSChineseTrad:
            return cp950;
        case kCFStringEncodingWindowsLatin2:
            return cp1250;
        case kCFStringEncodingWindowsCyrillic:
            return cp1251;
        case kCFStringEncodingWindowsLatin1:
            return cp1252;
        case kCFStringEncodingWindowsGreek:
            return cp1253;
        case kCFStringEncodingWindowsLatin5:
            return cp1254;
        case kCFStringEncodingWindowsHebrew:
            return cp1255;
        case kCFStringEncodingWindowsArabic:
            return cp1256;
        case kCFStringEncodingWindowsBalticRim:
            return cp1257;
        case kCFStringEncodingWindowsVietnamese:
            return cp1258;
        default:
            return NULL;
    }
}

static const uint16_t *tableForNSEncoding(NSStringEncoding encoding)
{
    CFStringEncoding cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    return tableForCFEncoding(cfencoding);
}

static NSDictionary *dictionaryForEncoding(NSStringEncoding encoding)
{
    NSMutableDictionary *dict = nil;
    static NSMutableDictionary *sAllDicts = nil;
    @synchronized(sAllDicts) {
        if (sAllDicts == nil) {
            sAllDicts = [[NSMutableDictionary alloc] init];
        }
        dict = [sAllDicts objectForKey:[NSNumber numberWithInteger:encoding]];
        if (dict == nil) {
            const uint16_t *table = tableForNSEncoding(encoding);
            if (table) {
                dict = [NSMutableDictionary dictionary];
                for (int i = 0; table[i] != (uint16_t)-1; i+=2) {
                    [dict setObject:[NSNumber numberWithUnsignedShort:table[i+1]] forKey:[NSNumber numberWithUnsignedShort:table[i]]];
                }
                [sAllDicts setObject:dict forKey:[NSNumber numberWithInteger:encoding]];
            }
        }
    }
    return dict;
}

unichar *NSBytesToUnicode(const unsigned char *bytes,NSUInteger length,NSStringEncoding encoding, NSUInteger *resultLength,NSZone *zone)
{
    unichar *data = NULL;
    NSDictionary *dict = dictionaryForEncoding(encoding);
    if (dict) {
        NSUInteger unicodeLength = 0;
        unichar unibuffer[length];
        unichar current = 0;
        for (NSUInteger i = 0; i < length; ++i) {
            // mask the byte with any pending one (for 2-bytes char translation)
            current |= bytes[i];
            NSNumber *n = [dict objectForKey:[NSNumber numberWithUnsignedShort:current]];
            if (n) {
                uint16_t u = [n unsignedShortValue];
                if (u == (uint16_t)-1) {
                    // 2-bytes char
                    current <<= 8;
                } else {
                   unibuffer[unicodeLength++] = [n unsignedShortValue];
                    current = 0;
                }
            } else {
                // Unknown code
                NSCLog("NSBytesToUnicode : unknown code 0x%X for encoding 0x%X", current, encoding);
                current = 0;
            }
        }
        data = malloc(sizeof(unichar) * unicodeLength);
        if (resultLength) {
            *resultLength = unicodeLength;
        }
        bcopy(unibuffer, data, unicodeLength * sizeof(unichar));
    } else {
        NSCLog("NSBytesToUnicode : encoding %d (%x) to unicode not (yet) implemented", encoding, encoding);
    }
    return data;
}
