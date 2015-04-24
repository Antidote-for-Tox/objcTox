//
//  OCTDBMessageText.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageText.h"
#import "OCTMessageText+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTFriend+Private.h"

@implementation OCTDBMessageText

- (instancetype)initWithMessageText:(OCTMessageText *)message
{
    self = [super initWithMessageAbstract:message];

    if (! self) {
        return nil;
    }

    self.text = message.text;
    self.isDelivered = message.isDelivered;

    return self;
}

- (OCTMessageText *)message
{
    OCTMessageText *message = [OCTMessageText new];

    message.date = [NSDate dateWithTimeIntervalSince1970:self.dateInterval];
    message.isOutgoing = self.isOutgoing;
    message.sender = [OCTFriend new];
    message.sender.friendNumber = (OCTToxFriendNumber)self.senderFriendNumber;

    message.text = self.text;
    message.isDelivered = self.isDelivered;

    return message;
}

@end
