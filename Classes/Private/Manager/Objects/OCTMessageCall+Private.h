//
//  OCTMessageCall+Private.h
//  objcTox
//
//  Created by Chuong Vu on 5/14/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageCall.h"

@interface OCTMessageCall (Private)

@property (assign, nonatomic, readwrite) NSTimeInterval callDuration;
@property (assign, nonatomic, readwrite) OCTMessageCallType callType;

@end
