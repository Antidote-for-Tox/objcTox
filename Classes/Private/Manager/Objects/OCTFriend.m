//
//  OCTFriend.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 10.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriend.h"

@interface OCTFriend ()

@property (assign, nonatomic, readwrite) OCTToxFriendNumber friendNumber;
@property (copy, nonatomic, readwrite) NSString *publicKey;
@property (copy, nonatomic, readwrite) NSString *name;
@property (copy, nonatomic, readwrite) NSString *statusMessage;
@property (assign, nonatomic, readwrite) OCTToxUserStatus status;
@property (assign, nonatomic, readwrite) OCTToxConnectionStatus connectionStatus;
@property (strong, nonatomic, readwrite) NSDate *lastSeenOnline;
@property (assign, nonatomic, readwrite) BOOL isTyping;

@property (copy, nonatomic) void (^nicknameUpdateBlock)(NSString *nickname);

@end

@implementation OCTFriend

#pragma mark -  Properties

- (void)setNickname:(NSString *)nickname
{
    _nickname = nickname;

    if (self.nicknameUpdateBlock) {
        self.nicknameUpdateBlock(nickname);
    }
}

#pragma mark -  Public

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTFriend with friendNumber %u, name %@", self.friendNumber, self.name];
}

@end
