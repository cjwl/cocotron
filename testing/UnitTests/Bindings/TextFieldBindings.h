//
//  TextFieldBindings.h
//  UnitTests
//
//  Created by Johannes Fortmann on 25.01.09.
//  Copyright 2009 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <AppKit/AppKit.h>

@interface TextFieldBindings : SenTestCase {
   NSArray* _topLevelObjects;
   id IBOutlet _textField;
   id _textFieldContents;
}
@property (copy) NSString *textFieldContents;

@end
