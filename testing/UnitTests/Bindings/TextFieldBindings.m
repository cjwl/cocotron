//
//  TextFieldBindings.m
//  UnitTests
//
//  Created by Johannes Fortmann on 25.01.09.
//  Copyright 2009 -. All rights reserved.
//

#import "TextFieldBindings.h"


@implementation TextFieldBindings
@synthesize textFieldContents=_textFieldContents;

-(void)setTextFieldContents:(NSString*)value {
   if(value!=_textFieldContents) {
      NSLog(@"set to %@", value);
      [_textFieldContents release];
      _textFieldContents=[value retain];
   }   
}

-(void)dealloc {
   [_textFieldContents release];
   [super dealloc];
}

-(void)setUp {
   id nib = [[NSNib alloc] initWithNibNamed:[self className] bundle:[NSBundle bundleForClass:isa]];
   
   [nib instantiateNibWithOwner:self topLevelObjects:&_topLevelObjects];
   [_topLevelObjects retain];
   
   [nib release];
}

-(void)testManualSetting {
   self.textFieldContents=@"Test";
   [_textField setStringValue:@"NotTest"];
   
   STAssertEqualObjects([_textField objectValue], @"NotTest", nil);
   STAssertEqualObjects(self.textFieldContents, @"Test", @"Binding shouldn't be influenced by setStringValue");
}

-(void)testBindingSetting {
   self.textFieldContents=@"Test2";
   
   STAssertEqualObjects([_textField stringValue], @"Test2blah", nil);
   STAssertEqualObjects(_textFieldContents, @"Test2", nil);
}

-(void)tearDown {
   [_topLevelObjects release];
   _topLevelObjects=nil;
}
@end
