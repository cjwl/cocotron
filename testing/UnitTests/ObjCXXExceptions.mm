/* Copyright (c) 2008 Johannes Fortmann
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#include <string>
#include <vector>

#import "ObjCXXExceptions.h"

@implementation ObjCXXExceptions
-(void)throwObjCException
{
   [NSException raise:NSInvalidArgumentException format:nil];
}

-(void)throwCXXException
{
   throw(std::string("c++ exception"));
}

-(void)testCXXThrow
{
   try {
      @try {
         [self throwCXXException];
      }
      @catch(id e) {
         STFail(@"objc exception caught");         
      }      
   }
   catch(std::vector<std::string> vec) {
      STFail(@"wrong type caught");
   }
   catch(std::string str) {
      STAssertTrue(str == std::string("c++ exception"), nil);
      return;
   }
   STFail(@"nothing caught");
}

-(void)testObjCThrow
{
   @try {
      try {
         [self throwObjCException];
      }
      catch(void* ex) {
         STFail(@"C++ exception caught");         
      }
   }
   @catch(NSString *str) {
      STFail(@"wrong type caught");
   }
   @catch(NSException *ex) {
      return;
   }
   STFail(@"nothing caught");
}

@end
