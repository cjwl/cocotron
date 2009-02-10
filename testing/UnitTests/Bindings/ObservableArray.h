//
//  ObservableArray.h
//  UnitTests
//
//  Created by Johannes Fortmann on 10.02.09.
//  Copyright 2009 -. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface _NSObservableArray : NSMutableArray
-(void)setROI:(id)roi;
@end

@interface ObservableArray : SenTestCase {
   _NSObservableArray *_array;
   id _lastObservedKey;
}
@property (copy) NSString* lastObservedKey;
@end
