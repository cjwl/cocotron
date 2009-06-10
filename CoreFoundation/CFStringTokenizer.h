/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <CoreFoundation/CFBase.h>

typedef struct CFStringTokenizer *CFStringTokenizerRef;

typedef CFOptionFlags CFStringTokenizerTokenType;

CFTypeID      CFStringTokenizerGetTypeID(void);

CFOptionFlags CFStringTokenizerGetSupportedOptionsForLanguage(CFStringRef language);

CFStringTokenizerRef CFStringTokenizerCreate(CFAllocatorRef allocator,CFStringRef string,CFRange range,CFOptionFlags options,CFLocaleRef locale);

CFStringTokenizerTokenType CFStringTokenizerAdvanceToNextToken(CFStringTokenizerRef self);
CFStringRef                CFStringTokenizerCopyBestStringLanguage(CFStringRef string,CFRange range);
CFTypeRef                  CFStringTokenizerCopyCurrentTokenAttribute(CFStringTokenizerRef self,CFOptionFlags attribute);
CFIndex                    CFStringTokenizerGetCurrentSubTokens(CFStringTokenizerRef self,CFRange *ranges,CFIndex maxRangeLength,CFMutableArrayRef subTokens);
CFRange                    CFStringTokenizerGetCurrentTokenRange(CFStringTokenizerRef self);
CFStringTokenizerTokenType CFStringTokenizerGoToTokenAtIndex(CFStringTokenizerRef self,CFIndex index);
void                       CFStringTokenizerSetString(CFStringTokenizerRef self,CFStringRef string,CFRange range);
