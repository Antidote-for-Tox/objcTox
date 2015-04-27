//
//  OCTDBMessageFile.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageFile.h"
#import "OCTMessageFile+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTFriend+Private.h"

@implementation OCTDBMessageFile

- (instancetype)initWithMessageFile:(OCTMessageFile *)message realm:(RLMRealm *)realm
{
    self = [super initWithMessageAbstract:message realm:realm];

    if (! self) {
        return nil;
    }

    self.fileType = message.fileType;
    self.fileSize = message.fileSize;
    self.fileName = message.fileName;
    self.filePath = message.filePath;
    self.fileUTI = message.fileUTI;

    return self;
}

- (OCTMessageFile *)message
{
    OCTMessageFile *message = [OCTMessageFile new];

    message.date = [NSDate dateWithTimeIntervalSince1970:self.dateInterval];
    message.isOutgoing = self.isOutgoing;
    message.sender = [OCTFriend new];
    message.sender.friendNumber = (OCTToxFriendNumber)self.sender.friendNumber;

    message.fileType = self.fileType;
    message.fileSize = self.fileSize;
    message.fileName = self.fileName;
    message.filePath = self.filePath;
    message.fileUTI = self.fileUTI;

    return message;
}

@end
