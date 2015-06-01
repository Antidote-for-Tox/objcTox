//
//  OCTDBMessageCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/14/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageCall.h"

@implementation OCTDBMessageCall

- (instancetype)initWithMessageCall:(OCTMessageCall *)call
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.callDuration = call.callDuration;
    return self;
}

@end
