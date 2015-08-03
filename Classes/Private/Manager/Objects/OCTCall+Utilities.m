//
//  OCTCall+Utilities.m
//  objcTox
//
//  Created by Chuong Vu on 8/3/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall+Utilities.h"

@implementation OCTCall (Utilities)

- (BOOL)isPaused
{
    return (self.pausedStatus != OCTCallPausedStatusNone);
}

@end
