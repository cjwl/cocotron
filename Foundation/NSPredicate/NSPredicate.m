/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <Foundation/NSPredicate.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSRaise.h>
#import "NSPredicate_BOOL.h"

#define LF 10
#define FF 12
#define CR 13

enum {
 predTokenEOF=-1,
 
 predToken_AND=1,
 predToken_OR,
 predToken_IN,
 predToken_NOT,
 predToken_ALL,
 predToken_ANY,
 predToken_NONE,
 predToken_LIKE,
 predToken_CASEINSENSITIVE,
 predToken_CI,
 predToken_MATCHES,
 predToken_CONTAINS,
 predToken_BEGINSWITH,
 predToken_ENDSWITH,
 predToken_BETWEEN,
 predToken_NULL,
 predToken_SELF,
 predToken_TRUE,
 predToken_FALSE,
 predToken_FIRST,
 predToken_LAST,
 predToken_SIZE,
 predToken_ANYKEY,
 predToken_SUBQUERY,
 predToken_CAST,
 predToken_TRUEPREDICATE,
 predToken_FALSEPREDICATE,
 
 predTokenIdentifier,
 predTokenString,
 predTokenReservedWord,
 predTokenNumeric,
 
 predTokenNotEqual,
 predTokenLessThan='<',
 predTokenGreaterThan='>',
 predTokenLessThanOrEqual,
 predTokenGreaterThanOrEqual,
 predTokenColonEqual,
 
 predTokenEqual='=',
 predTokenLeftParen='(',
 predTokenRightParen=')',
 predTokenLeftBracket='[',
 predTokenRightBracket=']',
 predTokenLeftBrace='{',
 predTokenRightBrace='}',
 
 predTokenPercent='%',
 predTokenDollar='$',
 predTokenAtSign='@',
 predTokenPeriod='.',
 predTokenComma=',',
 predTokenPlus='+',
 predTokenMinus='-',
 predTokenAsterisk='*',
 predTokenSlash='/',
 predTokenExclamation='!',
 predTokenAsteriskAsterisk,
};

typedef struct {
   NSString *original;
   unichar *unicode;
   int      length;
   int      position;
   BOOL     isArgumentArray;
   union {
    va_list  arguments;
    NSArray *argumentArray;
   };
} predicateScanner;

static void raiseError(predicateScanner *scanner,NSString *format,...){
   NSString *reason;
   va_list   arguments;

   va_start(arguments,format);
   
   reason=[[[NSString alloc] initWithFormat:format arguments:arguments] autorelease];
   
   [NSException raise:NSInvalidArgumentException format:@"Unable to parse the format string \"%@\", reason = %@",scanner->original,reason];
}

static int classifyToken(NSString *token){
   struct {
    NSString *name;
    int       type;
   } table[]={
    { @"AND", predToken_AND },
    { @"OR", predToken_OR },
    { @"IN", predToken_IN },
    { @"NOT", predToken_NOT },
    { @"ALL", predToken_ALL },
    { @"ANY", predToken_ANY },
    { @"SOME", predToken_ANY },
    { @"NONE", predToken_NONE },
    { @"LIKE", predToken_LIKE },
    { @"CASEINSENSITIVE", predToken_CASEINSENSITIVE },
    { @"CI", predToken_CI },
    { @"MATCHES", predToken_MATCHES },
    { @"CONTAINS", predToken_CONTAINS },
    { @"BEGINSWITH", predToken_BEGINSWITH },
    { @"ENDSWITH", predToken_ENDSWITH },
    { @"BETWEEN", predToken_BETWEEN },
    { @"NULL", predToken_NULL },
    { @"NIL", predToken_NULL },
    { @"SELF", predToken_SELF },
    { @"TRUE", predToken_TRUE },
    { @"YES", predToken_TRUE },
    { @"FALSE", predToken_FALSE },
    { @"NO", predToken_FALSE },
    { @"FIRST", predToken_FIRST },
    { @"LAST", predToken_LAST },
    { @"SIZE", predToken_SIZE },
    { @"ANYKEY", predToken_ANYKEY },
    { @"SUBQUERY", predToken_SUBQUERY },
    { @"CAST", predToken_CAST },
    { @"TRUEPREDICATE", predToken_TRUEPREDICATE },
    { @"FALSEPREDICATE", predToken_FALSEPREDICATE },
    nil,0
   };
   int i;
   
   for(i=0;table[i].name!=nil;i++)
    if([table[i].name isEqualToString:token])
     return table[i].type;
     
   return predTokenIdentifier;
}

static int scanToken(predicateScanner *scanner,id *token){
   int   currentSign=1,currentInt=0;
   float currentReal=0,currentFraction=0;
   BOOL  identifyReservedWords=YES;
   int   identifierLocation=0;
   auto enum {
    STATE_SCANNING,
    STATE_IDENTIFIER,
    STATE_ESCAPED_IDENTIFIER,
    STATE_INTEGER,
    STATE_REAL,
    STATE_EXPONENT,
    STATE_HEX_SEQUENCE,
    STATE_OCTAL_SEQUENCE,
    STATE_BINARY_SEQUENCE,
    
    STATE_STRING_DOUBLE,
    STATE_STRING_SINGLE,
    
    STATE_EQUALS,
    STATE_EXCLAMATION,
    
    STATE_LESSTHAN,
    STATE_GREATERTHAN,
    STATE_COLON,
    STATE_AMPERSAND,
    STATE_BAR,
    STATE_ASTERISK,
   } state=STATE_SCANNING;
   
   *token=nil;
   
   for(;scanner->position<=scanner->length;scanner->position++){
    unichar code=(scanner->position<scanner->length)?scanner->unicode[scanner->position]:0xFFFF;
    
    switch(state){
    
	 case STATE_SCANNING:
      switch(code){

	   case ' ':
	   case  CR:
	   case  FF:
	   case  LF:
	   case '\t':
	    break;
        
       case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H': case 'I':
       case 'J': case 'K': case 'L': case 'M': case 'N': case 'O': case 'P': case 'Q': case 'R':
       case 'S': case 'T': case 'U': case 'V': case 'W': case 'X': case 'Y': case 'Z':
       case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': case 'h': case 'i':
       case 'j': case 'k': case 'l': case 'm': case 'n': case 'o': case 'p': case 'q': case 'r':
       case 's': case 't': case 'u': case 'v': case 'w': case 'x': case 'y': case 'z':
       case '_':
        state=STATE_IDENTIFIER;
        identifierLocation=scanner->position;
        break;
        
       case '0': case '1': case '2': case '3': case '4':
       case '5': case '6': case '7': case '8': case '9':
        state=STATE_INTEGER;
	    currentSign=1;
	    currentInt=code-'0';
        break;

       case '(':
       case ')':
       case '[':
       case ']':
       case '%':
       case '$':
       case '@':
       case '.':
       case '+':
        scanner->position++;
        return code;
       
       case '=':
        state=STATE_EQUALS;
        break;
        
       case '!':
        state=STATE_EXCLAMATION;
        break;
        
       case '<':
        state=STATE_LESSTHAN;
        break;
        
       case '>':
        state=STATE_GREATERTHAN;
        break;
        
       case ':':
        state=STATE_COLON;
        break;
       
       case '&':
        state=STATE_AMPERSAND;
        break;
        
       case '|':
        state=STATE_BAR;
        break;
        
       case '*':
        state=STATE_ASTERISK;
        break;

       case '#':
        state=STATE_ESCAPED_IDENTIFIER;
        break;
        
       case '\"':
        state=STATE_STRING_DOUBLE;
        break;
        
       case '\'':
        state=STATE_STRING_SINGLE;
        break;
      }
      break;
      
     case STATE_IDENTIFIER:
      switch(code){
      
       case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H': case 'I':
       case 'J': case 'K': case 'L': case 'M': case 'N': case 'O': case 'P': case 'Q': case 'R':
       case 'S': case 'T': case 'U': case 'V': case 'W': case 'X': case 'Y': case 'Z':
       case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': case 'h': case 'i':
       case 'j': case 'k': case 'l': case 'm': case 'n': case 'o': case 'p': case 'q': case 'r':
       case 's': case 't': case 'u': case 'v': case 'w': case 'x': case 'y': case 'z':
       case '_':
       case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': 
        state=STATE_IDENTIFIER;
        break;
        
       default:
        *token=[NSString stringWithCharacters:scanner->unicode+identifierLocation length:(scanner->position-identifierLocation)];
        return identifyReservedWords?predTokenIdentifier:classifyToken(*token);
        return YES;
      }
      break;
 
     case STATE_ESCAPED_IDENTIFIER:
      switch(code){
       case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H': case 'I':
       case 'J': case 'K': case 'L': case 'M': case 'N': case 'O': case 'P': case 'Q': case 'R':
       case 'S': case 'T': case 'U': case 'V': case 'W': case 'X': case 'Y': case 'Z':
       case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': case 'h': case 'i':
       case 'j': case 'k': case 'l': case 'm': case 'n': case 'o': case 'p': case 'q': case 'r':
       case 's': case 't': case 'u': case 'v': case 'w': case 'x': case 'y': case 'z':
       case '_':
        state=STATE_IDENTIFIER;
        identifyReservedWords=NO;
        identifierLocation=scanner->position;
        break;
        
       default:
        raiseError(scanner,@"Expecting identifier after #");
        break;
      }
      break;

     case STATE_INTEGER:
      if(code=='.'){
       state=STATE_REAL;
       currentReal=currentInt;
       currentFraction=0.1;
      }
      else if(code=='e')
       state=STATE_EXPONENT;
      else if(code>='0' && code<='9')
       currentInt=currentInt*10+code-'0';
      else if(code=='x')
       state=STATE_HEX_SEQUENCE;
      else if(code=='o')
       state=STATE_OCTAL_SEQUENCE;
      else if(code=='b')
       state=STATE_BINARY_SEQUENCE;
      else {
       *token=[NSNumber numberWithInt:currentSign*currentInt];
       return predTokenNumeric;
      }
      break;

     case STATE_REAL:
      if(code>='0' && code<='9'){
       currentReal+=currentFraction*(code-'0');
       currentFraction*=0.1;
      }
      else if(code=='e'){
       state=STATE_EXPONENT;
      }
      else {
       *token=[NSNumber numberWithFloat:currentSign*currentReal];
       return predTokenNumeric;
      }
      break;

     case STATE_STRING_DOUBLE:
      break;

     case STATE_STRING_SINGLE:
      break;

     case STATE_EQUALS:
      if(code=='='){
       scanner->position++;
       return  predTokenEqual;
      }
      if(code=='<'){
       scanner->position++;
       return  predTokenGreaterThanOrEqual;
      }
      if(code=='>'){
       scanner->position++;
       return  predTokenLessThanOrEqual;
      }
      return predTokenEqual;
        
     case STATE_EXCLAMATION:
      if(code=='='){
       scanner->position++;
       return  predTokenNotEqual;
      }
      return predTokenExclamation;
        
     case STATE_LESSTHAN:
      if(code=='='){
       scanner->position++;
       return  predTokenLessThanOrEqual;
      }
      if(code=='>'){
       scanner->position++;
       return  predTokenNotEqual;
      }
      return predTokenLessThan;
        
     case STATE_GREATERTHAN:
      if(code=='='){
       scanner->position++;
       return  predTokenGreaterThanOrEqual;
      }
      return predTokenGreaterThan;

     case STATE_COLON:
      if(code=='='){
       scanner->position++;
       return  predTokenColonEqual;
      }
      raiseError(scanner,@"Expecting = after :");
      break;

     case STATE_AMPERSAND:
      if(code=='&'){
       scanner->position++;
       return  predToken_AND;
      }
      raiseError(scanner,@"Expecting & after &");
      break;
      
     case STATE_BAR:
      if(code=='|'){
       scanner->position++;
       return  predToken_OR;
      }
      raiseError(scanner,@"Expecting | after |");
      break;

     case STATE_ASTERISK:
      if(code=='*'){
       scanner->position++;
       return  predTokenAsteriskAsterisk;
      }
      return predTokenAsterisk;
    }
    
   }
   return predTokenEOF;
}

static int peekTokenType(predicateScanner *scanner){
   int save=scanner->position;
   id  token;
   int tokenType;
   
   tokenType=scanToken(scanner,&token);
   scanner->position=save;
   
   return tokenType;
}

static void skipToken(predicateScanner *scanner){
   id token;
   
   scanToken(scanner,&token);
}

static void expectTokenType(predicateScanner *scanner,int expect){
   id  token;
   int tokenType;

   if((tokenType=scanToken(scanner,&token))!=expect)
    raiseError(scanner,@"Expecting token type %d, got %d",expect,tokenType);   
}

static NSExpression *nextExpression(predicateScanner *scanner);
static NSPredicate *nextPredicate(predicateScanner *scanner);

static NSExpression *nextFunctionExpression(predicateScanner *scanner,NSString *name){
   NSMutableArray *arguments=[NSMutableArray array];
         
   while(peekTokenType(scanner)!=predTokenRightParen){       
    if([arguments count]>0){
     if(peekTokenType(scanner)==predTokenComma)
      skipToken(scanner);
    }
       
    [arguments addObject:nextExpression(scanner)];
   }
   skipToken(scanner);

   return [NSExpression expressionForFunction:name arguments:arguments];      
}

static NSExpression *nextPrimaryExpression(predicateScanner *scanner){
   id  token;
   int tokenType=scanToken(scanner,&token);
   
   switch(tokenType){
   
    case predTokenEOF:
     raiseError(scanner,@"Encountered EOF while parsing expression");
     break;
     
    case predTokenLeftParen:{
      auto NSExpression *result=nextExpression(scanner);
      
      expectTokenType(scanner,predTokenRightParen);
      
      return result;
     }
    
    case predTokenIdentifier:
     if(peekTokenType(scanner)!=predTokenLeftParen)
      return [NSExpression expressionForKeyPath:token];
      
     return nextFunctionExpression(scanner,token);
    
    case predTokenAtSign:
     skipToken(scanner);
     if((tokenType=scanToken(scanner,&token))!=predTokenIdentifier)
      raiseError(scanner,@"Expecting identifer after @ for keypath expression");

     return [NSExpression expressionForKeyPath:token];
     
    case predTokenString:
     return [NSExpression expressionForConstantValue:token];
   
    case predTokenNumeric:
     return [NSExpression expressionForConstantValue:token];
  
    case predTokenPercent:{
// format string
            
     }
     break;
  
    case predTokenDollar:{
      id  identifier;
      int identifierType;
      
      if((identifierType=scanToken(scanner,&identifier))!=predTokenIdentifier){
       NSLog(@"expecting identifier, got %@",identifier);
       return nil;
      }
      
      if(peekTokenType(scanner)!=predTokenColonEqual)
       return [NSExpression expressionForVariable:identifier];

      skipToken(scanner);
      return [NSExpression expressionForVariable:identifier assignment:nextExpression(scanner)];      
     }
     break;
    
    case predToken_NULL:
     return [NSExpression expressionForConstantValue:[NSNull null]];

    case predToken_TRUE:
     return [NSExpression expressionForConstantValue:[NSNumber numberWithBool:YES]];

    case predToken_FALSE:
      return [NSExpression expressionForConstantValue:[NSNumber numberWithBool:NO]];

    case predToken_SELF:
      return [NSExpression expressionForEvaluatedObject];
    
    case predTokenLeftBrace:{
      NSMutableArray *aggregate=[NSMutableArray array];
      
      while(peekTokenType(scanner)!=predTokenRightBrace){       
       if([aggregate count]>0){
        if(peekTokenType(scanner)==predTokenComma)
         skipToken(scanner);
       }
       
       [aggregate addObject:nextExpression(scanner)];
      }
      skipToken(scanner);
      
      return [NSExpression expressionForConstantValue:aggregate];
     }
     
   }
   
   return nil;
}

static NSExpression *nextKeypathExpression(predicateScanner *scanner){
   NSExpression *left=nextPrimaryExpression(scanner);
   
   do{
    switch(peekTokenType(scanner)){
    
     case predTokenPeriod:
      skipToken(scanner);
      left=[NSExpression expressionForFunction:@"." arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
      break;

     case predTokenLeftBracket:
      skipToken(scanner);

      switch(peekTokenType(scanner)){
   
       case predToken_FIRST:
        left=[NSExpression expressionForFunction:@"firstObject" arguments:[NSArray arrayWithObject:left]];
        break;
        
       case predToken_LAST:
        left=[NSExpression expressionForFunction:@"lastObject" arguments:[NSArray arrayWithObject:left]];
        break;

       case predToken_SIZE:
        left=[NSExpression expressionForFunction:@"count" arguments:[NSArray arrayWithObject:left]];
        break;
    
       default:
        left=[NSExpression expressionForFunction:@"objectAtIndex:" arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
        break;
      }
      expectTokenType(scanner,predTokenRightBracket);
      break;

     default:
      return left;
    }
    
   }while(YES);
}

static NSExpression *nextUnaryExpression(predicateScanner *scanner){
   if(peekTokenType(scanner)==predTokenMinus){
     skipToken(scanner);
     return [NSExpression expressionForFunction:@"negate" arguments:[NSArray arrayWithObject:nextUnaryExpression(scanner)]];
   }

   return nextKeypathExpression(scanner);
}

static NSExpression *nextExponentiationExpression(predicateScanner *scanner){
   NSExpression *left=nextUnaryExpression(scanner);
   
   do{
    switch(peekTokenType(scanner)){
    
     case predTokenAsteriskAsterisk:
      skipToken(scanner);
      left=[NSExpression expressionForFunction:@"**" arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
      break;

     default:
      return left;
    }
    
   }while(YES);
}

static NSExpression *nextMultiplicativeExpression(predicateScanner *scanner){
   NSExpression *left=nextExponentiationExpression(scanner);
   
   do{
    switch(peekTokenType(scanner)){
    
     case predTokenAsterisk:
      skipToken(scanner);
      left=[NSExpression expressionForFunction:@"*" arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
      break;

     case predTokenSlash:
      skipToken(scanner);
      left=[NSExpression expressionForFunction:@"/" arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
      break;

     default:
      return left;
    }
    
   }while(YES);
}

static NSExpression *nextAdditiveExpression(predicateScanner *scanner){
   NSExpression *left=nextMultiplicativeExpression(scanner);
   
   do{
    switch(peekTokenType(scanner)){
    
     case predTokenPlus:
      skipToken(scanner);
      left=[NSExpression expressionForFunction:@"+" arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
      break;

     case predTokenMinus:
      skipToken(scanner);
      left=[NSExpression expressionForFunction:@"-" arguments:[NSArray arrayWithObjects:left,nextExpression(scanner),nil]];
      break;

     default:
      return left;
    }
    
   }while(YES);
}

static NSExpression *nextExpression(predicateScanner *scanner){
   return nextAdditiveExpression(scanner);
}

static void nextOperationOption(predicateScanner *scanner,unsigned *options){
   id  token;
   int tokenType;
   
   if(peekTokenType(scanner)!=predTokenLeftBracket)
    return;
      
   if((tokenType=scanToken(scanner,&token))!=predTokenIdentifier)
    raiseError(scanner,@"Expecting identifier in options");
   
   if([token isEqualToString:@"c"]){
    *options=NSCaseInsensitivePredicateOption;
    return;
   }
   else if([token isEqualToString:@"d"]){
    *options=NSDiacriticInsensitivePredicateOption;
    return;
   }
   else if([token isEqualToString:@"cd"]){
    *options=NSCaseInsensitivePredicateOption|NSDiacriticInsensitivePredicateOption;
    return;
   }
   else {
    raiseError(scanner,@"Expecting c, d, or cd in string options");
   }
   
   expectTokenType(scanner,predTokenRightBracket);
}

static void nextOperation(predicateScanner *scanner,NSPredicateOperatorType *type,unsigned *options){   
   *options=0;
   
   switch(peekTokenType(scanner)){
   
    case predTokenEqual:
     skipToken(scanner);
     *type=NSEqualToPredicateOperatorType;
     break;
     
    case predTokenNotEqual:
     skipToken(scanner);
     *type=NSNotEqualToPredicateOperatorType;
     break;
     
    case predTokenLessThan:
     skipToken(scanner);
     *type=NSLessThanPredicateOperatorType;
     break;

    case predTokenGreaterThan:
     skipToken(scanner);
     *type=NSGreaterThanPredicateOperatorType;
     break;

    case predTokenLessThanOrEqual:
     skipToken(scanner);
     *type=NSLessThanOrEqualToPredicateOperatorType;
     break;

    case predTokenGreaterThanOrEqual:
     skipToken(scanner);
     *type=NSGreaterThanOrEqualToPredicateOperatorType;
     break;

    case predToken_BETWEEN:
     skipToken(scanner);
     //*type=FIX
     break;

    case predToken_CONTAINS:
     skipToken(scanner);
     //*type=FIX
     nextOperationOption(scanner,options);
     break;
     
    case predToken_IN:
     skipToken(scanner);
     //*type=FIX
     nextOperationOption(scanner,options);
     break;

    case predToken_BEGINSWITH:
     skipToken(scanner);
     *type=NSBeginsWithPredicateOperatorType;
     nextOperationOption(scanner,options);
     break;
     
    case predToken_ENDSWITH:
     skipToken(scanner);
     *type=NSEndsWithPredicateOperatorType;
     nextOperationOption(scanner,options);
     break;

    case predToken_LIKE:
     skipToken(scanner);
     *type=NSLikePredicateOperatorType;
     nextOperationOption(scanner,options);
     break;

    case predToken_MATCHES:
     skipToken(scanner);
     *type=NSMatchesPredicateOperatorType;
     nextOperationOption(scanner,options);
     break;
   }
      
}

static NSPredicate *nextComparisonPredicate(predicateScanner *scanner){
   NSComparisonPredicateModifier modifier=NSDirectPredicateModifier;
   BOOL negate=NO;
   
   switch(peekTokenType(scanner)){
   
    case predToken_ANY:
     skipToken(scanner);
     modifier=NSAnyPredicateModifier;
     break;
     
    case predToken_ALL:
     skipToken(scanner);
     modifier=NSAllPredicateModifier;
     break;
     
    case predToken_NONE:
     skipToken(scanner);
     modifier=NSAnyPredicateModifier;
     negate=YES;
     break;
  }
  
  {
   NSExpression *left=nextExpression(scanner);
   NSExpression *right;
   NSPredicate  *result;
   NSPredicateOperatorType type;
   auto unsigned options;
    
   nextOperation(scanner,&type,&options);
   right=nextExpression(scanner);
      
   result=[NSComparisonPredicate predicateWithLeftExpression:left rightExpression:right modifier:modifier type:type options:options];
   if(negate)
    result=[NSCompoundPredicate notPredicateWithSubpredicate:result];
   
   return result;
  }
}

static NSPredicate *nextPrimaryPredicate(predicateScanner *scanner){

   switch(peekTokenType(scanner)){
    case predToken_NOT:
     skipToken(scanner);
     return [NSCompoundPredicate notPredicateWithSubpredicate:nextPrimaryPredicate(scanner)];
     
    case predToken_TRUEPREDICATE:
     skipToken(scanner);
     return [NSPredicate predicateWithValue:YES];
     
    case predToken_FALSEPREDICATE:
     skipToken(scanner);
     return [NSPredicate predicateWithValue:NO];

    case predTokenLeftParen:{
      NSPredicate *result;
      
      skipToken(scanner);
      
      result=nextPredicate(scanner);
      
      expectTokenType(scanner,predTokenRightParen);
      
      return result;
     }
   }
   
   return nextComparisonPredicate(scanner);
}

static NSPredicate *nextConditionalAndPredicate(predicateScanner *scanner){
   NSPredicate *left=nextPrimaryPredicate(scanner);
   
   do{
    switch(peekTokenType(scanner)){
   
     case predToken_AND:
      skipToken(scanner);
      left=[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:left,nextPrimaryPredicate(scanner),nil]];
      break;
      
     default:
      return left;
    }
   }while(YES);
}

static NSPredicate *nextConditionalOrPredicate(predicateScanner *scanner){
   NSPredicate *left=nextConditionalAndPredicate(scanner);
   
   do{
    switch(peekTokenType(scanner)){
   
     case predToken_OR:
      skipToken(scanner);
      left=[NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:left,nextConditionalAndPredicate(scanner),nil]];
      break;
      
     default:
      return left;
    }
   }while(YES);
}

static NSPredicate *nextPredicate(predicateScanner *scanner){
   return nextConditionalOrPredicate(scanner);
}
 
@implementation NSPredicate

-initWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
   return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
   NSUnimplementedMethod();
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

+(NSPredicate *)predicateWithFormat:(NSString *)format arguments:(va_list)arguments {
   predicateScanner scanner;
   unsigned         length=[format length];
   unichar          buffer[length];
   
   [format getCharacters:buffer];

   scanner.original=format;
   scanner.unicode=buffer;
   scanner.length=length;
   scanner.position=0;
   scanner.isArgumentArray=NO;
   scanner.arguments=arguments;
   
   return nextPredicate(&scanner);
}

+(NSPredicate *)predicateWithFormat:(NSString *)format,... {
   va_list arguments;

   va_start(arguments,format);

   return [self predicateWithFormat:format arguments:arguments];
}

+(NSPredicate *)predicateWithFormat:(NSString *)format argumentArray:(NSArray *)arguments {
   predicateScanner scanner;
   unsigned         length=[format length];
   unichar          buffer[length];
   
   [format getCharacters:buffer];
   
   scanner.original=format;
   scanner.unicode=buffer;
   scanner.length=length;
   scanner.position=0;
   scanner.isArgumentArray=YES;
   scanner.argumentArray=arguments;
   
   return nextPredicate(&scanner);
}

+(NSPredicate *)predicateWithValue:(BOOL)value {
   return [[[NSPredicate_BOOL allocWithZone:NULL] initWithBool:value] autorelease];
}

-(NSString *)predicateFormat {
   return nil;
}

-(NSPredicate *)predicateWithSubstitutionVariables:(NSDictionary *)variables {
}

-(BOOL)evaluateObject:object {
   return NO;
}

@end
