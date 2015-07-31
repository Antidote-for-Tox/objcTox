//
//  OCTCall+Private.m
//  objcTox
//
//  Created by Chuong Vu on 7/31/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall+Private.h"

@implementation OCTCall (Private)

- (BOOL)isPaused
{
    return ! (self.pausedStatus == OCTCallPausedStatusNone);
}

@end
