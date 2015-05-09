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

- (instancetype)initWithMessageAbstract:(OCTMessageAbstract *)message sender:(OCTDBFriend *)sender
{
    NSParameterAssert(message);
    NSParameterAssert(sender);

    self = [super init];

    if (! self) {
        return nil;
    }

    self.dateInterval = [message.date timeIntervalSince1970];
    self.isOutgoing = message.isOutgoing;
    self.sender = sender;

    if ([message isKindOfClass:[OCTMessageText class]]) {
        self.textMessage = [[OCTDBMessageText alloc] initWithMessageText:(OCTMessageText *)message];
    }
    else if ([message isKindOfClass:[OCTMessageFile class]]) {
        self.fileMessage = [[OCTDBMessageFile alloc] initWithMessageFile:(OCTMessageFile *)message];
    }

    return self;
}

@end
