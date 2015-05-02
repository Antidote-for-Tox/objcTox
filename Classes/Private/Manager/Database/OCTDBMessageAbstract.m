//
//  OCTDBMessageAbstract.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageAbstract.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTMessageText.h"
#import "OCTMessageFile.h"
#import "OCTFriend+Private.h"

@implementation OCTDBMessageAbstract

- (instancetype)initWithMessageAbstract:(OCTMessageAbstract *)message realm:(RLMRealm *)realm
{
    NSParameterAssert(message);
    NSParameterAssert(realm);

    self = [super init];

    if (! self) {
        return nil;
    }

    self.dateInterval = [message.date timeIntervalSince1970];
    self.isOutgoing = message.isOutgoing;
    self.sender = [OCTDBFriend findOrCreateFriendInRealm:realm withFriendNumber:message.sender.friendNumber];

    if ([message isKindOfClass:[OCTMessageText class]]) {
        self.textMessage = [[OCTDBMessageText alloc] initWithMessageText:(OCTMessageText *)message];
    }
    else if ([message isKindOfClass:[OCTMessageFile class]]) {
        self.fileMessage = [[OCTDBMessageFile alloc] initWithMessageFile:(OCTMessageFile *)message];
    }

    return self;
}

- (OCTMessageAbstract *)message
{
    OCTMessageAbstract *message;

    if (self.textMessage) {
        message = [OCTMessageText new];

        [self.textMessage fillMessage:(OCTMessageText *)message];
    }
    else if (self.fileMessage) {
        message = [OCTMessageFile new];

        [self.fileMessage fillMessage:(OCTMessageFile *)message];
    }

    message.date = [NSDate dateWithTimeIntervalSince1970:self.dateInterval];
    message.isOutgoing = self.isOutgoing;
    message.sender = [OCTFriend new];
    message.sender.friendNumber = (OCTToxFriendNumber)self.sender.friendNumber;

    return message;
}

@end
