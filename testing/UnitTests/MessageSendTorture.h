//
//  MessageSendTorture.h
//  UnitTests
//
//  Created by Johannes Fortmann on 23.09.08.
//  Copyright 2008 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface MessageSendTorture : SenTestCase {
   int _numFailures;
   int _numSuccesses;
}
-(void)callSelectors:(BOOL)msgSend;
@end
