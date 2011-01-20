/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
                 2009 Markus Hitter <mah@jump-ing.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSScanner_concrete.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSLocale.h>
#import <limits.h>

@implementation NSScanner_concrete

-initWithString:(NSString *)string {

   self=[self init];
   if(self!=nil){
    _string=[string copy];
    _location=0;
    _skipSet=[[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
    _isCaseSensitive=NO;
    _locale=nil;
   }

   return self;
}

-(void)dealloc {
   [_string release];
   [_skipSet release];
   [_locale release];
   [super dealloc];
}

-(NSString *)string {
    return _string;
}

-(NSCharacterSet *)charactersToBeSkipped {
    return _skipSet;
}

-(BOOL)caseSensitive {
    return _isCaseSensitive;
}

-(NSDictionary *)locale {
    return _locale;
}

-(void)setCharactersToBeSkipped:(NSCharacterSet *)set {
    [_skipSet autorelease];
    _skipSet = [set retain];
}

-(void)setCaseSensitive:(BOOL)flag {
    _isCaseSensitive = flag;
}

-(void)setLocale:(NSDictionary *)locale {
    [_locale autorelease];
    _locale = [locale retain];
}

-(BOOL)isAtEnd {
    NSUInteger length = [_string length];
    NSUInteger currentLocation = _location;
    
    for(;currentLocation < length;currentLocation++){
        if([_skipSet characterIsMember:[_string characterAtIndex:currentLocation]] == YES) {
            continue;
        }
        else {
            return NO;
        }
    }
    
    return YES;
}

-(NSUInteger)scanLocation {
    return _location;
}

-(void)setScanLocation:(NSUInteger)pos {
   _location=pos;
}

-(BOOL)scanInt:(int *)valuep {
	long long scanValue=0;
	
	// This assumes sizeof(long long) >= sizeof(int).
	if(![self scanLongLong:&scanValue])
		return NO;
	else if (NULL != valuep) {
		if(scanValue>INT_MAX)
			*valuep=INT_MAX;
		else if(scanValue<INT_MIN)
			*valuep=INT_MIN;
		else
			*valuep=(int)scanValue;
	}
	
	return YES;
}

-(BOOL)scanInteger:(NSInteger *)valuep{
	long long scanValue=0;
	
	// This assumes sizeof(long long) >= sizeof(NSInteger).
	if(![self scanLongLong:&scanValue])
		return NO;
	else if (NULL != valuep) {
		if(scanValue>NSIntegerMax)
			*valuep=NSIntegerMax;
		else if(scanValue<NSIntegerMin)
			*valuep=NSIntegerMin;
		else
			*valuep=(NSInteger)scanValue;
	}
	
	return YES;
}

-(BOOL)scanLongLong:(long long *)valuep {
// FIXME: this should use C99 LLONG_*, but switching has some link problems for Linux
#define long_long_MAX 0x7fffffffffffffffLL
#define long_long_MIN (-0x7fffffffffffffffLL-1)

   NSUInteger length;
   int sign=1;
   BOOL hasSign=NO;
   long long value=0;
   BOOL hasValue=NO;
   BOOL hasOverflow=NO;

   for(length=[_string length];_location<length;_location++){
    unichar unicode=[_string characterAtIndex:_location];

    if(!hasValue && [_skipSet characterIsMember:unicode])
     continue;
    else if(!hasSign && unicode=='-'){
     sign=-1;
     hasSign=YES;
    }
    else if(!hasSign && unicode=='+'){
     sign=1;
     hasSign=YES;
    }
    else if(unicode>='0' && unicode<='9'){
     if(!hasOverflow){
      int c=unicode-'0';

      // Inspired by http://www.math.utoledo.edu/~dbastos/overflow.html 
      if ((long_long_MAX-c)/10<value)
       hasOverflow=YES;
      else
       value=(value*10)+c;
      hasSign=YES;
      hasValue=YES;
     }
    }
    else
     break;
   }

   if(hasOverflow){
	   if (NULL != valuep) {
		   if(sign>0)
			   *valuep=long_long_MAX;
		   else
			   *valuep=long_long_MIN;
	   }
    return YES;
   }
   else if(hasValue){
	   if (NULL != valuep)
		   *valuep=sign*value;
    return YES;
   }

   return NO;
}

-(BOOL)scanFloat:(float *)valuep {
    double d;
    BOOL r;

    r = [self scanDouble:&d];
	if (NULL != valuep)
		*valuep = (float)d;
    return r;
}

// "...returns HUGE_VAL or -HUGE_VAL on overflow, 0.0 on underflow." hmm...
-(BOOL)scanDouble:(double *)valuep {
	double value;
   NSString *seperatorString;
   unichar   decimalSeperator;
   if(_locale)
      seperatorString = [_locale objectForKey:NSLocaleDecimalSeparator];
   else
      seperatorString = [[NSLocale systemLocale] objectForKey:NSLocaleDecimalSeparator];
   decimalSeperator = ([seperatorString length] > 0 ) ? [seperatorString characterAtIndex:0] : '.';

   NSInteger     i;
   NSInteger     len = [_string length] - _location;
   char    p[len + 1], *q;
   unichar c;

   for (i = 0; i < len; i++)
   {
      c  = [_string characterAtIndex:i + _location];    
      if (c == decimalSeperator) c = '.';
      p[i] = (char)c;
   }
   p[i] = '\0';

	value = strtod(p, &q);
	if (NULL != valuep)
		*valuep = value;
   _location += (q - p);
   return (q > p);

/*
    enum {
        STATE_SPACE,
        STATE_DIGITS_ONLY
    } state=STATE_SPACE;
    int sign=1;
    double value=1.0;
    BOOL hasValue=NO;

    for(;_location<[_string length];_location++){
        unichar unicode=[_string characterAtIndex:_location];

        switch(state){
            case STATE_SPACE:
                if([_skipSet characterIsMember:unicode])
                    state=STATE_SPACE;
                else if(unicode=='-') {
                    sign=-1;
                    state=STATE_DIGITS_ONLY;
                }
                else if(unicode=='+'){
                    sign=1;
                    state=STATE_DIGITS_ONLY;
                }
                else if(unicode>='0' && unicode<='9'){
                    value=(value*10)+unicode-'0';
                    state=STATE_DIGITS_ONLY;
                    hasValue=YES;
                }
                else if(unicode==decimalSeperator) {
                    double multiplier=1;

                    _location++;
                    for(;_location<[_string length];_location++){
                        if(unicode<'0' || unicode>'9')
                            break;

                        multiplier/=10.0;
                        value+=(unicode-'0')*multiplier;
                    }
                }
                else
                    return NO;
                break;

            case STATE_DIGITS_ONLY:
                if(unicode>='0' && unicode<='9'){
                    value=(value*10)+unicode-'0';
                    hasValue=YES;
                }
                else if(!hasValue)
                    return NO;
                else if(unicode==decimalSeperator) {
                    double multiplier=1;

                    _location++;
                    for(;_location<[_string length];_location++){
                        if(unicode<'0' || unicode>'9')
                            break;

                        multiplier/=10.0;
                        value+=(unicode-'0')*multiplier;
                    }
                }
                else {
                    *valuep=sign*value;
                    return YES;
                }
                break;
        }
    }

    if(!hasValue)
        return NO;
    else {
        *valuep=sign*value;
        return YES;
    }
*/
}

-(BOOL)scanDecimal:(NSDecimal *)valuep {
    NSUnimplementedMethod();
    return NO;
}

// The documentation appears to be wrong, it returns -1 on overflow.
-(BOOL)scanHexInt:(unsigned *)valuep {
   enum {
    STATE_SPACE,
    STATE_ZERO,
    STATE_HEX,
   } state=STATE_SPACE;
   unsigned value=0;
   BOOL     hasValue=NO;
   BOOL     overflow=NO;
   
   for(;_location<[_string length];_location++){
    unichar unicode=[_string characterAtIndex:_location];

    switch(state){
    
     case STATE_SPACE:
      if([_skipSet characterIsMember:unicode])
       state=STATE_SPACE;
      else if(unicode == '0'){
       state=STATE_ZERO;
       hasValue=YES;
      }
      else if(unicode>='1' && unicode<='9'){
       value=value*16+(unicode-'0');
       state=STATE_HEX;
       hasValue=YES;
      }
      else if(unicode>='a' && unicode<='f'){
       value=value*16+(unicode-'a')+10;
       state=STATE_HEX;
       hasValue=YES;
      }
      else if(unicode>='A' && unicode<='F'){
       value=value*16+(unicode-'A')+10;
       state=STATE_HEX;
       hasValue=YES;
      }
      else
       return NO;
      break;
      
     case STATE_ZERO:
      state=STATE_HEX;
      if(unicode=='x' || unicode=='X')
       break;
      // fallthrough
     case STATE_HEX:
      if(unicode>='0' && unicode<='9'){
       if(!overflow){
        unsigned check=value*16+(unicode-'0');
        if(check>=value)
         value=check;
        else {
         value=-1;
         overflow=YES;
        }
       }
      }
      else if(unicode>='a' && unicode<='f'){
       if(!overflow){
        unsigned check=value*16+(unicode-'a')+10;
        if(check>=value)
         value=check;
        else {
         value=-1;
         overflow=YES;
        }
       }
      }
      else if(unicode>='A' && unicode<='F'){
       if(!overflow){
        unsigned check=value*16+(unicode-'A')+10;
        
        if(check>=value)
         value=check;
        else {
         value=-1;
         overflow=YES;
        }
       }
      }
      else {
       if(valuep!=NULL)
        *valuep=value;
        
       return YES;
      }
      break;
    }
   }
   
   if(hasValue){
    if(valuep!=NULL)
     *valuep=value;
     
    return YES;
   }
    
   return NO;
}

-(BOOL)scanHexLongLong:(unsigned long long *)valuep {
   enum {
		STATE_SPACE,
		STATE_ZERO,
		STATE_HEX,
   } state=STATE_SPACE;
   unsigned long long value=0;
   BOOL     hasValue=NO;
   BOOL     overflow=NO;
   
   for(;_location<[_string length];_location++){
		unichar unicode=[_string characterAtIndex:_location];
		
		switch(state){
				
			case STATE_SPACE:
				if([_skipSet characterIsMember:unicode])
					state=STATE_SPACE;
				else if(unicode == '0'){
					state=STATE_ZERO;
					hasValue=YES;
				}
				else if(unicode>='1' && unicode<='9'){
					value=value*16+(unicode-'0');
					state=STATE_HEX;
					hasValue=YES;
				}
				else if(unicode>='a' && unicode<='f'){
					value=value*16+(unicode-'a')+10;
					state=STATE_HEX;
					hasValue=YES;
				}
				else if(unicode>='A' && unicode<='F'){
					value=value*16+(unicode-'A')+10;
					state=STATE_HEX;
					hasValue=YES;
				}
				else
					return NO;
				break;
				
			case STATE_ZERO:
				state=STATE_HEX;
				if(unicode=='x' || unicode=='X')
					break;
				// fallthrough
			case STATE_HEX:
				if(unicode>='0' && unicode<='9'){
					if(!overflow){
						unsigned check=value*16+(unicode-'0');
						if(check>=value)
							value=check;
						else {
							value=-1;
							overflow=YES;
						}
					}
				}
				else if(unicode>='a' && unicode<='f'){
					if(!overflow){
						unsigned check=value*16+(unicode-'a')+10;
						if(check>=value)
							value=check;
						else {
							value=-1;
							overflow=YES;
						}
					}
				}
				else if(unicode>='A' && unicode<='F'){
					if(!overflow){
						unsigned check=value*16+(unicode-'A')+10;
						
						if(check>=value)
							value=check;
						else {
							value=-1;
							overflow=YES;
						}
					}
				}
				else {
					if(valuep!=NULL)
						*valuep=value;
					
					return YES;
				}
				break;
		}
   }
   
   if(hasValue){
		if(valuep!=NULL)
			*valuep=value;
		
		return YES;
   }
	
   return NO;
}


-(BOOL)scanString:(NSString *)string intoString:(NSString **)stringp {
    NSInteger length=[_string length];
    NSStringCompareOptions compareOption = 0;
    NSRange range = {0,[string length]};
    NSInteger oldLocation =_location;
    
    BOOL result = NO;
    
    if(!_isCaseSensitive) {
        compareOption = NSCaseInsensitiveSearch;
    }
    
    for(;_location<length;_location++) {
        unichar     unicode=[_string characterAtIndex:_location];
        NSString    *subStr = [_string substringFromIndex:_location];
        if([subStr length] < [string length]) {
            result = NO;
            break;
        }
        
        if([_skipSet characterIsMember:unicode] == YES) 
        {
            continue;
        }
        if ([subStr compare:string options:compareOption range:range] == NSOrderedSame) {
            if (stringp != NULL)
                *stringp = string;
            
            _location += [string length];
            result = YES;
            break;
        } 
        else {
            result = NO;
            break;
        }

    }
    
    if(result == NO) {
        _location = oldLocation;
    }
    
    return result;
}

-(BOOL)scanUpToString:(NSString *)string intoString:(NSString **)stringp {
    NSInteger length=[_string length];
    unichar result[length];
    int resultLength = 0;
    BOOL scanStarted = NO;
    NSStringCompareOptions compareOption = 0;
    NSRange range = {0,[string length]};
    NSInteger oldLocation =_location;
    
    if(!_isCaseSensitive) {
        compareOption = NSCaseInsensitiveSearch;
    }

    for(;_location<length;_location++) {
        unichar unicode=[_string characterAtIndex:_location];
        NSString    *subStr = [_string substringFromIndex:_location];
        
        if([subStr length] < [string length]) {
            _location = oldLocation;  
            return NO;
        } 
        if ([subStr compare:string options:compareOption range:range] == NSOrderedSame) {
            if (scanStarted) {
                if (stringp != NULL)
                    *stringp = [NSString stringWithCharacters:result length:resultLength];

                return YES;
            } else {
                return NO;
            }
        }
        else if ([_skipSet characterIsMember:unicode] && scanStarted == NO)
            continue;
        else {
            scanStarted = YES;
            result[resultLength++] = unicode;
        }
    }

    if (resultLength > 0) {
        if (stringp != NULL)
            *stringp = [NSString stringWithCharacters:result length:resultLength];

        return YES;
    }
    else {
        _location = oldLocation;  
        return NO;
    }
}

-(BOOL)scanCharactersFromSet:(NSCharacterSet *)charset intoString:(NSString **)stringp
{
    NSInteger length=[_string length];
    unichar result[length];
    int resultLength = 0;
    BOOL scanStarted = NO;

    for(;_location<length;_location++)
		{
		unichar unicode=[_string characterAtIndex:_location];

		if ([_skipSet characterIsMember:unicode] && (scanStarted == NO))
			{
			// do nothing
			}
		else
			{
			if ([charset characterIsMember: unicode])
				{
				scanStarted = YES;
				result[resultLength++] = unicode;
				}
			else
				{
				break; // used to be "return NO";
				}
			}
		}

    if (scanStarted)
		{
                if (stringp != NULL)
			{
			*stringp = [NSString stringWithCharacters:result length:resultLength];
			}
		}
	return scanStarted;
}

-(BOOL)scanUpToCharactersFromSet:(NSCharacterSet *)charset intoString:(NSString **)stringp {
    NSInteger length=[_string length];
    unichar result[length];
    int resultLength = 0;
    BOOL scanStarted = NO;
    NSInteger oldLocation =_location;
    
    for(;_location<length;_location++) {
        unichar unicode=[_string characterAtIndex:_location];
        
        if ([_skipSet characterIsMember:unicode] && scanStarted == NO)
            continue;
        else if ([charset characterIsMember:unicode])
            break;
        else {
            scanStarted = YES;
            result[resultLength++] = unicode;
        }
    }
    
    if (resultLength > 0) {
        if (stringp != NULL)
            *stringp = [NSString stringWithCharacters:result length:resultLength];
        
        return YES;
    }
    else {
        _location = oldLocation;
        
        return NO;
    }
}

@end
