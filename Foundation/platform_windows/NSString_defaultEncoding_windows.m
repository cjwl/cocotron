/* Copyright (c) 2009 Glenn Ganz
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import <Foundation/NSString_defaultEncoding.h>
#import <Foundation/NSException.h>
#import <windows.h>

NSStringEncoding defaultEnconding()
{
    //don't use objc calls because they call often defaultCStringEncoding
    
    UINT codepage = GetACP();
	switch(codepage)
	{
		case 1250:
            return NSWindowsCP1250StringEncoding;
			
		case 1251:
            return NSWindowsCP1251StringEncoding;
            
		case 1252:
            return NSWindowsCP1252StringEncoding;	
            
		case 1253:
            return NSWindowsCP1253StringEncoding;
            
		case 1254:
            return NSWindowsCP1254StringEncoding;		
            
		case 50220:
            return NSISO2022JPStringEncoding;
            
		case 10000:
			return NSMacOSRomanStringEncoding;
            
		case 12000:
			return NSUTF32LittleEndianStringEncoding;
            
		case 12001:
			return NSUTF32BigEndianStringEncoding;
            
		case 20127:
			return NSASCIIStringEncoding;
            
		case 20932:
			return NSJapaneseEUCStringEncoding;
            
		case 65001:
			return NSUTF8StringEncoding;
            
		case 28591:
			return NSISOLatin1StringEncoding;
            
		case 28592:
			return NSISOLatin2StringEncoding;
			
		default:
            [NSException raise:NSInternalInconsistencyException
						format:@"defaultCStringEncoding() failed with codepage=%d", codepage];
	}
    
}
