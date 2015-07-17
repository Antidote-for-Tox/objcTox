//
//  OCTCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"
#import "OCTToxAVConstants.h"

@interface OCTCall ()

@end

@implementation OCTCall

- (BOOL)isOutgoing
{
    return (self.caller == nil);
}

- (NSDate *)onHoldDate
{
    if (self.onHoldStartInterval <= 0) {
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970:self.onHoldStartInterval];
}

@end
