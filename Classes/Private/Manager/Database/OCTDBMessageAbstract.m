//
//  OCTDBMessageAbstract.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageAbstract.h"

@implementation OCTDBMessageAbstract

- (instancetype)initWithMessageAbstract:(OCTMessageAbstract *)message
{
    NSParameterAssert(message);

    self = [super init];

    if (! self) {
        return nil;
    }

    self.dateInterval = [message.date timeIntervalSince1970];
    self.isOutgoing = message.isOutgoing;
    self.senderFriendNumber = message.sender.friendNumber;

    return self;
}

@end
